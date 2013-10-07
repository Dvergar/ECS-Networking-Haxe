import enh.EntityManager;
import enh.Builders;

import Common;


class MouseMovementSystem extends System<Server, EntityCreator>
{
    public function init()
    {
        @registerListener "NET_MOUSE_POSITION";
    }

    @x('Int') @y('Int')
    public function onNetMousePosition(entity:String, event:Dynamic)
    {
        var pos = em.getComponent(entity, CPosition);
        pos.x = event.x;
        pos.y = event.y;
    }
}


class Server extends Enh2<Server, EntityCreator>
{
    public function new()
    {
        super(this, EntityCreator);
    }

    public function init()
    {
        this.startServer("", 32000);

        @addSystem MouseMovementSystem;

        this.em.registerListener("CONNECTION", onConnection);
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
        net.sendWorldStateTo(connectionEntity);

        var mouseEntity = net.createNetworkEntity("mouse", connectionEntity, [100, 100]);
        net.setConnectionEntityFromTo(connectionEntity, mouseEntity);

        trace("onConnection " + connectionEntity);
        @RPC("NET_ACTION_LOL", 50, "hello") {hp:Int, msg:String};
    }

    private function loop():Void
    {
        // trace("ok");
    }

    static function main() {new Server();}
}