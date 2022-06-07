package;

import Song.SwagSong;
import flixel.math.FlxMath;

/**
 * ...
 * @author
 */

typedef BPMChangeEvent =
{
	var stepTime:Int;
	var songTime:Float;
	var bpm:Float;
}

typedef SignatureChangeEvent =
{
	var stepTime:Int;
	var songTime:Float;
	var timeSignature:Array<Int>;
}

class Conductor
{
	public static var bpm:Float = 100;
	public static var timeSignature:Array<Int> = [4, 4];
	public static var crochet:Float = ((60 / bpm) * 4000) / timeSignature[1]; // beats in milliseconds
	public static var stepCrochet:Float = crochet / 4; // steps in milliseconds
	public static var songPosition:Float = 0;

	public static var safeZoneOffset:Float = (ClientPrefs.safeFrames / 60) * 1000; // is calculated in create(), is safeFrames in milliseconds

	public static var bpmChangeMap:Array<BPMChangeEvent> = [];
	public static var signatureChangeMap:Array<SignatureChangeEvent> = [];

	/**
	 * Gives a rating based on how close you were to hitting a note in milliseconds.
	 *
	 * @param	diff	Difference from the note's strum time to when you actually hit it.
	 * @return	Rating of the note ('Sick', 'Good', 'Bad', or 'Shit')
	 */
	public static function judgeNote(diff:Float = 0) //STOLEN FROM KADE ENGINE (bbpanzu) - I had to rewrite it later anyway after i added the custom hit windows lmao (Shadow Mario)
	{
		//tryna do MS based judgment due to popular demand
		var timingWindows:Array<Int> = [ClientPrefs.sickWindow, ClientPrefs.goodWindow, ClientPrefs.badWindow];
		var windowNames:Array<String> = ['sick', 'good', 'bad'];

		for(i in 0...timingWindows.length) // based on 4 timing windows, will break with anything else
		{
			if (diff <= timingWindows[FlxMath.minInt(i, timingWindows.length - 1)])
			{
				return windowNames[i];
			}
		}
		return 'shit';
	}

	/**
	 * Creates a new `bpmChangeMap` and `signatureChangeMap` from the inputted song.
	 *
	 * @param	song	Song to take the BPM and time signature changes from.
	 * @param	mult	Optional multiplier for the BPMs, used for playback rates.
	 */
	public static function mapBPMChanges(song:SwagSong, mult:Float = 1)
	{
		bpmChangeMap = [];
		signatureChangeMap = [];

		var curBPM:Float = song.bpm * mult;
		var curSignature:Array<Int> = song.timeSignature;
		var totalSteps:Int = 0;
		var totalPos:Float = 0;
		for (i in 0...song.notes.length)
		{
			var sec = song.notes[i];
			if (sec.changeBPM && sec.bpm * mult != curBPM && sec.bpm > 0)
			{
				curBPM = sec.bpm * mult;
				var event:BPMChangeEvent = {
					stepTime: totalSteps,
					songTime: totalPos,
					bpm: curBPM
				};
				bpmChangeMap.push(event);
			}
			if (sec.changeSignature && (sec.timeSignature[0] != curSignature[0] || sec.timeSignature[1] != curSignature[1]))
			{
				curSignature = sec.timeSignature;
				var event:SignatureChangeEvent = {
					stepTime: totalSteps,
					songTime: totalPos,
					timeSignature: curSignature
				};
				signatureChangeMap.push(event);
			}

			var deltaSteps:Int = sec.lengthInSteps;
			totalSteps += deltaSteps;
			totalPos += ((((60 / curBPM) * 4000) / timeSignature[1]) / 4) * deltaSteps;
		}
	}

	/**
	 * Changes the Conductor's BPM.
	 *
	 * @param	newBpm	The BPM to change to.
	 * @param   mult    Optional multiplier for the BPM, used for playback rates.
	 */
	public static function changeBPM(newBpm:Float, mult:Float = 1)
	{
		if (newBpm > 0) {
			bpm = newBpm * mult;
			updateCrochet();
		}
	}

	/**
	 * Changes the Conductor's time signature.
	 *
	 * @param	newNumerator	The numerator (beats per section) to change to.
	 * @param   newDenominator	The denominator (step length, 4 means 1/4 of a whole note) to change to.
	 */
	public static function changeSignature(newSignature:Array<Int>)
	{
		if (newSignature[0] > 0 && newSignature[1] > 0) {
			timeSignature = newSignature.copy();
			updateCrochet();
		}
	}

	static function updateCrochet() {
		crochet = ((60 / bpm) * 4000) / timeSignature[1];
		stepCrochet = crochet / 4;
	}

	/**
	 * Gets the latest BPM and time signature based on the current step and changes the Conductor values if necessary.
	 *
	 * @param	song	Song to take the BPM and time signature changes from.
	 * @param   step	The current step of the song.
	 * @param	mult	Optional multiplier for the BPMs, used for playback rates.
	 */
	public static function getLastBPM(song:SwagSong, step:Int, mult:Float = 1) {
		var daBPM:Float = song.bpm * mult;
		var daSignature:Array<Int> = song.timeSignature;
		for (i in 0...bpmChangeMap.length) {
			if (step >= bpmChangeMap[i].stepTime) {
				daBPM = bpmChangeMap[i].bpm;
			}
		}
		for (i in 0...signatureChangeMap.length) {
			if (step >= signatureChangeMap[i].stepTime) {
				daSignature = signatureChangeMap[i].timeSignature;
			}
		}
		if (bpm != daBPM)
			changeBPM(daBPM);
		if (timeSignature[0] != daSignature[0] || timeSignature[1] != daSignature[1])
			changeSignature(daSignature);
	}

	/**
	 * Gets the current section of a song based on the current step.
	 *
	 * @param	song	Song to take the BPM and time signature changes from.
	 * @param   step	The current step of the song.
	 * @return	The current section of the song.
	 */
	public static function getCurSection(song:SwagSong, step:Int):Int {
		//every time i try to optimize this it just fucking stops working
		if (step <= 0) {
			return 0;
		}
		var daNumerator:Int = song.timeSignature[0];
		var daPos:Int = 0;
		var lastStep:Int = 0;
		for (i in 0...song.notes.length) {
			if (song.notes[i] != null) {
				if (song.notes[i].changeSignature) {
					daNumerator = song.notes[i].timeSignature[0];
				}
			}
			if (lastStep + (daNumerator * 4) >= step) {
				return FlxMath.maxInt(daPos + Math.floor((step - lastStep) / (daNumerator * 4)), 0);
			}
			lastStep += daNumerator * 4;
			daPos++;
		}
		return FlxMath.maxInt(daPos, 0);
	}

	/**
	 * Gets the current beat of a song, starting from the last numerator change. Used for camera bopping
	 *
	 * @param	song	Song to take the BPM and time signature changes from.
	 * @param   beat	The current beat of the song.
	 * @return	The current beat of the song, starting from the last numerator change.
	 */
	public static function getCurNumeratorBeat(song:SwagSong, beat:Int):Int {
		var lastBeat = 0;
		var daBeat = 0;
		var daNumerator = song.timeSignature[0];
		for (i in 0...song.notes.length) {
			if (song.notes[i] != null && beat >= daBeat) {
				if (song.notes[i].changeSignature) {
					daNumerator = song.notes[i].timeSignature[0];
					lastBeat = daBeat;
				}
				daBeat += daNumerator;
			}
		}
		return beat - lastBeat;
	}
}
