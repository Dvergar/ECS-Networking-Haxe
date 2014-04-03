package enh;

import enh.EntityManager;
import anette.Bytes;
import enh.macros.EntityComponentMacro.ComponentTemplate;
import enh.macros.EntityComponentMacro.EntityTemplate;


typedef Short = Int;
typedef LoopDatas = {loopFunction: Void->Void, gameRate: Float, netRate: Float}


@:autoBuild(enh.macros.EntityComponentMacro.buildComponent())
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


@:autoBuild(enh.macros.EntityComponentMacro.buildMap())
class EntityCreatorBase
{
    public var em:EntityManager;
    public var entities:Array<EntityTemplate> = new Array();
    public var entityIdByName:Map<String, Int> = new Map();
    public var functionByEntityName:Map<String, Array<Int> -> Entity>;
    public var networkComponents:Array<Component> = new Array();

    public function serialize(componentType:Int, entity:Entity,
                              output:BytesOutputEnhanced):Void
    {
        var componentClass = untyped networkComponents[componentType];
        var component = em.getComponent(entity, componentClass);

        component.serialize(output);
    }

    public function unserialize(componentType:Int, entity:Entity,
                                input:BytesInputEnhanced):Void
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
        var netEntitiesSerialized = haxe.Resource.getString("netEntities");
        this.entities = haxe.Unserializer.run(netEntitiesSerialized);
        var netComponentsSerialized = haxe.Resource.getString("netComponents");
        var components:Array<ComponentTemplate> = 
                                haxe.Unserializer.run(netComponentsSerialized);

        // PUSH COMPONENTS IDS INTO ENTITY COMPONENTS IDS
        for(entity in entities)
        {
            var keepComponents = [];
            for(component in entity.components)
            {
                for(netComp in components)
                {
                    if(component.name == netComp.name)
                    {
                        component.id = netComp.id;
                        keepComponents.push(component);
                    }
                }
            }

            entity.components = keepComponents; // Filter out client-side comps
        }

        // FILL ARRAYS & SHIT
        for(entity in entities)
        {
            entityIdByName.set(entity.name, entity.id);

            for(component in entity.components)
            {
                entity.componentsIds.push(component.id);
                if(component.sync == true)
                {
                    entity.syncComponentsIds.push(component.id);
                    entity.sync = true;
                }
            }
        }

        for(component in components)
        {
            var c = Type.resolveClass(component.name);
            networkComponents.push(untyped c);
        }
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
class SystemManager<ROOTTYPE:{function init():Void;},
                    ECTYPE:{var em:EntityManager;}>
{
    var em:EntityManager;
    var ec:ECTYPE;
    var root:ROOTTYPE;  // ALLOWS ACCESS TO SYSTEM MANAGER

    var oldTime:Float;
    var oldNetTime:Float;
    var accumulator:Float;
    var loopDatas:LoopDatas;

    public function new(root:ROOTTYPE, entityCreatorType:Class<ECTYPE>)
    {
        this.root = root;
        this.em = new EntityManager();
        this.ec = Type.createInstance(entityCreatorType, []);
        this.ec.em = em;

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

        while(accumulator >= loopDatas.gameRate)
        {
            socket.pumpIn();
            loopDatas.loopFunction();
            
            accumulator -= loopDatas.gameRate;
        }

        if(newTime - oldNetTime > loopDatas.netRate)
        {
            socket.pumpOut();
            oldNetTime = newTime;
        }
    }

    #if client
    public var socket:Socket;
    public var net:ClientManager;

    public function connect(ip:String, port:Int)
    {
        socket.connect(ip, port);
    }

    public function startLoop(loopDatas:LoopDatas)
    {
        this.oldTime = Timer.getTime();
        this.oldNetTime = Timer.getTime();
        this.accumulator = 0;
        this.loopDatas = loopDatas;

        Loop.startLoop(step);
    }
    #end

    #if server
    public var socket:ServerSocket;
    public var net:ServerManager;

    public function startLoop(loopDatas:LoopDatas)
    {
        this.oldTime = Timer.getTime();
        this.oldNetTime = Timer.getTime();
        this.accumulator = 0;
        this.loopDatas = loopDatas;

        #if (cpp || neko)
        while(true)
        {
            step();
            Sys.sleep(loopDatas.gameRate / 2);  // For CPU : Ugly isn't it :3
        }

        #elseif js
        var timer = new haxe.Timer(Std.int(1000 * rate / 2));
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
