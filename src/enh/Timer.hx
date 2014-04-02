package enh;

#if (flash || openfl)
typedef Timer = enh.flash.Timer;
#elseif (cpp || neko)
class Timer
{
	public static function getTime():Float
	{
		return Sys.time();
	}
}
#elseif js
class Timer
{
	public static function getTime():Float
	{
		return Date.now().getTime() / 1000;
	}
}
#end