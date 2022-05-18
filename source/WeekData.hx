package;

import haxe.Json;
import haxe.io.Path;
#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#else
import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;
#end

using StringTools;

typedef WeekFile =
{
	// JSON variables
	var songs:Array<Array<Dynamic>>;
	var weekCharacters:Array<String>;
	var weekBackground:String;
	var weekBefore:String;
	var storyName:String;
	var weekName:String;
	var startUnlocked:Bool;
	var ?hiddenUntilUnlocked:Bool;
	var hideStoryMode:Bool;
	var hideFreeplay:Bool;
	var ?difficulties:String;
}

class WeekData {
	public static var weeksLoaded:Map<String, WeekData> = new Map();
	public static var weeksList:Array<String> = [];
	public var folder:String = '';
	
	// JSON variables
	public var songs:Array<Array<Dynamic>>;
	public var weekCharacters:Array<String>;
	public var weekBackground:String;
	public var weekBefore:String;
	public var storyName:String;
	public var weekName:String;
	public var startUnlocked:Bool;
	public var hiddenUntilUnlocked:Null<Bool>;
	public var hideStoryMode:Bool;
	public var hideFreeplay:Bool;
	public var difficulties:String;

	public var fileName:String;

	public static function createWeekFile():WeekFile {
		var weekFile:WeekFile = {
			songs: [["Bopeebo", "dad", [146, 113, 253]], ["Fresh", "dad", [146, 113, 253]], ["Dad Battle", "dad", [146, 113, 253]]],
			weekCharacters: ['dad', 'bf', 'gf'],
			weekBackground: 'stage',
			weekBefore: 'tutorial',
			storyName: 'Your New Week',
			weekName: 'Custom Week',
			startUnlocked: true,
			hiddenUntilUnlocked: false,
			hideStoryMode: false,
			hideFreeplay: false,
			difficulties: ''
		};
		return weekFile;
	}

	public function new(weekFile:WeekFile, fileName:String) {
		var template = createWeekFile();
		for (i in Reflect.fields(weekFile)) {
			if (Reflect.hasField(template, i)) { //just doing Reflect.hasField on itself doesnt work for some reason so we are doing it on a template
				Reflect.setProperty(this, i, Reflect.field(weekFile, i));
			}
		}

		if (hiddenUntilUnlocked == null) {
			hiddenUntilUnlocked = false;
		}

		this.fileName = fileName;
	}

	public static function reloadWeekFiles(?isStoryMode:Bool = false)
	{
		weeksList = [];
		weeksLoaded.clear();
		#if MODS_ALLOWED
		var disabledMods:Array<String> = [];
		var modsListPath:String = 'modsList.txt';
		var directories:Array<String> = [Paths.mods(), Paths.getPreloadPath()];
		var modNames:Array<String> = ['', ''];
		var originalLength:Int = directories.length;
		if (FileSystem.exists(modsListPath))
		{
			var stuff:Array<String> = CoolUtil.coolTextFile(modsListPath);
			for (i in 0...stuff.length)
			{
				var splitName:Array<String> = stuff[i].trim().split('|');
				if (splitName[1] == '0') // Disable mod
				{
					disabledMods.push(splitName[0]);
				}
				else // Sort mod loading order based on modsList.txt file
				{
					var path = Path.join([Paths.mods(), splitName[0]]);
					if (FileSystem.isDirectory(path) && !Paths.ignoreModFolders.contains(splitName[0]) && !disabledMods.contains(splitName[0]) && !directories.contains('$path/'))
					{
						directories.push('$path/');
						modNames.push(splitName[0]);
					}
				}
			}
		}

		var modsDirectories:Array<String> = Paths.getModDirectories();
		for (folder in modsDirectories)
		{
			var pathThing:String = '${Path.join([Paths.mods(), folder])}/';
			if (!disabledMods.contains(folder) && !directories.contains(pathThing))
			{
				directories.push(pathThing);
				modNames.push(folder);
			}
		}
		#else
		var directories:Array<String> = [Paths.getPreloadPath()];
		var modNames:Array<String> = [''];
		var originalLength:Int = directories.length;
		#end

		var sexList:Array<String> = CoolUtil.coolTextFile(Paths.getPreloadPath('weeks/weekList.txt'));
		for (i in 0...sexList.length) {
			for (j in 0...directories.length) {
				var fileToCheck:String = '${directories[j]}weeks/${sexList[i]}.json';
				var weekName = WeekData.formatWeek(sexList[i], modNames[j]);
				if (!weeksLoaded.exists(weekName)) {
					var week:WeekFile = getWeekFile(fileToCheck);
					if (week != null) {
						var weekFile:WeekData = new WeekData(week, sexList[i]);

						#if MODS_ALLOWED
						if (j >= originalLength) {
							weekFile.folder = directories[j].substring(Paths.mods().length, directories[j].length - 1);
						}
						#end

						if (weekFile != null && (isStoryMode == null || (isStoryMode && !weekFile.hideStoryMode) || (!isStoryMode && !weekFile.hideFreeplay))) {
							weeksLoaded.set(weekName, weekFile);
							weeksList.push(weekName);
						}
					}
				}
			}
		}

		#if MODS_ALLOWED
		for (i in 0...directories.length) {
			var directory:String = '${directories[i]}weeks/';
			if (FileSystem.exists(directory)) {
				var listOfWeeks:Array<String> = CoolUtil.coolTextFile('${directory}weekList.txt');
				for (daWeek in listOfWeeks)
				{
					var path:String = '${directory}${daWeek}.json';
					if (FileSystem.exists(path))
					{
						addWeek(daWeek, path, directories[i], i, originalLength, modNames[i]);
					}
				}

				for (file in FileSystem.readDirectory(directory))
				{
					var path = Path.join([directory, file]);
					if (!FileSystem.isDirectory(path) && file.endsWith('.json'))
					{
						addWeek(file.substr(0, file.length - 5), path, directories[i], i, originalLength, modNames[i]);
					}
				}
			}
		}
		#end
	}

	private static function addWeek(weekToCheck:String, path:String, directory:String, i:Int, originalLength:Int, modName:String = '')
	{
		var modAndWeek = WeekData.formatWeek(weekToCheck, modName);
		if (!weeksLoaded.exists(modAndWeek))
		{
			var week:WeekFile = getWeekFile(path);
			if (week != null)
			{
				var weekFile:WeekData = new WeekData(week, weekToCheck);
				if (i >= originalLength)
				{
					#if MODS_ALLOWED
					weekFile.folder = directory.substring(Paths.mods().length, directory.length - 1);
					#end
				}
				if ((PlayState.isStoryMode && !weekFile.hideStoryMode) || (!PlayState.isStoryMode && !weekFile.hideFreeplay))
				{
					weeksLoaded.set(modAndWeek, weekFile);
					weeksList.push(modAndWeek);
				}
			}
		}
	}

	private static function getWeekFile(path:String):WeekFile {
		var rawJson:String = null;
		#if MODS_ALLOWED
		if (FileSystem.exists(path)) {
			rawJson = File.getContent(path);
		}
		#else
		if (OpenFlAssets.exists(path)) {
			rawJson = Assets.getText(path);
		}
		#end

		if (rawJson != null && rawJson.length > 0) {
			return cast Json.parse(rawJson);
		}
		return null;
	}

	//   FUNCTIONS YOU WILL PROBABLY NEVER NEED TO USE

	//returns raw week file name, no mod directory included
	public static function getWeekFileName():String {
		return weeksLoaded.get(weeksList[PlayState.storyWeek]).fileName;
	}

	//returns week file name with mod directory included
	public static function getWeekName():String {
		return weeksList[PlayState.storyWeek];
	}

	public static function getCurrentWeek():WeekData {
		return weeksLoaded.get(weeksList[PlayState.storyWeek]);
	}

	public static function setDirectoryFromWeek(?data:WeekData = null) {
		Paths.currentModDirectory = '';
		if (data != null && data.folder != null && data.folder.length > 0) {
			Paths.currentModDirectory = data.folder;
		}
	}

	public static function formatWeek(week:String, ?directory:String):String {
		if (directory == null) directory = Paths.currentModDirectory;
		return ((directory.length > 0) ? '${directory}:' : '') + week;
	}

	public static function loadTheFirstEnabledMod()
	{
		Paths.currentModDirectory = '';

		#if MODS_ALLOWED
		if (FileSystem.exists("modsList.txt"))
		{
			var list:Array<String> = CoolUtil.coolTextFile("modsList.txt");
			for (i in list)
			{
				var dat = i.split("|");
				if (dat[1] == "1")
				{
					Paths.currentModDirectory = dat[0];
					break;
				}
			}
		}
		#end
	}
}