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
    public function onNetMousePosition(entity:Entity, event:Dynamic)
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
        @registerListener "PING";

        this.em.registerListener("CONNECTION", onConnection);
        this.em.registerListener("NET_HELLO", onNetHello);

        this.startLoop(loop, 1/60);

    }

    function onPing(entity:Entity, ev:Dynamic) {}

    @msg('String')
    private function onNetHello(entity:Entity, ev:Dynamic)
    {
        trace("onNetHellod");
    }

    private function onConnection(connectionEntity:Entity, ev:Dynamic)
    {
        net.sendWorldStateTo(connectionEntity);

        var mouseEntity = net.createNetworkEntity("mouse", connectionEntity, [100, 100]);
        net.addComponent(mouseEntity, new CPepito());
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