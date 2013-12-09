package enh;

typedef Entity = String;

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


@:autoBuild(enh.macros.MacroTest.buildMap())
class EntityCreatowr
{
    // TO-DO : God, refactor this mess with typedefs or something :'(
    public var entityTypeIdByEntityTypeName:Map<String, Int>;
    public var entityTypeNameById:Map<Int, String>;
    public var functionByEntityType:Map<String, Array<Int>->String>;
    public var componentsNameByEntityId:Array<Array<Int>>; // ComponentName ? Component Id !
    public var syncComponentsNameByEntityId:Array<Array<Int>>;
    public var networkComponents:Array<Component>;
    public var syncedEntities:Array<Bool>;
    public var em:EntityManager;

    // TO-DO : Refactor, specific methods are now useless
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
            // Why untyped ?
            networkComponents.push(untyped c);
        }
        trace("networkComponents " + networkComponents);
    } 
}


@:autoBuild(enh.macros.Template.system())
class System<ROOTTYPE, ECTYPE>
{
    public var em:EntityManager;
    public var root:ROOTTYPE;
    public var enh:ROOTTYPE;
    public var ec:ECTYPE;
    #if server
    public var net:ServerManager;
    #end
}


@:autoBuild(enh.macros.Template.main())
// @:generic
class Enh2<ROOTTYPE:{function init():Void;},
           ECTYPE:{var em:EntityManager;}>
{
    public static var EM:EntityManager;
    var em:EntityManager;
    var ec:ECTYPE;
    var enh:Enh2<ROOTTYPE, ECTYPE>;
    var root:ROOTTYPE;

    var _enh:Enh;

    var oldTime:Float;
    var accumulator:Float;
    var rate:Float;
    var loopFunc:Void->Void;

    public function new(root:ROOTTYPE, entityCreatorType:Class<ECTYPE>)
    {
        this.root = root;
        Enh2.EM = new EntityManager();
        this.em = Enh2.EM;
        // this.root = cast(this, ROOTTYPE);
        this.ec = Type.createInstance(entityCreatorType, []);
        this.ec.em = Enh2.EM;
        this.enh = this; // allows root to also _processRPCs correctly

        // Only only used as a helper to reach ec & em without type parameter
        this._enh = new Enh(Enh2.EM, cast ec);
        #if server
        this.net = _enh.manager;
        #end

        #if client
        socket = new Socket(this._enh);
        #end

        root.init();
    }

    public function addSystem<U>(systemClass:Class<U>):U
    {
        // var system:U = Type.createInstance(systemClass, []);
        var system:U = Type.createEmptyInstance(systemClass);

        Reflect.setField(system, "em", Enh2.EM);
        Reflect.setField(system, "root", root);
        Reflect.setField(system, "enh", this);
        Reflect.setField(system, "ec", ec);
        #if server
        Reflect.setField(system, "net", _enh.manager);
        #end
        // trace("system enh " + system.enh);
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
            if(socket.connected) socket.pumpIn();
            loopFunc();
            if(socket.connected) socket.pumpOut();
            
            accumulator -= rate;
        }
    }

    #if client
    public var socket:ISocketClient;


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

        while(true)
        {
            step();

            Sys.sleep(rate/2);  // For CPU : Ugly isn't it :3
        }
    }

    public function startServer(address:String, port:Int)
    {
        trace("startserver");
        this.socket = new ServerSocket(address, port, this._enh);
        trace("socket " + Type.getClass(socket));
        return socket;
    }
    #end
}

// Non exposed
class Enh
{
    public var em:EntityManager;
    public var ec:EntityCreatowr;
    #if client
    public var manager:ClientManager;
    #end
    #if server
    public var manager:ServerManager;
    #end

    public function new(em, ec)
    {
        this.em = em;
        this.ec = ec;

        #if server
        manager = new ServerManager(this);
        #end
        #if client
        manager = new ClientManager(this);
        #end
    }

    // public function setEntityCreator<T:EntityCreatowr>(entityCreator:Class<T>)
    // {
    //     var ec:T = Type.createInstance(entityCreator, []);
    //     ec.em = this.em;
    //     this.ec = ec;
    // }

    // public function addSystem<T:{em:EntityManager}>(system:T):T
    // {
    //     trace("type " + this.me);
        // system.em = this.em;
        // var system:T = Type.createInstance(systemClass, []);

        // Reflect.setField(system, "em", em);
        // Reflect.setField(system, "root", this);
        // Reflect.setField(system, "enh", this);
        // #if server
        // Reflect.setField(system, "net", manager);
        // #end
        // trace("system enh " + system.enh);
        // Reflect.callMethod(system, Reflect.field(system, "init"), []);

        // return system;
    // }

    // public function addSystem<T:{root:Dynamic}>(systemClass:Class<T>):T
    // {
    //     var system:T = Type.createInstance(systemClass, []);

    //     // Reflect.setField(system, "em", em);
    //     Reflect.setField(system, "root", this);
    //     // Reflect.setField(system, "enh", this);
    //     #if server
    //     Reflect.setField(system, "net", manager);
    //     #end
    //     // trace("system enh " + system.enh);
    //     Reflect.callMethod(system, Reflect.field(system, "init"), []);

    //     return system;
    // }


}

