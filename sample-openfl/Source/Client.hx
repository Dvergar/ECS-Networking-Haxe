package;

import flash.display.Sprite;
import flash.net.Socket;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import flash.events.ProgressEvent;
import flash.utils.ByteArray;

import enh.EntityManager;
import enh.Builders;
import enh.ClientManager;

import Common;



class Client extends Enh {
	private var cm:ClientManager;
	private var socket:Socket;
	private var ba:ByteArray;

	public function new () {
		super(EntityCreator);

		this.ba = new ByteArray();
		// this.setRoot(this);
		// this.setEntityCreator(EntityCreator);

		cm = new ClientManager(this);

		socket = new Socket();
        socket.connect("192.168.1.4", 32000);
        socket.addEventListener(Event.CONNECT, onConnect);
        socket.addEventListener(ProgressEvent.SOCKET_DATA, onData);

        @registerListener "NET_ACTION_LOL";

		trace("hello");
		flash.Lib.current.stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
	}

	@hp('Int') @msg('String')
	private function onNetActionLol(entity:String, ev:Dynamic)
	{
		trace("onNetActionLol");
	}

	private function onConnect(ev:Event)
	{
		trace("connected");
		@RPC("NET_HELLO", "Hoy") {msg:String};
	}

	private function onData(ev:ProgressEvent)
	{
		trace("onData " + socket.bytesAvailable);

		// var ba = new ByteArray();
		// socket.readShort();
		// socket.readBytes(ba, 0, socket.bytesAvailable);
		// cm.readMessageFromTheInternetTub
		// socket.readShort();

		socket.readBytes(ba, 0, socket.bytesAvailable);
		
        while(ba.bytesAvailable > 2)
        {
        	trace("ba " + ba.bytesAvailable);

        	var msgLength = ba.readShort();
        	trace("msglength " + msgLength);

        	var positionBeforeReading = ba.position;

        	if(ba.bytesAvailable >= msgLength)
        	{
        		while(ba.position - positionBeforeReading < msgLength)
        		{
        			cm.readMessageFromTheInternetTubes(ba);
        		}
        	}
        	else
        	{
        		ba.position -= 2;
        	}

        	if(ba.bytesAvailable == 0) ba.clear();
        }

        var myplayer = em.getEntitiesWithComponent(CMyPlayer).next();
		var c = em.getComponent(myplayer, CComponent1);
		var c2 = em.getComponent(myplayer, CComponent2);
		trace("unserialized update x" + c.x);
		trace("unserialized update y" + c.y);
		trace("unserialized update hp" + c2.hp);
	}

	private function onEnterFrame(ev:Event)
	{
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