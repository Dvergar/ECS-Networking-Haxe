package;

import flash.display.Sprite;
import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.net.Socket;
import flash.events.MouseEvent;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import flash.events.ProgressEvent;
import flash.utils.ByteArray;

// import enh.EntityManager;
import enh.Builders;
// import enh.ClientManager;

import Common;


class CDrawable extends Component
{
    public var displayObject:DisplayObject;
    public var parent:DisplayObjectContainer;

    public function new(displayObject:DisplayObject, ?parent:DisplayObjectContainer)
    {
        super();

        this.displayObject = displayObject;

        if(parent == null) parent = flash.Lib.current.stage;
        parent.addChild(displayObject);

        this.parent = parent;
    }
}


class InputSystem extends System<Client, EntityCreator>
{
    public function init() {}

    public function activate()
    {
        flash.Lib.current.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
    }

    private function onMouseMove(event:MouseEvent)
    {
        @RPC("NET_MOUSE_POSITION", Std.int(event.stageX), Std.int(event.stageY)) {x:Int, y:Int};
    }
}


class DrawableSystem extends System<Client, EntityCreator>
{
    public function init()
    {
    }

    public function processEntities()
    {
        var allDrawables = em.getEntitiesWithComponent(CDrawable);
        for(entity in allDrawables)
        {
            var drawable = em.getComponent(entity, CDrawable);
            var position = em.getComponent(entity, CPosition);

            drawable.displayObject.x = position.x;
            drawable.displayObject.y = position.y;
        }
    }
}


class Client extends Enh2<Client, EntityCreator>
{
    public function new()
    {
        super(this, EntityCreator);
    }

    public function init()
    {
        connect("192.168.1.2", 32000);

        @addSystem DrawableSystem;
        @addSystem InputSystem;

        @registerListener "NET_ACTION_LOL";
        @registerListener "CONNECTION";

        // this.em.registerListener("CONNECTION", onConnection);

        startLoop(loop, 1/60);
    }

    @hp('Int') @msg('String')
    private function onNetActionLol(entity:String, ev:Dynamic)
    {
        trace("onNetActionLol");
    }

    private function onConnection(entity:String, ev:Dynamic)
    {
        trace("connected");
        inputSystem.activate();
        @RPC("NET_HELLO", "Hoy") {msg:String};
    }


    private function loop()
    {
        drawableSystem.processEntities();
    }
}