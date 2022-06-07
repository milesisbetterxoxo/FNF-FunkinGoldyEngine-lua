package;

import flixel.FlxG;
import flixel.FlxSubState;
import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;

class MusicBeatSubState extends FlxSubState
{
	public var resetCameraOnClose:Bool = false;
	var lastScroll:FlxPoint = FlxPoint.get();
	public function new()
	{
		lastScroll.copyFrom(FlxG.camera.scroll);
		super();
		closeCallback = onClose;
	}

	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;
	private var controls(get, never):Controls;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	override function update(elapsed:Float)
	{
		var oldStep:Int = curStep;

		updateCurStep();
		curBeat = Math.floor(curStep / 4);

		if (oldStep != curStep && curStep >= 0)
			stepHit();

		super.update(elapsed);
	}

	private function updateCurStep():Void
	{
		var lastChange:Dynamic = {
			stepTime: 0,
			songTime: 0.0
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (Conductor.songPosition >= Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}
		for (i in 0...Conductor.signatureChangeMap.length)
		{
			if (Conductor.songPosition >= Conductor.signatureChangeMap[i].songTime && Conductor.signatureChangeMap[i].songTime > lastChange.songTime)
				lastChange = Conductor.signatureChangeMap[i];
		}

		curStep = lastChange.stepTime + Math.floor(((Conductor.songPosition - ClientPrefs.noteOffset) - lastChange.songTime) / Conductor.stepCrochet);
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		//do literally nothing dumbass
	}

	function onClose() {
		if (resetCameraOnClose) {
			FlxG.camera.follow(null);
			FlxG.camera.scroll.set();
		}

		lastScroll = FlxDestroyUtil.put(lastScroll);
	}
}
