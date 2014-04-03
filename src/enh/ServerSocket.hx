package enh;

import enh.Builders;
import enh.Tools;
import enh.Constants;


class ServerSocket
{
    public var connections:Map<anette.Connection, Connection> = new Map();
    public var gameConnections:Map<anette.Connection, Connection> = new Map();
    public var waitingSockets:Map<Connection, anette.Connection> = new Map();
    private var connectionIds:IdManager;

    var manager:ServerManager;
    var server:anette.Server;

    public function new(address:String, port:Int, manager:ServerManager)
    {
        this.manager = manager;
        connectionIds = new IdManager(32);  // Careful i don't put them back in

        server = new anette.Server(address, port);
        server.onData = onData;
        server.onConnection = onConnection;
        server.onDisconnection = onDisconnection;
    }

    public function test():Void
    {
        throw("GOOD SERVERSOCKET");
    }

    function onData(anconnection:anette.Connection)
    {
        manager.processDatas(anconnection);
    }

    function onConnection(anconnection:anette.Connection)
    {
        trace("onConnection");
        var connection = new Connection(anconnection, connectionIds.get());
        connections.set(anconnection, connection);
        waitingSockets.set(connection, anconnection);
        notifyConnection(anconnection, connection);
    }

    function onDisconnection(anconnection:anette.Connection)
    {
        trace("enh disconnection");
        disconnect(connections.get(anconnection), anconnection);
    }

    public function pumpIn():Void
    {
        server.pump();
    }

    public function disconnect(conn:Connection, anconn:anette.Connection)
    {
        trace("disconnect " + conn.entity);
        connections.remove(anconn);
        manager._disconnect(conn);
        gameConnections.remove(anconn);
        waitingSockets.remove(conn);
    }

    public function connect(conn:Connection)
    {
        manager.connect(conn);
        var anconn = waitingSockets.get(conn);
        waitingSockets.remove(conn);
        gameConnections.set(anconn, conn);

        trace("connected");
    }

    function notifyConnection(annconn:anette.Connection, conn:Connection)
    {
        var output = annconn.output;

        output.writeByte(CONST.CONNECTION);
        output.writeInt16(conn.id);

        trace("notify length msg " + output.length);
        trace("notifyConnection id " + conn.id);

        trace("SOCKET : onConnect " + conn.entity);
    }

    public function pumpOut():Void
    {
        server.flush();
        manager.pumpSyncedEntities();
    }
}