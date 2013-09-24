import enh.EntityManager;
import enh.Builders;

import Common;


class MovementSystem extends System<Server>
{
	public function init()
	{
		@registerListener "UPDATE_PLAYER";
		em.pushEvent("UPDATE_PLAYER", "dummy", {future:42});
	}

	public function hello()
	{
		trace("hello");
	}

	@future('Int')
	public function onUpdatePlayer(entity:String, event:Dynamic)
	{
		trace("onUpdatePlayer");
		trace("event " + event.future);
	}
}


class Server extends Enh
{
	public function new()
	{
		super(EntityCreator);
		this.startServer("", 32000);

		@addSystem MovementSystem;
		movementSystem.hello();
		this.em.registerListener("ON_CONNECTION", onConnection);
		this.em.registerListener("ON_DATA", onData);
		this.em.registerListener("NET_HELLO", onNetHello);

		this.startLoop(loop, 1/60);
	}

	@msg('String')
	private function onNetHello(entity:String, ev:Dynamic)
	{
		trace("onNetHello");
	}

	private function onConnection(entity:String, ev:Dynamic)
	{
		trace("onConnect");
		// @RPC("NET_ACTION_LOL", 50, "hello") {hp:Int, msg:String};
		var entity = net.createNetworkEntity("player");
		var c = em.getComponent(entity, CComponent1);
		c.x = 500;
		c.y = 42;

		net.updateNetworkEntity(entity);

	}

	private function onData(entity:String, ev:Dynamic)
	{
		trace("onData");
	}

	private function loop():Void
	{
		// trace("ok");
	}

	static function main() {new Server();}
}