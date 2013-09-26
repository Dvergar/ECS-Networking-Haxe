import enh.EntityManager;
import enh.Builders;

import Common;


class MouseMovementSystem extends System<Server>
{
	public function init()
	{
		@registerListener "NET_MOUSE_POSITION";
		// em.pushEvent("UPDATE_PLAYER", "dummy", {future:42});
	}

	@x('Int') @y('Int')
	public function onNetMousePosition(entity:String, event:Dynamic)
	{
		// trace("onNetMousePosition " + entity);
		var pos = em.getComponent(entity, CPosition);
		pos.x = event.x;
		pos.y = event.y;
	}
}


class Server extends Enh
{
	public function new()
	{
		super(EntityCreator);
		this.startServer("", 32000);

		@addSystem MouseMovementSystem;

		this.em.registerListener("CONNECTION", onConnection);
		this.em.registerListener("DATA", onData);
		this.em.registerListener("NET_HELLO", onNetHello);

		this.startLoop(loop, 1/60);
	}

	@msg('String')
	private function onNetHello(entity:String, ev:Dynamic)
	{
		trace("onNetHello");
	}

	private function onConnection(connectionEntity:String, ev:Dynamic)
	{
		net.sendWorldState(connectionEntity);

		var mouseEntity = net.createNetworkEntity("mouse", connectionEntity);
		net.setConnectionEntityFromTo(connectionEntity, mouseEntity);

		trace("onConnection " + connectionEntity);
		// trace("mousentity " + mouseEntity);

		@RPC("NET_ACTION_LOL", 50, "hello") {hp:Int, msg:String};
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