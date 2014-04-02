package enh.flash;

import enh.Builders;

import flash.events.Event;
import flash.events.ProgressEvent;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import anette.Client;


class Socket
{
	public var connection:Connection;
	public var connected:Bool;
    private var socket:flash.net.Socket;
    var client:anette.Client;
    var manager:ClientManager;

	public function new(manager:ClientManager)
	{
        this.manager = manager;
        this.client = new Client();
        client.onConnection = onConnection;
        client.onData = onData;
        client.onDisconnection = onDisconnection;
	}

    function onData(anconnection:anette.Connection)
    {
        manager.processDatas(anconnection);
    }

    function onConnection(anconnection:anette.Connection)
    {
        trace("connection");
        this.connection = new Connection(anconnection);
        connected = true;
    }

    function onDisconnection(anconnection:anette.Connection)
    {
        trace("disco");
        connected = false;
    }

	public function connect(ip:String, port:Int)
	{
		trace("connect");
        client.connect(ip, port);
	}

    public function pumpIn()
    {
        client.pump();
    }

    public function pumpOut()
    {
        client.flush();
    }
}