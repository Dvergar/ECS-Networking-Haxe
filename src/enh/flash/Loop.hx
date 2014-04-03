package enh.flash;

import flash.events.Event;

class Loop
{
	public static function startLoop(step:Dynamic->Void)
	{
		flash.Lib.current.stage.addEventListener(Event.ENTER_FRAME, step);
	}
}