package enh;

import enh.Builders;
import enh.Tools;
import enh.Constants;


class ServerSocket extends SocketHelper
{
    public var connected:Bool;
    private var em:EntityManager;
    private var serverSocket:sys.net.Socket;
    private var sockets:Array<sys.net.Socket>;
    public var connections:Map<sys.net.Socket, Connection>;
    public var gameConnections:Map<sys.net.Socket, Connection>;
    public var waitingSockets:Map<Connection, sys.net.Socket>;
    private var connectionIds:IdManager;

    public function new(address:String, port:Int, enh:Enh)
    {
        super(enh);
        this.em = enh.em;
        this.connected = true;

        connectionIds = new IdManager(32);
        connections = new Map();
        gameConnections = new Map();
        waitingSockets = new Map();
        sockets = new Array();

        serverSocket = new sys.net.Socket();
        serverSocket.output.bigEndian = true;
        serverSocket.input.bigEndian = true;
        serverSocket.bind(new sys.net.Host(address), port);
        serverSocket.listen(1);
        serverSocket.setBlocking(false);
        sockets.push(serverSocket);
        trace("plouf");
    }

    public function pumpIn():Void
    {
        // trace("1");
        for(socket in connections.keys())
        {
            var conn = connections.get(socket);
            // trace("time " + (Timer.getTime() - conn.activityTime));
            if(Timer.getTime() - conn.activityTime > 3)
            {
                trace("TIMED OUT");
                disconnect(conn, socket);
            }
        }

        var inputSockets = sys.net.Socket.select(sockets, null, null, 0);

        for(socket in inputSockets.read)
        {
            if(socket == serverSocket)
            {
                var newSocket = socket.accept();
                newSocket.output.bigEndian = true;
                newSocket.input.bigEndian = true;
                newSocket.setBlocking(false);
                sockets.push(newSocket);

                var connection = new Connection(connectionIds.get());
                connection.output.writeShort(0);
                connections.set(newSocket, connection);
                waitingSockets.set(connection, newSocket);

                notifyConnection(newSocket, connection);
            }
            else
            {
                // trace("SOMETHING HAPPENED");
                var conn = connections[socket];
                conn.activityTime = Timer.getTime();
                var input = conn.input;
                // var pos = input.position;

                try
                {
                    // trace("0");
                    // var bytes = input.getBytes();
                    while(true)
                    {
                        var bytes = haxe.io.Bytes.alloc(1);
                        var newBytes = socket.input.readBytes(bytes, 0, 1);
                        // trace("readbytes " + newBytes);
                        // trace("bytes " + bytes);

                        // var byte = socket.input.readByte();
                        // trace("byte " + byte);
                        // input.writeByte(byte);
                        input.writeBytes(bytes, 0, 1);
                    }
                }
                catch(ex:haxe.io.Eof)
                {
                    trace("SOCKET EOF");
                    disconnect(conn, socket);
                }
                // catch(err:Dynamic)
                // {
                //     trace("err " + err);
                // }
                catch(ex:haxe.io.Error)
                {
                    // trace("io error");
                    if(ex == haxe.io.Error.Blocked)
                    {
                        // trace("BLOCKED");
                    }
                    if(ex == haxe.io.Error.Overflow)
                    {
                        trace("OVERFLOW");
                        trace("input length " + input.length);
                    }
                    if(ex == haxe.io.Error.OutsideBounds)
                    {
                        trace("OUTSIDE BOUNDS");
                        trace("input length " + input.length + " / " + input);
                    }
                }

                // input.position = pos;

                this.readSocket(conn);

                // while(input.bytesAvailable > 2)
                // {
                //     var msgLength = input.readShort();
                //     if(input.bytesAvailable < msgLength) break;

                //     var msgPos = input.position;
                //     while(input.position - msgPos < msgLength)
                //     {
                //         enh.serverManager.processDatas(conn);
                //     }
                // }

                // if(input.bytesAvailable == 0) input.clear();  // May be risky
            }
        }
    }

    // Ugly but don't really care (only for disconnection)
    public function getSocketFromConnection(conn:Connection):sys.net.Socket
    {
        var s:sys.net.Socket = sockets[0]; // I KNOW !!!
        
        for(socket in connections.keys())
        {
            var connection = connections[socket];
            if(conn == connection)
            {
                s = socket;
                break;
            }
        }

        return s;
    }

    // A bit too much :3
    public function disconnect(conn:Connection, socket:sys.net.Socket)
    {
        trace("disconnect " + conn.entity);
        enh.manager._disconnect(conn);
        socket.shutdown(true, true);
        socket.close();
        sockets.remove(socket);
        connections.remove(socket);
        gameConnections.remove(socket);
        waitingSockets.remove(conn);
    }

    public function connect(conn:Connection)
    {
        enh.manager.connect(conn);
        var socket = waitingSockets.get(conn);
        waitingSockets.remove(conn);
        gameConnections.set(socket, conn);

        trace("connected");
    }

    function notifyConnection(socket:sys.net.Socket, conn:Connection)
    {
        var output = conn.output;

        output.writeByte(CONST.CONNECTION);
        output.writeShort(conn.id);

        output.position = 0;
        output.writeShort(output.length - 2);
        socket.output.write(output);

        output.clear();
        output.writeShort(0);

        trace("SOCKET : onConnect " + conn.entity);
    }

    public function pumpOut():Void
    {
        for(socket in connections.keys())
        {
            var conn = connections[socket];
            var output = conn.output;

            if(output.length > 2)
            {
                // trace("out " + ba.length);

                output.position = 0;
                output.writeShort(output.length - 2);

                try
                {
                    socket.output.write(output);
                }
                catch(ex:haxe.io.Error)
                {
                    trace("IO ERROR 2");
                    disconnect(conn, socket);
                }

                output.clear();
                output.writeShort(0);
            }
        }

        enh.manager.pumpSyncedEntities();
    }
}