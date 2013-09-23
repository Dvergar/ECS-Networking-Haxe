package enh.macros;

import haxe.macro.Expr;
import haxe.macro.Context;

import enh.macros.EventMacro;
import enh.Constants;


class MacroTest
{
    static public var componentIds:Int = -1;
    static public var entityIds:Int = -1;
    // static public var assignedComponents:Map<String, Int> = new Map();
    static public var componentsById:Array<String> = new Array();
    static public var componentsByString:Map<String, Int> = new Map();
    static public var componentsMsgType:Map<String, Array<String>> = new Map();
    static public var components:Array<String> = new Array();

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

    public static inline function buildSerializationFunction(serializationType:String, cases:Array<haxe.macro.Case>, fields, pos)
    {
        // if(cases.length != 0)
        // {
            var defExpr = { expr:EBlock([{ expr:ECall({ expr:EConst(CIdent("trace")), pos:pos },[{ expr:EConst(CString("hello2")), pos:pos }]), pos:pos }]), pos:pos }
            // var defDefaultExpr = { expr:null, pos:null };
            var defDefaultExpr = { expr:EBlock([macro throw "Error while un/serializing : No component of this type found"]), pos:pos };
            var switchExpr = {expr: ESwitch({ expr: EParenthesis({ expr: EConst(CIdent("componentType")), pos:pos }), pos:pos },cases, defDefaultExpr), pos:pos };
            var funcExpr = { kind:FFun({ args:[{ name:"componentType", type:TPath({ name:"Int", pack:[], params:[] }), opt:false, value:null },{ name:"entity", type:TPath({ name:"String", pack:[], params:[] } ), opt:false, value:null },{ name:"ba", type:TPath({ name:"ByteArray", pack:[], params:[] }), opt:false, value:null }], expr:{ expr:EBlock([switchExpr]), pos:pos }, params:[], ret:null }), meta:[], name:serializationType, doc:null, pos:pos, access:[APublic,AOverride] };

            fields.push(funcExpr);
        // }
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

        // GRAB DATAS AND FEED ARRAYS
        var entitiesMethodsById = [];  // id, method
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

                        switch(f.kind){
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

        // COMPONENT MAP SAMPLE
        // var l = { expr:EArrayDecl([{ expr:EConst(CIdent(CPosition)), pos:pos },{ expr:EConst(CIdent(CTower)), pos:pos }]), pos:pos };

        trace("ENTITIESMETHODSBYID : " + entitiesMethodsById);  // Actually method to id map
        trace("ENTITIESCOMPONENTMAP " + entitiesComponentMap);
        trace("COMPONENTS BY STRING " + componentsByString);
        trace("COMPONENTS BY ID " + componentsById);


        // // BUILD ENTITYCOMPONENTSMAP
        // var newEntityComponentsMap = [[], [], [], []];

        // var entityId = 0;
        // for(entity in entitiesComponentMap)
        // {
        //     for(type in newEntityComponentsMap) type.push([]);

        //     for(component in entity)
        //     {
        //         var componentId = componentsByString.get(component);

        //         var compTypes = componentsMsgType.get(component);

        //         trace("COMPTYPES " + compTypes);
        //         if(compTypes == null) continue;

        //         for(compType in compTypes)
        //         {
        //             if(compType == "create")
        //             {
        //                 newEntityComponentsMap[CONST.CREATE][entityId].push(componentId);
        //             }

        //             if(compType == "update")
        //             {
        //                 newEntityComponentsMap[CONST.UPDATE][entityId].push(componentId);
        //             }

        //             if(compType == "delete")
        //             {
        //                 newEntityComponentsMap[CONST.DELETE][entityId].push(componentId);
        //             }

        //             if(compType == "sync")
        //             {
        //                 newEntityComponentsMap[CONST.SYNC][entityId].push(componentId);
        //             }
        //         }
        //     }

        //     entityId++;
        // }



        // var arr = macro $v{newEntityComponentsMap};
        // trace("ARR " + arr);
        //STATIC DEFINITION
        // fields.push({ kind:FVar(null, arr), meta:[], name:"entityComponentsMap", doc:null, pos:pos, access:[AStatic, APublic] });
        // fields.push({ kind : FVar(TPath({ name : "Array", pack : [], params : [TPType(TPath({ name : "Array", pack : [], params : [TPType(TPath({ name : "Array", pack : [], params : [TPType(TPath({ name : "Int", pack : [], params : [] }))] }))] }))] }),null), meta : [], name : "entityComponentsMap", doc : null, pos : pos, access : [APublic] });
        // trace("NEWENTITYCOMPONENTSMAP " + newEntityComponentsMap);

        // BUILD ENTITYFUNCTIONSMAP
        var exprs = [];
        // var funcMap = [];
        var entityId = 0;

        for(fname in entitiesMethodsById)
        {
            // EXPRESSIONS FOR entityFunctionsMap
            exprs.push({expr:EConst(CIdent(fname)), pos:pos});

            // CONSTANTS PLAYER, ARROW...
            var constName = fname.substr(6).toUpperCase();
            fields.insert(0, {kind:FVar(TPath({ name:"Int", pack:[], params:[] }),{ expr:EConst(CInt(Std.string(entityId))), pos:pos }), meta:[], name:constName, doc:null, pos:pos, access:[AInline,AStatic,APublic]});

            entityId++;
        }

        // DEFINITION ENTITYFUNCTIONSMAP
        // fields.push({ kind: FVar(TPath({ name: "Array", pack: [], params: [TPType(TFunction([TPath({ name: "Void", pack: [], params: [] })],TPath({ name: "String", pack: [], params: [] })))] }),null), meta: [], name: "entityFunctionsMap", doc: null, pos:pos, access: [APublic] });
        
        //STATIC
        // var funcArr = { expr:EArrayDecl(exprs), pos:pos };
        // fields.push({ kind:FVar(null, funcArr), meta:[], name:"entityFunctionsMap", doc:null, pos:pos, access:[AStatic, APublic] });

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
                                block.insert(0, { expr:EBinop(OpAssign,{expr:EConst(CIdent("entityFunctionsMap")), pos:pos },{ expr:EArrayDecl(exprs), pos:pos }), pos:pos });
                                // block.insert(0, macro entityComponentsMap = $v{newEntityComponentsMap});
                            default:
                        }

                    default:
                }
            }
        }

        function getCase(serializationName:String, componentName:String, componentId:Int)
        {
            var getComponentExpr = macro var c = em.getComponent(entity, $i{componentName});
            var serializeExpr = macro c.$serializationName(ba);

            return {expr: {expr: EBlock($b{[getComponentExpr, serializeExpr]}), pos:pos}, values:[{ expr:EConst(CInt(Std.string(componentId))), pos:pos }], guard:null };
        }

        // FUNCTION SWITCH SERIALIZATION
        var serializeCreateCaseExprs = [];
        var serializeUpdateCaseExprs = [];
        var serializeDeleteCaseExprs = [];

        var unserializeCreateCaseExprs = [];
        var unserializeUpdateCaseExprs = [];
        var unserializeDeleteCaseExprs = [];

        for(componentName in componentsMsgType.keys())
        {
            var componentId:Int = componentsByString.get(componentName);
            var serializationTypes = componentsMsgType.get(componentName);

            for(serializationType in serializationTypes)
            {
                switch(serializationType) // REFACTOOOOR WITH FUNCTION IN FUNCTION
                {
                    // TODO Move serialize expression to macro reification
                    case "create":
                        serializeCreateCaseExprs.push(getCase("serializeCreate", componentName, componentId));
                        unserializeCreateCaseExprs.push(getCase("unserializeCreate", componentName, componentId));

                    case "update":
                        serializeUpdateCaseExprs.push(getCase("serializeUpdate", componentName, componentId));
                        unserializeUpdateCaseExprs.push(getCase("unserializeUpdate", componentName, componentId));

                    case "delete":
                        serializeDeleteCaseExprs.push(getCase("serializeDelete", componentName, componentId));
                        unserializeDeleteCaseExprs.push(getCase("unserializeDelete", componentName, componentId));
                }
            }
        }

        // buildSerializationFunction("serializeCreate", serializeCreateCaseExprs, fields, pos);
        // buildSerializationFunction("unserializeCreate", unserializeCreateCaseExprs, fields, pos);
        // buildSerializationFunction("serializeUpdate", serializeUpdateCaseExprs, fields, pos);
        // buildSerializationFunction("unserializeUpdate", unserializeUpdateCaseExprs, fields, pos);
        // buildSerializationFunction("serializeDelete", serializeDeleteCaseExprs, fields, pos);
        // buildSerializationFunction("unserializeDelete", unserializeDeleteCaseExprs, fields, pos);

        // BUILD COMPONENTS MAP
        var exprs = [];

        for(componentName in componentsById)
        {
            exprs.push({expr:EConst(CIdent(componentName)), pos:pos});
        }

        // fields.push({ kind:FFun({ args:[], expr:{ expr:EBlock([{ expr:EReturn({ expr:EArrayDecl(exprs), pos:pos }), pos:pos }]), pos:pos }, params:[], ret:TPath({ name:"Array", pack:[], params:[TPType(TPath({ name:"Class", pack:[], params:[TPType(TPath({ name:"NetComponent", pack:[], params:[] }))] }))] }) }), meta:[], name:"componentsById", doc:null, pos:pos, access:[AInline,AStatic] });

        // PRINTER SAMPLE
        for(f in fields)
        {
            trace("kobo : " + f);
            trace("humpf : " + new haxe.macro.Printer().printField(f));
        }


        // trace("lolilol " + newEntityComponentsMap);

        haxe.macro.Context.onGenerate(function (types) {


            // BUILD ENTITYCOMPONENTSMAP
            var newEntityComponentsMap = [[], [], [], []];

            var entityId = 0;
            for(entity in entitiesComponentMap)
            {
                for(type in newEntityComponentsMap) type.push([]);

                for(component in entity)
                {
                    var componentId = componentsByString.get(component);

                    var compTypes = componentsMsgType.get(component);

                    trace("COMPTYPES " + compTypes);
                    if(compTypes == null) continue;

                    for(compType in compTypes)
                    {
                        if(compType == "create")
                        {
                            newEntityComponentsMap[CONST.CREATE][entityId].push(componentId);
                        }

                        if(compType == "update")
                        {
                            newEntityComponentsMap[CONST.UPDATE][entityId].push(componentId);
                        }

                        if(compType == "delete")
                        {
                            newEntityComponentsMap[CONST.DELETE][entityId].push(componentId);
                        }

                        if(compType == "sync")
                        {
                            newEntityComponentsMap[CONST.SYNC][entityId].push(componentId);
                        }
                    }
                }
                entityId++;
            }

            trace("Exporting : newEntityComponentsMap " + newEntityComponentsMap);
            Context.addResource("test", haxe.io.Bytes.ofString("hoy"));
            var newEntityComponentsMapSerialized = haxe.Serializer.run(newEntityComponentsMap);
            Context.addResource("entityComponentsMap", haxe.io.Bytes.ofString(newEntityComponentsMapSerialized));


            Context.addResource("components", haxe.io.Bytes.ofString(haxe.Serializer.run(components)));

        });

        // ON GENERATE SAMPLE
        // haxe.macro.Context.onGenerate(function (types) {
            // casimir = 42;
            // trace("casimir " + casimir);
            // for ( t in types )
            // {
            //    // trace("T " + t);
            //     switch( t )
            //     {
            //         case TInst(c, _):
            //             if (c.get().name == "MyComponent") {

            //                 var rttiData = c.get();
            //                 trace("JAZPEROJAZERPOJAEZRPOEJAZRPOAZEJ " + c.get()); // [{ params => 
            //     //             // add meta rtti to Main
            //     //             rttiData.meta.add( "rtti", [] );
            //     //             // it seems to work
            //     //             trace(rttiData.meta.get()); // [{ params => 
            //             }

            //         default:
            //     }
            // }
        // });
        return fields;
    }

    // hum ? careful about static array for _process stuff

    macro static public function buildComponent():Array<haxe.macro.Field>
    {
        var fields = Context.getBuildFields();
        var cls = Context.getLocalClass().get();
        var pos = Context.currentPos();

        var networked = false;
        var sync = false;
        for(meta in Context.getLocalClass().get().meta.get())
        {
            if(meta.name == "sync") sync = true;
            if(meta.name == "networked") networked = true;
        }

        if(!networked) return fields;


        // ID
        var id = getComponentId();
        components[id] = Context.getLocalClass().get().name;
        componentsById.push(cls.name);
        componentsByString.set(cls.name, id);
        fields.push({ kind:FVar(null,{ expr:EConst(CInt(Std.string(id))), pos:pos }), meta:[], name:"id", doc:null, pos:pos, access:[AInline, AStatic, APublic] });

        // GRAB MSGTYPES & DATATYPES
        var netFields:Map<String, Array<Array<String>>> = new Map();
        netFields.set("create", new Array<Array<String>>());
        netFields.set("update", new Array<Array<String>>());
        netFields.set("destroy", new Array<Array<String>>());

        componentsMsgType.set(cls.name, []);

        // var classMsgType = componentsMsgType.get(cls.name);
        if(sync) componentsMsgType[cls.name].push("sync");

        for (f in fields)
        {
            trace("meta " + f.meta);

            if(f.meta.length != 0)
            {
                // REUSED BY OTHER MACRO

                var msgTypes = [];
                // PUSH NET MESSAGE TYPE
                for(m in f.meta)
                {

                    if(m.name == "create" ||
                       m.name == "update" ||
                       m.name == "destroy")
                    {
                        // REUSED BY OTHER MACRO
                        var classMsgType = componentsMsgType.get(cls.name);

                        // PASS IF TAG ALREADY IN LIST UGLY
                        var sameTag = false;
                        for(type in classMsgType)
                        {
                            if(m.name == type) sameTag = true;
                        }

                        if(!sameTag) classMsgType.push(m.name);

                        msgTypes.push(m.name);
                        
                    }

                    // if(m.name == "sync")
                    // {
                    //     var classMsgType = componentsMsgType.get(cls.name);
                    //     classMsgType.push(m.name);
                    // }

                }


                // NET TYPES (can't be above because typemeta related to msgtypesmetas)
                for(m in f.meta)
                {
                    if(m.name == "short" ||
                       m.name == "byte")
                    {
                        for(msgType in msgTypes)
                        {
                            var n = new Array<String>();
                            n.push(m.name);
                            n.push(f.name);

                            trace("N : " + n + " / msgtype : " + msgType);
                            netFields.get(msgType).push(n);
                        }
                    }
                }
                trace("componentsMsgType " + componentsMsgType);
            }
        }

        trace("FINALcomponentsMsgType " + componentsMsgType);
        trace("netfiels " + netFields);

        // CREATE METHODS
        for(messageType in netFields.keys())
        {
            if(netFields.get(messageType).length == 0) continue;

            var inExprlist = [];
            var outExprlist = [];

            for(netfield in netFields.get(messageType))
            {
                trace("koko " + netfield);
                var dataType = netfield[0];  // byte, short..
                var netVar = netfield[1];  // name of the variable to call

                var ein;
                var eout;
                var debugInShort;
                var debugOutShort;

                switch(dataType)
                {
                    case "short":
                        ein  = macro $i{netVar} = ba.readShort();
                        debugInShort = macro trace($i{netVar});
                        // #if neko
                        // eout = macro ba.writeShort(try Std.int($i{netVar}) catch(e:Dynamic) 0);
                        // #else
                        // #end
                        eout = macro ba.writeShort($i{netVar});
                        debugOutShort = macro trace($i{netVar});
                }

                inExprlist.push(ein);
                inExprlist.push(debugInShort);
                outExprlist.push(eout);
                outExprlist.push(debugOutShort);
            }

            // IN
            var arg = {name:"ba", type:null, opt:false, value:null};
            var func = {args:[arg], ret:null, params:[], expr:{expr:EBlock(inExprlist), pos:pos} };
            fields.push({ name : "unserialize" + toUpperCaseFirst(messageType), doc : null, meta : [], access : [APublic], kind : FFun(func), pos : pos });

            // OUT
            var arg = {name:"ba", type:null, opt:false, value:null};
            var func = {args:[arg], ret:null, params:[], expr:{expr:EBlock(outExprlist), pos:pos} };
            fields.push({ name : "serialize" + toUpperCaseFirst(messageType), doc : null, meta : [], access : [APublic], kind : FFun(func), pos : pos });
        }

        for(f in fields)
        {
            trace("Comp : " + new haxe.macro.Printer().printField(f));
        }

        // return fields.concat([{name:"caca", doc:null, meta:[], access:[APublic], kind:FVar(tint, null), pos:pos }]);
        return fields;
    }
}
