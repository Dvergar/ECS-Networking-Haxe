package enh.macros;

import haxe.macro.Expr;
import haxe.macro.Context;

import enh.macros.EventMacro;
import enh.Constants;


class MacroTest
{
    static public var componentIds:Int = -1;
    static public var entityIds:Int = -1;
    static public var componentsById:Array<String> = new Array();
    static public var componentIdByString:Map<String, Int> = new Map();
    static public var componentsMsgType:Map<String, Array<String>> = new Map();
    static public var networkComponents:Array<String> = new Array();
    static public var syncedComponents:Array<String> = new Array();

    public static inline function toUpperCaseFirst(value:String):String
    {
        return value.charAt(0).toUpperCase() + value.substr(1).toLowerCase();
    }

    public static inline function getComponentId():Int
    {
        componentIds++;
        return componentIds;
    }

    public static inline function getEntityId():Int
    {
        entityIds++;
        return entityIds;
    }

    public static function findMetas(e:Expr) { 
        switch(e.expr) { 
            case EMeta(a, meta): // handle s 
                trace("META FOUND !!! " + meta);
            case _: haxe.macro.ExprTools.iter(e, findMetas); 
        }
    }

    macro static public function buildMap():Array<haxe.macro.Field>
    {
        trace("############# buildMap #############");

        var fields = Context.getBuildFields();
        var cls = Context.getLocalClass().get();
        var pos = Context.currentPos();

        // RPC
        fields = RPCMacro._processRPCs(fields);

        // GRAB DATAS AND FEED ARRAYS (TODO : pattern matching !!!)
        var entitiesMethodsById = [];
        var entitiesComponentMap = [];

        for (f in fields)
        {
            trace("#########");
            // trace(f);

            if(f.meta.length != 0)
            {
                for(m in f.meta)
                {
                    trace("metanames "  + m.name);
                    if(m.name == "loltest")
                    {
                        trace("LOLTEST " + f);

                        switch(f.kind){
                            case FFun(fun):
                                findMetas(fun.expr);
                            default:
                        }
                    }

                    if(m.name == "freeze")
                    {
                        trace("METHOD " + f.name);
                        var methodName = f.name;

                        getEntityId();
                        entitiesMethodsById.push(methodName);
                        var componentsList = [];

                        switch(f.kind)
                        {
                            case FFun(fun):
                                switch(fun.expr.expr)
                                {
                                    case EBlock(block):
                                        for(b in block)
                                        {    
                                            switch(b.expr)
                                            {
                                                case EVars(vars):

                                                    var entity = vars[0].name;

                                                    switch(vars[0].expr.expr)
                                                    {
                                                        case ECall(call, dummy):
                                                            // trace(call);
                                                            switch(call.expr)
                                                            {
                                                                case EField(dummy, field):
                                                                    trace("entity : " + entity);
                                                                    var createEntity = field == "createEntity";
                                                                    trace("create entity ? " + createEntity);
                                                                default:
                                                            }
                                                        default:
                                                    }
                                                case ECall(call, dummy):
                                                    trace("kall " + call);
                                                    switch(call.expr)
                                                    {
                                                        case EField(c, field):
                                                            trace("methodd : " + field);
                                                            if(field == "addComponent")
                                                            {
                                                                trace("dummyy " + dummy);
                                                                switch(dummy[0].expr)
                                                                {
                                                                    case EConst(identity):
                                                                        switch(identity)
                                                                        {
                                                                            case CIdent(entity):
                                                                                trace("component entity : " + entity);
                                                                            default:
                                                                        }
                                                                    default:
                                                                }
                                                                switch(dummy[1].expr)
                                                                {
                                                                    case ENew(n, a):
                                                                        var component = n.name;
                                                                        trace("compcomp :" + component);

                                                                        componentsList.push(component);
                                                                        // assignedComponents.set(component);

                                                                    default:
                                                                }

                                                            }
                                                        default:
                                                    }


                                                default:
                                            }
                                        }
                                    default:
                                }
                            default:
                        }
                        entitiesComponentMap.push(componentsList);
                    }
                }
            }
        }

        trace("ENTITIESMETHODSBYID : " + entitiesMethodsById);  // Actually method to id map
        trace("ENTITIESCOMPONENTMAP " + entitiesComponentMap);
        trace("COMPONENTS BY STRING " + componentIdByString);
        trace("COMPONENTS BY ID " + componentsById);

        // BUILD
        var exprsFunctionByEntityType = [];
        var exprsEntityTypeIdByEntityTypeName = [];
        var exprsEntityTypeNameById = [];
        var entityId = 0;

        for(fname in entitiesMethodsById)
        {
            exprsFunctionByEntityType.push({expr : EBinop(OpArrow,{ expr : EConst(CString(fname)), pos : pos },{ expr : EConst(CIdent(fname)), pos : pos }), pos : pos});
            exprsEntityTypeIdByEntityTypeName.push({expr : EBinop(OpArrow,{ expr : EConst(CString(fname)), pos : pos },{ expr : EConst(CInt(Std.string(entityId))), pos : pos }), pos : pos});
            exprsEntityTypeNameById.push({expr : EBinop(OpArrow,{ expr : EConst(CInt(Std.string(entityId))), pos : pos }, { expr : EConst(CString(fname)), pos : pos }), pos : pos});

            entityId++;
        }

        // DECLARATION ENTITYFUNCTIONSMAP
        for(f in fields)
        {
            if(f.name == "new")
            {
                switch(f.kind){
                    case FFun(fun):
                        switch(fun.expr.expr)
                        {
                            case EBlock(block):
                                block.insert(0, { expr : EBinop(OpAssign,{ expr : EConst(CIdent("functionByEntityType")), pos : pos },{ expr : EArrayDecl(exprsFunctionByEntityType), pos : pos }), pos : pos });
                                block.insert(0, { expr : EBinop(OpAssign,{ expr : EConst(CIdent("entityTypeIdByEntityTypeName")), pos : pos },{ expr : EArrayDecl(exprsEntityTypeIdByEntityTypeName), pos : pos }), pos : pos });
                                block.insert(0, { expr : EBinop(OpAssign,{ expr : EConst(CIdent("entityTypeNameById")), pos : pos },{ expr : EArrayDecl(exprsEntityTypeNameById), pos : pos }), pos : pos });
                            default:
                        }

                    default:
                }
            }
        }

        var exprs = [];

        for(componentName in componentsById)
        {
            exprs.push({expr:EConst(CIdent(componentName)), pos:pos});
        }

        // PRINTER SAMPLE
        for(f in fields)
        {
            trace("humpf : " + new haxe.macro.Printer().printField(f));
        }

        haxe.macro.Context.onGenerate(function(types)
        {
            // BUILD ENTITYCOMPONENTSMAP
            // To-do : Typedefs Typedefs Typedefs Typedefs
            var syncedEntities = [];
            var componentsNameByEntityId = [];
            var syncComponentsNameByEntityId = [];

            var entityId = 0;
            for(entityType in entitiesComponentMap)
            {
                var comps = [];
                var syncComps = [];

                componentsNameByEntityId.push(comps);
                syncComponentsNameByEntityId.push(syncComps);

                var syncedEntity = false;
                for(component in entityType)
                {
                    var netComponent = false;
                    for(networkComponent in networkComponents)
                    {
                        if(component == networkComponent)
                        {
                            netComponent = true;
                            break;
                        }
                    }

                    if(!netComponent) continue;

                    var componentId = componentIdByString.get(component);
                    comps.push(componentId);

                    var syncedComponent = false;
                    for(syncComponent in syncedComponents)
                    {
                        if(component == syncComponent)
                        {
                            syncedComponent = true;
                            syncedEntity = true;
                            break;
                        }
                    }

                    if(syncedComponent) syncComps.push(componentId);
                }

                syncedEntities.push(syncedEntity);

                entityId++;
            }

            // EXPORT
            trace("Exporting : componentsNameByEntityId " + componentsNameByEntityId);
            var componentsNameByEntityIdSerialized = haxe.Serializer.run(componentsNameByEntityId);
            var syncComponentsNameByEntityIdSerialized = haxe.Serializer.run(syncComponentsNameByEntityId);
            Context.addResource("componentsNameByEntityId", haxe.io.Bytes.ofString(componentsNameByEntityIdSerialized));
            Context.addResource("syncComponentsNameByEntityId", haxe.io.Bytes.ofString(syncComponentsNameByEntityIdSerialized));
            Context.addResource("components", haxe.io.Bytes.ofString(haxe.Serializer.run(networkComponents)));
            Context.addResource("syncedEntities", haxe.io.Bytes.ofString(haxe.Serializer.run(syncedEntities)));
        });

        return fields;
    }


    macro static public function buildComponent():Array<haxe.macro.Field>
    {
        var fields = Context.getBuildFields();
        var cls = Context.getLocalClass().get();
        var pos = Context.currentPos();

        var componentName = cls.name;

        var networked = false;
        var sync = false;
        for(meta in Context.getLocalClass().get().meta.get())
        {
            if(meta.name == "sync") sync = true;
            if(meta.name == "networked") networked = true;
        }

        if(!networked) return fields;
        if(sync) syncedComponents.push(componentName);


        var varTypeByVarName:Map<String, String> = new Map();

        for(f in fields)
        {
            trace("meta " + f.meta);

            if(f.meta.length != 0)
            {

                // NET TYPES (can't be above because typemeta related to msgtypesmetas)
                for(m in f.meta)
                {
                    if(m.name == "short" ||
                       m.name == "byte")
                    {
                        trace("added " + m.name + " / " + f.name);
                        varTypeByVarName[f.name] = m.name;
                    }
                }
            }
        }

        trace("pre varTypeByVarName : " + varTypeByVarName);


        // ID
        var id = getComponentId();
        networkComponents[id] = componentName;
        componentsById.push(cls.name);
        componentIdByString.set(cls.name, id);

        if(Lambda.empty(varTypeByVarName)) return fields;

        ////////////////////////////////////////
        // RETURN HERE PLEASE DONT FORGET HIM
        ////////////////////////////////////////

        trace("varTypeByVarName " + varTypeByVarName);

        var inExprlist = [];
        var outExprlist = [];

        for(varName in varTypeByVarName.keys())
        {
            var varType = varTypeByVarName.get(varName);

            var ein;
            var eout;
            var debugInShort;
            var debugOutShort;

            trace("varNameByVarType2 " + varTypeByVarName);
            trace("varType " + varType);
            trace("varName " + varName);

            switch(varType)
            {
                case "short":
                    ein  = macro $i{varName} = ba.readShort();
                    debugInShort = macro trace("unserialize : " + $i{varName});
                    // #if neko
                    // eout = macro ba.writeShort(try Std.int($i{netVar}) catch(e:Dynamic) 0);
                    // #else
                    // #end
                    eout = macro ba.writeShort($i{varName});
                    debugOutShort = macro trace("serialize : " + $i{varName});
            }

            trace("ein " + ein);
            trace("eout " + eout);

            inExprlist.push(ein);
            // inExprlist.push(debugInShort);
            outExprlist.push(eout);
            // outExprlist.push(debugOutShort);
        }

        // IN
        var arg = {name:"ba", type:null, opt:false, value:null};
        var func = {args:[arg], ret:null, params:[], expr:{expr:EBlock(inExprlist), pos:pos} };
        fields.push({ name : "unserialize", doc : null, meta : [], access : [APublic], kind : FFun(func), pos : pos });

        // OUT
        var arg = {name:"ba", type:null, opt:false, value:null};
        var func = {args:[arg], ret:null, params:[], expr:{expr:EBlock(outExprlist), pos:pos} };
        fields.push({ name : "serialize", doc : null, meta : [], access : [APublic], kind : FFun(func), pos : pos });

        for(f in fields)
        {
            trace("Comp : " + new haxe.macro.Printer().printField(f));
        }

        return fields;
    }
}
