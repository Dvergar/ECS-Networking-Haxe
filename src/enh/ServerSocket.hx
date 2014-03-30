package enh;

import enh.Builders;
import enh.Tools;
import enh.Constants;
import anette.Server;


// class ServerSocket extends SocketHelper



// class ServerSocket
// {
//     public var connected:Bool;
//     private var em:EntityManager;
//     public var connections:Map<anette.Connection, Connection>;
//     public var gameConnections:Map<anette.Connection, Connection>;
//     public var waitingSockets:Map<Connection, anette.Connection>;
//     private var connectionIds:IdManager;
//     var enh:Enh;
//     var server:Server;

//     public function new(address:String, port:Int, enh:Enh)
//     {
//         // super(port);
//         this.test();
//     }

//     public function test():Void
//     {
//         trace("test");
//     }

//     function onData(anconnection:anette.Connection)
//     {
//     }

//     function onConnection(anconnection:anette.Connection)
//     {
//     }

//     public function pumpIn():Void
//     {
//     }

//     public function disconnect(conn:Connection, anconn:anette.Connection)
//     {

//     }

//     public function connect(conn:Connection)
//     {

//     }

//     function notifyConnection(annconn:anette.Connection, conn:Connection)
//     {

//     }

//     public function pumpOut():Void
//     {
//     }
// }




class ServerSocket
{
    public var connected:Bool;
    private var em:EntityManager;
    public var connections:Map<anette.Connection, Connection>;
    public var gameConnections:Map<anette.Connection, Connection>;
    public var waitingSockets:Map<Connection, anette.Connection>;
    private var connectionIds:IdManager;
    var _enh:Enh;
    var server:Server;

    // public function new(address:String, port:Int)
    // Careful _enh was named enh before and breaks with neko, collision with pkg name
    public function new(address:String, port:Int, _enh:Enh)
    {

        // this.test();  // Uncaught exception - Invalid call
        this._enh = _enh;
        this.em = Enh.em;
        this.connected = true;

        connectionIds = new IdManager(32);
        connections = new Map();
        gameConnections = new Map();
        waitingSockets = new Map();

        server = new Server(address, port);
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
        _enh.manager.processDatas(anconnection);
    }

    function onConnection(anconnection:anette.Connection)
    {
        trace("onConnection");
        var connection = new Connection(anconnection, connectionIds.get());
        // connection.anette.output.writeInt16(0);  // CONNECTION
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
        // // trace("1");
        // for(socket in connections.keys())
        // {
        //     var conn = connections.get(socket);
        //     // trace("time " + (Timer.getTime() - conn.activityTime));
        //     if(Timer.getTime() - conn.activityTime > 3)
        //     {
        //         trace("TIMED OUT");
        //         disconnect(conn, socket);
        //     }
        // }

        // var inputSockets = sys.net.Socket.select(sockets, null, null, 0);

        // for(socket in inputSockets.read)
        // {
        //     if(socket == serverSocket)
        //     {
        //         trace("pop");
        //         var newSocket = socket.accept();
        //         newSocket.output.bigEndian = true;
        //         newSocket.input.bigEndian = true;
        //         newSocket.setBlocking(false);
        //         sockets.push(newSocket);

        //         var connection = new Connection(connectionIds.get());
        //         connection.output.writeShort(0);
        //         connections.set(newSocket, connection);
        //         waitingSockets.set(connection, newSocket);

        //         notifyConnection(newSocket, connection);
        //     }
        //     else
        //     {
        //         // trace("SOMETHING HAPPENED");
        //         var conn = connections[socket];
        //         conn.activityTime = Timer.getTime();
        //         var input = conn.input;
        //         // var pos = input.position;

        //         try
        //         {
        //             // trace("0");
        //             // var bytes = input.getBytes();
        //             while(true)
        //             {
        //                 var bytes = haxe.io.Bytes.alloc(1);
        //                 var newBytes = socket.input.readBytes(bytes, 0, 1);
        //                 // trace("readbytes " + newBytes);
        //                 // trace("bytes " + bytes);

        //                 // var byte = socket.input.readByte();
        //                 // trace("byte " + byte);
        //                 // input.writeByte(byte);
        //                 input.writeBytes(bytes, 0, 1);
        //             }
        //         }
        //         catch(ex:haxe.io.Eof)
        //         {
        //             trace("SOCKET EOF");
        //             disconnect(conn, socket);
        //         }
        //         // catch(err:Dynamic)
        //         // {
        //         //     trace("err " + err);
        //         // }
        //         catch(ex:haxe.io.Error)
        //         {
        //             // trace("io error");
        //             if(ex == haxe.io.Error.Blocked)
        //             {
        //                 // trace("BLOCKED");
        //             }
        //             if(ex == haxe.io.Error.Overflow)
        //             {
        //                 trace("OVERFLOW");
        //                 trace("input length " + input.length);
        //             }
        //             if(ex == haxe.io.Error.OutsideBounds)
        //             {
        //                 trace("OUTSIDE BOUNDS");
        //                 trace("input length " + input.length + " / " + input);
        //             }
        //         }

        //         // input.position = pos;

        //         this.readSocket(conn);

        //         // while(input.bytesAvailable > 2)
        //         // {
        //         //     var msgLength = input.readShort();
        //         //     if(input.bytesAvailable < msgLength) break;

        //         //     var msgPos = input.position;
        //         //     while(input.position - msgPos < msgLength)
        //         //     {
        //         //         CONST.SERVERManager.processDatas(conn);
        //         //     }
        //         // }

        //         // if(input.bytesAvailable == 0) input.clear();  // May be risky
        //     }
        // }
    }

    // Ugly but don't really care (only for disconnection)
    // public function getSocketFromConnection(conn:Connection):sys.net.Socket
    // {
    //     var s:sys.net.Socket = sockets[0]; // I KNOW !!!
        
    //     for(socket in connections.keys())
    //     {
    //         var connection = connections[socket];
    //         if(conn == connection)
    //         {
    //             s = socket;
    //             break;
    //         }
    //     }

    //     return s;
    // }

    // A bit too much :3
    public function disconnect(conn:Connection, anconn:anette.Connection)
    {
        trace("disconnect " + conn.entity);
        connections.remove(anconn);
        _enh.manager._disconnect(conn);
        // anconn.disconnect();
        // socket.shutdown(true, true);
        // socket.close();
        // sockets.remove(socket);
        // connections.remove(socket);
        gameConnections.remove(anconn);
        waitingSockets.remove(conn);
    }

    public function connect(conn:Connection)
    {
        _enh.manager.connect(conn);
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
        // output.position = 0;
        // output.writeInt16(output.length - 2);
        // annconn.output.write(output);

        // output.clear();
        // output.writeInt16(0);

        trace("SOCKET : onConnect " + conn.entity);
    }

    public function pumpOut():Void
    {
        server.flush();
        // for(socket in connections.keys())
        // {
        //     var conn = connections[socket];
        //     var output = conn.output;

        //     if(output.length > 2)
        //     {
        //         // trace("out " + ba.length);

        //         output.position = 0;
        //         output.writeShort(output.length - 2);

        //         try
        //         {
        //             socket.output.write(output);
        //         }
        //         // catch(err:Dynamic)
        //         // {
        //         //     trace("err2 " + err);
        //         // }
        //         catch(ex:haxe.io.Error)
        //         {
        //             trace("IO ERROR 2");
        //             disconnect(conn, socket);
        //         }

        //         output.clear();
        //         output.writeShort(0);
        //     }
        // }
        // trace("woot " + this._enh.manager);
        this._enh.manager.pumpSyncedEntities();
    }
}