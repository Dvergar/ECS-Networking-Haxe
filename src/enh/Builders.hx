package enh;


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


class CType extends Component
{
    public var value:String;

    public function new(value:String)
    {
        super();
        this.value = value;
    }
}


class EntityCreatowr
{
    // TO-DO : God, refactor this mess with typedefs or something :'(
    public var entityTypeIdByEntityTypeName:Map<String, Int>;
    public var entityTypeNameById:Map<Int, String>;
    public var functionByEntityType:Map<String, Void->String>;
    public var componentsNameByEntityId:Array<Array<Int>>;
    public var syncComponentsNameByEntityId:Array<Array<Int>>;
    public var networkComponents:Array<Component>;
    public var syncedEntities:Array<Bool>;
    public var em:EntityManager;

    public function serializeCreate(componentType:Int,entity:String,ba:ByteArray):Void {
        var componentClass = untyped networkComponents[componentType];
        var component = em.getComponent(entity, componentClass);

        component.serialize(ba);
    }
    public function serializeUpdate(componentType:Int,entity:String,ba:ByteArray):Void {
        var componentClass = untyped networkComponents[componentType];
        var component = em.getComponent(entity, componentClass);

        component.serialize(ba);
    }
    public function serializeDelete(componentType:Int,entity:String,ba:ByteArray):Void {
        var componentClass = untyped networkComponents[componentType];
        var component = em.getComponent(entity, componentClass);

        component.serialize(ba);
    }
    public function unserializeCreate(componentType:Int,entity:String,ba:ByteArray):Void {
        var componentClass = untyped networkComponents[componentType];
        var component = em.getComponent(entity, componentClass);

        component.unserialize(ba);
    }
    public function unserializeUpdate(componentType:Int,entity:String,ba:ByteArray):Void {
        var componentClass = untyped networkComponents[componentType];
        var component = em.getComponent(entity, componentClass);

        component.unserialize(ba);
    }
    public function unserializeDelete(componentType:Int,entity:String,ba:ByteArray):Void {
        var componentClass = untyped networkComponents[componentType];
        var component = em.getComponent(entity, componentClass);

        component.unserialize(ba);
    }

    public function new()
    {
        var syncComponentsNameByEntityIdSerialized = haxe.Resource.getString("syncComponentsNameByEntityId");
        syncComponentsNameByEntityId = haxe.Unserializer.run(syncComponentsNameByEntityIdSerialized);

        var componentsNameByEntityIdSerialized = haxe.Resource.getString("componentsNameByEntityId");
        componentsNameByEntityId = haxe.Unserializer.run(componentsNameByEntityIdSerialized);

        syncedEntities = haxe.Unserializer.run(haxe.Resource.getString("syncedEntities"));

        trace("componentsNameByEntityId " + componentsNameByEntityId);

        var componentsSerialized = haxe.Resource.getString("components");
        var components:Array<String> = haxe.Unserializer.run(componentsSerialized);

        this.networkComponents = new Array();

        for(comp in components)
        {
            var c = Type.resolveClass(comp);
            networkComponents.push(untyped c);
        }
        trace("networkComponents " + networkComponents);
    } 
}


@:autoBuild(enh.macros.Template.system())
class System<T>
{
    public var em:EntityManager;
    public var root:T;
    public var enh:Enh;
    #if server
    public var net:ServerManager;
    #end
}


@:autoBuild(enh.macros.Template.main())
class Enh
{
    public var em:EntityManager;
    public var ec:EntityCreatowr;
    public var enh:Enh;

    private var oldTime:Float;
    private var accumulator:Float;
    private var rate:Float;
    private var loopFunc:Void->Void;

    public function new(entityCreator:Class<EntityCreatowr>)
    {
        this.em = new EntityManager();

        this.enh = this; // allows root to also _processRPCs correctly

        this.ec = Type.createInstance(entityCreator, []);
        this.ec.em = this.em;

        #if server
        manager = new ServerManager(this);
        net = manager;
        #end
        #if client
        manager = new ClientManager(this);
        #end
    }

    public function setEntityCreator<T:EntityCreatowr>(entityCreator:Class<T>)
    {
        var ec:T = Type.createInstance(entityCreator, []);
        ec.em = this.em;
        this.ec = ec;
    }

    public function addSystem<T>(systemClass:Class<T>):T
    {
        var system:T = Type.createInstance(systemClass, []);

        Reflect.setField(system, "em", em);
        Reflect.setField(system, "root", this);
        Reflect.setField(system, "enh", this);
        #if server
        Reflect.setField(system, "net", manager);
        #end
        Reflect.callMethod(system, Reflect.field(system, "init"), []);

        return system;
    }

    private function step(?dummy)
    {
        // FIXED TIME STEP
        var newTime = Timer.getTime();
        var frameTime = newTime - oldTime;
        accumulator += frameTime;
        oldTime = newTime;

        while(accumulator >= rate)
        {
            if(socket.connected) socket.pumpIn();
            loopFunc();
            if(socket.connected) socket.pumpOut();
            
            accumulator -= rate;
        }
    }

    #if client
    public var socket:ISocketClient;
    public var manager:ClientManager;

    public function connect(ip:String, port:Int)
    {
        socket = new Socket(this);
        socket.connect(ip, port);
    }

    public function startLoop(loopFunc:Void -> Void, rate:Float)
    {
        trace("startloop");
        this.oldTime = Timer.getTime();
        this.accumulator = 0;
        this.rate = rate;
        this.loopFunc = loopFunc;

        Loop.startLoop(step);
    }
    #end

    #if server
    public var socket:ServerSocket;
    public var manager:ServerManager;
    public var net:ServerManager;

    public function startLoop(loopFunc:Void -> Void, rate:Float)
    {
        this.oldTime = Timer.getTime();
        this.accumulator = 0;
        this.rate = rate;
        this.loopFunc = loopFunc;

        while(true)
        {
            step();

            Sys.sleep(rate/2);  // For CPU : Ugly isn't it :3
        }
    }

    public function startServer(address:String, port:Int)
    {
        socket = new ServerSocket(address, port, this);
        return socket;
    }
    #end
}

