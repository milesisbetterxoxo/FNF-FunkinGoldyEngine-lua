package;

import haxe.Json;
import Section;
#if MODS_ALLOWED
import sys.io.File;
import sys.FileSystem;
#else
import lime.utils.Assets;
#end

using StringTools;

typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var events:Array<Array<Dynamic>>;
	var bpm:Float;
	var timeSignature:Array<Int>;
	var needsVoices:Bool;
	var speed:Float;
	var ?playerKeyAmount:Int;
	var ?opponentKeyAmount:Int;

	var player1:String;
	var player2:String;
	var gfVersion:String;
	var stage:String;

	var arrowSkin:String;
	var splashSkin:String;
	var uiSkin:String;
	var uiSkinOpponent:String;

	var validScore:Bool;
}

class Song
{
	private static function onLoadJson(songJson:SwagSong) // Convert old charts to newest format
	{
		if (songJson.events == null)
		{
			songJson.events = [];
			for (secNum in 0...songJson.notes.length)
			{
				var sec:SwagSection = songJson.notes[secNum];

				var i:Int = 0;
				var notes = sec.sectionNotes;
				var len:Int = notes.length;
				while(i < len)
				{
					var note = notes[i];
					if (note[1] < 0)
					{
						songJson.events.push([note[0], [[note[2], note[3], note[4]]]]);
						notes.remove(note);
						len = notes.length;
					}
					else i++;
				}
			}
		}

		if (songJson.playerKeyAmount == null)
		{
			songJson.playerKeyAmount = 4;
			songJson.opponentKeyAmount = 4;
		}
		if (songJson.timeSignature == null)
		{
			songJson.timeSignature = [4, 4];
		}
		if (songJson.uiSkin == null)
		{
			songJson.uiSkin = '';
		}
		if (songJson.uiSkinOpponent == null)
		{
			songJson.uiSkinOpponent = songJson.uiSkin;
		}
		
		for (secNum in 0...songJson.notes.length) {
			var sec:SwagSection = songJson.notes[secNum];
			if (sec.gfSection == null) sec.gfSection = false;
			if (sec.bpm == null) sec.bpm = songJson.bpm;
			if (sec.changeBPM == null) sec.changeBPM = false;
			if (sec.timeSignature == null) sec.timeSignature = songJson.timeSignature;
			if (sec.changeSignature == null) sec.changeSignature = false;
			if (sec.altAnim == null) sec.altAnim = false;
			if (sec.changeKeys == null) sec.changeKeys = false;
			if (sec.playerKeys == null) sec.playerKeys = songJson.playerKeyAmount;
			if (sec.opponentKeys == null) sec.opponentKeys = songJson.opponentKeyAmount;
			var i:Int = 0;
			var notes = sec.sectionNotes;
			var len:Int = notes.length;
			while(i < len)
			{
				//i dont even know if this does anything
				var note = notes[i];
				while (note.length < 4) {
					note.push(null);
				}
				if (note[3] != null && Std.isOfType(note[3], Int)) note[3] = editors.ChartingState.noteTypeList[note[3]];
				if (note[3] == null) note[3] = '';
				if (note[4] == null || note[4].length < 1) note[4] = [0];
				notes[i] = [note[0], note[1], note[2], note[3], note[4]];
				i++;
			}
			songJson.notes[secNum] = sec;
		}
	}

	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		var rawJson = null;
		
		var formattedFolder:String = Paths.formatToSongPath(folder);
		var formattedSong:String = Paths.formatToSongPath(jsonInput);
		#if MODS_ALLOWED
		var moddyFile:String = Paths.modsData('$formattedFolder/$formattedSong');
		if (FileSystem.exists(moddyFile)) {
			rawJson = File.getContent(moddyFile).trim();
		}
		#end

		if (rawJson == null) {
			#if MODS_ALLOWED
			rawJson = File.getContent(Paths.json('$formattedFolder/$formattedSong')).trim();
			#else
			rawJson = Assets.getText(Paths.json('$formattedFolder/$formattedSong')).trim();
			#end
		}

		while (!rawJson.endsWith("}"))
		{
			rawJson = rawJson.substr(0, rawJson.length - 1);
			// LOL GOING THROUGH THE BULLSHIT TO CLEAN IDK WHATS STRANGE
		}

		var songJson:SwagSong = parseJSONshit(rawJson);
		if (formattedSong != 'events') StageData.loadDirectory(songJson);
		onLoadJson(songJson);
		return songJson;
	}

	public static function parseJSONshit(rawJson:String):SwagSong
	{
		var swagShit:SwagSong = cast Json.parse(rawJson).song; //actual song
		var tempSong:Dynamic = cast Json.parse(rawJson).song; //copy to check for other variables

		if (swagShit.gfVersion == null) {
			if (tempSong.player3 != null) {
				swagShit.gfVersion = tempSong.player3;
			}
			if (tempSong.gf != null) {
				swagShit.gfVersion = tempSong.gf;
			}
		}
		if (swagShit.uiSkin == null) {
			if (tempSong.ui_Skin != null) {
				swagShit.uiSkin = tempSong.ui_Skin;
				swagShit.uiSkinOpponent = tempSong.ui_Skin;
			}
		}
		if (swagShit.playerKeyAmount == null) {
			if (tempSong.mania != null) {
				switch (tempSong.mania) {
					case 1:
						swagShit.playerKeyAmount = 6;
					case 2:
						swagShit.playerKeyAmount = 7;
					case 3:
						swagShit.playerKeyAmount = 9;
					default:
						swagShit.playerKeyAmount = 4;
				}
				swagShit.opponentKeyAmount = swagShit.playerKeyAmount;
			}
			if (tempSong.keyCount != null) {
				swagShit.playerKeyAmount = tempSong.keyCount;
				swagShit.opponentKeyAmount = tempSong.keyCount;
			}
			if (tempSong.playerKeyCount != null) {
				swagShit.playerKeyAmount = tempSong.playerKeyCount;
			}
		}
		if (swagShit.timeSignature == null) {
			if (tempSong.numerator != null && tempSong.denominator != null) {
				swagShit.timeSignature = [tempSong.numerator, tempSong.denominator];
			}
			if (tempSong.timescale != null && tempSong.timescale.length == 2) {
				swagShit.timeSignature = tempSong.timescale;
			}
		}

		for (i in 0...tempSong.notes.length) {
			var sec = tempSong.notes[i];
			var numerator:Null<Int> = sec.numerator;
			var denominator:Null<Int> = sec.denominator;
			if (numerator != null && denominator != null) {
				swagShit.notes[i].timeSignature = [numerator, denominator];
			}
		}

		swagShit.validScore = true;
		return swagShit;
	}
}
