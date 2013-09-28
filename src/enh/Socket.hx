package enh;

#if(flash || openfl)
typedef Socket = enh.flash.Socket;
#else

class Socket
{
	public function new()
	{
		throw("Sorry, no client socket was found for your platform");
	}
}

#end