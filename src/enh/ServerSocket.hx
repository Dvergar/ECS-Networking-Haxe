package enh;

import enh.ByteArray;
import enh.Builders;


class ServerSocket
{
	private var enh:Enh;
	private var em:EntityManager;
	private var serverSocket:sys.net.Socket;
    private var sockets:Array<sys.net.Socket>;
    public var connectionsIn:Map<sys.net.Socket, ByteArray>;
    public var connectionsOut:Map<sys.net.Socket, ByteArray>;

	public function new(address:String, port:Int, enh:Enh)
	{
		this.enh = enh;
		this.em = enh.em;

		connectionsIn = new Map();
		connectionsOut = new Map();
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

                // newSocket.output.writeByte(5);

                connectionsIn[newSocket] = new ByteArray();
                connectionsOut[newSocket] = new ByteArray();
                connectionsOut[newSocket].writeShort(0);

                trace("connected : " + socket);
				em.pushEvent("ON_CONNECTION", "dummy", {});
            }
	        else
	        {
	        	trace("SOMETHING HAPPENED");
	        	var ba = connectionsIn[socket];
	        	var pos = ba.position;
	            try
	            {
		        	while(true)
		        	{
		        		var byte = socket.input.readByte();
		        		ba.writeByte(byte);
		        	}
		        }
	            catch(ex:haxe.io.Eof)
	            {
	                trace("SOCKET EOF");
	            }
	            catch(ex:haxe.io.Error)
                {
                	trace("io error");
                    if(ex == haxe.io.Error.Blocked)
                    {
                		trace("BLOCKED");
                    }
                }
                trace("input bytesAvailable " + ba.bytesAvailable);
                ba.position = pos;
	            while(ba.bytesAvailable > 2)
	            {
	            	var msgLength = ba.readShort();
	            	if(ba.bytesAvailable >= msgLength)
	            	{
	            		enh.serverManager.processDatas(ba);
	            	}
	            	else
	            	{
	            		ba.position -= 2;
	            	}
	            }

	            if(ba.bytesAvailable == 0) ba.clear();  // May be risky

	            em.pushEvent("ON_DATA", "dummy", {ba:ba});
	        }
        }
    }

	public function pumpOut():Void
	{
		for(socket in connectionsOut.keys())
		{
			var ba = connectionsOut[socket];
			if(ba.length > 2)
			{
				trace("BABA " + ba.length);
				trace("out " + ba.length);

				ba.position = 0;
				ba.writeShort(ba.length - 2);
				socket.output.write(ba);

				ba.clear();
				ba.writeShort(0);
			}
		}
	}
}