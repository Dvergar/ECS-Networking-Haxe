package enh.macros;

import haxe.macro.Expr;
import haxe.macro.Context;


class SystemHelperMacro
{
    static public var metas:Array<Expr> = new Array();

    public static function getMetas(e:Expr) {
        switch(e.expr) { 
            case EMeta(rpc, link): // handle s 
                if(rpc.name == "addSystem")
                {
                    trace("addsystem FOUND !!! " + rpc);
                    trace("addsystem FOUND link !!! " + link);
                    trace("hep " + e);
                    metas.push(e);
                }
            case _: haxe.macro.ExprTools.iter(e, getMetas);
        }

    }

    #if macro
    public static function replaceMeta(systemClassName:String, meta:Expr, fields:Array<Field>):Array<Field>
    {
        var pos = Context.currentPos();
        var rootName:String = Context.getLocalClass().get().module;
        var systemInstanceName = systemClassName.substr(0, 1).toLowerCase() + systemClassName.substr(1);

        // ADD SYSTEM INSTANCE FIELD
        fields.insert(0, { kind : FVar(TPath({ name : systemClassName, pack : [], params : [] }),null), meta : [], name : systemInstanceName, doc : null, pos : pos, access : [APublic] });

        // REPLACE META
        var addSystemExpr = macro this.$systemInstanceName = this.addSystem($i{systemClassName});
        meta.expr = addSystemExpr.expr;

        return fields;
    }


    public static function _replaceMetas(fields:Array<Field>)
    {
        // GET METAS
        for(f in fields)
        {
            trace("fff " + f);

            if(f.name == "init")
            {
                switch(f.kind){
                    case FFun(fun):
                        getMetas(fun.expr);
                    default:
                }
            }
        }

        trace("mamoo " + metas);
        for(meta in metas)
        {
            switch(meta.expr)
            {
                case EMeta(m, {expr:EConst(CIdent(systemName)), pos:_}):
                    trace("dameta " + systemName);
                    fields = replaceMeta(systemName, meta, fields);
                default:

            }
        }

        for(f in fields)
        {
            trace("boo2 : " + new haxe.macro.Printer().printField(f));
        }

        return fields;
    }
    #end
    macro static public function replaceMetas():Array<Field>
    {

        trace("SystemHelperMacro ");
        var fields = Context.getBuildFields();

        _replaceMetas(fields);

        return fields;
    }
}