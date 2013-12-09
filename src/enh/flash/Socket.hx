package enh.flash;

import enh.Builders;

import flash.events.Event;
import flash.events.ProgressEvent;


class Socket extends SocketHelper implements ISocketClient
{
	public var conn:Connection;
	public var connected:Bool;
    private var socket:flash.net.Socket;
    private var em:EntityManager;

	public function new(enh:Enh)
	{
		trace("flashsocket");
		super(enh);

		em = enh.em;
        socket = new flash.net.Socket();
		socket.addEventListener(Event.CONNECT, onConnect);
	}

	private function onConnect(ev:Event)
	{
		trace("flash : onConnect");
		conn = new Connection();
		connected = true;
	}

	public function connect(ip:String, port:Int)
	{
		trace("connect");
        socket.connect(ip, port);
	}

    public function pumpIn()
    {
        socket.readBytes(this.conn.input, 0, socket.bytesAvailable);

        this.readSocket(conn);
    }

    public function pumpOut()
    {
        if(conn.output.length > 0)
        {
            conn.output.position = 0;
            socket.writeShort(conn.output.length);
            socket.writeBytes(conn.output, 0, conn.output.length);
            socket.flush();
            conn.output.clear();
        }
    }
}