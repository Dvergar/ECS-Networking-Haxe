package enh;

import anette.Bytes;

typedef Entity = Int;
typedef Short = Int;


@:autoBuild(enh.macros.MacroTest.buildComponent())
class Component
{
    public function new(){}
    public function _detach(){}
}


class CNetOwner extends Component
{
    public var id:Int;

    public function new(id:Int)
    {
        super();
        this.id = id;
    }
}


class CId extends Component
{
    public var value:Int;

    public function new(value:Int)
    {
        super();
        this.value = value;
    }
}


class CType extends Component
{
    public var value:String;

    public function new(value:String)
    {
        super();
        this.value = value;
    }
}


@:autoBuild(enh.macros.MacroTest.buildMap())
class EntityCreatorBase
{
    // TO-DO : God, refactor this mess with typedefs or something :'(
    public var entityTypeIdByEntityTypeName:Map<String, Int>;
    public var entityTypeNameById:Map<Int, String>;
    public var functionByEntityType:Map<String, Array<Int>->Entity>;
    public var componentsNameByEntityId:Array<Array<Int>>; // ComponentName ? Component Id !
    public var syncComponentsNameByEntityId:Array<Array<Int>>;
    public var networkComponents:Array<Component>;
    public var syncedEntities:Array<Bool>;
    public var em:EntityManager;

    public function serialize(componentType:Int, entity:Entity, output:BytesOutputEnhanced):Void
    {
        var componentClass = untyped networkComponents[componentType];
        var component = em.getComponent(entity, componentClass);

        component.serialize(output);
    }

    public function unserialize(componentType:Int, entity:Entity, input:BytesInputEnhanced):Void
    {
        var componentClass = untyped networkComponents[componentType];
        var component = em.getComponent(entity, componentClass);

        component.unserialize(input);
    }

    public function addComponent(componentType:Int, entity:Entity)
    {
        var componentClass = untyped networkComponents[componentType];
        var component = Type.createInstance(componentClass, []);

        em.addComponent(entity, component);
    }

    public function new()
    {
        var syncComponentsNameByEntityIdSerialized = haxe.Resource.getString("syncComponentsNameByEntityId");
        syncComponentsNameByEntityId = haxe.Unserializer.run(syncComponentsNameByEntityIdSerialized);

        var componentsNameByEntityIdSerialized = haxe.Resource.getString("componentsNameByEntityId");
        componentsNameByEntityId = haxe.Unserializer.run(componentsNameByEntityIdSerialized);

        syncedEntities = haxe.Unserializer.run(haxe.Resource.getString("syncedEntities"));

        var componentsSerialized = haxe.Resource.getString("components");
        var components:Array<String> = haxe.Unserializer.run(componentsSerialized);

        this.networkComponents = new Array();

        for(comp in components)
        {
            var c = Type.resolveClass(comp);
            networkComponents.push(untyped c);
        }

        trace("syncComponentsNameByEntityId " + syncComponentsNameByEntityId);
        trace("componentsNameByEntityId " + componentsNameByEntityId);
    } 
}


@:autoBuild(enh.macros.Template.system())
class System<ROOTTYPE, ECTYPE>
{
    public var em:EntityManager;
    public var root:ROOTTYPE;
    public var enhwot:ROOTTYPE;
    public var ec:ECTYPE;
    #if server
    public var net:ServerManager;
    #end
}


@:autoBuild(enh.macros.Template.main())
class Enh<ROOTTYPE:{function init():Void;},
          ECTYPE:{var em:EntityManager;}>
{
    var em:EntityManager;
    var ec:ECTYPE;
    var enhwot:Enh<ROOTTYPE, ECTYPE>;
    var root:ROOTTYPE;  // ALLOWS ACCESS TO SYSTEM MANAGER

    var oldTime:Float;
    var accumulator:Float;
    var rate:Float;
    var loopFunc:Void->Void;

    public function new(root:ROOTTYPE, entityCreatorType:Class<ECTYPE>)
    {
        this.root = root;
        this.em = new EntityManager();
        this.ec = Type.createInstance(entityCreatorType, []);
        this.ec.em = em;
        this.enhwot = this; // allows root to  _processRPCs like Systems

        #if server
        this.net = new ServerManager(em, cast ec);
        #end

        #if client
        this.net = new ClientManager(em, cast ec);
        this.socket = new Socket(net);
        this.net.socket = socket;
        #end

        root.init(); // mhhh ?
    }

    public function addSystem<U>(systemClass:Class<U>):U
    {
        var system:U = Type.createEmptyInstance(systemClass);

        Reflect.setField(system, "em", em);
        Reflect.setField(system, "root", root);
        Reflect.setField(system, "enhwot", this);  // enh ? neko ?
        Reflect.setField(system, "ec", ec);
        #if server
        Reflect.setField(system, "net", net);
        #end
        Reflect.callMethod(system, Reflect.field(system, "init"), []);

        return system;
    }

    function step(?dummy)
    {
        // FIXED TIME STEP
        var newTime = Timer.getTime();
        var frameTime = newTime - oldTime;
        accumulator += frameTime;
        oldTime = newTime;

        while(accumulator >= rate)
        {
            socket.pumpIn();
            loopFunc();
            socket.pumpOut();
            
            accumulator -= rate;
        }
    }

    #if client
    public var socket:Socket;
    public var net:ClientManager;

    public function connect(ip:String, port:Int)
    {
        socket.connect(ip, port);
    }

    public function startLoop(loopFunc:Void -> Void, rate:Float)
    {
        this.oldTime = Timer.getTime();
        this.accumulator = 0;
        this.rate = rate;
        this.loopFunc = loopFunc;

        Loop.startLoop(step);
    }
    #end

    #if server
    public var socket:ServerSocket;
    public var net:ServerManager;

    public function startLoop(loopFunc:Void -> Void, rate:Float)
    {
        this.oldTime = Timer.getTime();
        this.accumulator = 0;
        this.rate = rate;
        this.loopFunc = loopFunc;

        #if (cpp || neko)
        while(true)
        {
            step();
            Sys.sleep(rate / 2);  // For CPU : Ugly isn't it :3
        }

        #elseif js
        var timer = new haxe.Timer(Std.int(1000 * rate/2));
        timer.run = step.bind();
        #end
    }

    public function startServer(address:String, port:Int)
    {
        this.socket = new ServerSocket(address, port, net);
        this.net.socket = socket;
        return socket;
    }
    #end
}
