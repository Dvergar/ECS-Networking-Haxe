package enh;


import enh.EntityManager;

#if (flash || openfl)
import flash.utils.ByteArray;
#else
import enh.ServerManager;
import enh.ByteArray;
#end

@:autoBuild(enh.macros.MacroTest.buildComponent())
class Component
{
    public function new(){}
    public function _detach(){}
}


interface IEntityCreator
{
	// public var entityFunctionsMap:Array<Void->String>;
	// public var entityComponentsMap:Array<Array<Array<Int>>>;

    public function serializeCreate(componentType:Int,entity:String,ba:ByteArray):Void;
    public function serializeUpdate(componentType:Int,entity:String,ba:ByteArray):Void;
    public function serializeDelete(componentType:Int,entity:String,ba:ByteArray):Void;
    public function unserializeCreate(componentType:Int,entity:String,ba:ByteArray):Void;
    public function unserializeUpdate(componentType:Int,entity:String,ba:ByteArray):Void;
    public function unserializeDelete(componentType:Int,entity:String,ba:ByteArray):Void;
}

class EntityCreatowr implements IEntityCreator
{
	public var entityFunctionsMap:Array<Void->String>;
	public var entityComponentsMap:Array<Array<Array<Int>>>;
	public var networkComponents:Array<Component>;
	public var em:EntityManager;

    public function serializeCreate(componentType:Int,entity:String,ba:ByteArray):Void {
    	var componentClass = untyped networkComponents[componentType];
    	var component = em.getComponent(entity, componentClass);

    	component.serializeCreate(ba);
    }
    public function serializeUpdate(componentType:Int,entity:String,ba:ByteArray):Void {
    	var componentClass = untyped networkComponents[componentType];
    	var component = em.getComponent(entity, componentClass);

    	component.serializeUpdate(ba);
    }
    public function serializeDelete(componentType:Int,entity:String,ba:ByteArray):Void {
    	var componentClass = untyped networkComponents[componentType];
    	var component = em.getComponent(entity, componentClass);

    	component.serializeDelete(ba);
    }
    public function unserializeCreate(componentType:Int,entity:String,ba:ByteArray):Void {
    	var componentClass = untyped networkComponents[componentType];
    	var component = em.getComponent(entity, componentClass);

    	component.unserializeCreate(ba);
    }
    public function unserializeUpdate(componentType:Int,entity:String,ba:ByteArray):Void {
    	var componentClass = untyped networkComponents[componentType];
    	var component = em.getComponent(entity, componentClass);

    	component.unserializeUpdate(ba);
    }
    public function unserializeDelete(componentType:Int,entity:String,ba:ByteArray):Void {
    	var componentClass = untyped networkComponents[componentType];
    	var component = em.getComponent(entity, componentClass);

    	component.unserializeDelete(ba);
    }

    public function new()
    {
    	var entityComponentsMapSerialized = haxe.Resource.getString("entityComponentsMap");
    	trace("entityComponentsMapSerialized " + entityComponentsMapSerialized);
    	entityComponentsMap = haxe.Unserializer.run(entityComponentsMapSerialized);
    	trace("superentitycomponentsmap " + entityComponentsMap);

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
	public var output:ByteArray;
	public var enh:Enh;


	public function new(entityCreator:Class<EntityCreatowr>)
	{
        // throw(haxe.Resource.getString("test"));

		this.em = new EntityManager();
		this.output = new ByteArray();
		this.enh = this; // allows root to also _processRPCs correctly

		this.ec = Type.createInstance(entityCreator, []);
		this.ec.em = this.em;

		#if server
		serverManager = new ServerManager(this);
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
		#if server
		Reflect.setField(system, "net", serverManager);
		#end
		Reflect.callMethod(system, Reflect.field(system, "init"), []);

		return system;
	}

	#if server
	public var serverSocket:ServerSocket;
	public var serverManager:ServerManager;

	public function startLoop(loopFunc:Void -> Void, rate:Float)
	{
		var oldTime = Sys.time();
		var accumulator:Float = 0;

		while(true)
		{
            // FIXED TIME STEP
            var newTime = Sys.time();
            var frameTime = newTime - oldTime;
            accumulator += frameTime;
            oldTime = newTime;

            while(accumulator >= rate)
            {
                if(serverSocket != null) serverSocket.pumpIn();
                loopFunc();
				if(serverSocket != null) serverSocket.pumpOut();
				
                accumulator -= rate;
            }

            Sys.sleep(rate/2);  // For CPU : Ugly isn't it :3
		}
	}

	public function startServer(address:String, port:Int)
	{
		serverSocket = new ServerSocket(address, port, this);
		return serverSocket;
	}
	#end
}

