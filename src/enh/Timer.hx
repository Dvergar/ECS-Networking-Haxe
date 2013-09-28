package enh;

#if(flash || openfl)
typedef Timer = enh.flash.Timer;
#else

class Timer
{
	public static function getTime():Float
	{
		return Sys.time();
	}
}
#end