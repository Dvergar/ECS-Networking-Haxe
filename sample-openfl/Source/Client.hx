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

import enh.Builders;
import enh.Timer;
import enh.Constants;

import Common;


class CDrawable extends Component
{
    public var displayObject:DisplayObject;
    public var parent:DisplayObjectContainer;

    public function new(displayObject:DisplayObject,
                        ?parent:DisplayObjectContainer)
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
        flash.Lib.current.stage.addEventListener(MouseEvent.MOUSE_MOVE,
                                                 onMouseMove);
    }

    private function onMouseMove(event:MouseEvent)
    {
        @RPC("NET_MOUSE_POSITION", Client.myEntity,
                                   Std.int(event.stageX),
                                   Std.int(event.stageY))
                                           {x:Int, y:Int};
    }
}


class DrawableSystem extends System<Client, EntityCreator>
{
    public function init() {}

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


class Client extends Enh<Client, EntityCreator>
{
    var pingTime:Float;
    public static var myEntity:Entity = -1;

    public function new()
    {
        super(this, EntityCreator);
    }

    public function init()
    {
        this.pingTime = Timer.getTime();
        connect("192.168.1.4", 32000);

        @addSystem DrawableSystem;
        @addSystem InputSystem;

        @registerListener "HI";
        @registerListener "CONNECTION";
        @registerListener "DISCONNECTION";
        @registerListener "SQUARE_CREATE";

        startLoop(loop, 1 / 60);
    }

    private function onSquareCreate(entity:Entity, ev:Dynamic)
    {
        trace("onSquareCreate " + entity);
        if(Client.myEntity == -1)
        {
            Client.myEntity = entity;
            inputSystem.activate();
        }
    }

    @msg('String')
    private function onHi(entity:Entity, ev:Dynamic)
    {
        trace(ev.msg);
    }

    private function onConnection(entity:Entity, ev:Dynamic)
    {
        trace("connected");

        @RPC("HELLO", CONST.DUMMY, "Hoy") {msg:String};
    }

    private function onDisconnection(entity:Entity, ev:Dynamic)
    {
        trace("disconnected");
    }

    private function loop()
    {
        // trace(enh.socket.connected);
        drawableSystem.processEntities();

        // if(Timer.getTime() - pingTime > 1)
        // {
        //     @RPC("PING", CONST.DUMMY) {};
        //     pingTime = Timer.getTime();
        // }
    }
}