package enh.flash;

class Timer
{
	public static function getTime():Float
	{
		return flash.Lib.getTimer() / 1000;
	}
}