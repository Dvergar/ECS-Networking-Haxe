package enh.macros;

import enh.Constants;

import haxe.macro.Expr;
import haxe.macro.Context;
#if macro
import sys.io.File;
#end


typedef RPCType = {id:Int, name:String, argTypes:Array<Array<String>>};


class RPCMacro
{
    static public var onGenerateIndex:Int = 1;
    static public var rpcIds:Int = -1;
    static public var rpcsExported:Bool = false;
    static public var rpcMetas:Array<Expr> = new Array();
    static public var rpcsOut:Array<RPCType> = new Array();
    static public var rpcsIn:Map<String, Array<Array<String>>> = new Map();

    public static inline function toUpperCaseFirst(value:String):String
    {
        return value.charAt(0).toUpperCase() + value.substr(1).toLowerCase();
    }

    public static inline function getRPCId():Int
    {
        rpcIds++;
        return rpcIds;
    }

    public static function getRPCMetas(e:Expr) {
        switch(e.expr)
        { 
            case EMeta(rpc, link):
                if(rpc.name == "RPC")
                {
                    trace("RPC FOUND !!! " + rpc);
                    // trace("RPC FOUND link !!! " + link);
                    rpcMetas.push(e);
                }
            case _: haxe.macro.ExprTools.iter(e, getRPCMetas);
        }

    }

    public static function getRPCs(fields:Array<haxe.macro.Field>):Void
    {
        for (f in fields)
        {
            switch(f.kind)
            {
                case FFun(fun):
                    getRPCMetas(fun.expr);
                default:
            }
        }
    }

    public static function getRPCname(meta:MetadataEntry):String
    {
        trace("lolol " + meta.params[0].expr);
        switch(meta.params[0].expr)
        {

            case EConst(const):
                switch(const)
                {
                    case CString(string):
                        trace("RPC Name " + string);
                        return string;

                    default:
                        throw("name of RPC should be String, got " + const + " instead");
                }
            default: throw("Hotoy");
        }
    }

    #if macro
    public static function getRPCArgumentTypes(e:Expr):Array<Array<String>>
    {
        // trace("argumentexpr " + e);
        var args:Array<Array<String>> = new Array();

        switch(e.expr)
        {
            case EObjectDecl(fields):
                for(field in fields)
                {
                    var varName = field.field;
                    var typeName = "";

                    trace("NAMEZ " + varName);

                    switch(field.expr.expr)
                    {
                        case EConst(const):
                            trace("CONconst " + const);
                            switch(const)
                            {
                                case CIdent(vartype):
                                    switch(vartype)
                                    {
                                        case "Int":
                                            trace("Type is Int");
                                            typeName = vartype;
                                        case "Short":
                                            trace("Type is Short");
                                            typeName = vartype;
                                        case "String":
                                            trace("Type is String");
                                            typeName = vartype;
                                        case "Bool":
                                            trace("Type is Bool");
                                            typeName = vartype;
                                        default:
                                            trace("Wrong type for RPC only Int & String are allowed");
                                    }
                                default:
                            }
                        default:
                    }
                    args.push([varName, typeName]);
                }
            default:
        }
        return args;
    }

    public static function getRPCArguments(meta:MetadataEntry):Array<Expr>
    {
        var args = [];

        for(i in 1...meta.params.length)
        { 
            var param = meta.params[i];

            args.push(param);
        }

        return args;
    }

    public static function getWriteByteExpression(x:Int, pos:Position):Expr
    {
        // conn.bytes.writeByte(x);
        var xexpr = { expr : EConst(CInt(Std.string(x))), pos : pos };
        return { expr : ECall({ expr : EField({ expr : EField({ expr : EConst(CIdent("conn")), pos : pos },"bytes"), pos : pos },"writeByte"), pos : pos },[xexpr]), pos : pos };
    }

    public static function getFunctionName(rpcName:String):String
    {
        var words = rpcName.split("_");
        var wordsUpperCaseFirst = Lambda.map(words, function(w) { return toUpperCaseFirst(w); } );
        var wordsJoined = wordsUpperCaseFirst.join("");
        var functionName = wordsJoined.charAt(0).toLowerCase() + wordsJoined.substr(1);

        return functionName;
    }

    public static function _processRPCs(fields:Array<Field>):Array<haxe.macro.Field>
    {
        // trace("############# _processRPCs #############");
        var pos = Context.currentPos();

        // RESET FIELDS SINCE ITS USED ALSO BY OTHER MACROS
        rpcMetas = new Array();

        getRPCs(fields);
        // trace("RPCEPXRS " + rpcMetas);
        
        for(rpcExpr in rpcMetas)
        {
            var rpcId = getRPCId();
            var name = "";
            var argTypes = [];
            var argExprs = [];
            var entityName = "";

            switch(rpcExpr.expr)
            {
                case EMeta(rpc, link):
                    name = getRPCname(rpc);
                    argTypes = getRPCArgumentTypes(link);
                    argExprs = getRPCArguments(rpc);
                default:
            }

            var functionName = getFunctionName(name);

            trace("rpcname " + name);
            trace("functionName " + functionName);
            trace("argTypes " + argTypes);
            trace("argExprs " + argExprs);
            // throw("entity " + entity);

            // CHANGE FUNCTION NAME & ARGUMENTS
            rpcExpr.expr = ECall({ expr:EConst(CIdent(functionName)), pos:pos }, argExprs);

            // CREATE SEND METHOD
            var args = [];
            var funcBlock = [];
            var serializationBlock = [];

            // CALLED FROM A SYSTEM
            #if server
            serializationBlock.push(macro trace("entity out " + entity));
            serializationBlock.push(macro trace("RPC OUT " + $v{name} + " id : " + $v{rpcId}));
            serializationBlock.push(macro conn.output.writeByte($v{CONST.RPC}));
            serializationBlock.push(macro conn.output.writeByte($v{rpcId}));
            serializationBlock.push(macro trace("entityrpc " + em.getIdFroEntityTemplate(entity)));
            serializationBlock.push(macro conn.output.writeInt32(em.getIdFroEntityTemplate(entity)));
            serializationBlock.push(macro trace("plouf"));
            #elseif client
            // A longer path maybe ? Refactor dat shit
            // serializationBlock.push(macro trace("socket output " + enh.socket.conn));
            serializationBlock.push(macro root.socket.connection.anette.output.writeByte($v{CONST.RPC}));
            serializationBlock.push(macro root.socket.connection.anette.output.writeByte($v{rpcId}));
            serializationBlock.push(macro root.socket.connection.anette.output.writeInt32(em.getIdFroEntityTemplate(entity)));
            #end


            // var typeExport:Array<Array<Array<String>>> = new Array();
            rpcsOut.push({id:rpcId, name:name, argTypes:argTypes});

            // First RPC serialization function argument : Entity
            args.push({name:"entity",
                       type:TPath({name : "Entity",
                                   pack : [],
                                   params : []}),
                       opt:false,
                       value:null});

            for(i in 0...argTypes.length)
            {
                // Args
                var varName = argTypes[i][0];
                var argTypeString = argTypes[i][1];
                var type = { name : argTypeString, pack : [], params : []};
                args.push({name:varName, type:TPath(type), opt:false, value:null});

                // SERIALIZATION
                #if server
                switch(argTypeString)
                {
                    case "String":                        
                        serializationBlock.push( macro conn.output.writeUTF($i{varName}) );
                    case "Int":
                        serializationBlock.push( macro conn.output.writeInt32($i{varName}) );
                    case "Short":
                        serializationBlock.push( macro conn.output.writeInt16($i{varName}) );
                    case "Bool":
                        serializationBlock.push( macro conn.output.writeBoolean($i{varName}) );
                }
                #elseif client
                switch(argTypeString)
                {
                    case "String":                        
                        serializationBlock.push( macro root.socket.connection.anette.output.writeUTF($i{varName}) );
                    case "Int":
                        serializationBlock.push( macro root.socket.connection.anette.output.writeInt32($i{varName}) );
                    case "Short":
                        serializationBlock.push( macro root.socket.connection.anette.output.writeInt16($i{varName}) );
                    case "Bool":
                        serializationBlock.push( macro root.socket.connection.anette.output.writeBoolean($i{varName}) );
                }
                #end
            }

            // FILLING BLOCK
            #if client
            funcBlock = serializationBlock;
            #elseif server
            funcBlock.push( macro var connections = root.socket.gameConnections.keys() );
            funcBlock.push( macro for(conn in connections) { $a{serializationBlock} } );
            #end

            // BUILD FUNCTION
            var func = {args:args, ret:null, params:[], expr:{expr:EBlock(funcBlock), pos:pos} };
            var field = { name : functionName, doc : null, meta : [], access : [APublic], kind : FFun(func), pos : pos };
            fields.push(field);

            trace("PRPC : " + new haxe.macro.Printer().printField(field));
        }


        for(f in fields)
        {
            // trace("PRPC : " + new haxe.macro.Printer().printField(f));
        }

        // RPC TYPING
        pushRpcsIn(fields);
        #if client
        fields = rpcTyper(fields, pos);
        #end

        // trace("NOOGA");
        // EXPORT RPC TYPES TO FILE
        haxe.macro.Context.onGenerate(function (types)
        {
            if(!rpcsExported)
            {
                // trace("ongenerate " + onGenerateIndex);
                // trace("clsname " + Context.getLocalClass().get());
                onGenerateIndex++;
                #if server
                // SERVER RPCSOUT
                var fname = "server_rpcsOut.txt";
                var fout = File.write(fname, false);
                var s = haxe.Serializer.run(rpcsOut);

                fout.writeString(s);
                fout.close();

                // SERVER RPCSIN
                var fname = "server_rpcsIn.txt";
                var fout = File.write(fname, false);
                var s = haxe.Serializer.run(rpcsIn);

                fout.writeString(s);
                fout.close();

                #elseif client
                // CLIENT RPCSOut
                filesCheck();
                var oldRpcsOutSerialized = File.getContent("Source/client_rpcsOut.txt");
                var rpcSOutSerialized = haxe.Serializer.run(rpcsOut);
                // trace("oldRpcsOutSerialized " + oldRpcsOutSerialized);
                // trace("rpcSOutSerialized " + rpcSOutSerialized);

                if(oldRpcsOutSerialized != rpcSOutSerialized)
                {
                    var fname = "Source/client_rpcsOut.txt";
                    var fout = File.write(fname, false);

                    fout.writeString(rpcSOutSerialized);
                    fout.close();

                    throw "New RPCs have been added, please restart the server";
                }

                #end
                rpcsExported = true;
            }
        });

        return fields;
    }
    #end

    macro static public function processRPCs():Array<haxe.macro.Field>
    {
        // trace("############# processRPCs #############");

        var fields = Context.getBuildFields();
        var pos = Context.currentPos();

        // fields = EventMacro._processEvents(fields);
        fields = _processRPCs(fields);

        return fields;
    }

    /////////////////////////////////
    // UNSERIALIZER RPC
    /////////////////////////////////

    public static function pushRpcsIn(fields:Array<Field>):Void
    {
        for(f in fields)
        {
            // if(f.name.substr(0, 5) == "onNet")
            if(f.name.substr(0, 2) == "on")
            {
                // trace("PLOOM");
                rpcsIn.set(f.name, EventMacro.getMetaTypes(f.name, fields));
            }
        }
    }

    #if macro
    public static function filesCheck():Void
    {
        var prefix = "";
        #if client
        var prefix = "Source/";
        #end
        // REFACTOR with funcFunction
        // SERVER RPCOUT TEXT
        if( !sys.FileSystem.exists(prefix + "server_rpcsOut.txt") )
        {
            var rpcsOutExport:Array<RPCType> = new Array();

            var fout = File.write(prefix + "server_rpcsOut.txt", false);
            var s = haxe.Serializer.run(rpcsOutExport);
            fout.writeString(s);
            fout.close();
        }

        if( !sys.FileSystem.exists(prefix + "server_rpcsIn.txt") )
        {
            var rpcsInExport:Map<String, Array<Array<String>>> = new Map();

            var fout = File.write(prefix + "server_rpcsIn.txt", false);
            var s = haxe.Serializer.run(rpcsInExport);
            fout.writeString(s);
            fout.close();
        }

        // CLIENT RPCOUT TEXT
        if( !sys.FileSystem.exists(prefix + "client_rpcsOut.txt") )
        {
            var rpcsOutExport:Array<RPCType> = new Array();

            var fout = File.write(prefix + "client_rpcsOut.txt", false);
            var s = haxe.Serializer.run(rpcsOutExport);
            fout.writeString(s);
            fout.close();
        }
    }
    #end

    macro static public function addRpcUnserializeMethod():Array<haxe.macro.Field>
    {
        // trace("############# rpcUnserializer #############");

        var fields = Context.getBuildFields();
        var pos = Context.currentPos();

        filesCheck();
        #if client
        var rpcTypes:Array<RPCType> = haxe.Unserializer.run( File.getContent("Source/server_rpcsOut.txt") );
        #elseif server
        var rpcTypes:Array<RPCType> = haxe.Unserializer.run( File.getContent("client_rpcsOut.txt") );
        #end

        var block = [];

        block.push(macro var rpcType = input.readByte());
        // block.push(macro trace("rpc received " + rpcType));
        block.push(macro var entity = em.getEntityFromId(input.readInt32()));

        var cases = [];

        for(rpcType in rpcTypes)
        {
            var caseBlock = [];

            var objFields = [];
            for(type in rpcType.argTypes)
            {
                var varName = type[0];
                var typeName = type[1];

                var e:Expr;
                switch(typeName)
                {
                    case "Int":
                        e = macro input.readInt32();
                    case "Short":
                        e = macro input.readInt16();
                    case "String":
                        e = macro input.readUTF();
                    case "Bool":
                        e = macro input.readBoolean();
                    default:
                        throw "Types should be Int or String";
                }

                objFields.push({ expr : e, field : varName });
            }


            var obj =  { expr : EObjectDecl(objFields), pos : pos };
            #if server
            var pushArgs = [{ expr : EConst(CString(rpcType.name)), pos : pos }, macro entity, obj];
            #elseif client
            var pushArgs = [{ expr : EConst(CString(rpcType.name)), pos : pos }, macro entity, obj];
            #end
            // var pushArgs = [{ expr : EConst(CString(rpcType.name)), pos : pos }, { expr : EConst(CString("dummy")), pos : pos }, obj];

            var pushEv = {expr : ECall({ expr : EField({ expr : EConst(CIdent("em")), pos : pos },"pushEvent"), pos : pos }, pushArgs), pos : pos}
            caseBlock.push(pushEv);
            var rpcCase = { expr: { expr: EBlock(caseBlock), pos:pos } , values:[macro $v{rpcType.id}], guard:null };
            cases.push(rpcCase);
            // id++;
        }

        // var defExpr = { expr:EBlock([{ expr:ECall({ expr:EConst(CIdent("trace")), pos:pos },[{ expr:EConst(CString("hello2")), pos:pos }]), pos:pos }]), pos:pos }
        var defEmptyExpr = { expr:EBlock([macro throw "RPCTYPE doesn't exist"]), pos:pos };
        var switchExpr = {expr: ESwitch({ expr: EParenthesis({ expr: EConst(CIdent("rpcType")), pos:pos }), pos:pos },cases, defEmptyExpr), pos:pos };

        block.push(switchExpr);

        // var funcArgs = [{ name:"input", type:TPath({ name:"ByteArray", pack:[], params:[] }), opt:false, value:null }, { name:"entity", type:TPath({ name:"Entity", pack:[], params:[] }), opt:false, value:null }];
        var funcArgs = [{ name:"input", type:TPath({ name:"BytesInputEnhanced", pack:[], params:[] }), opt:false, value:null }];
        var funcExpr = { kind:FFun({ args:funcArgs, expr:{ expr:EBlock(block), pos:pos }, params:[], ret:null }), meta:[], name:"unserializeRpc", doc:null, pos:pos, access:[APublic] };

        fields.push(funcExpr);

        // PRINT
        for(f in fields)
        {
            trace("gol : " + new haxe.macro.Printer().printField(f));
        }

        return fields;
    }

    /////////////////////////////////
    // TYPER RPC
    /////////////////////////////////

    static public function compareRPCTypes(host:Int, rpcs0ut:Array<RPCType>, rpcs1n:Map<String, Array<Array<String>>>)
    {
        // COMPARE TYPES
        for(rpcOut in rpcs0ut)
        {
            var words = rpcOut.name.split("_");
            var wordsLowerCase = Lambda.map(words, function(w) { return w.toLowerCase(); } );
            var wordsUpperCaseFirst = Lambda.map(words, function(w) { return toUpperCaseFirst(w); } );
            var functionName = "on" + wordsUpperCaseFirst.join("");

            // trace("HAHA " + functionName + " / " + rpcsDest);

            if(!rpcs1n.exists(functionName))
                if(host == CONST.SERVER)
                {
                    throw "Client has no method " + functionName + " for the Server RPC";
                }
                else if(host == CONST.CLIENT)
                {
                    throw "Server has no method " + functionName + " for the Client RPC";
                }

            var argTypesIn = rpcs1n.get(functionName);
            var argTypesOut = rpcOut.argTypes;

            if(argTypesOut.length != argTypesIn.length) throw "RPC arguments number mismatch for " + functionName + " hint out : " + argTypesOut + " / in : " + argTypesIn;


            // TODO : CLEANUP
            for(i in 0...argTypesOut.length)
            {
                if(argTypesOut[i][0] != argTypesIn[i][0])
                {
                    if(argTypesOut[i][0] == "Int" && argTypesIn[i][0] == "Short" ||
                       argTypesOut[i][0] == "Short" && argTypesIn[i][0] == "Int")
                    {

                    }
                    else
                    {
                        throw "RPC variable name mismatch : " + argTypesOut[i][0] + " != " + argTypesIn[i][0] + " for " + rpcOut.name + " host " + host;
                    }
                }

                if(argTypesOut[i][1] != argTypesIn[i][1])
                {
                    if(argTypesOut[i][1] == "Int" && argTypesIn[i][1] == "Short" ||
                       argTypesOut[i][1] == "Short" && argTypesIn[i][1] == "Int")
                    {
                        
                    }
                    else
                    {
                        throw "RPC arg type mismatch: " + argTypesOut[i][1] + "!=" + argTypesIn[i][1] + " for " + rpcOut.name + " host " + host;
                    }
                }

                // if(argTypesOut[i][0] != argTypesIn[i][0])
                //     throw "RPC variable name mismatch : " + argTypesOut[i][0] + " != " + argTypesIn[i][0] + " for " + rpcOut.name + " host " + host;

                // if(argTypesOut[i][1] != argTypesIn[i][1])
                //     throw "RPC arg type mismatch: " + argTypesOut[i][1] + "!=" + argTypesIn[i][1] + " for " + rpcOut.name + " host " + host;
            }

        }
    }

    #if macro
    static public function rpcTyper(fields:Array<Field>, pos:Position):Array<haxe.macro.Field>
    {
        // trace("############# rpcTyper #############");

        filesCheck();
        var rpcsServerOut:Array<RPCType> = haxe.Unserializer.run( File.getContent("Source/server_rpcsOut.txt") );
        var rpcsServerIn:Map<String, Array<Array<String>>> = haxe.Unserializer.run( File.getContent("Source/server_rpcsIn.txt") );
        var rpcsClientOut = rpcsOut;
        var rpcsClientIn = rpcsIn;

        // trace("rpcsServerOut : " + rpcsServerOut);
        // trace("rpcsServerIn : " + rpcsServerIn);
        // trace("rpcsClientOut : " + rpcsClientOut);
        // trace("rpcsClientIn : " + rpcsClientIn);

        haxe.macro.Context.onGenerate(function (types) {
            compareRPCTypes(CONST.SERVER, rpcsServerOut, rpcsClientIn);
            compareRPCTypes(CONST.CLIENT, rpcsClientOut, rpcsServerIn);
        });

        return fields;
    }
    #end
}