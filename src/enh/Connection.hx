package enh;


class Connection
{
    public var input:ByteArray;
    public var output:ByteArray;
    public var id:Int;
    public var entity:String;
    public var activityTime:Float;

    public function new(?id:Int=0)
    {
        this.id = id;
        this.input = new ByteArray();
        this.output = new ByteArray();
        this.activityTime = enh.Timer.getTime();
    }
}