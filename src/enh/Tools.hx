package enh;


class IdManager
{
	private var ids:Array<Int>;

	public function new(nbItems:Int)
	{
		ids = new Array();
		for(i in 0...nbItems) ids.push(i);
	}

	public function get():Int
	{
		return ids.pop();
	}

	public function release(id:Int)
	{
		ids.push(id);
	}
}