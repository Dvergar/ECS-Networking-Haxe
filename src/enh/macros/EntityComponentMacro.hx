package enh.macros;

import haxe.macro.Expr;
import haxe.macro.Context;

import enh.macros.EventMacro;
import enh.Constants;


typedef NetworkVariable = {name:String, type:String, redirection:String};


class ComponentTemplate
{
    public var id:Int;
    public var name:String;
    public var sync:Bool;

    public function new(?name:String, ?id:Int)
    {
        this.name = name;
        this.id = id;
    }
}


class EntityTemplate
{
    public var id:Int;
    public var name:String;
    public var sync:Bool;
    public var components:Array<ComponentTemplate> = new Array();
    public var componentsIds:Array<Int> = new Array();
    public var syncComponentsIds:Array<Int> = new Array();

    public function new(?name:String, ?id:Int)
    {
        this.name = name;
        this.id = id;
    }
}


class EntityComponentMacro
{
    static public var componentIds:Int = -1;
    static public var entityIds:Int = -1;
    static public var netEntities:Array<EntityTemplate> = new Array();
    static public var netComponents:Array<ComponentTemplate> = new Array();

    static inline function toUpperCaseFirst(value:String):String
    {
        return value.charAt(0).toUpperCase() + value.substr(1).toLowerCase();
    }

    static inline function getComponentId():Int
    {
        componentIds++;
        return componentIds;
    }

    static inline function getEntityId():Int
    {
        entityIds++;
        return entityIds;
    }

    // BUILDS AN ENTITY->COMPONENT MAP
    macro static public function buildMap():Array<haxe.macro.Field>
    {
        trace("############# BUILDMAP #############");

        var fields = Context.getBuildFields();
        var cls = Context.getLocalClass().get();
        var pos = Context.currentPos();

        // RPC
        fields = RPCMacro._processRPCs(fields);

        // FOR EACH CLASS FIELD
        for (f in fields)
        {
            // IF META ON METHOD
            if(f.meta.length != 0)
            {
                // FOR EACH META
                for(m in f.meta)
                {
                    // IF META IS @NETWORKED
                    if(m.name == "networked")
                    {
                        var methodName = f.name;

                        // ASSIGN ID
                        var id = getEntityId();

                        var EntityTemplate = new EntityTemplate(methodName, id);
                        netEntities.push(EntityTemplate);

                        switch(f.kind)
                        {
                            case FFun(fun):
                                // FIND ALL ADDCOMPONENT
                                var components:Array<String> = [];
                                function findComponent(e:Expr)
                                {
                                    switch(e.expr) { 
                                        case ECall({expr:EField(_, "addComponent")},
                                                   [_, {expr:ENew(comp, _)}]):
                                            components.push(comp.name);

                                        case _: haxe.macro.ExprTools.iter(e, findComponent); 
                                    }
                                }
                                findComponent(fun.expr);

                                for(compName in components)
                                    EntityTemplate.components.push(new ComponentTemplate(compName));

                                // FIND SYNC COMPONENTS
                                components = [];
                                function findSyncComponent(e:Expr) { 
                                    switch(e.expr) { 
                                        case EMeta(a, b):
                                            trace("AAABBB " + a + " / " + b);
                                            // if(a.name == "sync")
                                                findComponent(e);

                                        case _: haxe.macro.ExprTools.iter(e, findSyncComponent); 
                                    }
                                }
                                findSyncComponent(fun.expr);

                                for(syncCompName in components)                             
                                    for(comp in EntityTemplate.components)
                                        if(comp.name == syncCompName)
                                            comp.sync = true;

                            default:
                        }

                        trace("\n\n#######\n\n");
                    }
                }
            }
        }

        var exprsFunctionByEntityName = []; // FUTURE
        var entityId = 0;

        for(entity in netEntities)
        {
            var fname = entity.name;
            exprsFunctionByEntityName.push({expr: EBinop(OpArrow, {expr: EConst(CString(fname)), pos: pos}, {expr: EConst(CIdent(fname)), pos: pos}), pos: pos});
            entityId++;
        }

        // DECLARATION ENTITYFUNCTIONSMAP
        if(exprsFunctionByEntityName.length != 0)
        {
            for(f in fields)
            {
                if(f.name == "new")
                {
                    switch(f.kind){
                        case FFun(fun):
                            switch(fun.expr.expr)
                            {
                                case EBlock(block):
                                    block.insert(0, {expr: EBinop(OpAssign, {expr: EConst(CIdent("functionByEntityName")), pos: pos},
                                                                            {expr: EArrayDecl(exprsFunctionByEntityName), pos: pos}),
                                                                  pos: pos});
                                default:
                            }

                        default:
                    }
                }
            }
        }

        // PRINTER SAMPLE
        for(f in fields)
        {
            // trace("humpf : " + new haxe.macro.Printer().printField(f));
        }

        haxe.macro.Context.onGenerate(function(types)
        {
            Context.addResource("netEntities", haxe.io.Bytes.ofString(haxe.Serializer.run(netEntities)));
            Context.addResource("netComponents", haxe.io.Bytes.ofString(haxe.Serializer.run(netComponents)));
        });

        return fields;
    }

    macro static public function buildComponent():Array<haxe.macro.Field>
    {
        var fields = Context.getBuildFields();
        var cls = Context.getLocalClass().get();
        var pos = Context.currentPos();

        // CHECK IF WE WANT TO SERIALIZE
        var networked = false;
        for(meta in Context.getLocalClass().get().meta.get())
        {
            if(meta.name == "networked") networked = true;
        }
        if(!networked) return fields;

        var componentName = cls.name;
        trace("component " + componentName + " / networked ? " + networked);

        // PROCESS EACH PARAMETER AND SAVE IT UP
        var networkVariables:Array<NetworkVariable> = new Array();
        for(f in fields)
        {
            if(f.meta.length != 0)
            {
                // META NET TYPES (can't be above because typemeta related to msgtypesmetas)
                for(m in f.meta)
                {
                    if(m.name == "short" ||
                       m.name == "int" ||
                       m.name == "float" ||
                       m.name == "bool" ||
                       m.name == "byte")
                    {
                        trace("m " + m);
                        // trace("added " + m.name + " / " + f.name);
                        var netVar:NetworkVariable = {name:f.name,
                                                      type:m.name,
                                                      redirection:null};

                        if(m.params.length != 0)
                        {
                            trace("param " + m.params[0].expr);
                            switch(m.params[0].expr)
                            {
                                case EConst(CString(redirection)):
                                    trace("redirection " + redirection);
                                    netVar.redirection = redirection;
                                case _:
                            }
                        }

                        networkVariables.push(netVar);
                    }
                    else
                    {
                        Context.error("Not a network type", pos);
                    }
                }
            }
        }

        trace("pre networkVariables : " + networkVariables);

        // ASSIGN COMPONENT ID
        var id = getComponentId();
        if(networked) netComponents.push(new ComponentTemplate(cls.name, id));

        // ADDS id to component object
        fields.push({kind: FVar(TPath({name: "Int", pack: [], params: [] }),
                                      {expr: EConst(CInt(Std.string(id))), pos : pos }),
                     meta: [], name: "_id", doc: null, pos: pos, access: [APublic] });

        // TODO context error if no netvariable is assigned
        if(networkVariables.length == 0) return fields; // TO TEST

        ////////////////////////////////////////
        // RETURN HERE PLEASE DONT FORGET HIM :'('
        ////////////////////////////////////////

        trace("networkVariables " + networkVariables);

        var inExprlist = [];
        var outExprlist = [];

        for(netVar in networkVariables)
        {
            var varNameOut = netVar.name;
            var varNameIn = netVar.name;
            if(netVar.redirection != null) varNameIn = netVar.redirection;
            var varType = netVar.type;

            var ein;
            var eout;

            trace("varType " + varType);
            trace("varName " + varNameIn + " / " + varNameOut);

            // outExprlist.push(macro trace("serialize " + $v{varNameOut} + " / " + $i{varNameOut}));
            // inExprlist.push(macro trace("unserialize " + $v{varNameIn} + " / " + $i{varNameIn}));

            switch(varType)
            {
                case "short":
                    eout = macro ba.writeInt16($i{varNameOut});
                    ein = macro $i{varNameIn} = ba.readInt16();
                case "int":
                    eout = macro ba.writeInt32($i{varNameOut});
                    ein  = macro $i{varNameIn} = ba.readInt32();

                case "byte":
                    eout = macro ba.writeByte($i{varNameOut});
                    ein  = macro $i{varNameIn} = ba.readByte();
                case "float":
                    eout = macro ba.writeFloat($i{varNameOut});
                    ein  = macro $i{varNameIn} = ba.readFloat();
                case "bool":
                    eout = macro ($i{varNameOut} == true) ? ba.writeByte(1) : ba.writeByte(0);
                    ein  = macro $i{varNameIn} = (ba.readByte() == 0) ? return false : return true;
            }

            // trace("ein " + ein);
            // trace("eout " + eout);

            inExprlist.push(ein);
            outExprlist.push(eout);
        }

        // IN
        var arg = {name:"ba", type:null, opt:false, value:null};

        var func = {args:[arg],
                    ret:null,
                    params:[],
                    expr:{expr:EBlock(inExprlist), pos:pos}};

        fields.push({name: "unserialize",
                     doc: null,
                     meta: [],
                     access: [APublic],
                     kind: FFun(func),
                     pos: pos});

        // OUT
        var arg = {name:"ba", type:null, opt:false, value:null};

        var func = {args:[arg],
                    ret:null,
                    params:[],
                    expr:{expr:EBlock(outExprlist), pos:pos}};

        fields.push({name: "serialize",
                     doc: null,
                     meta: [],
                     access: [APublic],
                     kind: FFun(func),
                     pos: pos});

        for(f in fields)
        {
            trace("Comp : " + new haxe.macro.Printer().printField(f));
        }

        return fields;
    }
}
