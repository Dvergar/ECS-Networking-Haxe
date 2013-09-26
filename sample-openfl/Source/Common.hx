import enh.EntityManager;
import enh.Builders;

#if (flash || openfl)
import flash.utils.ByteArray;
import flash.display.Shape;
import Client;
#else
import enh.ByteArray;
#end

// class CMyPlayer extends Component
// {
//     public function new()
//     {
//         super();
//     }
// }


// class CId extends Component
// {
//     public var value:Int;
//     public function new(value:Int)
//     {
//         super();
//         this.value = value;
//     }
// }


// class CConnexion extends Component
// {
//     public var bytes:ByteArray;
// 	public function new()
// 	{
// 		super();
// 		this.bytes = new ByteArray();
// 	}
// }




@networked @sync
class CPosition extends Component
{
	@short public var x:Int;
	@short public var y:Int;

	public function new(x:Int, y:Int)
	{
		super();
		this.x = x;
		this.y = y;
	}
}


@networked
class CComponentTest extends Component
{
	@short public var hp:Int;

	public function new() {super();}
}



@:build(enh.macros.MacroTest.buildMap())
class EntityCreator extends EntityCreatowr
{
	public function new() {
		super();
	}

	@freeze
	public function mouse():String
	{
		trace("mouse");
		var player = em.createEntity();
		em.addComponent(player, new CPosition(100, 100));
		em.addComponent(player, new CComponentTest());

		#if client
		var shape = new Shape();
        shape.graphics.beginFill(0x3FBF2E);
        shape.graphics.drawRect(0, 0, 100, 100);
        shape.graphics.endFill();

		em.addComponent(player, new CDrawable(shape));
		// em.addComponent(player, new CDrawable());
		#end

		return player;
	}

	@freeze
	public function fucker():String
	{
		trace("createFucker");
		var fucker = em.createEntity();
		// em.addComponent(fucker, new CComponent3());
		// em.addComponent(fucker, new CComponent2());
		// em.removeComponentOfType(fucker, CComponent2);

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


