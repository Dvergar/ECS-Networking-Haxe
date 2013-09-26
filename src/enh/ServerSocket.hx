package enh;

import enh.ByteArray;
import enh.Builders;
import enh.Tools;


class Connection
{
	public var input:ByteArray;
	public var output:ByteArray;
	public var id:Int;
	public var entity:String;

	public function new(id:Int)
	{
		this.id = id;
		this.input = new ByteArray();
		this.output = new ByteArray();
	}
}


class ServerSocket
{
	private var enh:Enh;
	private var em:EntityManager;
	private var serverSocket:sys.net.Socket;
    private var sockets:Array<sys.net.Socket>;
    public var connections:Map<sys.net.Socket, Connection>;
	private var connectionIds:IdManager;

	public function new(address:String, port:Int, enh:Enh)
	{
		this.enh = enh;
		this.em = enh.em;

		connectionIds = new IdManager(32);
		connections = new Map();
		sockets = new Array();

        serverSocket = new sys.net.Socket();
        serverSocket.output.bigEndian = true;
        serverSocket.input.bigEndian = true;
        serverSocket.bind(new sys.net.Host(address), port);
        serverSocket.listen(1);
        serverSocket.setBlocking(false);
        sockets.push(serverSocket);
	}

	public function pumpIn():Void
	{
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

                connections[newSocket] = connection;
				enh.serverManager.onConnect(connection);
            }
	        else
	        {
	        	// trace("SOMETHING HAPPENED");
	        	var conn = connections[socket];
	        	var input = conn.input;
	        	var pos = input.position;

	            try
	            {
		        	while(true)
		        	{
		        		var byte = socket.input.readByte();
		        		input.writeByte(byte);
		        	}
		        }
	            catch(ex:haxe.io.Eof)
	            {
	                trace("SOCKET EOF");
	            }
	            catch(ex:haxe.io.Error)
                {
                	// trace("io error");
                    if(ex == haxe.io.Error.Blocked)
                    {
                		// trace("BLOCKED");
                    }
                }

                input.position = pos;

				while(input.bytesAvailable > 2)
				{
					var msgLength = input.readShort();
					if(input.bytesAvailable < msgLength) break;

					var msgPos = input.position;
					while(input.position - msgPos < msgLength)
					{
	            		enh.serverManager.processDatas(conn);
					}
				}

	            if(input.bytesAvailable == 0) input.clear();  // May be risky
	        }
        }
    }

	public function pumpOut():Void
	{
		for(socket in connections.keys())
		{
			var conn = connections[socket];
			// trace("output socket " + conn.output.length);
			var output = conn.output;

			if(output.length > 2)
			{
				// trace("BABA " + ba.length);
				// trace("out " + ba.length);

				output.position = 0;
				output.writeShort(output.length - 2);
				socket.output.write(output);

				output.clear();
				output.writeShort(0);
			}
		}

		enh.serverManager.pumpSyncedEntities();
	}
}