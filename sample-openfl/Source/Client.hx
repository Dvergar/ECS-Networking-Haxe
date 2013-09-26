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

import enh.EntityManager;
import enh.Builders;
import enh.ClientManager;

import Common;


// class CDrawable extends Component
// {
// }


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


class InputSystem extends System<Client>
{
	public function init()
	{
        
	}

	public function activate()
	{
		flash.Lib.current.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
	}

    private function onMouseMove(event:MouseEvent)
    {
    	// trace(event.stageX);
    	trace("mouse " + event.stageY + " / " + event.stageX);
    	// trace("enh " + enh);
    	@RPC("NET_MOUSE_POSITION", Std.int(event.stageX), Std.int(event.stageY)) {x:Int, y:Int};
	}
}


class DrawableSystem extends System<Client>
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



class Client extends Enh {
	private var cm:ClientManager;
	private var socket:Socket;

	public function new () {
		super(EntityCreator);

		cm = new ClientManager(this);

		socket = new Socket();
        socket.connect("192.168.1.4", 32000);
        // socket.addEventListener(Event.CONNECT, onConnect);
        socket.addEventListener(ProgressEvent.SOCKET_DATA, onData);

		@addSystem DrawableSystem;
		@addSystem InputSystem;

        @registerListener "NET_ACTION_LOL";

		this.em.registerListener("CONNECTION", onConnection);
		flash.Lib.current.stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
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

	private function onData(ev:ProgressEvent)
	{
		trace("onData " + socket.bytesAvailable);

		socket.readBytes(input, 0, socket.bytesAvailable);
		
        while(input.bytesAvailable > 2)
        {
        	trace("output " + input.bytesAvailable);

        	var msgLength = input.readShort();
        	trace("msglength " + msgLength);

        	var positionBeforeReading = input.position;

        	if(input.bytesAvailable >= msgLength)
        	{
        		while(input.position - positionBeforeReading < msgLength)
        		{
        			cm.readMessageFromTheInternetTubes(input);
        		}
        	}
        	else
        	{
        		input.position -= 2;
        	}

        	if(input.bytesAvailable == 0) input.clear();
        }
	}

	private function onEnterFrame(ev:Event)
	{
		drawableSystem.processEntities();

		if(socket.connected)
		{
			if(this.output.length > 0)
			{
				trace("DATA SENT " + this.output.length);
				this.output.position = 0;
				socket.writeShort(this.output.length);
				socket.writeBytes(this.output, 0, this.output.length);
				socket.flush();
				this.output.clear();
			}
		}
	}
}