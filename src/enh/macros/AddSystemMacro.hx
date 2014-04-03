package enh.macros;

import haxe.macro.Expr;
import haxe.macro.Context;


class AddSystemMacro
{
    #if macro
    public static function replaceMeta(systemClassName:String, meta:Expr,
                                       fields:Array<Field>):Array<Field>
    {
        var pos = Context.currentPos();
        var systemInstanceName = systemClassName.substr(0, 1).toLowerCase()
                                 + systemClassName.substr(1);

        // ADD SYSTEM INSTANCE FIELD
        fields.insert(0, {kind:FVar(TPath({name: systemClassName,
                                           pack: [],
                                           params: []}), null),
                                                meta: [],
                                                name: systemInstanceName,
                                                doc: null,
                                                pos: pos,
                                                access: [APublic]});

        // REPLACE META
        var addSystemExpr = macro this.$systemInstanceName
                            = this.addSystem($i{systemClassName});
        meta.expr = addSystemExpr.expr;

        return fields;
    }

    public static function _replaceMetas(fields:Array<Field>):Array<Field>
    {
        // GET METAS
        var metas:Array<Expr> = new Array();
        function getMetas(e:Expr)
        {
            switch(e.expr)
            { 
                case EMeta(rpc, link):
                    if(rpc.name == "addSystem")
                        metas.push(e);
                case _: haxe.macro.ExprTools.iter(e, getMetas);
            }
        }

        for(f in fields)
        {
            switch(f.kind){
                case FFun(fun):
                    getMetas(fun.expr);
                default:
            }
        }

        // REPLACE METAS
        for(meta in metas)
        {
            switch(meta.expr)
            {
                case EMeta(m, {expr:EConst(CIdent(systemName)), pos:_}):
                    // trace("Meta " + systemName);
                    fields = replaceMeta(systemName, meta, fields);
                default:

            }
        }

        // DEBUG
        // for(f in fields)
            // trace(new haxe.macro.Printer().printField(f));

        return fields;
    }
    #end

    macro static public function replaceMetas():Array<Field>
    {
        var fields = Context.getBuildFields();

        _replaceMetas(fields);

        return fields;
    }
}