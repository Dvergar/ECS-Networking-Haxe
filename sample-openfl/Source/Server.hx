import enh.EntityManager;
import enh.Builders;
import enh.Constants;

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


class Server extends Enh<Server, EntityCreator>
{
    public function new()
    {
        super(this, EntityCreator);
    }

    public function init()
    {
        this.startServer("192.168.1.4", 32000);

        @addSystem MouseMovementSystem;

        @registerListener "PING";
        @registerListener "CONNECTION";
        @registerListener "DISCONNECTION";
        @registerListener "HELLO";

        this.startLoop(loop, 1/60);

    }

    function onPing(entity:Entity, ev:Dynamic) {}

    @msg('String')
    private function onHello(entity:Entity, ev:Dynamic)
    {
        trace(ev.msg);
    }

    private function onConnection(connectionEntity:Entity, ev:Dynamic)
    {

        var square = net.createNetworkEntity("square",
                                             null,
                                             [100, 100],
                                             true);
        net.addComponent(square, new CPepito());
        net.setConnectionEntityFromTo(connectionEntity, square);
        net.sendWorldStateTo(square);

        trace("square net id " + em.getIdFromEntity(square));
        trace("onConnection " + connectionEntity);

        @RPC("HI", CONST.DUMMY, "hi") {msg:String};
    }

    private function onDisconnection(entity:Entity, ev:Dynamic)
    {
        trace("client disconnected");
    }

    private function loop():Void
    {
        // trace("ok");
    }

    static function main() {new Server();}
}