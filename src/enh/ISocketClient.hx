package enh;

interface ISocketClient
{
    public var conn:Connection;
    public var connected:Bool;

    public function connect(ip:String, port:Int):Void;
    public function pumpIn():Void;
    public function pumpOut():Void;
}
