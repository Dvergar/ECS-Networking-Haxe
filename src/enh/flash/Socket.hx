package enh.flash;

import enh.Builders;

import flash.events.Event;
import flash.events.ProgressEvent;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import anette.Client;


class Socket implements ISocketClient
{
	public var conn:Connection;
	public var connected:Bool;
    private var socket:flash.net.Socket;
    private var em:EntityManager;
    var client:anette.Client;
    var enh:Enh;

	public function new(enh:Enh)
	{
		trace("flashsocket");
		// super(enh);

        this.enh = enh;
		this.em = Enh.em;
        this.client = new Client();
        client.onConnection = onConnection;
        client.onData = onData;
        client.onDisconnection = onDisconnection;
        // socket = new flash.net.Socket();
        // socket.addEventListener(Event.CONNECT, onConnect);
        // socket.addEventListener(Event.CLOSE, onClose);
        // socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecError);
        // socket.addEventListener(IOErrorEvent.IO_ERROR, onError);
	}

    function onData(anconnection:anette.Connection)
    {
        enh.manager.processDatas(anconnection);
    }

    function onConnection(anconnection:anette.Connection)
    {
        trace("connection");
        conn = new Connection(anconnection);
        connected = true;
    }

    function onDisconnection(anconnection:anette.Connection)
    {
        trace("disco");
        connected = false;
    }

	// private function onConnect(ev:Event)
	// {
	// 	trace("flash : onConnect");
	// 	conn = new Connection();
	// 	connected = true;
	// }


 //    private function onClose(ev:Event)
 //    {
 //        trace("flash : onClose");
 //        em.pushEvent("DISCONNECTION", -1, {});
 //    }

 //    private function onError(event:Event)
 //    {
 //        trace("flash : onError");
 //    }

 //    private function onSecError(event:Event)
 //    {
 //        trace("flash : onSecError");
 //    }

	public function connect(ip:String, port:Int)
	{
		trace("connect");
        // socket.connect(ip, port);
        client.connect(ip, port);
	}

    public function pumpIn()
    {
        client.pump();

        // socket.readBytes(this.conn.input, 0, socket.bytesAvailable);

        // this.readSocket(conn);
    }

    public function pumpOut()
    {
        client.flush();
        // if(conn.output.length > 0)
        // {
        //     conn.output.position = 0;
        //     socket.writeShort(conn.output.length);
        //     socket.writeBytes(conn.output, 0, conn.output.length);
        //     socket.flush();
        //     conn.output.clear();
        // }
    }
}