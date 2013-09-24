import enh.EntityManager;
import enh.Builders;

#if (flash || openfl)
import flash.utils.ByteArray;
#else
import enh.ByteArray;
#end



class CMyPlayer extends Component
{
    public function new()
    {
        super();
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


class CConnexion extends Component
{
    public var bytes:ByteArray;
	public function new()
	{
		super();
		this.bytes = new ByteArray();
	}
}


// @:autoBuild(enh.macros.MacroTest.buildComponent())
// class NetComponent extends Component {}

@networked @sync
class CComponent1 extends Component
{
	public static var l = [1, 2, 3];
	@create @update @short public var x:Int;
	@create @update @short public var y:Int;

	public function new()
	{
		super();
	}
}

@networked
class CComponent2 extends Component
{
	@create @update @short public var hp:Int;

	public function new() {super();}
}

class CComponent3 extends Component
{
	public function new() {super();}
}


@:build(enh.macros.MacroTest.buildMap())
class EntityCreator extends EntityCreatowr
{
	public function new() {
		super();
		// trace("entityfunci " + entityFunctionsMap);
	}

	@freeze
	public function player():String
	{
		trace("createPlayer");
		var k = 5;
		var player = em.createEntity();
		em.addComponent(player, new CComponent1());
		var i = 12;
		em.addComponent(player, new CComponent2());

		#if server
		em.addComponent(player, new CConnexion());
		#end

		#if client
		em.addComponent(player, new CMyPlayer());
		#end

		return player;
	}

	@freeze
	public function fucker():String
	{
		trace("createFucker");
		var k = 5;
		var fucker = em.createEntity();
		em.addComponent(fucker, new CComponent3());
		var i = 12;
		em.addComponent(fucker, new CComponent2());
		em.removeComponentOfType(fucker, CComponent2);

		return fucker;
	}

	@loltest
	public function test()
	{
		var d = "dummy";
		switch(d){
			default: throw "lol";
		}
	}
}


