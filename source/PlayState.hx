package;

import flixel.FlxBasic;
#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end
import editors.ChartingState;
import editors.CharacterEditorState;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.effects.FlxTrail;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxShader;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.util.FlxSave;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import openfl.display.Shader;
import openfl.filters.ShaderFilter;
import flixel.addons.transition.FlxTransitionableState;
#if HSCRIPT_ALLOWED
import hscript.ParserEx;
#end
import lime.app.Application;
import lime.graphics.Image;
import openfl.events.KeyboardEvent;
import flixel.input.gamepad.FlxGamepad;
import openfl.utils.Assets as OpenFlAssets;
import openfl.filters.BitmapFilter;
import ModchartFunctions;
import Achievements;
import Character;
import DialogueBoxPsych;
import FunkinLua;
import Note.EventNote;
import Section.SwagSection;
import Song.SwagSong;
import StageData;
import UIData;
import Shaders;
import haxe.Json;
#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end
#if cpp
import lime.media.openal.AL;
#end
import haxe.Timer;

using StringTools;


class PlayState extends MusicBeatState
{
	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;

	public var introSuffix:String = '';

	var woah:FlxText;


	var gottaHitNote:Bool;

	public static var ratingStuff:Array<Array<Dynamic>> = [
		['You Suck!', 0.2], //From 0% to 19%
		['Shit', 0.4], //From 20% to 39%
		['Bad', 0.5], //From 40% to 49%
		['Bruh', 0.6], //From 50% to 59%
		['Meh', 0.69], //From 60% to 68%
		['Nice', 0.7], //69%
		['Good', 0.8], //From 70% to 79%
		['Great', 0.9], //From 80% to 89%
		['Sick!', 1], //From 90% to 99%
		['Perfect!!', 1] //The value on this one isn't used actually, since Perfect is always "1"
	];

	public var stageSprites:FlxTypedGroup<FlxSprite>;

	public var modchartTweens:Map<String, FlxTween> = new Map();
	public var modchartSprites:Map<String, ModchartSprite> = new Map();
	public var modchartTimers:Map<String, FlxTimer> = new Map();
	public var modchartSounds:Map<String, FlxSound> = new Map();
	public var modchartTexts:Map<String, ModchartText> = new Map();
	public var modchartSaves:Map<String, FlxSave> = new Map();
	
	var modifiedCrochet:Float; //slows or speeds up to mimic normal quarter notes

	//shader shit
	public var shader_chromatic_abberation:ChromaticAberrationEffect;
	public var camGameShaders:Array<ShaderEffect> = [];
	public var camHUDShaders:Array<ShaderEffect> = [];
	public var camOtherShaders:Array<ShaderEffect> = [];
	//event variables
	private var isCameraOnForcedPos:Bool = false;
	public var boyfriendMap:Map<String, Character> = new Map();
	public var dadMap:Map<String, Character> = new Map();
	public var gfMap:Map<String, Character> = new Map();

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	
	public var boyfriendGroup:FlxTypedSpriteGroup<Character>;
	public var dadGroup:FlxTypedSpriteGroup<Character>;
	public var gfGroup:FlxTypedSpriteGroup<Character>;
	public var shaderUpdates:Array<Float->Void> = [];
	public static var curStage:String = '';
	public static var SONG:SwagSong = null;
	public static var originalSong:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public var vocals:FlxSound;
	public var vocalsDad:FlxSound;
	var foundDadVocals:Bool = false;

	public var dad:Character = null;
	public var gf:Character = null;
	public var boyfriend:Character = null;
	var playerChar:FlxTypedSpriteGroup<Character>;
	var opponentChar:FlxTypedSpriteGroup<Character>;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];

	private var strumLine:FlxSprite;

	//Handles the new epic mega sexy cam code that i've done
	private var camFollow:FlxPoint;
	private var camFollowPos:FlxObject;
	private static var prevCamFollow:FlxPoint;
	private static var prevCamFollowPos:FlxObject;

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	public var camZooming:Bool = false;
	public var camBop:Bool = false;
	private var curSong:String = "";

	public var health:Float = 1;
	public var shownHealth:Float = 1;
	public var combo:Int = 0;
	var sectionComboBreaks:Bool = false;

	private var healthBarBG:AttachedSprite;
	public var healthBar:FlxBar;
	var songPercent:Float = 0;

	private var timeBarBG:AttachedSprite;
	public var timeBar:FlxBar;

	var underlayPlayer:FlxSprite;
	var underlayOpponent:FlxSprite;
	
	public var sicks:Int = 0;
	public var goods:Int = 0;
	public var bads:Int = 0;
	public var shits:Int = 0;
	
	private var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	public var startingSong:Bool = false;
	private var updateTime:Bool = true;
	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;

	//Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;
	public var practiceMode:Bool = false;
	public var opponentChart:Bool = false;
	public var playbackRate:Float = 1;
	public var demoMode:Bool = false;
	public var opponentHealthDrain:Bool = true;

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;
	public var practiceFailedSine:Float = 0;
	public var practiceFailed:Bool = false;
	public var practiceFailedTxt:FlxText;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var cameraSpeed:Float = 1;
	public static var iconBopSpeed:Float = 0.5;

	var dialogue:Array<String> = null;
	var dialogueJson:DialogueFile = null;

	var halloweenBG:BGSprite;
	var halloweenWhite:BGSprite;

	var phillyCityLights:FlxTypedGroup<BGSprite>;
	var phillyTrain:BGSprite;
	var blammedLightsBlack:ModchartSprite;
	var blammedLightsBlackTween:FlxTween;
	var phillyCityLightsEvent:FlxTypedGroup<BGSprite>;
	var phillyCityLightsEventTween:FlxTween;
	var trainSound:FlxSound;

	var limoKillingState:Int = 0;
	var limo:BGSprite;
	var limoMetalPole:BGSprite;
	var limoLight:BGSprite;
	var limoCorpse:BGSprite;
	var limoCorpseTwo:BGSprite;
	var bgLimo:BGSprite;
	var grpLimoParticles:FlxTypedGroup<BGSprite>;
	var grpLimoDancers:FlxTypedGroup<BackgroundDancer>;
	var fastCar:BGSprite;

	var upperBoppers:BGSprite;
	var bottomBoppers:BGSprite;
	var santa:BGSprite;
	var heyTimer:Float;

	var bgGirls:BackgroundGirls;
	var bgGhouls:BGSprite;

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var scoreTxt:FlxText;
	var timeTxt:FlxText;
	var songTxt:FlxText;
	var scoreTxtTween:FlxTween;
	var stepTxt:FlxText;
	var beatTxt:FlxText;

	public var ratingTxtGroup:FlxTypedGroup<FlxText>;
	public var ratingTxtTweens:Array<FlxTween> = [null, null, null, null, null];

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public var defaultCamZoom:Float = 1.05;
	public var defaultCamHudZoom:Float = 1;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;
	var playerSingAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];
	var opponentSingAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public var inCutscene:Bool = false;
	public var skipCountdown:Bool = false;
	public var songLength:Float = 0;

	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;

	#if DISCORD_ALLOWED
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	//Achievement shit
	var keysPressed:Array<Bool> = [];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;

	// Lua shit
	public static var instance:PlayState;
	public var luaArray:Array<FunkinLua> = [];
	private var luaDebugGroup:FlxTypedGroup<DebugLuaText>;

	// Debug buttons
	private var debugKeysChart:Array<FlxKey>;
	private var debugKeysCharacter:Array<FlxKey>;
	
	// Less laggy controls
	private var keysArray:Array<Array<FlxKey>>;

	// gamepad shit??
	public var isUsingGamepad:Bool = false;

	public var bfKeys:Int = 4;
	public var dadKeys:Int = 4;
	public var playerKeys:Int = 4;
	public var opponentKeys:Int = 4;

	public var uiSkinMap:Map<String, SkinFile> = new Map();
	var playerColors:Array<String> = [];
	var opponentColors:Array<String> = [];

	var bfGroupFile:CharacterGroupFile = null;
	var dadGroupFile:CharacterGroupFile = null;
	var gfGroupFile:CharacterGroupFile = null;

	public var inEditor:Bool = false;
	var startPos:Float = 0;

	public var doubleTrailMap:Map<String, Character> = new Map();

	public var playerStrumMap:Map<Int, FlxTypedGroup<StrumNote>> = new Map();
	public var opponentStrumMap:Map<Int, FlxTypedGroup<StrumNote>> = new Map();

	var lastTitle = '';

	public var isInPlayState:Bool;

	public var hideInDemoMode:Array<FlxBasic> = [];


	public function new(?inEditor:Bool = false, ?startPos:Float = 0) {
		this.inEditor = inEditor;
		if (inEditor) {
			this.startPos = startPos;
			skipCountdown = true;
		}
		super();
	}

	public function getHealth():Float {
		return healthBar.percent;
	}

	override public function create()
	{
		Paths.clearStoredMemory();
		lastTitle = Application.current.window.title;
		FlxG.mouse.visible = false;

		// for lua
		instance = this;


		debugKeysChart = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		debugKeysCharacter = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_2'));
		PauseSubState.songName = null; //Reset to default
		woah = new FlxText();
		woah.text = "NOTE COMBO!";
		woah.setFormat('Pixels', 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		woah.setGraphicSize(Std.int(woah.width * 1.6));
		woah.antialiasing = ClientPrefs.globalAntialiasing;
		woah.scrollFactor.set();
		woah.updateHitbox();
		woah.screenCenter();

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		if (!inEditor) {
			// Gameplay settings
			healthGain = ClientPrefs.getGameplaySetting('healthgain', 1);
			healthLoss = ClientPrefs.getGameplaySetting('healthloss', 1);
			instakillOnMiss = ClientPrefs.getGameplaySetting('instakill', false);
			practiceMode = ClientPrefs.getGameplaySetting('practice', false);
			cpuControlled = ClientPrefs.getGameplaySetting('botplay', false);
			opponentChart = ClientPrefs.getGameplaySetting('opponentplay', false);
			//playbackRate = ClientPrefs.getGameplaySetting('songspeed', 1);
			demoMode = ClientPrefs.getGameplaySetting('demomode', false);
			opponentHealthDrain = ClientPrefs.getGameplaySetting('opponentHealthDrain', true);
			if (demoMode) {
				cpuControlled = true;
			}

			shader_chromatic_abberation = new ChromaticAberrationEffect();

			camGame = new FlxCamera();
			camHUD = new FlxCamera();
			camOther = new FlxCamera();
			camHUD.bgColor.alpha = 0;
			camOther.bgColor.alpha = 0;

			FlxG.cameras.reset(camGame);
			FlxG.cameras.add(camHUD, false);
			FlxG.cameras.add(camOther, false);
		} else {
			var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
			bg.scrollFactor.set();
			bg.color = FlxColor.fromHSB(FlxG.random.int(0, 359), FlxG.random.float(0, 0.8), FlxG.random.float(0.3, 1));
			add(bg);
		}

		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();

		if (!inEditor) {
			CustomFadeTransition.nextCamera = camOther;
			persistentUpdate = true;
		}

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial', 'tutorial');

		originalSong = Reflect.copy(SONG);

		curSong = Paths.formatToSongPath(SONG.song);

		bfKeys = SONG.playerKeyAmount;
		dadKeys = SONG.opponentKeyAmount;
		playerKeys = bfKeys;
		if (opponentChart) {
			playerKeys = dadKeys;
		}
		setKeysArray(playerKeys);
		opponentKeys = dadKeys;
		if (opponentChart) {
			opponentKeys = bfKeys;
		}

		if (SONG.uiSkin == null || SONG.uiSkin.length < 1) {
			SONG.uiSkin = 'default';
		}
		if (SONG.uiSkinOpponent == null || SONG.uiSkinOpponent.length < 1) {
			SONG.uiSkinOpponent = 'default';
		}

		setSkins();

		Conductor.mapBPMChanges(SONG, playbackRate);

		if (storyDifficulty > CoolUtil.difficulties.length - 1) {
			storyDifficulty = CoolUtil.difficulties.indexOf('Normal');
			if (storyDifficulty == -1) storyDifficulty = 0;
		}

		#if DISCORD_ALLOWED
		if (!inEditor) {
			storyDifficultyText = CoolUtil.difficulties[storyDifficulty];

			// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
			if (isStoryMode)
			{
				detailsText = 'Story Mode: ${WeekData.getCurrentWeek().weekName}';
			}
			else
			{
				detailsText = "Freeplay";
			}

			// String for when the game is paused
			detailsPausedText = 'Paused - $detailsText';
		}
		#end

		GameOverSubState.resetVariables();

		curStage = SONG.stage;
		if (SONG.stage == null || SONG.stage.length < 1) {
			switch (curSong)
			{
				case 'spookeez' | 'south' | 'monster':
					curStage = 'spooky';
				case 'pico' | 'blammed' | 'philly' | 'philly-nice':
					curStage = 'philly';
				case 'milf' | 'satin-panties' | 'high':
					curStage = 'limo';
				case 'cocoa' | 'eggnog':
					curStage = 'mall';
				case 'winter-horrorland':
					curStage = 'mallEvil';
				case 'senpai' | 'roses':
					curStage = 'school';
					introSuffix = '-pixel';
				case 'thorns':
					curStage = 'schoolEvil';
					introSuffix = '-evil';
				default:
					curStage = 'stage';
			}
		}

		var camPos:FlxPoint = null;
		var stageData:StageFile = StageData.getStageFile(curStage);
		if (!inEditor) {
			
			if (stageData == null) { //Stage couldn't be found, create a dummy stage for preventing a crash
				stageData = {
					directory: "",
					defaultZoom: 0.9,
					isPixelStage: false,
				
					boyfriend: [770, 100],
					girlfriend: [400, 130],
					opponent: [100, 100],
					hide_girlfriend: false,

					camera_boyfriend: [0, 0],
					camera_opponent: [0, 0],
					camera_girlfriend: [0, 0],
					camera_speed: 1
				};
			}

			defaultCamZoom = stageData.defaultZoom;
			BF_X = stageData.boyfriend[0];
			BF_Y = stageData.boyfriend[1];
			GF_X = stageData.girlfriend[0];
			GF_Y = stageData.girlfriend[1];
			DAD_X = stageData.opponent[0];
			DAD_Y = stageData.opponent[1];
			if (stageData.isPixelStage) {
				SONG.uiSkin = 'pixel';
				SONG.uiSkinOpponent = 'pixel';
				setSkins();
			}
			
			if(stageData.camera_speed != null)
				cameraSpeed = stageData.camera_speed;
	
			boyfriendCameraOffset = stageData.camera_boyfriend;
			if(boyfriendCameraOffset == null) //Fucks sake should have done it since the start :rolling_eyes:
				boyfriendCameraOffset = [0, 0];
	
			opponentCameraOffset = stageData.camera_opponent;
			if(opponentCameraOffset == null)
				opponentCameraOffset = [0, 0];
	
			girlfriendCameraOffset = stageData.camera_girlfriend;
			if(girlfriendCameraOffset == null)
				girlfriendCameraOffset = [0, 0];

			boyfriendGroup = new FlxTypedSpriteGroup(BF_X, BF_Y);
			dadGroup = new FlxTypedSpriteGroup(DAD_X, DAD_Y);
			gfGroup = new FlxTypedSpriteGroup(GF_X, GF_Y);

            loadOgStages(curStage);
            
			}	


			add(gfGroup); //Needed for blammed lights

			// Shitty layering but whatev it works LOL
			if (curStage == 'limo' && ClientPrefs.gameQuality != 'Crappy')
				add(limo);

			add(dadGroup);
			add(boyfriendGroup);
			
			if (curStage == 'spooky' && ClientPrefs.gameQuality != 'Crappy') {
				add(halloweenWhite);
			}

			#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
			luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
			luaDebugGroup.cameras = [camOther];
			add(luaDebugGroup);
			#end

			if (curStage == 'philly' && ClientPrefs.gameQuality != 'Crappy') {
				phillyCityLightsEvent = new FlxTypedGroup<BGSprite>();
				for (i in 0...5)
				{
					var light:BGSprite = new BGSprite('philly/win$i', -10, 0, 0.3, 0.3);
					light.visible = false;
					light.setGraphicSize(Std.int(light.width * 0.85));
					light.updateHitbox();
					phillyCityLightsEvent.add(light);
				}
			}


			#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
			// "GLOBAL" SCRIPTS
			var filesPushed:Array<String> = [];
			var foldersToCheck:Array<String> = [Paths.getPreloadPath('scripts/')];

			#if MODS_ALLOWED
			foldersToCheck.insert(0, Paths.mods('scripts/'));
			if (Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
				foldersToCheck.insert(0, Paths.mods('${Paths.currentModDirectory}/scripts/'));

			for (folder in foldersToCheck)
			{
				if (FileSystem.exists(folder))
				{
					for (file in FileSystem.readDirectory(folder))
					{
						#if LUA_ALLOWED
						if (file.endsWith('.lua') && !filesPushed.contains(file))
						{
							luaArray.push(new FunkinLua(folder + file));
							filesPushed.push(file);
						}
						#end
						#if HSCRIPT_ALLOWED
						if (file.endsWith('.hscript') && !filesPushed.contains(file))
						{
							addHscript(folder + file);
							filesPushed.push(file);
						}
						#end
					}
				}
			}
			// hmmmm
			if (ClientPrefs.camFollow && WeekData.getWeekFileName() != 'week6')
               luaArray.push(new FunkinLua('assets/scripts/optional/camFollow.lua'));
			#end
			
			// STAGE SCRIPTS
			if (ClientPrefs.gameQuality != 'Crappy') {
				#if LUA_ALLOWED
				var doPush:Bool = false;
				var luaFile:String = 'stages/$curStage.lua';
				if (FileSystem.exists(Paths.modFolders(luaFile))) {
					luaFile = Paths.modFolders(luaFile);
					doPush = true;
				} else {
					luaFile = Paths.getPreloadPath(luaFile);
					if (FileSystem.exists(luaFile)) {
						doPush = true;
					}
				}

				if (doPush) 
					luaArray.push(new FunkinLua(luaFile));
				#end

				#if HSCRIPT_ALLOWED
				var doPush:Bool = false;
				var hscriptFile:String = 'stages/$curStage.hscript';
				#if MODS_ALLOWED
				if (FileSystem.exists(Paths.modFolders(hscriptFile))) {
					hscriptFile = Paths.modFolders(hscriptFile);
					doPush = true;
				} else {
				#end
					hscriptFile = Paths.getPreloadPath(hscriptFile);
					if (OpenFlAssets.exists(hscriptFile)) {
						doPush = true;
					}
				#if MODS_ALLOWED
				}
				#end

				if (doPush) 
					addHscript(hscriptFile);
				#end
			}
			#end

			if (ClientPrefs.gameQuality != 'Crappy') {
				if (!modchartSprites.exists('blammedLightsBlack')) { //Creates blammed light black fade in case you didn't make your own
					blammedLightsBlack = new ModchartSprite(FlxG.width * -0.5, FlxG.height * -0.5);
					blammedLightsBlack.makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
					var position:Int = members.indexOf(gfGroup);
					if (members.indexOf(boyfriendGroup) < position) {
						position = members.indexOf(boyfriendGroup);
					} else if (members.indexOf(dadGroup) < position) {
						position = members.indexOf(dadGroup);
					}
					insert(position, blammedLightsBlack);

					blammedLightsBlack.wasAdded = true;
					modchartSprites.set('blammedLightsBlack', blammedLightsBlack);
				}
				if (curStage == 'philly') insert(members.indexOf(blammedLightsBlack) + 1, phillyCityLightsEvent);
				blammedLightsBlack = modchartSprites.get('blammedLightsBlack');
				blammedLightsBlack.alpha = 0.0;
			}

			var gfVersion:String = SONG.gfVersion;
			if (gfVersion == null || gfVersion.length < 1) {
				switch (curStage)
				{
					case 'limo':
						gfVersion = 'gf-car';
					case 'mall' | 'mallEvil':
						gfVersion = 'gf-christmas';
					case 'school' | 'schoolEvil':
						gfVersion = 'gf-pixel';
					default:
						gfVersion = 'gf';
				}
				SONG.gfVersion = gfVersion; //Fix for the Chart Editor
			}

			if (stageData.hide_girlfriend == false)
			{
				gfGroupFile = Character.getFile(gfVersion);
				if (gfGroupFile != null && gfGroupFile.characters != null && gfGroupFile.characters.length > 0) {
					for (i in 0...gfGroupFile.characters.length) {
						addCharacter(gfGroupFile.characters[i].name, i, false, false, gfGroup, 'gf$i', gfGroupFile.characters[i].position[0] + gfGroupFile.position[0], gfGroupFile.characters[i].position[1] + gfGroupFile.position[1], 0.95, 0.95);
					}
				} else {
					gfGroupFile = null;
					addCharacter(gfVersion, 0, false, false, gfGroup, 'gf0', 0, 0, 0.95, 0.95);
				}
				gf = gfGroup.members[0];
				for (i in gfGroup) {
					startCharacterScripts(i.curCharacter);
				}
			}

			dadGroupFile = Character.getFile(SONG.player2);
			if (dadGroupFile != null && dadGroupFile.characters != null && dadGroupFile.characters.length > 0) {
				for (i in 0...dadGroupFile.characters.length) {
					addCharacter(dadGroupFile.characters[i].name, i, false, opponentChart, dadGroup, 'dad$i', dadGroupFile.characters[i].position[0] + dadGroupFile.position[0], dadGroupFile.characters[i].position[1] + dadGroupFile.position[1]);
				}
			} else {
				dadGroupFile = null;
				addCharacter(SONG.player2, 0, false, opponentChart, dadGroup, 'dad0');
			}
			dad = dadGroup.members[0];
			for (i in dadGroup) {
				startCharacterScripts(i.curCharacter);
			}

			bfGroupFile = Character.getFile(SONG.player1);
			if (bfGroupFile != null && bfGroupFile.characters != null && bfGroupFile.characters.length > 0) {
				for (i in 0...bfGroupFile.characters.length) {
					addCharacter(bfGroupFile.characters[i].name, i, true, !opponentChart, boyfriendGroup, 'bf$i', bfGroupFile.characters[i].position[0] + bfGroupFile.position[0], bfGroupFile.characters[i].position[1] + bfGroupFile.position[1]);
				}
			} else {
				bfGroupFile = null;
				addCharacter(SONG.player1, 0, true, !opponentChart, boyfriendGroup, 'bf0');
			}
			boyfriend = boyfriendGroup.members[0];
			for (i in boyfriendGroup) {
				startCharacterScripts(i.curCharacter);
			}

			playerChar = boyfriendGroup;
			opponentChar = dadGroup;
			if (opponentChart) {
				playerChar = dadGroup;
				opponentChar = boyfriendGroup;
			}
			
			camPos = new FlxPoint(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
			if(gf != null)
			{
				camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
				camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
			}

			if (dad.curCharacter.startsWith('gf')) {
				dad.setPosition(GF_X, GF_Y);
				if(gf != null)
					gf.visible = false;
			}

			if (ClientPrefs.gameQuality != 'Crappy') {
				switch(curStage)
				{
					case 'limo':
						resetFastCar();
						insert(members.indexOf(gfGroup), fastCar);
					
					case 'schoolEvil':
						var evilTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069); //nice
						insert(members.indexOf(dadGroup), evilTrail);
				}
			}

		underlayPlayer = new FlxSprite(0, 0).makeGraphic(1, 1, FlxColor.BLACK);
		underlayPlayer.scrollFactor.set();
		underlayPlayer.alpha = ClientPrefs.underlayAlpha;
		underlayPlayer.visible = false;
		add(underlayPlayer);
		hideInDemoMode.push(underlayPlayer);

		underlayOpponent = new FlxSprite(0, 0).makeGraphic(1, 1, FlxColor.BLACK);
		underlayOpponent.scrollFactor.set();
		underlayOpponent.alpha = ClientPrefs.underlayAlpha;
		underlayOpponent.visible = false;
		add(underlayOpponent);
		hideInDemoMode.push(underlayOpponent);

		Conductor.songPosition = -5000;

		var imagesToCheck = [
			'shit',
			'bad',
			'good',
			'sick',
			'combo',
			'ready',
			'set',
			'go'
		];
		for (i in 0...10) {
			imagesToCheck.push('num$i');
		} 

		for (i in imagesToCheck) {
			Paths.returnGraphic(UIData.checkImageFile(i, uiSkinMap.get(i)));
		}

		strumLine = new FlxSprite(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, 50).makeGraphic(FlxG.width, 10);
		if (ClientPrefs.downScroll) strumLine.y = FlxG.height - 210;
		strumLine.scrollFactor.set();

		if (!inEditor) {
			var showTime:Bool = (ClientPrefs.timeBarType != 'Disabled');
			timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, 19, 400, "", 32);
			timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			timeTxt.scrollFactor.set();
			timeTxt.alpha = 0;
			timeTxt.borderSize = 2;
			timeTxt.visible = showTime;
			if (ClientPrefs.downScroll) timeTxt.y = FlxG.height - 44;
			if (ClientPrefs.timeBarType == 'Song Name') {
				timeTxt.text = SONG.song;
				timeTxt.size = 24;
				timeTxt.y += 3;
			}
			hideInDemoMode.push(timeTxt);
			updateTime = showTime;

			if (ClientPrefs.timeBarType != 'Song Name' && deathCounter < 1) {
				songTxt = new FlxText(timeTxt.x, timeTxt.y + 3, timeTxt.fieldWidth, SONG.song, 24);
				songTxt.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				songTxt.scrollFactor.set();
				songTxt.alpha = timeTxt.alpha;
				songTxt.borderSize = timeTxt.borderSize;
				songTxt.visible = timeTxt.visible;
				hideInDemoMode.push(songTxt);
			}

			timeBarBG = new AttachedSprite(UIData.checkImageFile('timeBar', uiSkinMap.get('timeBar')));
			timeBarBG.x = timeTxt.x;
			timeBarBG.y = timeTxt.y + (timeTxt.height / 4);
			timeBarBG.scrollFactor.set();
			timeBarBG.alpha = 0;
			timeBarBG.visible = showTime;
			timeBarBG.color = FlxColor.BLACK;
			timeBarBG.xAdd = -4;
			timeBarBG.yAdd = -4;
			add(timeBarBG);
			hideInDemoMode.push(timeBarBG);

			timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this,
				'songPercent', 0, 1);
			timeBar.scrollFactor.set();
			timeBar.createFilledBar(0xFF000000, 0xFFFFFFFF);
			timeBar.numDivisions = 800; //How much lag this causes?? Should i tone it down to idk, 400 or 200?
			timeBar.alpha = 0;
			timeBar.visible = showTime;
			hideInDemoMode.push(timeBar);
			add(timeBar);
			add(timeTxt);
			if (ClientPrefs.timeBarType != 'Song Name' && deathCounter < 1) add(songTxt);
			timeBarBG.sprTracker = timeBar;
		} else {
			updateTime = false;
		}

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		add(strumLineNotes);
		add(grpNoteSplashes);
		hideInDemoMode.push(strumLineNotes);
		hideInDemoMode.push(grpNoteSplashes);

		var splash:NoteSplash = new NoteSplash(100, 100, null);
		grpNoteSplashes.add(splash);
		splash.alphaMult = 0;

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();

		generateSong();
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		if (!inEditor) {
			for (notetype in noteTypeMap.keys())
			{
				#if LUA_ALLOWED
				var luaToLoad:String = Paths.modFolders('custom_notetypes/$notetype.lua');
				if (FileSystem.exists(luaToLoad))
				{
					luaArray.push(new FunkinLua(luaToLoad));
				}
				else
				{
					luaToLoad = Paths.getPreloadPath('custom_notetypes/$notetype.lua');
					if (FileSystem.exists(luaToLoad))
					{
						luaArray.push(new FunkinLua(luaToLoad));
					}
				}
				#end

				#if HSCRIPT_ALLOWED
				var hscriptToLoad:String = #if MODS_ALLOWED Paths.modFolders('custom_notetypes/$notetype.hscript') #else '' #end;
				#if MODS_ALLOWED
				if (FileSystem.exists(hscriptToLoad))
				{
					addHscript(hscriptToLoad);
				}
				else
				{
				#end
					hscriptToLoad = Paths.getPreloadPath('custom_notetypes/$notetype.hscript');
					if (OpenFlAssets.exists(hscriptToLoad))
					{
						addHscript(hscriptToLoad);
					}
				#if MODS_ALLOWED
				}
				#end
				#end
			}
			for (event in eventPushedMap.keys())
			{
				#if LUA_ALLOWED
				var luaToLoad:String = Paths.modFolders('custom_events/$event.lua');
				if (FileSystem.exists(luaToLoad))
				{
					luaArray.push(new FunkinLua(luaToLoad));
				}
				else
				{
					luaToLoad = Paths.getPreloadPath('custom_events/$event.lua');
					if (FileSystem.exists(luaToLoad))
					{
						luaArray.push(new FunkinLua(luaToLoad));
					}
				}
				#end

				#if HSCRIPT_ALLOWED
				var hscriptToLoad:String = #if MODS_ALLOWED Paths.modFolders('custom_events/$event.hscript') #else '' #end;
				#if MODS_ALLOWED
				if (FileSystem.exists(hscriptToLoad))
				{
					addHscript(hscriptToLoad);
				}
				else
				{
				#end
					hscriptToLoad = Paths.getPreloadPath('custom_events/$event.hscript');
					if (OpenFlAssets.exists(hscriptToLoad))
					{
						addHscript(hscriptToLoad);
					}
				#if MODS_ALLOWED	
				}
				#end
				#end
			}
		}
		#end
		noteTypeMap.clear();
		noteTypeMap = null;
		eventPushedMap.clear();
		eventPushedMap = null;

		var doof:DialogueBox = null;
		if (!inEditor) {
			#if MODS_ALLOWED
			var file:String = Paths.modsData('$curSong/dialogue'); //Checks for json/Psych Engine dialogue
			if (FileSystem.exists(file)) {
				dialogueJson = DialogueBoxPsych.parseDialogue(file);
			}

			var file:String = Paths.modsDataTxt('$curSong/${curSong}Dialogue'); //Checks for vanilla/Senpai dialogue
			if (FileSystem.exists(file)) {
				dialogue = CoolUtil.coolTextFile(file);
			}
			#end

			var file:String = Paths.json('$curSong/dialogue'); //Checks for json/Psych Engine dialogue
			if (OpenFlAssets.exists(file) && dialogueJson == null) {
				dialogueJson = DialogueBoxPsych.parseDialogue(file);
			}

			var file:String = Paths.txt('$curSong/${curSong}Dialogue'); //Checks for vanilla/Senpai dialogue
			if (OpenFlAssets.exists(file) && dialogue == null) {
				dialogue = CoolUtil.coolTextFile(file);
			}
			doof = new DialogueBox(dialogue);
			doof.scrollFactor.set();
			doof.finishThing = startCountdown;
			doof.nextDialogueThing = startNextDialogue;
			doof.skipDialogueThing = skipDialogue;

			camFollow = new FlxPoint();
			camFollowPos = new FlxObject(0, 0, 1, 1);

			snapCamFollowToPos(camPos.x, camPos.y);
			if (prevCamFollow != null)
			{
				camFollow = prevCamFollow;
				prevCamFollow = null;
			}
			if (prevCamFollowPos != null)
			{
				camFollowPos = prevCamFollowPos;
				prevCamFollowPos = null;
			}
			add(camFollowPos);

			FlxG.camera.follow(camFollowPos, LOCKON, 1);
			FlxG.camera.zoom = defaultCamZoom;
			camHUD.zoom = defaultCamHudZoom;
			FlxG.camera.focusOn(camFollow);

			FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

			FlxG.fixedTimestep = false;
			moveCameraSection(0);

			healthBarBG = new AttachedSprite(UIData.checkImageFile('healthBar', uiSkinMap.get('healthBar')));
			healthBarBG.y = FlxG.height * 0.89;
			healthBarBG.screenCenter(X);
			healthBarBG.scrollFactor.set();
			healthBarBG.visible = !ClientPrefs.hideHud;
			healthBarBG.xAdd = -4;
			healthBarBG.yAdd = -4;
			add(healthBarBG);
			if (ClientPrefs.downScroll) healthBarBG.y = 0.11 * FlxG.height;

			healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, (opponentChart ? LEFT_TO_RIGHT : RIGHT_TO_LEFT), Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
				'shownHealth', 0, 2);
			healthBar.scrollFactor.set();
			healthBar.visible = !ClientPrefs.hideHud;
			healthBar.alpha = ClientPrefs.healthBarAlpha;
			healthBar.numDivisions = 600;
			add(healthBar);
			healthBarBG.sprTracker = healthBar;

			if (bfGroupFile != null) {
				iconP1 = new HealthIcon(bfGroupFile.healthicon, true);
			} else {
				iconP1 = new HealthIcon(boyfriend.healthIcon, true);
			}
			iconP1.y = healthBar.y - 75;
			iconP1.visible = !ClientPrefs.hideHud;
			iconP1.alpha = ClientPrefs.healthBarAlpha;
			add(iconP1);

			if (dadGroupFile != null) {
				iconP2 = new HealthIcon(dadGroupFile.healthicon);
			} else {
				iconP2 = new HealthIcon(dad.healthIcon);
			}
			iconP2.y = healthBar.y - 75;
			iconP2.visible = !ClientPrefs.hideHud;
			iconP2.alpha = ClientPrefs.healthBarAlpha;
			add(iconP2);
			reloadHealthBarColors();
		}

		scoreTxt = new FlxText(0, FlxG.height * 0.89 + 36, FlxG.width, "", 20);
		if (ClientPrefs.downScroll) scoreTxt.y = 0.11 * FlxG.height + 36;
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = !ClientPrefs.hideHud && !cpuControlled;
		add(scoreTxt);
		hideInDemoMode.push(scoreTxt);

		if (!inEditor) {
			botplayTxt = new FlxText(400, timeBarBG.y + 55, FlxG.width - 800, "BOTPLAY", 32);
			botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			botplayTxt.scrollFactor.set();
			botplayTxt.borderSize = 1.25;
			botplayTxt.visible = cpuControlled;
			add(botplayTxt);
			if (ClientPrefs.downScroll) {
				botplayTxt.y = timeBarBG.y - 78;
			}
			hideInDemoMode.push(botplayTxt);

			practiceFailedTxt = new FlxText(400, timeBarBG.y + 105, FlxG.width - 800, "Failed!", 32);
			practiceFailedTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			practiceFailedTxt.scrollFactor.set();
			practiceFailedTxt.borderSize = 1.25;
			practiceFailedTxt.visible = practiceMode;
			practiceFailedTxt.alpha = 0;
			add(practiceFailedTxt);
			if (ClientPrefs.downScroll) {
				practiceFailedTxt.y = timeBarBG.y - 128;
			}
			hideInDemoMode.push(practiceFailedTxt);
		} else {
			beatTxt = new FlxText(0, scoreTxt.y - 67, FlxG.width, "Beat: 0", 20);
			beatTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			beatTxt.scrollFactor.set();
			beatTxt.borderSize = 1.25;
			add(beatTxt);

			stepTxt = new FlxText(0, beatTxt.y + 30, FlxG.width, "Step: 0", 20);
			stepTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			stepTxt.scrollFactor.set();
			stepTxt.borderSize = 1.25;
			add(stepTxt);

			var tipText:FlxText = new FlxText(10, FlxG.height - 24, 0, 'Press ESC to Go Back to Chart Editor', 16);
			tipText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			tipText.borderSize = 2;
			tipText.scrollFactor.set();
			add(tipText);
			FlxG.mouse.visible = false;
		}

		ratingTxtGroup = new FlxTypedGroup<FlxText>();
		ratingTxtGroup.visible = !ClientPrefs.hideHud && ClientPrefs.showRatings;
		hideInDemoMode.push(ratingTxtGroup);
		for (i in 0...5) {
			var ratingTxt = new FlxText(20, FlxG.height * 0.15 - 8 + (16 * (i - 2)), FlxG.width, "", 16);
			ratingTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			ratingTxt.scrollFactor.set();
			ratingTxtGroup.add(ratingTxt);
		}
		add(ratingTxtGroup);


		if (!inEditor) {
			strumLineNotes.cameras = [camHUD];
			grpNoteSplashes.cameras = [camHUD];
			notes.cameras = [camHUD];
			underlayPlayer.cameras = [camHUD];
			underlayOpponent.cameras = [camHUD];
			scoreTxt.cameras = [camHUD];
			ratingTxtGroup.cameras = [camHUD];
			healthBar.cameras = [camHUD];
			healthBarBG.cameras = [camHUD];
			iconP1.cameras = [camHUD];
			iconP2.cameras = [camHUD];
			botplayTxt.cameras = [camHUD];
			practiceFailedTxt.cameras = [camHUD];
			timeBar.cameras = [camHUD];
			timeBarBG.cameras = [camHUD];
			timeTxt.cameras = [camHUD];
			if (ClientPrefs.timeBarType != 'Song Name' && deathCounter < 1) songTxt.cameras = [camHUD];
			doof.cameras = [camHUD];
		}

		startingSong = true;

		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		// SONG SPECIFIC SCRIPTS
		if (!inEditor) {
			var filesPushed:Array<String> = [];
			var foldersToCheck:Array<String> = [Paths.getPreloadPath('data/$curSong/')];

			#if MODS_ALLOWED
			foldersToCheck.insert(0, Paths.mods('data/$curSong/'));
			if (Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
				foldersToCheck.insert(0, Paths.mods('${Paths.currentModDirectory}/data/$curSong/'));

			for (folder in foldersToCheck)
			{
				if (FileSystem.exists(folder))
				{
					for (file in FileSystem.readDirectory(folder))
					{
						#if LUA_ALLOWED
						if (file.endsWith('.lua') && !filesPushed.contains(file))
						{
							luaArray.push(new FunkinLua(folder + file));
							filesPushed.push(file);
						}
						#end

						#if HSCRIPT_ALLOWED
						if (file.endsWith('.hscript') && !filesPushed.contains(file))
						{
							addHscript(folder + file);
							filesPushed.push(file);
						}
						#end
					}
				}
			}
			#end
		// WEEK SPECIFIC SCRIPTS
		if (!inEditor) {
			var filesPushed:Array<String> = [];
			var weekName:String = WeekData.getWeekFileName();
			var foldersToCheck:Array<String> = [Paths.getPreloadPath('$weekName/scripts/')];

			#if MODS_ALLOWED
			foldersToCheck.insert(0, Paths.mods('$weekName/scripts/'));
			if (Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
				foldersToCheck.insert(0, Paths.mods('${Paths.currentModDirectory}/$weekName/scripts/'));

			for (folder in foldersToCheck)
			{
				if (FileSystem.exists(folder))
				{
					for (file in FileSystem.readDirectory(folder))
					{
						#if LUA_ALLOWED
						if (file.endsWith('.lua') && !filesPushed.contains(file))
						{
							luaArray.push(new FunkinLua(folder + file));
							filesPushed.push(file);
						}
						#end

						#if HSCRIPT_ALLOWED
						if (file.endsWith('.hscript') && !filesPushed.contains(file))
						{
							addHscript(folder + file);
							filesPushed.push(file);
						}
						#end
					}
				}
			}
			#end

			if (OpenFlAssets.exists(Paths.getPreloadPath('data/$curSong/$curSong.hscript')) && !filesPushed.contains('$curSong.hscript')) {
				addHscript(Paths.getPreloadPath('data/$curSong/$curSong.hscript'));
				filesPushed.push('$curSong.hscript');
			}

			var pushedFiles:Map<String, Bool> = [];
			for (i in uiSkinMap.keys()) {
				var daSkin = uiSkinMap.get(i).name;
				if (pushedFiles.exists(daSkin)) continue;
				#if LUA_ALLOWED
				var doPush:Bool = false;
				var luaFile:String = 'images/uiskins/$daSkin.lua';
				if (FileSystem.exists(Paths.modFolders(luaFile))) {
					luaFile = Paths.modFolders(luaFile);
					doPush = true;
				} else {
					luaFile = Paths.getPreloadPath(luaFile);
					if (FileSystem.exists(luaFile)) {
						doPush = true;
					}
				}

				if (doPush) {
					pushedFiles.set(daSkin, true);
					luaArray.push(new FunkinLua(luaFile));
				}
				#end

				#if HSCRIPT_ALLOWED
				var doPush:Bool = false;
				var hscriptFile:String = 'images/uiskins/$daSkin.hscript';
				#if MODS_ALLOWED
				if (FileSystem.exists(Paths.modFolders(hscriptFile))) {
					hscriptFile = Paths.modFolders(hscriptFile);
					doPush = true;
				} else {
				#end
					hscriptFile = Paths.getPreloadPath(hscriptFile);
					if (OpenFlAssets.exists(hscriptFile)) {
						doPush = true;
					}
				#if MODS_ALLOWED
				}
				#end

				if (doPush) {
					pushedFiles.set(daSkin, true);
					addHscript(hscriptFile);
				}
				#end
			}
		}
		#end
		
		if (!inEditor && isStoryMode && !seenCutscene)
		{
			switch (curSong)
			{
				case "monster":
					var whiteScreen:FlxSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.WHITE);
					add(whiteScreen);
					whiteScreen.scrollFactor.set();
					whiteScreen.blend = ADD;
					camHUD.visible = false;
					snapCamFollowToPos(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
					inCutscene = true;

					FlxTween.tween(whiteScreen, {alpha: 0}, 1, {
						startDelay: 0.1,
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween)
						{
							camHUD.visible = true;
							remove(whiteScreen);
							startCountdown();
						}
					});
					FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
					for (gf in gfGroup) {
						if (gf.animOffsets.exists('scared'))
							gf.playAnim('scared', true);
					}
					for (boyfriend in boyfriendGroup) {
						if (boyfriend.animOffsets.exists('scared'))
							boyfriend.playAnim('scared', true);
					}

				case "winter-horrorland":
					var blackScreen:FlxSprite = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
					add(blackScreen);
					blackScreen.scrollFactor.set();
					FlxTween.tween(blackScreen, {alpha: 0}, 0.7, {
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween) {
							remove(blackScreen);
						}
					});
					if (ClientPrefs.gameQuality != 'Crappy') {
						camHUD.visible = false;
						inCutscene = true;

						FlxG.sound.play(Paths.sound('Lights_Turn_On'));
						snapCamFollowToPos(400, -2050);
						FlxG.camera.focusOn(camFollow);
						FlxG.camera.zoom = 1.5;

						new FlxTimer().start(0.8, function(tmr:FlxTimer)
						{
							camHUD.visible = true;
							remove(blackScreen);
							FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 2.5, {
								ease: FlxEase.quadInOut,
								onComplete: function(twn:FlxTween)
								{
									startCountdown();
								}
							});
						});
					} else {
						startCountdown();
					}
				case 'senpai' | 'roses' | 'thorns':
					if (curSong == 'roses') FlxG.sound.play(Paths.sound('ANGRY'));
					    schoolIntro(doof);


				default:
				    startCountdown();
			}
			seenCutscene = true;
		} else {
			startCountdown();
		}
		recalculateRating();

		//PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
		if(ClientPrefs.hitsoundVolume > 0) CoolUtil.precacheSound('hitsound');
		CoolUtil.precacheSound('missnote1');
		CoolUtil.precacheSound('missnote2');
		CoolUtil.precacheSound('missnote3');
		
		if (PauseSubState.songName != null) {
			CoolUtil.precacheMusic(PauseSubState.songName);
		} else if(ClientPrefs.pauseMusic != 'None') {
			CoolUtil.precacheMusic(Paths.formatToSongPath(ClientPrefs.pauseMusic));
		}

		#if DISCORD_ALLOWED
		if (!inEditor) {
			// Updating Discord Rich Presence.
			DiscordClient.changePresence(detailsText, '${SONG.song} ($storyDifficultyText)', iconP2.getCharacter());
		}
		#end

        FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

		Conductor.safeZoneOffset = (ClientPrefs.safeFrames / 60) * 1000;

		#if HSCRIPT_ALLOWED
		postSetHscript();
		#end
		callOnScripts('onCreatePost', []);

		// gamepad shit again
		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;
		isUsingGamepad = !FlxG.keys.justReleased.ANY && !FlxG.keys.pressed.ANY && gamepad != null && !gamepad.justReleased.ANY && gamepad.pressed.ANY;

		//cache note splashes
		var textureMap:Map<String, Bool> = new Map();
		textureMap.set('noteSplashes', true);
		for (note in unspawnNotes) {
			if (note.noteSplashTexture != null && note.noteSplashTexture.length > 0 && !note.noteSplashDisabled && !textureMap.exists(note.noteSplashTexture)) {
				var skin = note.noteSplashTexture;
				if (note.uiSkin.isPixel && Paths.fileExists('images/pixelUI/$skin.png', IMAGE)) {
					skin = 'pixelUI/$skin';
				}
				Paths.returnGraphic(skin);
				textureMap.set(skin, true);
			}
		}
		
		super.create();

		Paths.clearUnusedMemory();
		if (!inEditor) {
			CustomFadeTransition.nextCamera = camOther;
		}
		// PUT HERE YOUR MODCHART THINGS
		callOnScripts('onModChartCreate', []);
	}
}
public function getCurSong():String {
	return curSong;
}
function loadOgStages(stage:String) {
	curStage = stage;
	if (ClientPrefs.gameQuality != 'Crappy') {
		switch (curStage)
				{
					case 'stage': //Week 1
						var bg:BGSprite = new BGSprite('stageback', -600, -200, 0.9, 0.9);
						add(bg);

						var stageFront:BGSprite = new BGSprite('stagefront', -650, 600, 0.9, 0.9);
						stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
						stageFront.updateHitbox();
						add(stageFront);

						if (ClientPrefs.gameQuality == 'Normal') {
							var stageLight:BGSprite = new BGSprite('stage_light', -125, -100, 0.9, 0.9);
							stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
							stageLight.updateHitbox();
							add(stageLight);
							var stageLight:BGSprite = new BGSprite('stage_light', 1225, -100, 0.9, 0.9);
							stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
							stageLight.updateHitbox();
							stageLight.flipX = true;
							add(stageLight);

							var stageCurtains:BGSprite = new BGSprite('stagecurtains', -500, -300, 1.3, 1.3);
							stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
							stageCurtains.updateHitbox();
							add(stageCurtains);
						}
						/*if (destroyStage)
							{
								bg.kill();
								stageFront.kill();
								if (ClientPrefs.gameQuality == 'Normal')
								{
									stageLight.kill();
									stageLight.kill();
									stageCurtains.kill();
								}
							}*/


					case 'spooky': //Week 2
						if (ClientPrefs.gameQuality == 'Normal') {
							halloweenBG = new BGSprite('halloween_bg', -200, -100, ['halloweem bg0', 'halloweem bg lightning strike']);
						} else {
							halloweenBG = new BGSprite('halloween_bg_low', -200, -100);
						}
						add(halloweenBG);

						halloweenWhite = new BGSprite(null, -FlxG.width, -FlxG.height, 0, 0);
						halloweenWhite.makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.WHITE);
						halloweenWhite.alpha = 0;
						halloweenWhite.blend = ADD;

						//PRECACHE SOUNDS
						CoolUtil.precacheSound('thunder_1');
						CoolUtil.precacheSound('thunder_2');
						/*if (destroyStage)
						{
							halloweenBG.kill();
						}*/

					case 'philly': //Week 3
						if (ClientPrefs.gameQuality == 'Normal') {
							var bg:BGSprite = new BGSprite('philly/sky', -100, 0, 0.1, 0.1);
							add(bg);
						}

						var city:BGSprite = new BGSprite('philly/city', -10, 0, 0.3, 0.3);
						city.setGraphicSize(Std.int(city.width * 0.85));
						city.updateHitbox();
						add(city);

						phillyCityLights = new FlxTypedGroup<BGSprite>();
						add(phillyCityLights);

						for (i in 0...5)
						{
							var light:BGSprite = new BGSprite('philly/win$i', city.x, city.y, 0.3, 0.3);
							light.visible = false;
							light.setGraphicSize(Std.int(light.width * 0.85));
							light.updateHitbox();
							phillyCityLights.add(light);
						}

						if (ClientPrefs.gameQuality == 'Normal') {
							var streetBehind:BGSprite = new BGSprite('philly/behindTrain', -40, 50);
							add(streetBehind);
						}

						phillyTrain = new BGSprite('philly/train', 2000, 360);
						add(phillyTrain);

						trainSound = new FlxSound().loadEmbedded(Paths.sound('train_passes'));
						CoolUtil.precacheSound('train_passes');
						FlxG.sound.list.add(trainSound);

						var street:BGSprite = new BGSprite('philly/street', -40, 50);
						add(street);

						/*if (destroyStage)
						{
							city.kill();
                            phillyCityLights.kill();
							phillyCityLights.kill(light);
							streetBehind.kill();
							phillyTrain.kill();
							street.kill();
							if (ClientPrefs.gameQuality == 'Normal')
							{
								bg.kill();
							}
						}*/

					case 'limo': //Week 4
						var skyBG:BGSprite = new BGSprite('limo/limoSunset', -120, -50, 0.1, 0.1);
						add(skyBG);

						if (ClientPrefs.gameQuality == 'Normal') {
							limoMetalPole = new BGSprite('gore/metalPole', -500, 220, 0.4, 0.4);
							add(limoMetalPole);

							bgLimo = new BGSprite('limo/bgLimo', -150, 480, 0.4, 0.4, ['background limo pink'], true);
							add(bgLimo);

							limoCorpse = new BGSprite('gore/noooooo', -500, limoMetalPole.y - 130, 0.4, 0.4, ['Henchmen on rail'], true);
							add(limoCorpse);

							limoCorpseTwo = new BGSprite('gore/noooooo', -500, limoMetalPole.y, 0.4, 0.4, ['henchmen death'], true);
							add(limoCorpseTwo);

							grpLimoDancers = new FlxTypedGroup<BackgroundDancer>();
							add(grpLimoDancers);

							for (i in 0...5)
							{
								var dancer:BackgroundDancer = new BackgroundDancer((370 * i) + 130, bgLimo.y - 400);
								dancer.scrollFactor.set(0.4, 0.4);
								grpLimoDancers.add(dancer);
							}

							limoLight = new BGSprite('gore/coldHeartKiller', limoMetalPole.x - 180, limoMetalPole.y - 80, 0.4, 0.4);
							add(limoLight);

							grpLimoParticles = new FlxTypedGroup<BGSprite>();
							add(grpLimoParticles);

							//PRECACHE BLOOD
							var particle:BGSprite = new BGSprite('gore/stupidBlood', -400, -400, 0.4, 0.4, ['blood'], false);
							particle.alpha = 0.01;
							grpLimoParticles.add(particle);
							resetLimoKill();

							//PRECACHE SOUND
							CoolUtil.precacheSound('dancerdeath');
						}

						limo = new BGSprite('limo/limoDrive', -120, 550, 1, 1, ['Limo stage'], true);

						fastCar = new BGSprite('limo/fastCarLol', -300, 160);
						fastCar.active = true;
						limoKillingState = 0;


					case 'mall': //Week 5 - Cocoa, Eggnog
						var bg:BGSprite = new BGSprite('christmas/bgWalls', -1000, -500, 0.2, 0.2);
						bg.setGraphicSize(Std.int(bg.width * 0.8));
						bg.updateHitbox();
						add(bg);
						/*if (destroyStage)
						{
							bg.kill();
						}*/

						if (ClientPrefs.gameQuality == 'Normal') {
							upperBoppers = new BGSprite('christmas/upperBop', -240, -90, 0.33, 0.33, ['Upper Crowd Bob']);
							upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
							upperBoppers.updateHitbox();
							add(upperBoppers);

							var bgEscalator:BGSprite = new BGSprite('christmas/bgEscalator', -1100, -600, 0.3, 0.3);
							bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
							bgEscalator.updateHitbox();
							add(bgEscalator);
						}

						var tree:BGSprite = new BGSprite('christmas/christmasTree', 370, -250, 0.40, 0.40);
						add(tree);

						bottomBoppers = new BGSprite('christmas/bottomBop', -300, 140, 0.9, 0.9, ['Bottom Level Boppers Idle']);
						bottomBoppers.animation.addByPrefix('hey', 'Bottom Level Boppers HEY', 24, false);
						bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 1));
						bottomBoppers.updateHitbox();
						add(bottomBoppers);

						var fgSnow:BGSprite = new BGSprite('christmas/fgSnow', -600, 700);
						add(fgSnow);

						santa = new BGSprite('christmas/santa', -840, 150, 1, 1, ['santa idle in fear']);
						add(santa);
						CoolUtil.precacheSound('Lights_Shut_off');
						/*if (destroyStage)
						{
							kill(tree);
							kill(bottomBoppers);
							kill(fgSnow);
							kill(santa);
						}*/

					case 'mallEvil': //Week 5 - Winter Horrorland
						var bg:BGSprite = new BGSprite('christmas/evilBG', -400, -500, 0.2, 0.2);
						bg.setGraphicSize(Std.int(bg.width * 0.8));
						bg.updateHitbox();
						add(bg);

						var evilTree:BGSprite = new BGSprite('christmas/evilTree', 300, -300, 0.2, 0.2);
						add(evilTree);

						var evilSnow:BGSprite = new BGSprite('christmas/evilSnow', -200, 700);
						add(evilSnow);
						/*if (destroyStage)
						{
							kill(bg);
							kill(evilTree);
							kill(evilSnow);
							if (ClientPrefs.gameQuality = 'Normal')
							{
								upperBoppers.kill();
							    bgEscalator.kill();
							}
							tree.kill();
							bottomBoppers.kill();
							fgSnow.kill();
							santa.kill(); // murdered santa real!!!!
						}*/

					case 'school': //Week 6 - Senpai, Roses
						GameOverSubState.deathSoundName = 'fnf_loss_sfx-pixel';
						GameOverSubState.loopSoundName = 'gameOver-pixel';
						GameOverSubState.endSoundName = 'gameOverEnd-pixel';
						GameOverSubState.characterName = 'bf-pixel-dead';


						introSuffix == '-pixel';

						var bgSky:BGSprite = new BGSprite('weeb/weebSky', 0, 0, 0.1, 0.1);
						add(bgSky);
						bgSky.antialiasing = false;

						var repositionShit = -200;

						var bgSchool:BGSprite = new BGSprite('weeb/weebSchool', repositionShit, 0, 0.6, 0.90);
						add(bgSchool);
						bgSchool.antialiasing = false;

						var bgStreet:BGSprite = new BGSprite('weeb/weebStreet', repositionShit, 0, 0.95, 0.95);
						add(bgStreet);
						bgStreet.antialiasing = false;



						var widShit = Std.int(bgSky.width * 6);
						if (ClientPrefs.gameQuality == 'Normal') {
							var fgTrees:BGSprite = new BGSprite('weeb/weebTreesBack', repositionShit + 170, 130, 0.9, 0.9);
							fgTrees.setGraphicSize(Std.int(widShit * 0.8));
							fgTrees.updateHitbox();
							add(fgTrees);
							fgTrees.antialiasing = false;
						}

						var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800);
						bgTrees.frames = Paths.getPackerAtlas('weeb/weebTrees');
						bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
						bgTrees.animation.play('treeLoop');
						bgTrees.scrollFactor.set(0.85, 0.85);
						add(bgTrees);
						bgTrees.antialiasing = false;

						if (ClientPrefs.gameQuality == 'Normal') {
							var treeLeaves:BGSprite = new BGSprite('weeb/petals', repositionShit, -40, 0.85, 0.85, ['PETALS ALL'], true);
							treeLeaves.setGraphicSize(widShit);
							treeLeaves.updateHitbox();
							add(treeLeaves);
							treeLeaves.antialiasing = false;
						}

						bgSky.setGraphicSize(widShit);
						bgSchool.setGraphicSize(widShit);
						bgStreet.setGraphicSize(widShit);
						bgTrees.setGraphicSize(Std.int(widShit * 1.4));

						bgSky.updateHitbox();
						bgSchool.updateHitbox();
						bgStreet.updateHitbox();
						bgTrees.updateHitbox();

						if (ClientPrefs.gameQuality == 'Normal') {
							bgGirls = new BackgroundGirls(-100, 190);
							bgGirls.scrollFactor.set(0.9, 0.9);

							bgGirls.setGraphicSize(Std.int(bgGirls.width * daPixelZoom));
							bgGirls.updateHitbox();
							add(bgGirls);
						}
						/*if (destroyStage)
							{
								bgSky.kill();
								bgSchool.kill();
								bgStreet.kill();
								bgTrees.kill();
								if (ClientPrefs.gameQuality == 'Normal')
								{
									fgTrees.kill();
									treeLeaves.kill();
									bgGirls.kill();
								}
							}*/

					case 'schoolEvil': //Week 6 - Thorns
						GameOverSubState.deathSoundName = 'fnf_loss_sfx-pixel';
						GameOverSubState.loopSoundName = 'gameOver-pixel';
						GameOverSubState.endSoundName = 'gameOverEnd-pixel';
						GameOverSubState.characterName = 'bf-pixel-dead';
						

						introSuffix == '-evil';

						var posX = 400;
						var posY = 200;
						if (ClientPrefs.gameQuality == 'Normal') {
							var bg:BGSprite = new BGSprite('weeb/animatedEvilSchool', posX, posY, 0.8, 0.9, ['background 2'], true);
							bg.scale.set(6, 6);
							bg.antialiasing = false;
							add(bg);

							bgGhouls = new BGSprite('weeb/bgGhouls', -100, 190, 0.9, 0.9, ['BG freaks glitch instance'], false);
							bgGhouls.setGraphicSize(Std.int(bgGhouls.width * daPixelZoom));
							bgGhouls.updateHitbox();
							bgGhouls.visible = false;
							bgGhouls.antialiasing = false;
							add(bgGhouls);
						} else {
							var bg:BGSprite = new BGSprite('weeb/animatedEvilSchool_low', posX, posY, 0.8, 0.9);
							bg.scale.set(6, 6);
							bg.antialiasing = false;
							add(bg);
						}
						/*if (destroyStage)
							{
								if (ClientPrefs.gameQuality == 'Normal')
								{
									bg.kill();
								    bgGhouls.kill();
								}
								else
								{
									bg.kill();
								}
							}*/
		}
	}
}


	function set_songSpeed(value:Float):Float
	{
		if (generatedMusic)
		{
			for (note in notes)
			{
				var ratio:Float = value / note.speed; //funny word huh
				note.speed *= ratio;
				if (note.isSustainNote) {
					note.strumTime = note.ogStrumTime + (note.stepCrochet / 2 / value);
				}
			}
			for (note in unspawnNotes)
			{
				var ratio:Float = value / note.speed; //funny word huh
				note.speed *= ratio;
				if (note.isSustainNote) {
					note.strumTime = note.ogStrumTime + (note.stepCrochet / 2 / value);
				}
			}
		}
		songSpeed = value;
		setOnScripts('scrollSpeed', songSpeed);
		return value;
	}

	public function addTextToDebug(text:String) {
		#if LUA_ALLOWED
		luaDebugGroup.forEachAlive(function(spr:DebugLuaText) {
			spr.y += 20;
		});

		if (luaDebugGroup.members.length > 34) {
			var blah = luaDebugGroup.members[34];
			blah.destroy();
			luaDebugGroup.remove(blah);
		}
		luaDebugGroup.insert(0, new DebugLuaText(text, luaDebugGroup));
		#end
	}

	public function reloadHealthBarColors() {
		var healthColors = [dad.healthColorArray, boyfriend.healthColorArray];
		if (dadGroupFile != null) {
			healthColors[0] = dadGroupFile.healthbar_colors;
		}
		if (bfGroupFile != null) {
			healthColors[1] = bfGroupFile.healthbar_colors;
		}
		if (!opponentChart) {
			healthBar.createFilledBar(FlxColor.fromRGB(healthColors[0][0], healthColors[0][1], healthColors[0][2]),
			FlxColor.fromRGB(healthColors[1][0], healthColors[1][1], healthColors[1][2]));
		} else {
			healthBar.createFilledBar(FlxColor.fromRGB(healthColors[1][0], healthColors[1][1], healthColors[1][2]),
			FlxColor.fromRGB(healthColors[0][0], healthColors[0][1], healthColors[0][2]));
		}
		healthBar.updateBar();
	}

	public function addCharacterToList(newCharacter:String, type:Int, ?index:Int = 0) {
		switch(type) {
			case 0:
				if (!boyfriendMap.exists(newCharacter)) {
					var xOffset = 0.0;
					var yOffset = 0.0;
					if (bfGroupFile != null) {
						xOffset = (bfGroupFile.characters[index] != null ? bfGroupFile.characters[index].position[0] : 0) + bfGroupFile.position[0];
						yOffset = (bfGroupFile.characters[index] != null ? bfGroupFile.characters[index].position[1] : 0) + bfGroupFile.position[1];
					}
					var newBoyfriend = addCharacter(newCharacter, index, true, !opponentChart, null, '', xOffset, yOffset);
					boyfriendMap.set(newCharacter, newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					add(newBoyfriend);
					startCharacterScripts(newCharacter);
				}

			case 1:
				if (!dadMap.exists(newCharacter)) {
					var xOffset = 0.0;
					var yOffset = 0.0;
					if (dadGroupFile != null) {
						xOffset = (dadGroupFile.characters[index] != null ? dadGroupFile.characters[index].position[0] : 0) + dadGroupFile.position[0];
						yOffset = (dadGroupFile.characters[index] != null ? dadGroupFile.characters[index].position[1] : 0) + dadGroupFile.position[1];
					}
					var newDad = addCharacter(newCharacter, index, false, opponentChart, null, '', xOffset, yOffset);
					dadMap.set(newCharacter, newDad);
					newDad.alpha = 0.00001;
					add(newDad);
					startCharacterScripts(newCharacter);
				}

			case 2:
				if (!gfMap.exists(newCharacter)) {
					var xOffset = 0.0;
					var yOffset = 0.0;
					if (gfGroupFile != null) {
						xOffset = (gfGroupFile.characters[index] != null ? gfGroupFile.characters[index].position[0] : 0) + gfGroupFile.position[0];
						yOffset = (gfGroupFile.characters[index] != null ? gfGroupFile.characters[index].position[1] : 0) + gfGroupFile.position[1];
					}
					var newGf = addCharacter(newCharacter, index, false, false, null, '', xOffset, yOffset, 0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					newGf.alpha = 0.00001;
					add(newGf);
					startCharacterScripts(newCharacter);
				}
		}
	}

	/*public function loadStage(stage:String)
		{
			#if LUA_ALLOWED
			if (FileSystem.exists('assets/stages/$stage.lua'))
			{
				luaArray.push(new FunkinLua('assets/stages/$stage.lua'))
			}
			else if (FileSystem.exists('mods/stages/$stage.lua'))
			{
				luaArray.push(new FunkinLua('mods/stages$stage.lua'))
			}
			#end
			#if HSCRIPT_ALLOWED
			if (FileSystem.exists('assets/stages/$stage.hscript'))
			{
				addHscript('assets/stages/$stage.hscript');
			}
			if (FileSystem.exists('mods/stages/$stage.hscript'))
			{
				addHscript('mods/stages/$stage.hscript');
			}
			#end
			StageData.getStageFile(stage);
		    destroyStage = true;
			modchartSprites.kill(); //for lua thing
			}*/
			// i dunno
		/*public function removeLuaSprite(tag:String, destroy:Bool = true)
			{
				if (!PlayState.instance.modchartSprites.exists(tag)) {
					return;
				}
				
				var pee:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
				if (destroy) {
					pee.kill();
				}
	
				if (pee.wasAdded) {
					getInstance().remove(pee, true);
					pee.wasAdded = false;
				}
	
				if (destroy) {
					pee.destroy();
					PlayState.instance.modchartSprites.remove(tag);
				}
			}*/
			// copyed from FunkinLua file
		private function noteCombo():Void
		{
			while (woah.alpha != 1) {
				woah.alpha += 0.01; // quick tween
			}
			add(woah);
			//var mytimer:FlxTimer;
			if (ClientPrefs.flashing)
			{
				FlxG.camera.flash(FlxColor.WHITE, 0.5); // funny mukbang flash
			}
			songScore = songScore + 1500; // no reason
			FlxTween.tween(woah, {alpha: 0}, modifiedCrochet / 100, {
				ease: FlxEase.cubeInOut,
				onComplete: function(twn:FlxTween)
				{
					remove(woah);
				}
			});
			// funee tween
		}

	#if HSCRIPT_ALLOWED
	var hscriptMap:Map<String, FunkinHscript> = new Map();
	public function addHscript(path:String) {
		var parser = new ParserEx();
		try {
			var program = parser.parseString(Paths.getContent(path));
			var interp = new FunkinHscript();

			//FUNCTIONS
			interp.variables.set('add', PlayState.instance.add);
			interp.variables.set('insert', PlayState.instance.insert);
			interp.variables.set('remove', remove);
			interp.variables.set('addBehindChars', function(obj:FlxBasic) {
				var index = members.indexOf(gfGroup);
				if (members.indexOf(dadGroup) < index) {
					index = members.indexOf(dadGroup);
				}
				if (members.indexOf(boyfriendGroup) < index) {
					index = members.indexOf(boyfriendGroup);
				}
				insert(index, obj);
			});
			interp.variables.set('addOverChars', function(obj:FlxBasic) {
				var index = members.indexOf(boyfriendGroup);
				if (members.indexOf(dadGroup) > index) {
					index = members.indexOf(dadGroup);
				}
				if (members.indexOf(gfGroup) > index) {
					index = members.indexOf(gfGroup);
				}
				insert(index + 1, obj);
			});
			interp.variables.set('getObjectOrder', function(obj:Dynamic) {
				if ((obj is String)) {
					var basic:FlxBasic = Reflect.getProperty(this, obj);
					if (basic != null) {
						return members.indexOf(basic);
					}
					return -1;
				} else {
					return members.indexOf(obj);
				}
			});
			interp.variables.set('setObjectOrder', function(obj:Dynamic, pos:Int = 0) {
				if ((obj is String)) {
					var basic:FlxBasic = Reflect.getProperty(this, obj);
					if (basic != null) {
						if (members.indexOf(basic) > -1) {
							remove(basic);
						}
						insert(pos, basic);
					}
				} else {
					if (members.indexOf(obj) > -1) {
						remove(obj);
					}
					insert(pos, obj);
				}
			});
			interp.variables.set('openSubState', openSubState);
			interp.variables.set('closeSubState', closeSubState);
			interp.variables.set('getProperty', function(variable:String) {
				return Reflect.getProperty(this, variable);
			});
			interp.variables.set('setProperty', function(variable:String, value:Dynamic) {
				Reflect.setProperty(this, variable, value);
			});
			interp.variables.set('getPropertyFromClass', function(classVar:String, variable:String) {
				return Reflect.getProperty(Type.resolveClass(classVar), variable);
			});
			interp.variables.set('setPropertyFromClass', function(classVar:String, variable:String, value:Dynamic) {
				Reflect.setProperty(Type.resolveClass(classVar), variable, value);
			});
			interp.variables.set("triggerEvent", triggerEventNote);
			interp.variables.set('startCountdown', startCountdown);
			interp.variables.set('loadSong', function(name:String = null, ?difficultyNum:Int = -1, ?skipTransition:Bool = false) {
				if (name == null) name = SONG.song;
				if (difficultyNum < 0) difficultyNum = storyDifficulty;
	
				if (skipTransition)
				{
					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;
				}
	
				if (isStoryMode && !transitioning) {
					campaignScore += songScore;
					campaignMisses += songMisses;
					storyPlaylist.remove(storyPlaylist[0]);
					storyPlaylist.insert(0, name);
				}
	
				CoolUtil.getDifficulties(name, true);
				if (difficultyNum >= CoolUtil.difficulties.length) {
					difficultyNum = CoolUtil.difficulties.length - 1;
				}
				var poop = Highscore.formatSong(name, difficultyNum, false);
				SONG = Song.loadFromJson(poop, name);
				storyDifficulty = difficultyNum;
				instance.persistentUpdate = false;
				cancelMusicFadeTween();
				deathCounter = 0;
				FlxG.sound.music.pause();
				FlxG.sound.music.volume = 0;
				if(vocals != null)
				{
					vocals.pause();
					vocals.volume = 0;
				}
				if(vocalsDad != null)
				{
					vocalsDad.pause();
					vocalsDad.volume = 0;
				}
				LoadingState.loadAndResetState();
			});
			interp.variables.set("endSong", function() {
				killNotes();
				finishSong(true);
			});
			interp.variables.set("restartSong", function(skipTransition:Bool = false) {
				persistentUpdate = false;
				PauseSubState.restartSong(skipTransition);
			});
			interp.variables.set("exitSong", function(skipTransition:Bool = false) {
				if (skipTransition)
				{
					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;
				}
	
				cancelMusicFadeTween();
				CustomFadeTransition.nextCamera = camOther;
				if (FlxTransitionableState.skipNextTransIn)
					CustomFadeTransition.nextCamera = null;
	
				if (isStoryMode)
					MusicBeatState.switchState(new StoryMenuState());
				else
					MusicBeatState.switchState(new FreeplayState());
	
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				changedDifficulty = false;
				chartingMode = false;
				instance.transitioning = true;
				deathCounter = 0;
			});
			interp.variables.set("pauseGame", pauseGame);
			interp.variables.set('openCredits', function(playMusic:Bool = true) {
				cancelMusicFadeTween();
				CustomFadeTransition.nextCamera = camOther;
				if (FlxTransitionableState.skipNextTransIn)
					CustomFadeTransition.nextCamera = null;

				CreditsState.skipToCurrentMod = true;
				MusicBeatState.switchState(new CreditsState());

				FlxG.sound.music.stop();
				if (playMusic)
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
				changedDifficulty = false;
				chartingMode = false;
				transitioning = true;
				deathCounter = 0;
			});
			interp.variables.set("setSongTime", setSongTime);
			interp.variables.set("moveCamera", moveCamera);
			interp.variables.set("setHealthBarColors", function(left:String = '0xFFFF0000', right:String = '0xFF66FF33') {
				var leftColorNum:Int = Std.parseInt(left);
				if (!left.startsWith('0x')) leftColorNum = Std.parseInt('0xff$left');
				var rightColorNum:Int = Std.parseInt(right);
				if (!right.startsWith('0x')) rightColorNum = Std.parseInt('0xff$right');
	
				healthBar.createFilledBar(leftColorNum, rightColorNum);
				healthBar.updateBar();
			});
			interp.variables.set("startDialogue", function(dialogueFile:String, music:String = null) {
				#if MODS_ALLOWED
				var path:String = Paths.modsData('${Paths.formatToSongPath(SONG.song)}/$dialogueFile');
				if (!FileSystem.exists(path)) {
					path = Paths.json('${Paths.formatToSongPath(SONG.song)}/$dialogueFile');
				}
				#else
				var path:String = Paths.json('${Paths.formatToSongPath(SONG.song)}/$dialogueFile');
				#end
				addTextToDebug('Trying to load dialogue: $path');
	
				if (#if MODS_ALLOWED FileSystem.exists(path) || #end OpenFlAssets.exists(path)) {
					var shit:DialogueFile = DialogueBoxPsych.parseDialogue(path);
					if (shit.dialogue.length > 0) {
						startDialogue(shit, music);
						addTextToDebug('Successfully loaded dialogue');
					} else {
						addTextToDebug('Your dialogue file is badly formatted!');
					}
				} else {
					addTextToDebug('Dialogue file not found');
					if (endingSong) {
						endSong();
					} else {
						startCountdown();
					}
				}
			});
			interp.variables.set("startVideo", startVideo);
			interp.variables.set("setWeekCompleted", function(name:String = '') {
				if(name.length > 0)
				{
					var weekName = WeekData.formatWeek(name);
					StoryMenuState.weekCompleted.set(weekName, true);
					FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
					FlxG.save.flush();
				}
			});
			//yea just have nearly every function :) (you can also just call the wanted function on `instance`)
			interp.variables.set("addTextToDebug", addTextToDebug);
			interp.variables.set("reloadHealthBarColors", reloadHealthBarColors);
			interp.variables.set("addCharacterToList", addCharacterToList);
			interp.variables.set("callHscript", callHscript);
			interp.variables.set("setOnHscripts", setOnHscripts);
			interp.variables.set("startCharacterScripts", startCharacterScripts);
			interp.variables.set("startCharacterPos", startCharacterPos);
			interp.variables.set("startAndEnd", startAndEnd);
			interp.variables.set("clearNotesBefore", clearNotesBefore);
			interp.variables.set("startSong", startSong);
			interp.variables.set("generateSong", generateSong);
			interp.variables.set("eventPushed", eventPushed);
			interp.variables.set("eventNoteEarlyTrigger", eventNoteEarlyTrigger);
			interp.variables.set("sortByShit", sortByShit);
			interp.variables.set("sortByTime", sortByTime);
			interp.variables.set("generateStaticArrows", generateStaticArrows);
			interp.variables.set("resetUnderlay", resetUnderlay);
			interp.variables.set("setKeysArray", setKeysArray);
			interp.variables.set("resyncVocals", resyncVocals);
			interp.variables.set("openChartEditor", openChartEditor);
			interp.variables.set("doDeathCheck", doDeathCheck);
			interp.variables.set("checkEventNote", checkEventNote);
			interp.variables.set("controlJustPressed", controlJustPressed);
			interp.variables.set("controlPressed", controlPressed);
			interp.variables.set("controlReleased", controlReleased);
			interp.variables.set("moveCameraSection", moveCameraSection);
			interp.variables.set("tweenCamIn", tweenCamIn);
			interp.variables.set("snapCamFollowToPos", snapCamFollowToPos);
			interp.variables.set("startAchievement", startAchievement);
			interp.variables.set("killNotes", killNotes);
			interp.variables.set("popUpScore", popUpScore);
			interp.variables.set("doRatingTween", doRatingTween);
			interp.variables.set("keyShit", keyShit);
			interp.variables.set("noteMiss", noteMiss);
			interp.variables.set("noteMissPress", noteMissPress);
			interp.variables.set("opponentNoteHit", opponentNoteHit);
			interp.variables.set("goodNoteHit", goodNoteHit);
			interp.variables.set("spawnNoteSplashOnNote", spawnNoteSplashOnNote);
			interp.variables.set("spawnNoteSplash", spawnNoteSplash);
			interp.variables.set("cancelMusicFadeTween", cancelMusicFadeTween);
			interp.variables.set("switchKeys", switchKeys);
			interp.variables.set("setSkins", setSkins);
			interp.variables.set("makeDoubleTrail", makeDoubleTrail);
			interp.variables.set("callOnScripts", callOnScripts);
			interp.variables.set("setOnScripts", setOnScripts);
			interp.variables.set("strumPlayAnim", strumPlayAnim);
			interp.variables.set("recalculateRating", recalculateRating);
			interp.variables.set("checkForAchievement", checkForAchievement);
			interp.variables.set('addScript', function(name:String, ?ignoreAlreadyRunning:Bool = false) {
				var cervix = '$name.hscript';
				var doPush = false;
				#if MODS_ALLOWED
				if (FileSystem.exists(Paths.modFolders(cervix))) {
					cervix = Paths.modFolders(cervix);
					doPush = true;
				} else {
				#end
					cervix = Paths.getPreloadPath(cervix);
					if (OpenFlAssets.exists(cervix)) {
						doPush = true;
					}
				#if MODS_ALLOWED	
				}
				#end
	
				if (doPush)
				{
					if (!ignoreAlreadyRunning && hscriptMap.exists(cervix))
					{
						addTextToDebug('The script "$cervix" is already running!');
						return;
					}
					addHscript(cervix);
					return;
				}
				addTextToDebug("Script doesn't exist!");
			});
			interp.variables.set('removeScript', function(name:String) {
				var cervix = '$name.hscript';
				var doPush = false;
				#if MODS_ALLOWED
				if (FileSystem.exists(Paths.modFolders(cervix))) {
					cervix = Paths.modFolders(cervix);
					doPush = true;
				} else {
				#end
					cervix = Paths.getPreloadPath(cervix);
					if (OpenFlAssets.exists(cervix)) {
						doPush = true;
					}
				#if MODS_ALLOWED	
				}
				#end
	
				if (doPush)
				{
					if (hscriptMap.exists(cervix))
					{
						var hscript = hscriptMap.get(cervix);
						hscriptMap.remove(cervix);
						hscript = null;
						return;
					}
					return;
				}
				addTextToDebug("Script doesn't exist!");
			});
			interp.variables.set('close', function() {
				if (!closeHscripts.contains(path)) {
					closeHscripts.push(path);
				}
			});
			interp.variables.set('debugPrint', function(text:Dynamic) {
				addTextToDebug('$text');
				trace(text);
			});

			//EVENTS
			var funcs = [
				'onStepHit',
				'onBeatHit',
				'onStartCountdown',
				'onSongStart',
				'onEndSong',
				'onSkipCutscene',
				'onBPMChange',
				'onSignatureChange',
				'onOpenChartEditor',
				'onOpenCharacterEditor',
				'onPause',
				'onResume',
				'onGameOver',
				'onRecalculateRating'
			];
			for (i in funcs)
				interp.variables.set(i, function() {});
			interp.variables.set('onCountdownTick', function(counter) {});
			interp.variables.set('onGameOverConfirm', function(retry) {});
			interp.variables.set('onNextDialogue', function(line) {});
			interp.variables.set('onSkipDialogue', function(line) {});
			interp.variables.set('goodNoteHit', function(id, direction, noteType, isSustainNote, characters) {});
			interp.variables.set('opponentNoteHit', function(id, direction, noteType, isSustainNote, characters) {});
			interp.variables.set('noteMissPress', function(direction) {});
			interp.variables.set('noteMiss', function(id, direction, noteType, isSustainNote, characters) {});
			interp.variables.set('onMoveCamera', function(focus) {});
			interp.variables.set('onEvent', function(name, value1, value2) {});
			interp.variables.set('eventPushed', function(name, strumTime, value1, value2) {});
			interp.variables.set('eventEarlyTrigger', function(name) {});
			interp.variables.set('onTweenCompleted', function(tag) {});
			interp.variables.set('onTimerCompleted', function(tag, loops, loopsLeft) {});

			interp.execute(program);
			hscriptMap.set(path, interp);
			callHscript(path, 'onCreate', []);
		} catch (e) {
			trace(e);
			addTextToDebug('$e');
			addTextToDebug('Could not load script $path');
		}
	}

	function callHscript(name:String, func:String, args:Array<Dynamic>) {
		if (!hscriptMap.exists(name) || !hscriptMap.get(name).variables.exists(func)) {
			return FunkinLua.Function_Continue;
		}
		var method = hscriptMap.get(name).variables.get(func);
		var ret:Dynamic = null;
		//need a better way for this ;v;
		switch(args.length) {
			case 0:
				ret = method();
			case 1:
				ret = method(args[0]);
			case 2:
				ret = method(args[0], args[1]);
			case 3:
				ret = method(args[0], args[1], args[2]);
			case 4:
				ret = method(args[0], args[1], args[2], args[3]);
			case 5:
				ret = method(args[0], args[1], args[2], args[3], args[4]);
		}
		if (ret != null && ret != FunkinLua.Function_Continue) {
			return ret;
		}
		return FunkinLua.Function_Continue;
	}

	function postSetHscript() {
		setOnHscripts('boyfriend', boyfriend);
		setOnHscripts('dad', dad);
		setOnHscripts('gf', gf);
		setOnHscripts('strumLineNotes', strumLineNotes);
		setOnHscripts('playerStrums', playerStrums);
		setOnHscripts('opponentStrums', opponentStrums);
		setOnHscripts('iconP1', iconP1);
		setOnHscripts('iconP2', iconP2);
		setOnHscripts('grpNoteSplashes', grpNoteSplashes);
		setOnHscripts('scoreTxt', scoreTxt);
		setOnHscripts('ratingTxtGroup', ratingTxtGroup);
		setOnHscripts('healthBar', healthBar);
		setOnHscripts('healthBarBG', healthBarBG);
		setOnHscripts('botplayTxt', botplayTxt);
		setOnHscripts('practiceFailedTxt', practiceFailedTxt);
		setOnHscripts('timeBar', timeBar);
		setOnHscripts('timeBarBG', timeBarBG);
		setOnHscripts('timeTxt', timeTxt);
		setOnHscripts('boyfriendGroup', boyfriendGroup);
		setOnHscripts('dadGroup', dadGroup);
		setOnHscripts('gfGroup', gfGroup);
		setOnHscripts('underlayPlayer', underlayPlayer);
		setOnHscripts('underlayOpponent', underlayOpponent);
		setOnHscripts('camGame', camGame);
		setOnHscripts('camHUD', camHUD);
		setOnHscripts('camOther', camOther);
		setOnHscripts('camFollow', camFollow);
		setOnHscripts('camFollowPos', camFollowPos);
		setOnHscripts('strumLine', strumLine);
		setOnHscripts('notes', notes);
		setOnHscripts('unspawnNotes', unspawnNotes);
		setOnHscripts('eventNotes', eventNotes);
		setOnHscripts('vocals', vocals);
		setOnHscripts('vocalsDad', vocalsDad);
	}

	/*
	var modules:Array<String> = [];
	function setupModules() {
		var sexList:Array<String> = CoolUtil.coolTextFile(Paths.getPreloadPath('scripts/classes/classList.txt'));
		var filesPushed:Array<String> = [];
		for (script in sexList) {
			var file = Paths.getPreloadPath('scripts/classes/$script.hscript');
			if (OpenFlAssets.exists(file) && !filesPushed.contains(file))
			{
				modules.push(Paths.getContent(file));
				filesPushed.push(file);
			}
		}

		#if MODS_ALLOWED
		var foldersToCheck:Array<String> = [Paths.mods('scripts/classes/')];
		if (Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods('${Paths.currentModDirectory}/scripts/classes/'));

		for (folder in foldersToCheck)
		{
			if (FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if (file.endsWith('.hscript') && !filesPushed.contains(file))
					{
						modules.push(Paths.getContent(folder + file));
						filesPushed.push(folder + file);
					}
				}
			}
		}
		#end
	}
	*/
	#end

	function setOnHscripts(variable:String, arg:Dynamic) {
		#if HSCRIPT_ALLOWED
		for (i in hscriptMap.keys()) {
			hscriptMap.get(i).variables.set(variable, arg);
		}
		#end
	}

	function startCharacterScripts(name:String)
	{
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = 'characters/$name.lua';
		if (FileSystem.exists(Paths.modFolders(luaFile))) {
			luaFile = Paths.modFolders(luaFile);
			doPush = true;
		} else {
			luaFile = Paths.getPreloadPath(luaFile);
			if (FileSystem.exists(luaFile)) {
				doPush = true;
			}
		}
		
		if (doPush)
		{
			for (lua in luaArray)
			{
				if (lua.scriptName == luaFile) return;
			}
			luaArray.push(new FunkinLua(luaFile));
		}
		#end

		#if HSCRIPT_ALLOWED
		var doPush:Bool = false;
		var hscriptFile:String = 'characters/$name.hscript';
		#if MODS_ALLOWED
		if (FileSystem.exists(Paths.modFolders(hscriptFile))) {
			hscriptFile = Paths.modFolders(hscriptFile);
			doPush = true;
		} else {
		#end
			hscriptFile = Paths.getPreloadPath(hscriptFile);
			if (OpenFlAssets.exists(hscriptFile)) {
				doPush = true;
			}
		#if MODS_ALLOWED
		}
		#end
		
		if (doPush && !hscriptMap.exists(hscriptFile))
		{
			addHscript(hscriptFile);
		}
		#end
	}

	public function addShaderToCamera(cam:String,effect:ShaderEffect){//STOLE FROM ANDROMEDA
	  
	  
	  
		switch(cam.toLowerCase()) {
			case 'camhud' | 'hud':
					camHUDShaders.push(effect);
					var newCamEffects:Array<BitmapFilter>=[]; // IT SHUTS HAXE UP IDK WHY BUT WHATEVER IDK WHY I CANT JUST ARRAY<SHADERFILTER>
					for(i in camHUDShaders){
					  newCamEffects.push(new ShaderFilter(i.shader));
					}
					camHUD.setFilters(newCamEffects);
			case 'camother' | 'other':
					camOtherShaders.push(effect);
					var newCamEffects:Array<BitmapFilter>=[]; // IT SHUTS HAXE UP IDK WHY BUT WHATEVER IDK WHY I CANT JUST ARRAY<SHADERFILTER>
					for(i in camOtherShaders){
					  newCamEffects.push(new ShaderFilter(i.shader));
					}
					camOther.setFilters(newCamEffects);
			case 'camgame' | 'game':
					camGameShaders.push(effect);
					var newCamEffects:Array<BitmapFilter>=[]; // IT SHUTS HAXE UP IDK WHY BUT WHATEVER IDK WHY I CANT JUST ARRAY<SHADERFILTER>
					for(i in camGameShaders){
					  newCamEffects.push(new ShaderFilter(i.shader));
					}
					camGame.setFilters(newCamEffects);
			default:
				if(modchartSprites.exists(cam)) {
					Reflect.setProperty(modchartSprites.get(cam),"shader",effect.shader);
				} else if(modchartTexts.exists(cam)) {
					Reflect.setProperty(modchartTexts.get(cam),"shader",effect.shader);
				} else {
					var OBJ = Reflect.getProperty(PlayState.instance,cam);
					Reflect.setProperty(OBJ,"shader", effect.shader);
				}
			
			
				
				
		}
	  
	  
	  
	  
  }

  public function removeShaderFromCamera(cam:String,effect:ShaderEffect){
	  
	  
		switch(cam.toLowerCase()) {
			case 'camhud' | 'hud': 
    camHUDShaders.remove(effect);
    var newCamEffects:Array<BitmapFilter>=[];
    for(i in camHUDShaders){
      newCamEffects.push(new ShaderFilter(i.shader));
    }
    camHUD.setFilters(newCamEffects);
			case 'camother' | 'other': 
					camOtherShaders.remove(effect);
					var newCamEffects:Array<BitmapFilter>=[];
					for(i in camOtherShaders){
					  newCamEffects.push(new ShaderFilter(i.shader));
					}
					camOther.setFilters(newCamEffects);
			default: 
				camGameShaders.remove(effect);
				var newCamEffects:Array<BitmapFilter>=[];
				for(i in camGameShaders){
				  newCamEffects.push(new ShaderFilter(i.shader));
				}
				camGame.setFilters(newCamEffects);
		}
		
	  
  }
	
	
	
  public function clearShaderFromCamera(cam:String){
	  
	  
		switch(cam.toLowerCase()) {
			case 'camhud' | 'hud': 
				camHUDShaders = [];
				var newCamEffects:Array<BitmapFilter>=[];
				camHUD.setFilters(newCamEffects);
			case 'camother' | 'other': 
				camOtherShaders = [];
				var newCamEffects:Array<BitmapFilter>=[];
				camOther.setFilters(newCamEffects);
			default: 
				camGameShaders = [];
				var newCamEffects:Array<BitmapFilter>=[];
				camGame.setFilters(newCamEffects);
		}
		
	  
  }
	
	function startCharacterPos(char:Character, gfCheck:Bool = false) {
		if (gfCheck && char.curCharacter.startsWith('gf')) { //IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	function addCharacter(name:String, index:Int = 0, flipped:Bool = false, isPlayer:Bool = false, ?group:FlxTypedSpriteGroup<Character>, trailName:String = '', xOffset:Float = 0, yOffset:Float = 0, scrollX:Float = 1, scrollY:Float = 1):Character {
		var char = new Character(0, 0, name, flipped);
		char.isPlayer = isPlayer;
		startCharacterPos(char);
		char.x += xOffset;
		char.y += yOffset;
		char.scrollFactor.set(scrollX, scrollY);
		if (group != null) {
			group.add(char);
		}
		if (trailName != null && trailName.length > 0) {
			makeDoubleTrail(char, trailName, flipped, index, group);
		}
		return char;
	}

	public function startVideo(name:String):Void {
		#if VIDEOS_ALLOWED
		var foundFile:Bool = false;
		var fileName:String = #if MODS_ALLOWED Paths.modsVideo(name); #else ''; #end
		#if MODS_ALLOWED
		if (FileSystem.exists(fileName)) {
			foundFile = true;
		}
		#end

		if (!foundFile) {
			fileName = Paths.video(name);
			#if MODS_ALLOWED
			if (FileSystem.exists(fileName)) {
			#else
			if (OpenFlAssets.exists(fileName)) {
			#end
				foundFile = true;

			}
		}

		if (foundFile) {
			inCutscene = true;
			var bg = new FlxSprite(-FlxG.width, -FlxG.height).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
			bg.scrollFactor.set();
			bg.cameras = [camHUD];
			add(bg);

			(new FlxVideo(fileName)).finishCallback = function() {
				remove(bg);
				startAndEnd();
			}
			return;
		} else {
			FlxG.log.warn('Couldnt find video file: $fileName');
			startAndEnd();
			return;
		}
		#end
		startAndEnd();
	}

	function startAndEnd() {
		if (endingSong)
			endSong();
		else if (startingSong)
			startCountdown();
	}

	var dialogueCount:Int = 0;
	public var psychDialogue:DialogueBoxPsych;
	//You don't have to add a song, just saying. You can just do "startDialogue(dialogueJson);" and it should work
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		// TO DO: Make this more flexible, maybe?
		if (psychDialogue != null) return;

		if (dialogueFile.dialogue.length > 0) {
			inCutscene = true;
			CoolUtil.precacheSound('dialogue');
			CoolUtil.precacheSound('dialogueClose');
			psychDialogue = new DialogueBoxPsych(dialogueFile, song);
			psychDialogue.scrollFactor.set();
			if (endingSong) {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					endSong();
				}
			} else {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					startCountdown();
				}
			}
			psychDialogue.nextDialogueThing = startNextDialogue;
			psychDialogue.skipDialogueThing = skipDialogue;
			psychDialogue.cameras = [camHUD];
			add(psychDialogue);
		} else {
			FlxG.log.warn('Your dialogue file is badly formatted!');
			if (endingSong) {
				endSong();
			} else {
				startCountdown();
			}
		}
	}

	function schoolIntro(?dialogueBox:DialogueBox):Void
	{
		inCutscene = true;
		var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		add(black);

		var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();

		var senpaiEvil:FlxSprite = new FlxSprite();
		senpaiEvil.frames = Paths.getSparrowAtlas('weeb/senpaiCrazy');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();
		senpaiEvil.x += 300;

		if (curSong == 'roses' || curSong == 'thorns')
		{
			remove(black);

			if (curSong == 'thorns')
			{
				add(red);
				camHUD.visible = false;
			}
		}

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			black.alpha -= 0.15;

			if (black.alpha > 0)
			{
				tmr.reset(0.3);
			}
			else
			{
				if (dialogueBox != null)
				{
					if (curSong == 'thorns')
					{
						add(senpaiEvil);
						senpaiEvil.alpha = 0;
						new FlxTimer().start(0.3, function(swagTimer:FlxTimer)
						{
							senpaiEvil.alpha += 0.15;
							if (senpaiEvil.alpha < 1)
							{
								swagTimer.reset();
							}
							else
							{
								senpaiEvil.animation.play('idle');
								FlxG.sound.play(Paths.sound('Senpai_Dies'), 1, false, null, true, function()
								{
									remove(senpaiEvil);
									remove(red);
									FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function()
									{
										add(dialogueBox);
										camHUD.visible = true;
									}, true);
								});
								new FlxTimer().start(3.2, function(deadTime:FlxTimer)
								{
									FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
								});
							}
						});
					}
					else
					{
						add(dialogueBox);
					}
				}
				else
					startCountdown();

				remove(black);
			}
		});
	}

	var startTimer:FlxTimer;
	var endingTimer:FlxTimer = null;

	// For being able to mess with the sprites on Lua
	public var countdownReady:FlxSprite;
	public var countdownSet:FlxSprite;
	public var countdownGo:FlxSprite;
	public static var startOnTime:Float = 0;
	public var introSoundsSuffix = '';

	public function startCountdown():Void
	{
		if (startedCountdown) {
			callOnScripts('onStartCountdown', []);
			return;
		}

		inCutscene = false;
		var ret:Dynamic = callOnScripts('onStartCountdown', []);
		if (ret != FunkinLua.Function_Stop) {
			if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;

			generateStaticArrows(0, dadKeys);
			generateStaticArrows(1, bfKeys);
			switchKeys(bfKeys, dadKeys, true);
			for (i in 0...playerStrums.length) {
				setOnScripts('defaultPlayerStrumX$i', playerStrums.members[i].x);
				setOnScripts('defaultPlayerStrumY$i', playerStrums.members[i].y);
			}
			for (i in 0...opponentStrums.length) {
				setOnScripts('defaultOpponentStrumX$i', opponentStrums.members[i].x);
				setOnScripts('defaultOpponentStrumY$i', opponentStrums.members[i].y);
			}

			var modifiedCrochet:Float = Conductor.crochet * (Conductor.timeSignature[1] / 4); //slows or speeds up to mimic normal quarter notes

			startedCountdown = true;
			Conductor.songPosition = startPos;
			Conductor.songPosition -= modifiedCrochet * 5;
			setOnScripts('startedCountdown', true);
			callOnScripts('onCountdownStarted', []);

			var swagCounter:Int = 0;

			if (skipCountdown || startOnTime > 0) {
				clearNotesBefore(startOnTime - 500);
				setSongTime(startOnTime - 500);
				return;
			}
			startTimer = new FlxTimer().start(modifiedCrochet / 1000, function(tmr:FlxTimer)
			{
				if (!inEditor) {
					if (swagCounter < 4) {
						var chars = [boyfriendGroup, dadGroup];
						for (group in chars) {
							for (char in group) {
								if (char.danceEveryNumBeats > 0 && tmr.loopsLeft % Math.round(char.danceEveryNumBeats) == 0 && !char.stunned && char.animation.curAnim != null && !char.animation.curAnim.name.startsWith("sing") && !char.specialAnim)
								{
									char.dance();
								}
							}
						}

						// head bopping for bg characters on Mall
						if (curStage == 'mall' && ClientPrefs.gameQuality != 'Crappy') {
							if (ClientPrefs.gameQuality == 'Normal')
								upperBoppers.dance(true);
			
							bottomBoppers.dance(true);
							santa.dance(true);
						}
					}

					switch (swagCounter)
					{
						case 0:
							var introSuffix = !opponentChart ? uiSkinMap.get('player').introSoundsSuffix : uiSkinMap.get('opponent').introSoundsSuffix;
							if (introSoundsSuffix != null && introSoundsSuffix.length > 0) {
								introSuffix = introSoundsSuffix;
							}
							FlxG.sound.play(Paths.sound('intro3$introSuffix'), 0.6);
						case 1:
							var introSuffix = uiSkinMap.get('ready').introSoundsSuffix;
							if (introSoundsSuffix != null && introSoundsSuffix.length > 0) {
								introSuffix = introSoundsSuffix;
							}
							countdownReady = new FlxSprite().loadGraphic(Paths.image(UIData.checkImageFile('ready', uiSkinMap.get('ready'))));
							countdownReady.scrollFactor.set();
							countdownReady.updateHitbox();

							countdownReady.setGraphicSize(Std.int(countdownReady.width * uiSkinMap.get('ready').scale * uiSkinMap.get('ready').countdownScale));

							countdownReady.screenCenter();
							countdownReady.antialiasing = ClientPrefs.globalAntialiasing && !uiSkinMap.get('ready').noAntialiasing;
							countdownReady.cameras = [camHUD];
							insert(members.indexOf(strumLineNotes), countdownReady);
							FlxTween.tween(countdownReady, {alpha: 0}, modifiedCrochet / 1000, {
								ease: FlxEase.cubeInOut,
								onComplete: function(twn:FlxTween)
								{
									remove(countdownReady);
									countdownReady.destroy();
								}
							});
							FlxG.sound.play(Paths.sound('intro2$introSuffix'), 0.6);
						case 2:
							var introSuffix = uiSkinMap.get('set').introSoundsSuffix;
							if (introSoundsSuffix != null && introSoundsSuffix.length > 0) {
								introSuffix = introSoundsSuffix;
							}
							countdownSet = new FlxSprite().loadGraphic(Paths.image(UIData.checkImageFile('set', uiSkinMap.get('set'))));
							countdownSet.scrollFactor.set();

							countdownSet.setGraphicSize(Std.int(countdownSet.width * uiSkinMap.get('set').scale * uiSkinMap.get('set').countdownScale));

							countdownSet.screenCenter();
							countdownSet.antialiasing = ClientPrefs.globalAntialiasing && !uiSkinMap.get('set').noAntialiasing;
							countdownSet.cameras = [camHUD];
							insert(members.indexOf(strumLineNotes), countdownSet);
							FlxTween.tween(countdownSet, {alpha: 0}, modifiedCrochet / 1000, {
								ease: FlxEase.cubeInOut,
								onComplete: function(twn:FlxTween)
								{
									remove(countdownSet);
									countdownSet.destroy();
								}
							});
							FlxG.sound.play(Paths.sound('intro1$introSuffix'), 0.6);
						case 3:
							var introSuffix = uiSkinMap.get('go').introSoundsSuffix;
							if (introSoundsSuffix != null && introSoundsSuffix.length > 0) {
								introSuffix = introSoundsSuffix;
							}
							countdownGo = new FlxSprite().loadGraphic(Paths.image(UIData.checkImageFile('go', uiSkinMap.get('go'))));
							countdownGo.scrollFactor.set();

							countdownGo.setGraphicSize(Std.int(countdownGo.width * uiSkinMap.get('go').scale * uiSkinMap.get('go').countdownScale));

							countdownGo.updateHitbox();

							countdownGo.screenCenter();
							countdownGo.antialiasing = ClientPrefs.globalAntialiasing && !uiSkinMap.get('go').noAntialiasing;
							countdownGo.cameras = [camHUD];
							insert(members.indexOf(strumLineNotes), countdownGo);
							FlxTween.tween(countdownGo, {alpha: 0}, modifiedCrochet / 1000, {
								ease: FlxEase.cubeInOut,
								onComplete: function(twn:FlxTween)
								{
									remove(countdownGo);
									countdownGo.destroy();
								}
							});
							FlxG.sound.play(Paths.sound('introGo$introSuffix'), 0.6);
					}
				}

				notes.forEachAlive(function(note:Note) {
					note.copyAlpha = false;
					note.alpha = note.multAlpha;
					if (ClientPrefs.middleScroll && !note.mustPress) {
						note.alpha *= 0.5;
					}
				});
				callOnScripts('onCountdownTick', [swagCounter]);

				swagCounter += 1;
			}, 5);
		}
	}

	public function clearNotesBefore(time:Float)
	{
		var i:Int = unspawnNotes.length - 1;
		while (i >= 0) {
			var daNote:Note = unspawnNotes[i];
			if(daNote.strumTime < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				unspawnNotes.remove(daNote);
				daNote.destroy();
			}
			--i;
		}

		i = notes.length - 1;
		while (i >= 0) {
			var daNote:Note = notes.members[i];
			if(daNote.strumTime < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				notes.remove(daNote, true);
				daNote.destroy();
			}
			--i;
		}
	}

	public function setSongTime(time:Float)
	{
		if(time < 0) time = 0;

		FlxG.sound.music.pause();
		vocals.pause();
		vocalsDad.pause();

		FlxG.sound.music.time = time * playbackRate;
		FlxG.sound.music.play();

		vocals.time = time * playbackRate;
		vocals.play();
		vocalsDad.time = time * playbackRate;
		vocalsDad.play();
		Conductor.songPosition = time;

		updateCurStep();
		Conductor.getLastBPM(SONG, curStep, playbackRate);
	}

	function startNextDialogue() {
		dialogueCount++;
		callOnScripts('onNextDialogue', [dialogueCount]);
	}

	function skipDialogue() {
		callOnScripts('onSkipDialogue', [dialogueCount]);
	}

	function startSong():Void
	{
		startingSong = false;

		FlxG.sound.playMusic(Paths.inst(curSong), ClientPrefs.instVolume, false);
		FlxG.sound.music.onComplete = onSongComplete;
		FlxG.sound.music.time = startPos;
		vocals.time = startPos;
		vocals.play();
		vocals.volume = ClientPrefs.voicesVolume;
		vocalsDad.time = startPos;
		vocalsDad.play();
		vocalsDad.volume = ClientPrefs.voicesVolume;

		if(startOnTime > 0)
		{
			setSongTime(startOnTime - 500);
		}
		startOnTime = 0;

		if (paused) {
			FlxG.sound.music.pause();
			vocals.pause();
			vocalsDad.pause();
		}

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length / playbackRate;
		if (!inEditor) {
			FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
			if (ClientPrefs.timeBarType != 'Song Name' && deathCounter < 1) {
				FlxTween.tween(songTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut, onComplete: function(twn:FlxTween) {
					var startDelay = ((Conductor.crochet / 1000) * (Conductor.timeSignature[0] * 2) * (Conductor.timeSignature[1] / 4)) - 0.5;
					FlxTween.tween(songTxt, {alpha: 0}, 0.5, {ease: FlxEase.circOut, startDelay: startDelay});
					FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut, startDelay: startDelay});
				}});
			} else {
				FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
			}
		
			#if DISCORD_ALLOWED
			// Updating Discord Rich Presence (with Time Left)
			DiscordClient.changePresence(detailsText, '${SONG.song} ($storyDifficultyText)', iconP2.getCharacter(), true, songLength);
			#end
		}
		setOnScripts('songLength', songLength);
		callOnScripts('onSongStart', []);
	}

	private var noteTypeMap:Map<String, Bool> = new Map();
	private var eventPushedMap:Map<String, Bool> = new Map();
	private function generateSong():Void
	{
		if (!inEditor) {
			songSpeedType = ClientPrefs.getGameplaySetting('scrolltype','multiplicative');

			switch(songSpeedType)
			{
				case "multiplicative":
					songSpeed = Math.min(SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * playbackRate, Math.max(SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1), 3)); //dont wanna be too fast
				case "constant":
					songSpeed = ClientPrefs.getGameplaySetting('scrollspeed', 1);
			}
		} else {
			songSpeed = SONG.speed;
		}
		
		Conductor.changeBPM(SONG.bpm, playbackRate);
		Conductor.changeSignature(SONG.timeSignature);

		if (SONG.needsVoices) {
			vocals = new FlxSound().loadEmbedded(Paths.voices(curSong));

			vocalsDad = new FlxSound();
			var suffix = 'Dad';
			if (Paths.fileExists('$curSong/VoicesOpponent.${Paths.SOUND_EXT}', MUSIC, false, 'songs'))
			{
				suffix = 'Opponent';
			}
			if (Paths.fileExists('$curSong/Voices$suffix.${Paths.SOUND_EXT}', MUSIC, false, 'songs')) {
				var file = Paths.voices(curSong, suffix);
				if (file != null) {
					foundDadVocals = true;
					vocalsDad.loadEmbedded(file);
				}
			}
		} else {
			vocals = new FlxSound();
			vocalsDad = new FlxSound();
		}

		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(vocalsDad);
		FlxG.sound.list.add(new FlxSound().loadEmbedded(Paths.inst(curSong)));

		if (members.indexOf(notes) < 0) {
			notes = new FlxTypedGroup<Note>();
			add(notes);
			hideInDemoMode.push(notes);
		}
		for (i in notes) {
			i.kill();
			notes.remove(i);
			i.destroy();
		}
		unspawnNotes = [];

		var noteData:Array<SwagSection> = SONG.notes;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped
		
		if (!inEditor) {
			if (Paths.fileExists('data/$curSong/events.json', TEXT)) {
				var eventsData:Array<Dynamic> = Song.loadFromJson('events', curSong).events;
				for (event in eventsData) //Event Notes
				{
					for (i in 0...event[1].length)
					{
						var newEventNote:Array<Dynamic> = [event[0] / playbackRate, event[1][i][0], event[1][i][1], event[1][i][2]];
						var subEvent:EventNote = {
							strumTime: newEventNote[0] + ClientPrefs.noteOffset,
							event: newEventNote[1],
							value1: newEventNote[2],
							value2: newEventNote[3]
						};
						subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
						eventNotes.push(subEvent);
						eventPushed(subEvent);
					}
				}
			}
		}

		var curStepCrochet = Conductor.stepCrochet;
		var curBPM = Conductor.bpm;
		var curDenominator = Conductor.timeSignature[1];
		var curPlayerKeys = SONG.playerKeyAmount;
		var curOpponentKeys = SONG.opponentKeyAmount;
		for (section in noteData)
		{
			if (section.changeBPM) {
				curBPM = section.bpm * playbackRate;
				curStepCrochet = (((60 / curBPM) * 4000) / curDenominator) / 4;
			}
			if (section.changeSignature) {
				curDenominator = section.timeSignature[1];
				curStepCrochet = (((60 / curBPM) * 4000) / curDenominator) / 4;
			}
			if (section.changeKeys) {
				curOpponentKeys = section.opponentKeys;
				curPlayerKeys = section.playerKeys;
				if (!opponentStrumMap.exists(curOpponentKeys))
					generateStaticArrows(0, curOpponentKeys);
				if (!playerStrumMap.exists(curPlayerKeys))
					generateStaticArrows(1, curPlayerKeys);
			}
			var leftKeys = (section.mustHitSection ? curPlayerKeys : curOpponentKeys);
			var rightKeys = (!section.mustHitSection ? curPlayerKeys : curOpponentKeys);
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0] / playbackRate;
				if (inEditor && daStrumTime < startPos) continue;
				var daNoteData:Int = Std.int(songNotes[1] % leftKeys);
				if (songNotes[1] >= leftKeys) {
					daNoteData = Std.int((songNotes[1] - leftKeys) % rightKeys);
				}

				gottaHitNote = section.mustHitSection;

				if (songNotes[1] >= leftKeys)
				{
					gottaHitNote = !gottaHitNote;
				}
				var isOpponent:Bool = !gottaHitNote;

				if (opponentChart) {
					gottaHitNote = !gottaHitNote;
				}

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[unspawnNotes.length - 1];
				else
					oldNote = null;

				var keys = curPlayerKeys;
				if (isOpponent) keys = curOpponentKeys;

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote, false, false, keys, !isOpponent ? uiSkinMap.get('player') : uiSkinMap.get('opponent'), curStepCrochet);
				swagNote.mustPress = gottaHitNote;
				swagNote.isOpponent = isOpponent;
				swagNote.sustainLength = songNotes[2] / playbackRate;
				swagNote.gfNote = (section.gfSection && (songNotes[1] < rightKeys));
				swagNote.characters = songNotes[4];
				if (songNotes[4] == null) swagNote.characters = [0];
				swagNote.noteType = songNotes[3];
				swagNote.scrollFactor.set();
				unspawnNotes.push(swagNote);

				var susLength:Float = swagNote.sustainLength / curStepCrochet;
				var floorSus:Int = Math.floor(susLength);
				if (floorSus > 0) {
					for (susNote in 0...floorSus + 1)
					{
						oldNote = unspawnNotes[unspawnNotes.length - 1];
						var ogStrum = daStrumTime + (curStepCrochet * susNote);

						var sustainNote:Note = new Note(ogStrum + (curStepCrochet / 2 / swagNote.speed), daNoteData, oldNote, true, false, keys, !isOpponent ? uiSkinMap.get('player') : uiSkinMap.get('opponent'), curStepCrochet);
						sustainNote.mustPress = gottaHitNote;
						sustainNote.isOpponent = isOpponent;
						sustainNote.gfNote = swagNote.gfNote;
						sustainNote.characters = songNotes[4];
						if (songNotes[4] == null) sustainNote.characters = [0];
						sustainNote.noteType = swagNote.noteType;
						sustainNote.ogStrumTime = ogStrum;
						sustainNote.scrollFactor.set();
						unspawnNotes.push(sustainNote);

						if (!sustainNote.isOpponent)
						{
							sustainNote.x += FlxG.width / 2; // general offset
						}
					}
				}

				if (!swagNote.isOpponent)
				{
					swagNote.x += FlxG.width / 2; // general offset
				}

				if (!noteTypeMap.exists(swagNote.noteType)) {
					noteTypeMap.set(swagNote.noteType, true);
				}
			}
			daBeats += 1;
		}
		if (!inEditor) {
			for (event in SONG.events) //Event Notes
			{
				for (i in 0...event[1].length)
				{
					var newEventNote:Array<Dynamic> = [event[0] / playbackRate, event[1][i][0], event[1][i][1], event[1][i][2]];
					var subEvent:EventNote = {
						strumTime: newEventNote[0] + ClientPrefs.noteOffset,
						event: newEventNote[1],
						value1: newEventNote[2],
						value2: newEventNote[3]
					};
					subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
					eventNotes.push(subEvent);
					eventPushed(subEvent);
				}
			}
		}

		unspawnNotes.sort(sortByShit);
		if (eventNotes.length > 1) { //No need to sort if there's a single one or none at all
			eventNotes.sort(sortByTime);
		}
		if (!inEditor) {
			checkEventNote();
		}
		generatedMusic = true;
	}

	function eventPushed(event:EventNote) {
		switch(event.event) {
			case 'Change Character':
				var charData:Array<String> = event.value1.split(',');
				var charType:Int = 0;
				var index = 0;
				switch(charData[0].toLowerCase()) {
					case 'gf' | 'girlfriend' | '2':
						charType = 2;
					case 'dad' | 'opponent' | '1':
						charType = 1;
				}
				if (charData[1] != null) index = Std.parseInt(charData[1]);

				var newCharacter:String = event.value2;
				addCharacterToList(newCharacter, charType, index);
		}

		if (!eventPushedMap.exists(event.event)) {
			eventPushedMap.set(event.event, true);
		}

		callOnScripts('eventPushed', [event.event, event.strumTime, event.value1, event.value2]);
	}

	function eventNoteEarlyTrigger(event:EventNote):Float {
		var returnedValue:Dynamic = callOnScripts('eventEarlyTrigger', [event.event]);
		if (returnedValue != 0) {
			return returnedValue;
		}

		switch(event.event) {
			case 'Kill Henchmen': //Better timing so that the kill sound matches the beat intended
				return 280; //Plays 280ms before the actual position
		}
		return 0;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	function sortByTime(Obj1:EventNote, Obj2:EventNote):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	public var skipArrowStartTween:Bool = false; //for lua
	private function generateStaticArrows(player:Int, keys:Int = 4):Void
	{
		var strumGroup = new FlxTypedGroup<StrumNote>();
		var underlay = underlayPlayer;
		if (player == 0) {
			underlay = underlayOpponent;
		}

		var delay = (Conductor.crochet * (Conductor.timeSignature[1] / 4)) / (250 * keys);

		for (i in 0...keys)
		{
			var targetAlpha:Float = 1;
			if ((player < 1 && ClientPrefs.middleScroll && !opponentChart) || (player > 0 && ClientPrefs.middleScroll && opponentChart)) targetAlpha = 0.35;

			var babyArrow:StrumNote = new StrumNote(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, strumLine.y, i, ClientPrefs.middleScroll && opponentChart ? 1 - player : player, keys, player > 0 ? uiSkinMap.get('player') : uiSkinMap.get('opponent'));
			babyArrow.y += 80 - (babyArrow.height / 2);
			babyArrow.downScroll = ClientPrefs.downScroll;
			if (!isStoryMode && !inEditor && !skipArrowStartTween)
			{
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {alpha: targetAlpha}, delay, {ease: FlxEase.circOut, startDelay: delay * (i + 1)});
			}
			else
			{
				babyArrow.alpha = targetAlpha;
			}

			if (player == 1)
			{
				if (ClientPrefs.middleScroll && opponentChart)
				{
					babyArrow.x = STRUM_X_MIDDLESCROLL + 310;
					if (i >= Math.floor(keys / 2)) {
						babyArrow.x += FlxG.width / 2 + 25;
					}
				}
			}
			else
			{
				if (ClientPrefs.middleScroll && !opponentChart)
				{
					babyArrow.x += 310;
					if (i >= Math.floor(keys / 2)) {
						babyArrow.x += FlxG.width / 2 + 25;
					}
				}
			}

			strumGroup.add(babyArrow);
			babyArrow.postAddedToGroup();
		}

		if (player == 0) {
			opponentStrumMap.set(keys, strumGroup);
		} else {
			playerStrumMap.set(keys, strumGroup);
		}
	}

	function resetUnderlay(underlay:FlxSprite, strums:FlxTypedGroup<StrumNote>) {
		var fullWidth = 0.0;
		for (i in 0...strums.members.length) {
			if (i == strums.members.length - 1) {
				fullWidth += strums.members[i].width;
			} else {
				fullWidth += strums.members[i].swagWidth;
			}
		}
		underlay.makeGraphic(Math.ceil(fullWidth), FlxG.height * 2, FlxColor.BLACK);
		underlay.x = strums.members[0].x;
		underlay.visible = true;
	}

	function setKeysArray(keys:Int = 4) {
		keysArray = [];
		for (i in 0...keys) {
			keysArray.push(ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note${keys}_$i')));
		}

		// For the "Just the Two of Us" achievement
		keysPressed = [];
		for (i in 0...keysArray.length)
		{
			keysPressed.push(false);
		}
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
				vocalsDad.pause();
			}

			if (startTimer != null && !startTimer.finished)
				startTimer.active = false;
			if (endingTimer != null && !endingTimer.finished)
				endingTimer.active = false;
			if (songSpeedTween != null)
				songSpeedTween.active = false;

			if (blammedLightsBlackTween != null)
				blammedLightsBlackTween.active = false;
			if (phillyCityLightsEventTween != null)
				phillyCityLightsEventTween.active = false;

			if (carTimer != null) carTimer.active = false;

			var chars = [boyfriendGroup, gfGroup, dadGroup];
			for (i in 0...chars.length) {
				for (char in chars[i]) {
					if (char.colorTween != null) {
						char.colorTween.active = false;
					}
				}
			}

			for (tween in modchartTweens) {
				tween.active = false;
			}
			for (timer in modchartTimers) {
				timer.active = false;
			}
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
			{
				resyncVocals(true);
			}

			if (startTimer != null && !startTimer.finished)
				startTimer.active = true;
			if (endingTimer != null && !endingTimer.finished)
				endingTimer.active = true;
			if (songSpeedTween != null)
				songSpeedTween.active = true;

			if (blammedLightsBlackTween != null)
				blammedLightsBlackTween.active = true;
			if (phillyCityLightsEventTween != null)
				phillyCityLightsEventTween.active = true;
			
			if (carTimer != null) carTimer.active = true;

			var chars = [boyfriendGroup, gfGroup, dadGroup];
			for (i in 0...chars.length) {
				for (char in chars[i]) {
					if (char.colorTween != null) {
						char.colorTween.active = true;
					}
				}
			}
			
			for (tween in modchartTweens) {
				tween.active = true;
			}
			for (timer in modchartTimers) {
				timer.active = true;
			}
			paused = false;
			persistentUpdate = true;
			callOnScripts('onResume', []);

			#if DISCORD_ALLOWED
			if (startTimer != null && startTimer.finished)
			{
				DiscordClient.changePresence(detailsText, '${SONG.song} ($storyDifficultyText)', iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, '${SONG.song} ($storyDifficultyText)', iconP2.getCharacter());
			}
			#end
		}

		super.closeSubState();
	}

	override public function onFocus():Void
	{
		if (!isDead && !paused)
		{
			if (FlxG.sound.music != null && !startingSong && !endingSong)
			{
				resyncVocals(true);
			}
			#if DISCORD_ALLOWED
			if (!inEditor) {
				if (Conductor.songPosition > 0.0)
				{
					DiscordClient.changePresence(detailsText, '${SONG.song} ($storyDifficultyText)', iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
				}
				else
				{
					DiscordClient.changePresence(detailsText, '${SONG.song} ($storyDifficultyText)', iconP2.getCharacter());
				}
			}
			#end
		}

		super.onFocus();
	}
	
	override public function onFocusLost():Void
	{
		if (!isDead && !paused && !inEditor) {
			if (ClientPrefs.focusLostPause) {
				pauseGame(false);
				FlxG.sound.music.pause();
				vocals.pause();
				vocalsDad.pause();
			}

			#if DISCORD_ALLOWED
			DiscordClient.changePresence(detailsPausedText, '${SONG.song} ($storyDifficultyText)', iconP2.getCharacter());
			#end
		}

		super.onFocusLost();
	}

	function resyncVocals(forcePlay:Bool = false):Void
	{
		if (FlxG.sound.music == null || vocals == null || startingSong || endingSong || endingTimer != null) return;

		vocals.pause();
		vocalsDad.pause();

		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time / playbackRate;
		if (Conductor.songPosition * playbackRate <= vocals.length || forcePlay) {
			vocals.time = Conductor.songPosition * playbackRate;
			vocals.play();
		}
		if (Conductor.songPosition * playbackRate <= vocalsDad.length || forcePlay) {
			vocalsDad.time = Conductor.songPosition * playbackRate;
			vocalsDad.play();
		}
	}

	public var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;
	var limoSpeed:Float = 0;
	var skipCutsceneHold:Float = 0;

	override public function update(elapsed:Float)
	{
		callOnScripts('onUpdate', [elapsed]);

		modifiedCrochet = Conductor.crochet * (Conductor.timeSignature[1] / 4);


		if (!inEditor) {
			#if (VIDEOS_ALLOWED && desktop)
			//STOLEN FROM VS PSYCHIC
			var video = FlxVideo.vlcBitmap;
			if(video != null)
			{
				if(FlxG.keys.pressed.ANY)
				{
					skipCutsceneHold += elapsed;
					FlxVideo.skipText.alpha = 0.25 + skipCutsceneHold * 0.75;
					if (skipCutsceneHold > 1)
					{
						callOnScripts('onSkipCutscene', []);
						if(video.onComplete != null)
							video.onComplete();

						skipCutsceneHold = 0;
					}
				}
				else
				{
					FlxVideo.skipText.alpha = 0;
					skipCutsceneHold = 0;
				}
			}
			/*if (controls.ACCEPT && ClientPrefs.skipIntro)
			{
				video = null;
			}*/
			#end

			if (FlxG.keys.justPressed.NINE)
			{
				iconP1.swapOldIcon();
			}

			if (ClientPrefs.gameQuality != 'Crappy') {
				switch (curStage)
				{
					case 'schoolEvil':
						if (ClientPrefs.gameQuality == 'Normal' && bgGhouls.animation.curAnim.finished) {
							bgGhouls.visible = false;
						}
					case 'philly':
						if (trainMoving)
						{
							trainFrameTiming += elapsed;

							if (trainFrameTiming >= 1 / 24)
							{
								updateTrainPos();
								trainFrameTiming = 0;
							}
						}
						phillyCityLights.members[curLight].alpha -= (Conductor.crochet * (Conductor.timeSignature[1] / 4) / 1000) * FlxG.elapsed * 1.5;
						case 'limo':
							if (ClientPrefs.gameQuality == 'Normal') {
								grpLimoParticles.forEach(function(spr:BGSprite) {
									if (spr.animation.curAnim.finished) {
										spr.kill();
										grpLimoParticles.remove(spr, true);
										spr.destroy();
									}
								});
	
								switch(limoKillingState) {
									case 1:
										limoMetalPole.x += 5000 * elapsed;
										limoLight.x = limoMetalPole.x - 180;
										limoCorpse.x = limoLight.x - 50;
										limoCorpseTwo.x = limoLight.x + 35;
	
										var dancers:Array<BackgroundDancer> = grpLimoDancers.members;
										for (i in 0...dancers.length) {
											if (dancers[i].x < FlxG.width * 1.5 && limoLight.x > (370 * i) + 130) {
												switch(i) {
													case 0 | 3:
														if (i == 0) FlxG.sound.play(Paths.sound('dancerdeath'), 0.5);
	
														var diffStr:String = i == 3 ? ' 2 ' : ' ';
														var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x + 200, dancers[i].y, 0.4, 0.4, ['hench leg spin${diffStr}PINK'], false);
														grpLimoParticles.add(particle);
														var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x + 160, dancers[i].y + 200, 0.4, 0.4, ['hench arm spin${diffStr}PINK'], false);
														grpLimoParticles.add(particle);
														var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x, dancers[i].y + 50, 0.4, 0.4, ['hench head spin${diffStr}PINK'], false);
														grpLimoParticles.add(particle);
	
														var particle:BGSprite = new BGSprite('gore/stupidBlood', dancers[i].x - 110, dancers[i].y + 20, 0.4, 0.4, ['blood'], false);
														particle.flipX = true;
														particle.angle = -57.5;
														grpLimoParticles.add(particle);
													case 1:
														limoCorpse.visible = true;
													case 2:
														limoCorpseTwo.visible = true;
												} //Note: Nobody cares about the fifth dancer because he is mostly hidden offscreen :(
												dancers[i].x += FlxG.width * 2;
											}
										}
	
										if (limoMetalPole.x > FlxG.width * 2) {
											resetLimoKill();
											limoSpeed = 800;
											limoKillingState = 2;
										}
	
									case 2:
										limoSpeed -= 4000 * elapsed;
										bgLimo.x -= limoSpeed * elapsed;
										if (bgLimo.x > FlxG.width * 1.5) {
											limoSpeed = 3000;
											limoKillingState = 3;
										}
	
									case 3:
										limoSpeed -= 2000 * elapsed;
										if (limoSpeed < 1000) limoSpeed = 1000;
	
										bgLimo.x -= limoSpeed * elapsed;
										if (bgLimo.x < -275) {
											limoKillingState = 4;
											limoSpeed = 800;
										}
	
									case 4:
										bgLimo.x = FlxMath.lerp(bgLimo.x, -150, CoolUtil.boundTo(elapsed * 9, 0, 1));
										if (Math.round(bgLimo.x) == -150) {
											bgLimo.x = -150;
											limoKillingState = 0;
										}
								}
	
								if (limoKillingState > 2) {
									var dancers:Array<BackgroundDancer> = grpLimoDancers.members;
									for (i in 0...dancers.length) {
										dancers[i].x = (370 * i) + bgLimo.x + 280;
									}
								}
							}
					case 'mall':
						if (heyTimer > 0) {
							heyTimer -= elapsed;
							if (heyTimer <= 0) {
								bottomBoppers.dance(true);
								heyTimer = 0;
							}
						}
				}
			}

			if (!inCutscene) {
				var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4 * cameraSpeed, 0, 1);
				camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
				if (!startingSong && !endingSong && boyfriend.animation.curAnim != null && (boyfriend.animation.curAnim.name.startsWith('idle') || boyfriend.animation.curAnim.name.startsWith('dance'))) {
					boyfriendIdleTime += elapsed;
					if (boyfriendIdleTime >= 0.15) { // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
						boyfriendIdled = true;
					}
				} else {
					boyfriendIdleTime = 0;
				}
			}
		} else {
			if (FlxG.keys.justPressed.ESCAPE)
			{
				FlxG.sound.music.pause();
				vocals.pause();
				vocalsDad.pause();
				LoadingState.loadAndSwitchState(new editors.ChartingState());
			}
		}

		super.update(elapsed);

		var curSection = Conductor.getCurSection(SONG, curStep);
		if (!inEditor && generatedMusic && SONG.notes[curSection] != null && !endingSong && !isCameraOnForcedPos)
		{
			moveCameraSection(curSection);

		}

		if (!inEditor) {
			if (botplayTxt.visible) {
				botplaySine += 180 * elapsed;
				botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
			}

			if (controls.PAUSE && startedCountdown && canPause)
			{
				var ret:Dynamic = callOnScripts('onPause', []);
				if (ret != FunkinLua.Function_Stop) {
					pauseGame();
				}
			}

			if (FlxG.keys.anyJustPressed(debugKeysChart) && !endingSong && !inCutscene)
			{
				var ret:Dynamic = callOnScripts('onOpenChartEditor', []);
				if (ret != FunkinLua.Function_Stop) {
					openChartEditor();
				}
			}

			if (ClientPrefs.smoothHealth) {
				shownHealth = FlxMath.lerp(shownHealth, health, CoolUtil.boundTo(elapsed * 7, 0, 1));
			} else {
				shownHealth = health;
			}

			var mult:Float = FlxMath.lerp(1, iconP1.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
			iconP1.scale.set(mult, mult);
			iconP1.updateHitbox();

			var mult:Float = FlxMath.lerp(1, iconP2.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
			iconP2.scale.set(mult, mult);
			iconP2.updateHitbox();

			var iconOffset:Int = 26;
			var division:Float = 1 / healthBar.numDivisions;

			if (!opponentChart) {
				iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, healthBar.numDivisions, 0) * division)) + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
				iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, healthBar.numDivisions, 0) * division)) - (150 * iconP2.scale.x) / 2 - iconOffset * 2;
			} else {
				iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 0, healthBar.numDivisions) * division)) + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
				iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 0, healthBar.numDivisions) * division)) - (150 * iconP2.scale.x) / 2 - iconOffset * 2;
			}


			// NEW HEALTH SYSTEM (actually old now)
			if (health > 2)
				health = 2;
			var stupidIcons:Array<HealthIcon> = [iconP1, iconP2];
			if (opponentChart) stupidIcons = [iconP2, iconP1];
			var playerIcon:HealthIcon = stupidIcons[0]; // i just mess up sometimes
			var opponentIcon:HealthIcon = stupidIcons[1];
			if (healthBar.percent < 20)
				playerIcon.changeIcon(playerIcon.char, 'lose');
			else if (healthBar.percent > 80)
				playerIcon.changeIcon(playerIcon.char, 'win');
			else
				playerIcon.changeIcon(playerIcon.char, 'default');

			if (healthBar.percent > 80)
				opponentIcon.changeIcon(opponentIcon.char, 'win');
			else if (healthBar.percent < 20)
				opponentIcon.changeIcon(opponentIcon.char, 'lose');
			else
				opponentIcon.changeIcon(opponentIcon.char, 'default');

			// real

			if (healthBar.percent > 80) {
				scoreTxt.color = 0x09ff00;
			}
			else if (healthBar.percent < 20) {
				scoreTxt.color = 0xff0000;
			}
			else {
				scoreTxt.color = 0xffffff;
			}

			#if desktop
			if (FlxG.keys.anyJustPressed(debugKeysCharacter) && !endingSong && !inCutscene) {
				var ret:Dynamic = callOnScripts('onOpenCharacterEditor', []);
				if (ret != FunkinLua.Function_Stop) {
					persistentUpdate = false;
					paused = true;
					cancelMusicFadeTween();
					SONG = originalSong;
					MusicBeatState.switchState(new CharacterEditorState(dad.curCharacter));
				}
			}
			#end
		}

		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += FlxG.elapsed * 1000;
				if (Conductor.songPosition >= startPos) {
					startSong();
					FlxG.sound.music.time = vocals.time = vocalsDad.time = Conductor.songPosition * playbackRate;
				}
			}
		}
		else
		{
			Conductor.songPosition += FlxG.elapsed * 1000;

			if (!paused && !inEditor)
			{
				if (updateTime) {
					var curTime:Float = Conductor.songPosition - ClientPrefs.noteOffset;
					if (curTime < 0) curTime = 0;
					songPercent = (curTime / songLength);

					var songCalc:Float = (songLength - curTime);
					if (ClientPrefs.timeBarType == 'Time Elapsed') songCalc = curTime;

					var secondsTotal:Int = Math.floor(songCalc / 1000);
					if (secondsTotal < 0) secondsTotal = 0;

					if (ClientPrefs.timeBarType != 'Song Name')
						timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
				}
			}
		}

		if (!inEditor) {
			if (camZooming)
			{
				FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
				camHUD.zoom = FlxMath.lerp(defaultCamHudZoom, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
			}

			FlxG.watch.addQuick("beatShit", curBeat);
			FlxG.watch.addQuick("stepShit", curStep);

			// RESET = Quick Game Over Screen
			if (!ClientPrefs.noReset && controls.RESET && !inCutscene && !endingSong)
			{
				health = 0;
				trace("RESET = True");
			}
			doDeathCheck();
		}

		if (unspawnNotes[0] != null)
		{
			var time:Float = 3000;//shit be werid on 4:3
			if (unspawnNotes[0].speed < 1) time /= unspawnNotes[0].speed;
			if (!inEditor) time /= camHUD.zoom;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.insert(0, dunceNote);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic)
		{
			if (!inCutscene) {
				if (!cpuControlled) {
					keyShit();
				}

				if (!inEditor) {
					for (char in playerChar) {
						if (!FlxG.keys.anyPressed(char.keysPressed) && char.holdTimer > Conductor.stepCrochet * 0.001 * char.singDuration * (Conductor.timeSignature[1] / 4) && char.animation.curAnim != null && char.animation.curAnim.name.startsWith('sing') && !char.animation.curAnim.name.endsWith('miss')) {
							char.dance();
						}
					}
				}
			}
			
			notes.forEachAlive(function(daNote:Note)
			{
				var strumGroup = playerStrums;
				if (daNote.isOpponent) strumGroup = opponentStrums;

				if (daNote.keyAmount != strumGroup.members.length) {
					if (daNote.isOpponent) {
						strumGroup = opponentStrumMap.get(daNote.keyAmount);
					} else {
						strumGroup = playerStrumMap.get(daNote.keyAmount);
					}
				}

				if (strumGroup != null && strumGroup.members[daNote.noteData] != null) {
					var strumX:Float = strumGroup.members[daNote.noteData].x;
					var strumY:Float = strumGroup.members[daNote.noteData].y;
					var strumAngle:Float = strumGroup.members[daNote.noteData].angle;
					var strumDirection:Float = strumGroup.members[daNote.noteData].direction;
					var strumAlpha:Float = strumGroup.members[daNote.noteData].alpha;
					var strumScroll:Bool = strumGroup.members[daNote.noteData].downScroll;
					var strumHeight:Float = strumGroup.members[daNote.noteData].height;

					strumX += daNote.offsetX;
					strumY += daNote.offsetY;
					strumAngle += daNote.offsetAngle;
					strumAlpha *= daNote.multAlpha;
					if (daNote.tooLate) strumAlpha * 0.3;

					if (strumScroll) //Downscroll
					{
						daNote.distance = (0.45 * (Conductor.songPosition - daNote.strumTime) * daNote.speed);
					}
					else //Upscroll
					{
						daNote.distance = (-0.45 * (Conductor.songPosition - daNote.strumTime) * daNote.speed);
					}

					var angleDir = strumDirection * Math.PI / 180;
					if (daNote.copyAngle)
						daNote.angle = strumDirection - 90 + strumAngle;

					if (daNote.copyAlpha)
						daNote.alpha = strumAlpha;

					if (daNote.copyScale) {
						daNote.scale.x = strumGroup.members[daNote.noteData].scale.x;
						if (!daNote.isSustainNote) {
							daNote.scale.y = strumGroup.members[daNote.noteData].scale.y;
						}
					}
					
					if (daNote.copyX)
						daNote.x = strumX + Math.cos(angleDir) * daNote.distance;

					if (daNote.copyY) {
						daNote.y = strumY + Math.sin(angleDir) * daNote.distance;

						if (daNote.isSustainNote && strumScroll) {
							if (daNote.animation.curAnim.name.endsWith('end')) {
								daNote.y += 10.5 * (daNote.stepCrochet * 4 / 400) * 1.5 * daNote.speed + (46 * (daNote.speed - 1));
								daNote.y -= 46 * (1 - (daNote.stepCrochet * 4 / 600)) * daNote.speed;
								daNote.y += daNote.uiSkin.downscrollTailYOffset;
							}
							
							daNote.y += (strumHeight / 2) - (60.5 * (daNote.speed - 1));
							daNote.y += 27.5 * ((Conductor.bpm / 100) - 1) * (daNote.speed - 1);
						}
					}

					if (!daNote.mustPress && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
					{
						opponentNoteHit(daNote);
					}

					if (cpuControlled && daNote.mustPress && !daNote.ignoreNote && !daNote.hitCausesMiss) {
						if (daNote.isSustainNote) {
							if (daNote.canBeHit) {
								goodNoteHit(daNote);
							}
						} else if (daNote.strumTime <= Conductor.songPosition) {
							goodNoteHit(daNote);
						}
					}

					var center:Float = strumY + strumHeight / 2;
					if (strumGroup.members[daNote.noteData].sustainReduce && daNote.isSustainNote && (daNote.mustPress || !daNote.ignoreNote) &&
						(!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
					{
						if (strumScroll)
						{
							if (daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center)
							{
								var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
								swagRect.height = (center - daNote.y) / daNote.scale.y;
								swagRect.y = daNote.frameHeight - swagRect.height;

								daNote.clipRect = swagRect;
							}
						}
						else
						{
							if (daNote.y + daNote.offset.y * daNote.scale.y <= center)
							{
								var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
								swagRect.y = (center - daNote.y) / daNote.scale.y;
								swagRect.height -= swagRect.y;

								daNote.clipRect = swagRect;
							}
						}
					}

					// Kill extremely late notes and cause misses
					if (Conductor.songPosition > (350 / daNote.speed) + daNote.strumTime)
					{
						if (daNote.mustPress && !cpuControlled && !daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit)) {
							noteMiss(daNote);
						}

						daNote.active = false;
						daNote.visible = false;

						daNote.kill();
						notes.remove(daNote, true);
						daNote.destroy();
					}
				}
			});
		}
		if (!inEditor) checkEventNote();

		if (ratingName == '?') {
			scoreTxt.text = 'Score: $songScore' + (!ClientPrefs.showRatings ? ' | Misses: $songMisses' : '') + ' | Rating: $ratingName';
		} else {
			scoreTxt.text = 'Score: $songScore' + (!ClientPrefs.showRatings ? ' | Misses: $songMisses' : '') + ' | Rating: $ratingName (${Highscore.floorDecimal(ratingPercent * 100, 2)}%) - $ratingFC';//peeps wanted no integer rating
		}
		for (i in 0...ratingTxtGroup.members.length) {
			var rating = ratingTxtGroup.members[i];
			switch (i) {
				case 0:
					rating.text = 'Sick!: $sicks';
				case 1:
					rating.text = 'Good: $goods';
				case 2:
					rating.text = 'Bad: $bads';
				case 3:
					rating.text = 'Shit: $shits';
				case 4:
					rating.text = 'Misses: $songMisses';
				case 5:
					rating.text = 'Combos: $combo';
			}
		}

		if (health < 0 && practiceMode) {
			health = 0;
		}

		for (name in doubleTrailMap.keys()) {
			var char:Character = doubleTrailMap.get(name);
			var charGroup = boyfriendGroup;
			if (name.startsWith('dad')) charGroup = dadGroup;
			else if (name.startsWith('gf')) charGroup = gfGroup;
			char.x = charGroup.members[char.ID].x;
			char.y = charGroup.members[char.ID].y;
			char.angle = charGroup.members[char.ID].angle;
			char.scale.x = charGroup.members[char.ID].scale.x;
			char.scale.y = charGroup.members[char.ID].scale.y;
			char.scrollFactor.x = charGroup.members[char.ID].scrollFactor.x;
			char.scrollFactor.y = charGroup.members[char.ID].scrollFactor.y;
			char.origin.x = charGroup.members[char.ID].origin.x;
			char.origin.y = charGroup.members[char.ID].origin.y;
			char.alpha = charGroup.members[char.ID].alpha * 0.5;
			char.color = charGroup.members[char.ID].color;
			char.blend = charGroup.members[char.ID].blend;
			if (char.animation.curAnim != null && char.animation.curAnim.name == char.lastAnim) {
				char.visible = charGroup.members[char.ID].visible;
			} else {
				char.visible = false;
			}
		}

		if (inEditor) {
			scoreTxt.text = 'Hits: $songHits';
			beatTxt.text = 'Beat: $curBeat';
			stepTxt.text = 'Step: $curStep';
		} else {
			if (practiceFailed) {
				practiceFailedSine += 180 * elapsed;
				practiceFailedTxt.alpha = 1 - Math.sin((Math.PI * practiceFailedSine) / 180);
			} else {
				practiceFailedTxt.alpha = 0;
			}
		}

		if (playerStrums.length > 0 && opponentStrums.length > 0) {
			underlayPlayer.x = playerStrums.members[0].x;
			underlayOpponent.x = opponentStrums.members[0].x;
		}
		
		#if debug
		if (!endingSong && !startingSong) {
			if (FlxG.keys.justPressed.ONE && !inEditor) {
				killNotes();
				FlxG.sound.music.onComplete();
			}
			if (FlxG.keys.justPressed.TWO) { //Go 10 seconds into the future :O
				setSongTime(Conductor.songPosition + 10000);
				clearNotesBefore(Conductor.songPosition);
			}
		}
		#end

		if (!inEditor) {
			setOnScripts('cameraX', camFollowPos.x);
			setOnScripts('cameraY', camFollowPos.y);
			setOnScripts('botPlay', cpuControlled);
		}
		
		callOnScripts('onUpdatePost', [elapsed]);

		//doing this after every update cause scripts might force them to be visible
		if (demoMode) {
			for (i in hideInDemoMode) {
				i.visible = false;
			}
		}
	}

	public function pauseGame(playSound:Bool = false) {
		persistentUpdate = false;
		paused = true;

		if (FlxG.sound.music != null) {
			FlxG.sound.music.pause();
			vocals.pause();
			vocalsDad.pause();
			@:privateAccess { //This is so hiding the debugger doesn't play the music again
				FlxG.sound.music._alreadyPaused = true;
				vocals._alreadyPaused = true;
				vocalsDad._alreadyPaused = true;
			}
		}
		openSubState(new PauseSubState(playSound));

		#if DISCORD_ALLOWED
		DiscordClient.changePresence(detailsPausedText, '${SONG.song} ($storyDifficultyText)', iconP2.getCharacter());
		#end
	}

	function openChartEditor()
	{
		persistentUpdate = false;
		paused = true;
		cancelMusicFadeTween();
		SONG = originalSong;
		MusicBeatState.switchState(new ChartingState(false));
		chartingMode = true;

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Chart Editor", null, null, true);
		#end
	}

	public var isDead:Bool = false; //Don't mess with this on Lua!!!
	function doDeathCheck(skipHealthCheck:Bool = false) {
		if (!cpuControlled && ((skipHealthCheck && instakillOnMiss) || health <= 0)) practiceFailed = true;
		else return false;
		if (!practiceMode && !isDead)
		{
			var ret:Dynamic = callOnScripts('onGameOver', []);
			if (ret != FunkinLua.Function_Stop) {
				for (i in playerChar.members) {
					i.stunned = true;
				}
				deathCounter++;

				paused = true;

				vocals.stop();
				vocalsDad.stop();
				FlxG.sound.music.stop();

				persistentUpdate = false;
				persistentDraw = false;
				for (tween in modchartTweens) {
					tween.active = true;
				}
				for (timer in modchartTimers) {
					timer.active = true;
				}
				SONG = originalSong;
				if (ClientPrefs.instantRestart) {
					FlxG.resetState();
				} else {
					openSubState(new GameOverSubState(boyfriend.getScreenPosition().x - boyfriend.positionArray[0], boyfriend.getScreenPosition().y - boyfriend.positionArray[1]));
				}
				
				#if DISCORD_ALLOWED
				// Game Over doesn't get his own variable because it's only used here
				DiscordClient.changePresence('Game Over - $detailsText', '${SONG.song} ($storyDifficultyText)', iconP2.getCharacter());
				#end
				isDead = true;
				return true;
			}
		}
		return false;
	}

	public function checkEventNote() {
		while(eventNotes.length > 0) {
			var leStrumTime:Float = eventNotes[0].strumTime;
			if (Conductor.songPosition < leStrumTime) {
				break;
			}

			var value1:String = '';
			if (eventNotes[0].value1 != null)
				value1 = eventNotes[0].value1;

			var value2:String = '';
			if (eventNotes[0].value2 != null)
				value2 = eventNotes[0].value2;

			triggerEventNote(eventNotes[0].event, value1, value2);
			eventNotes.shift();
		}
	}

	public function controlJustPressed(key:String) {
		var pressed:Bool = FlxG.keys.anyJustPressed(ClientPrefs.copyKey(ClientPrefs.keyBinds.get(key)));
		return pressed;
	}

	public function controlPressed(key:String) {
		var pressed:Bool = FlxG.keys.anyPressed(ClientPrefs.copyKey(ClientPrefs.keyBinds.get(key)));
		return pressed;
	}

	public function controlReleased(key:String) {
		var pressed:Bool = FlxG.keys.anyJustReleased(ClientPrefs.copyKey(ClientPrefs.keyBinds.get(key)));
		return pressed;
	}

	public function triggerEventNote(eventName:String, value1:String, value2:String) {
		switch(eventName) {
			case 'Hey!':
				var value:Int = 2;
				switch(value1.toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '0':
						value = 0;
					case 'gf' | 'girlfriend' | '1':
						value = 1;
				}

				var time:Float = Std.parseFloat(value2);
				if (Math.isNaN(time) || time <= 0) time = 0.6;
				time /= playbackRate;

				if (value != 0) {
					for (dad in dadGroup) {
						if (dad.curCharacter.startsWith('gf') && dad.animOffsets.exists('cheer')) { //Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
							dad.playAnim('cheer', true);
							dad.specialAnim = true;
							dad.heyTimer = time;
						}
					}

					for (gf in gfGroup) {
						if (gf.animOffsets.exists('cheer')) {
							gf.playAnim('cheer', true);
							gf.specialAnim = true;
							gf.heyTimer = time;
						}
					}

					if (curStage == 'mall' && ClientPrefs.gameQuality != 'Crappy') {
						bottomBoppers.animation.play('hey', true);
						heyTimer = time;
					}
				}
				if (value != 1) {
					for (boyfriend in boyfriendGroup) {
						if (boyfriend.animOffsets.exists('hey')) {
							boyfriend.playAnim('hey', true);
							boyfriend.specialAnim = true;
							boyfriend.heyTimer = time;
						}
					}
				}

			case 'Set GF Speed':
				var value:Int = Std.parseInt(value1);
				if (Math.isNaN(value)) value = 1;
				if (value < 0) value = 0;
				for (gf in gfGroup) {
					gf.danceEveryNumBeats = value;
				}

			case 'Blammed Lights':
				var lightId:Int = Std.parseInt(value1);
				if (Math.isNaN(lightId)) lightId = 0;

				if (lightId > 0 && curLightEvent != lightId) {
					if (lightId > 5) lightId = FlxG.random.int(1, 5, [curLightEvent]);

					var color:Int = 0xffffffff;
					switch(lightId) {
						case 1: //Blue
							color = 0xff31a2fd;
						case 2: //Green
							color = 0xff31fd8c;
						case 3: //Pink
							color = 0xfff794f7;
						case 4: //Red
							color = 0xfff96d63;
						case 5: //Orange
							color = 0xfffba633;
					}
					curLightEvent = lightId;

					if (ClientPrefs.gameQuality != 'Crappy' && blammedLightsBlack.alpha == 0) {
						if (blammedLightsBlackTween != null) {
							blammedLightsBlackTween.cancel();
						}
						blammedLightsBlackTween = FlxTween.tween(blammedLightsBlack, {alpha: 1}, 1, {ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween) {
								blammedLightsBlackTween = null;
							}
						});

						var chars = [boyfriendGroup, gfGroup, dadGroup];
						for (i in 0...chars.length) {
							for (char in chars[i]) {
								if (char.colorTween != null) {
									char.colorTween.cancel();
								}
								char.colorTween = FlxTween.color(char, 1, FlxColor.WHITE, color, {onComplete: function(twn:FlxTween) {
									char.colorTween = null;
								}, ease: FlxEase.quadInOut});
							}
						}
					} else {
						if (blammedLightsBlackTween != null) {
							blammedLightsBlackTween.cancel();
						}
						blammedLightsBlackTween = null;
						if (blammedLightsBlack != null)
							blammedLightsBlack.alpha = 1;

						var chars = [boyfriendGroup, gfGroup, dadGroup];
						for (i in 0...chars.length) {
							for (char in chars[i]) {
								if (char.colorTween != null) {
									char.colorTween.cancel();
								}
								char.colorTween = null;
								char.color = color;
							}
						}
					}
					
					if (curStage == 'philly' && ClientPrefs.gameQuality != 'Crappy') {
						if (phillyCityLightsEvent != null) {
							phillyCityLightsEvent.forEach(function(spr:BGSprite) {
								spr.visible = false;
							});
							phillyCityLightsEvent.members[lightId - 1].visible = true;
							phillyCityLightsEvent.members[lightId - 1].alpha = 1;
						}
					}
				} else {
					if (ClientPrefs.gameQuality != 'Crappy' && blammedLightsBlack.alpha != 0) {
						if (blammedLightsBlackTween != null) {
							blammedLightsBlackTween.cancel();
						}
						blammedLightsBlackTween = FlxTween.tween(blammedLightsBlack, {alpha: 0}, 1, {ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween) {
								blammedLightsBlackTween = null;
							}
						});
					}

					if (curStage == 'philly' && ClientPrefs.gameQuality != 'Crappy') {
						phillyCityLights.forEach(function(spr:BGSprite) {
							spr.visible = false;
						});
						phillyCityLightsEvent.forEach(function(spr:BGSprite) {
							spr.visible = false;
						});

						var memb:FlxSprite = phillyCityLightsEvent.members[curLightEvent - 1];
						if (memb != null) {
							memb.visible = true;
							memb.alpha = 1;
							if (phillyCityLightsEventTween != null)
								phillyCityLightsEventTween.cancel();

							phillyCityLightsEventTween = FlxTween.tween(memb, {alpha: 0}, 1, {onComplete: function(twn:FlxTween) {
								phillyCityLightsEventTween = null;
							}, ease: FlxEase.quadInOut});
						}
					}

					var chars = [boyfriendGroup, gfGroup, dadGroup];
					for (i in 0...chars.length) {
						for (char in chars[i]) {
							if (char.colorTween != null) {
								char.colorTween.cancel();
							}
							char.colorTween = FlxTween.color(char, 1, char.color, FlxColor.WHITE, {onComplete: function(twn:FlxTween) {
								char.colorTween = null;
							}, ease: FlxEase.quadInOut});
						}
					}

					curLight = 0;
					curLightEvent = 0;
				}

			case 'Kill Henchmen':
				killHenchmen();

			case 'Add Camera Zoom':
				if (ClientPrefs.camZooms && FlxG.camera.zoom < 1.35) {
					var camZoom:Float = Std.parseFloat(value1);
					var hudZoom:Float = Std.parseFloat(value2);
					if (Math.isNaN(camZoom)) camZoom = 0.015;
					if (Math.isNaN(hudZoom)) hudZoom = 0.03;

					FlxG.camera.zoom += camZoom;
					camHUD.zoom += hudZoom;
				}

			case 'Trigger BG Ghouls':
				if (curStage == 'schoolEvil' && ClientPrefs.gameQuality == 'Normal') {
					bgGhouls.dance(true);
					bgGhouls.visible = true;
				}

			case 'Play Animation':
				var charGroup = dadGroup;
				var index = 0;
				var charData = value2.split(',');
				switch(charData[0].toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '1':
						charGroup = boyfriendGroup;
					case 'gf' | 'girlfriend' | '2':
						charGroup = gfGroup;
				}
				if (charData[1] != null) index = Std.parseInt(charData[1]);
				if (charGroup.members[index % charGroup.length] != null && charGroup.members[index % charGroup.length].animOffsets.exists(value1)) {
					charGroup.members[index % charGroup.length].playAnim(value1, true);
					charGroup.members[index % charGroup.length].specialAnim = true;
				}

			case 'Camera Follow Pos':
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if (Math.isNaN(val1)) val1 = 0;
				if (Math.isNaN(val2)) val2 = 0;

				isCameraOnForcedPos = false;
				if (!Math.isNaN(Std.parseFloat(value1)) || !Math.isNaN(Std.parseFloat(value2))) {
					camFollow.x = val1;
					camFollow.y = val2;
					isCameraOnForcedPos = true;
				}

			case 'Alt Idle Animation':
				var charGroup = dadGroup;
				var index = 0;
				var charData = value1.split(',');
				switch(charData[0].toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '1':
						charGroup = boyfriendGroup;
					case 'gf' | 'girlfriend' | '2':
						charGroup = gfGroup;
				}
				if (charData[1] != null) index = Std.parseInt(charData[1]);
				if (charGroup.members[index % charGroup.length] != null) {
					charGroup.members[index % charGroup.length].idleSuffix = value2;
					charGroup.members[index % charGroup.length].recalculateDanceIdle();
				}

			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length) {
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = 0;
					var intensity:Float = 0;
					if (split[0] != null) duration = Std.parseFloat(split[0].trim());
					if (split[1] != null) intensity = Std.parseFloat(split[1].trim());
					if (Math.isNaN(duration)) duration = 0;
					if (Math.isNaN(intensity)) intensity = 0;
					duration /= playbackRate;

					if (duration > 0 && intensity != 0) {
						targetsArray[i].shake(intensity, duration);
					}
				}


			case 'Change Character':
				var charType:Int = 0;
				var index = 0;
				var charData = value1.split(',');
				switch(charData[0].toLowerCase().trim()) {
					case 'gf' | 'girlfriend' | '2':
						charType = 2;
					case 'dad' | 'opponent' | '1':
						charType = 1;
				}
				if (charData[1] != null) index = Std.parseInt(charData[1]);

				switch(charType) {
					case 0:
						index %= boyfriendGroup.length;
						if (boyfriendGroup.members[index].curCharacter != value2) {
							if (!boyfriendMap.exists(value2)) {
								addCharacterToList(value2, charType, index);
							}

							var lastAlpha:Float = boyfriendGroup.members[index].alpha;
							boyfriendGroup.members[index].alpha = 0.00001;
							boyfriendGroup.remove(boyfriendGroup.members[index], true);
							boyfriendGroup.insert(index, boyfriendMap.get(value2));
							boyfriendGroup.members[index].alpha = lastAlpha;
							makeDoubleTrail(boyfriendGroup.members[index], 'bf$index', true, index, boyfriendGroup);
							boyfriend = boyfriendGroup.members[0];
							if (boyfriendGroup.members.length == 1) {
								iconP1.changeIcon(iconP1.char, "default");
							}
							setOnScripts('boyfriendName', boyfriend.curCharacter);
							setOnHscripts('boyfriend', boyfriend);
							reloadHealthBarColors();
						}

					case 1:
						index %= dadGroup.length;
						if (dadGroup.members[index].curCharacter != value2) {
							if (!dadMap.exists(value2)) {
								addCharacterToList(value2, charType, index);
							}

							var wasGf:Bool = dadGroup.members[index].curCharacter.startsWith('gf');
							var lastAlpha:Float = dadGroup.members[index].alpha;
							dadGroup.members[index].alpha = 0.00001;
							dadGroup.remove(dadGroup.members[index], true);
							dadGroup.insert(index, dadMap.get(value2));
							if (gf != null) {
								if (!dadGroup.members[index].curCharacter.startsWith('gf')) {
									if (wasGf) {
										gf.visible = true;
									}
								} else {
									gf.visible = false;
								}
							}
							dadGroup.members[index].alpha = lastAlpha;
							makeDoubleTrail(dadGroup.members[index], 'dad$index', false, index, dadGroup);
							dad = dadGroup.members[0];
							if (dadGroup.members.length == 1) {
								iconP2.changeIcon(iconP2.char, "default");
							}
							setOnScripts('dadName', dad.curCharacter);
							setOnHscripts('dad', dad);
							reloadHealthBarColors();
						}

					case 2:
						if (gf != null) {
							index %= gfGroup.length;
							if (gfGroup.members[index].curCharacter != value2) {
								if (!gfMap.exists(value2)) {
									addCharacterToList(value2, charType, index);
								}

								var lastAlpha:Float = gfGroup.members[index].alpha;
								gfGroup.members[index].alpha = 0.00001;
								gfGroup.remove(gfGroup.members[index], true);
								gfGroup.insert(index, gfMap.get(value2));
								gfGroup.members[index].alpha = lastAlpha;
								makeDoubleTrail(gfGroup.members[index], 'gf$index', false, index, gfGroup);
								gf = gfGroup.members[0];
								setOnScripts('gfName', gf.curCharacter);
								setOnHscripts('gf', gf);
							}
						}
				}
			
			case 'BG Freaks Expression':
				if (bgGirls != null) bgGirls.swapDanceType();
			
			case 'Change Scroll Speed':
				if (songSpeedType == "constant")
					return;
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if (Math.isNaN(val1)) val1 = 1;
				if (Math.isNaN(val2)) val2 = 0;
				val2 /= playbackRate;

				var newValue:Float = Math.min(SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * playbackRate * val1, Math.max(SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * val1, 3));

				if (val2 <= 0)
				{
					songSpeed = newValue;
				}
				else
				{
					songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, val2, {ease: FlxEase.linear, onComplete:
						function (twn:FlxTween)
						{
							songSpeedTween = null;
						}
					});
				}
		}
		callOnScripts('onEvent', [eventName, value1, value2]);
	}

	function moveCameraSection(?id:Int = 0):Void {
		if (SONG.notes[id] == null) return;

		if (gf != null && SONG.notes[id].gfSection)
		{
			camFollow.set(gf.getMidpoint().x, gf.getMidpoint().y);
			if (gfGroupFile != null) {
				camFollow.x += gfGroupFile.camera_position[0] + girlfriendCameraOffset[0];
				camFollow.y += gfGroupFile.camera_position[1] + girlfriendCameraOffset[1];
			} else {
				camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
				camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];
			}
			tweenCamIn();
			callOnScripts('onMoveCamera', ['gf']);
			return;
		}

		if (!SONG.notes[id].mustHitSection)
		{
			moveCamera(true);
			callOnScripts('onMoveCamera', ['dad']);
		}
		/*if (!SONG.notes[id].gfSection)
		{
			//moveCamera(false);
			callOnScripts('onMoveCamera', ['gf']);
		}*/
		else
		{
			moveCamera(false);
			callOnScripts('onMoveCamera', ['boyfriend']);
		}
	}

	var cameraTwn:FlxTween;
	var lastCamFocused:Bool;
	public function moveCamera(isDad:Bool)
	{
		if (isDad)
		{
			camFollow.set(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);

			if (dadGroupFile != null) {
				camFollow.x += dadGroupFile.camera_position[0] + opponentCameraOffset[0];
				camFollow.y += dadGroupFile.camera_position[1] + opponentCameraOffset[1];
			} else {
				camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0];
				camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];
			}
			tweenCamIn();
			if (lastCamFocused != isDad)
				{
					if (!sectionComboBreaks && combo > 1 && ClientPrefs.noteCombo && WeekData.getWeekFileName() != 'week6') // disabled the note combo on week 6, get over it
						noteCombo();
					
					sectionComboBreaks = false;
				}
		}
		else
		{
			camFollow.set(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);

			if (bfGroupFile != null) {
				camFollow.x -= bfGroupFile.camera_position[0] - boyfriendCameraOffset[0];
				camFollow.y += bfGroupFile.camera_position[1] + boyfriendCameraOffset[1];
			} else {
				camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
				camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];
			}

			if (curSong == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1)
			{
				cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.crochet * (Conductor.timeSignature[1] / 4) / 1000), {ease: FlxEase.elasticInOut, onComplete:
					function (twn:FlxTween)
					{
						cameraTwn = null;
					}
				});
			}
		}
		lastCamFocused = isDad;
	}

	function tweenCamIn() {
		if (curSong == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1.3) {
			cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.crochet * (Conductor.timeSignature[1] / 4) / 1000), {ease: FlxEase.elasticInOut, onComplete:
				function (twn:FlxTween) {
					cameraTwn = null;
				}
			});
		}
	}

	function snapCamFollowToPos(x:Float, y:Float) {
		camFollow.set(x, y);
		camFollowPos.setPosition(x, y);
	}

	//Any way to do this without using a different function? kinda dumb
	private function onSongComplete()
	{
		finishSong(false);
	}
	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		var finishCallback:Void->Void = endSong; //In case you want to change it in a specific song.

		updateTime = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		vocals.pause();
		vocalsDad.volume = 0;
		vocalsDad.pause();
		if (ClientPrefs.noteOffset <= 0 || ignoreNoteOffset) {
			finishCallback();
		} else {
			endingTimer = new FlxTimer().start(ClientPrefs.noteOffset / 1000, function(tmr:FlxTimer) {
				finishCallback();
			});
		}
	}


	public var transitioning = false;
	public function endSong():Void
	{
		if (inEditor) {
			LoadingState.loadAndSwitchState(new editors.ChartingState());
			return;
		}
		//Should kill you if you tried to cheat
		if (!startingSong) {
			notes.forEach(function(daNote:Note) {
				if (daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			});
			for (daNote in unspawnNotes) {
				if (daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			}

			if (doDeathCheck()) {
				return;
			}
		}
		
		timeBarBG.visible = false;
		timeBar.visible = false;
		timeTxt.visible = false;
		canPause = false;
		endingSong = true;
		camZooming = false;
		camBop = false;
		inCutscene = false;
		updateTime = false;

		deathCounter = 0;
		seenCutscene = false;

		#if ACHIEVEMENTS_ALLOWED
		if (achievementObj != null) {
			return;
		} else {
			var achieve:String = checkForAchievement(['week1_nomiss', 'week2_nomiss', 'week3_nomiss', 'week4_nomiss',
				'week5_nomiss', 'week6_nomiss', 'week7_nomiss', 'ur_bad',
				'ur_good', 'hype', 'two_keys', 'toastie', 'debugger']);

			if (achieve != null) {
				startAchievement(achieve);
				return;
			}
		}
		#end
		
		var ret:Dynamic = callOnScripts('onEndSong', []);
		if (ret != FunkinLua.Function_Stop && !transitioning) {
			if (SONG.validScore)
			{
				#if HIGHSCORE_ALLOWED
				var percent:Float = ratingPercent;
				if (Math.isNaN(percent)) percent = 0;
				Highscore.saveScore(curSong, songScore, storyDifficulty, percent);
				#end
			}

			if (chartingMode)
			{
				openChartEditor();
				return;
			}

			if (isStoryMode)
			{
				campaignScore += songScore;
				campaignMisses += songMisses;

				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0)
				{
					WeekData.loadTheFirstEnabledMod();
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
					#if cpp
					@:privateAccess
					{
						AL.sourcef(FlxG.sound.music._channel.__source.__backend.handle, AL.PITCH, 1);
					}
					#end

					cancelMusicFadeTween();
					if (FlxTransitionableState.skipNextTransIn) {
						CustomFadeTransition.nextCamera = null;
					}
					MusicBeatState.switchState(new StoryMenuState());

					if (!practiceMode && !cpuControlled) {
						StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);

						if (SONG.validScore)
						{
							Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);
						}

						FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
						FlxG.save.flush();
					}
					changedDifficulty = false;
				}
				else
				{
					var difficulty:String = CoolUtil.getDifficultyFilePath();

					trace('LOADING NEXT SONG');
					trace(Paths.formatToSongPath(storyPlaylist[0]) + difficulty);

					var winterHorrorlandNext = (curSong == "eggnog");
					if (winterHorrorlandNext)
					{
						var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
							-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
						blackShit.scrollFactor.set();
						add(blackShit);
						camHUD.visible = false;

						FlxG.sound.play(Paths.sound('Lights_Shut_off'));
					}

					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;

					prevCamFollow = camFollow;
					prevCamFollowPos = camFollowPos;

					SONG = Song.loadFromJson(storyPlaylist[0] + difficulty, storyPlaylist[0]);
					FlxG.sound.music.stop();

					if (winterHorrorlandNext) {
						new FlxTimer().start(1.5, function(tmr:FlxTimer) {
							cancelMusicFadeTween();
							LoadingState.loadAndResetState();
						});
					} else {
						cancelMusicFadeTween();
						LoadingState.loadAndResetState();
					}
				}
			}
			else
			{
				trace('WENT BACK TO FREEPLAY??');
				WeekData.loadTheFirstEnabledMod();
				cancelMusicFadeTween();
				if (FlxTransitionableState.skipNextTransIn) {
					CustomFadeTransition.nextCamera = null;
				}
				SONG = originalSong;
				MusicBeatState.switchState(new FreeplayState());
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				#if cpp
				@:privateAccess
				{
					AL.sourcef(FlxG.sound.music._channel.__source.__backend.handle, AL.PITCH, 1);
				}
				#end
				changedDifficulty = false;
			}
			transitioning = true;
		}
	}

	#if ACHIEVEMENTS_ALLOWED
	var achievementObj:AchievementObject = null;
	function startAchievement(achieve:String) {
		achievementObj = new AchievementObject(achieve, camOther);
		achievementObj.onFinish = achievementEnd;
		add(achievementObj);
		trace('Giving achievement $achieve');
	}
	function achievementEnd():Void
	{
		achievementObj = null;
		if (endingSong && !inCutscene) {
			endSong();
		}
	}
	#end

	public function killNotes() {
		while(notes.length > 0) {
			var daNote:Note = notes.members[0];
			daNote.active = false;
			daNote.visible = false;

			daNote.kill();
			notes.remove(daNote, true);
			daNote.destroy();
		}
		unspawnNotes = [];
		eventNotes = [];
	}

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;

	public var showCombo:Bool = true;
	public var showRating:Bool = true;

	private function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.ratingOffset);

		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.35;
		if (opponentChart) coolText.x = FlxG.width * 0.55;

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		//tryna do MS based judgment due to popular demand
		var daRating:String = Conductor.judgeNote(noteDiff);

		switch (daRating)
		{
			case "shit": // shit
				totalNotesHit += 0;
				note.ratingMod = 0;
				score = 50;
				if(!note.ratingDisabled) {
					shits++;
					doRatingTween(3);
				}
			case "bad": // bad
				totalNotesHit += 0.5;
				note.ratingMod = 0.5;
				score = 100;
				if(!note.ratingDisabled) {
					bads++;
					doRatingTween(2);
				}
			case "good": // good
				totalNotesHit += 0.75;
				note.ratingMod = 0.75;
				score = 200;
				if(!note.ratingDisabled) {
					goods++;
					doRatingTween(1);
				}
			case "sick": // sick
				totalNotesHit += 1;
				note.ratingMod = 1;
				if(!note.ratingDisabled) {
					sicks++;
					doRatingTween(0);
				}
		}

		note.rating = daRating;

		if (daRating == 'sick' && !note.noteSplashDisabled)
		{
			spawnNoteSplashOnNote(note);
		}

		if (!ClientPrefs.shitMisses || daRating != 'shit') {
			health += note.hitHealth * healthGain;
			if (!practiceMode && !cpuControlled) {
				songScore += score;
				if(!note.ratingDisabled) {
					songHits++;
					totalPlayed++;
					recalculateRating();
				}

				if (ClientPrefs.scoreZoom)
				{
					if (scoreTxtTween != null) {
						scoreTxtTween.cancel();
					}
					scoreTxt.scale.x = 1.075;
					scoreTxt.scale.y = 1.075;
					scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
						onComplete: function(twn:FlxTween) {
							scoreTxtTween = null;
						}
					});
				}
			}
		} else {
			noteMissPress(note.noteData);
		}

		rating.loadGraphic(Paths.image(UIData.checkImageFile(daRating, uiSkinMap.get(daRating))));
		if (!inEditor) rating.cameras = [camHUD];
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);
		rating.visible = !ClientPrefs.hideHud && showRating && !demoMode;
		rating.x += ClientPrefs.comboOffset[0];
		rating.y -= ClientPrefs.comboOffset[1];

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(UIData.checkImageFile('combo', uiSkinMap.get('combo'))));
		if (!inEditor) comboSpr.cameras = [camHUD];
		comboSpr.screenCenter();
		comboSpr.x = coolText.x + 80;
		comboSpr.y += 60;
		comboSpr.acceleration.y = 600;
		comboSpr.velocity.y -= 150;
		comboSpr.visible = !ClientPrefs.hideHud && showCombo && !demoMode;
		comboSpr.x += ClientPrefs.comboOffset[0];
		comboSpr.y -= ClientPrefs.comboOffset[1];

		comboSpr.velocity.x += FlxG.random.int(1, 10);
		insert(members.indexOf(strumLineNotes), rating);

		rating.setGraphicSize(Std.int(rating.width * uiSkinMap.get(daRating).scale * uiSkinMap.get(daRating).ratingScale));
		comboSpr.setGraphicSize(Std.int(comboSpr.width * uiSkinMap.get('combo').scale * uiSkinMap.get('combo').ratingScale));
		rating.antialiasing = ClientPrefs.globalAntialiasing && !uiSkinMap.get(daRating).noAntialiasing;
		comboSpr.antialiasing = ClientPrefs.globalAntialiasing && !uiSkinMap.get('combo').noAntialiasing;

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var seperatedScore:Array<Int> = [];

		if (combo >= 1000) {
			seperatedScore.push(Math.floor(combo / 1000) % 10);
		}
		seperatedScore.push(Math.floor(combo / 100) % 10);
		seperatedScore.push(Math.floor(combo / 10) % 10);
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(UIData.checkImageFile('num${Std.int(i)}', uiSkinMap.get('num${Std.int(i)}'))));
			if (!inEditor) numScore.cameras = [camHUD];
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90;
			numScore.y += 80;

			numScore.x += ClientPrefs.comboOffset[2];
			numScore.y -= ClientPrefs.comboOffset[3];

			numScore.setGraphicSize(Std.int(numScore.width * uiSkinMap.get('num${Std.int(i)}').scale * uiSkinMap.get('num${Std.int(i)}').comboNumScale));
			numScore.updateHitbox();
			numScore.antialiasing = ClientPrefs.globalAntialiasing && !uiSkinMap.get('num${Std.int(i)}').noAntialiasing;

			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);
			numScore.visible = !ClientPrefs.hideHud && showCombo && !demoMode;

			insert(members.indexOf(strumLineNotes), numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * (Conductor.timeSignature[1] / 4) * 0.002
			});

			daLoop++;
		}

		coolText.text = Std.string(seperatedScore);

		FlxTween.tween(rating, {alpha: 0}, 0.2, {
			startDelay: Conductor.crochet * (Conductor.timeSignature[1] / 4) * 0.001
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();
				comboSpr.destroy();

				rating.destroy();
			},
			startDelay: Conductor.crochet * (Conductor.timeSignature[1] / 4) * 0.001
		});
	}

	function doRatingTween(ind:Int = 0) {
		if (ClientPrefs.scoreZoom)
		{
			if (ratingTxtTweens[ind] != null) {
				ratingTxtTweens[ind].cancel();
			}
			ratingTxtGroup.members[ind].scale.x = 1.02;
			ratingTxtGroup.members[ind].scale.y = 1.02;
			ratingTxtTweens[ind] = FlxTween.tween(ratingTxtGroup.members[ind].scale, {x: 1, y: 1}, 0.2, {
				onComplete: function(twn:FlxTween) {
					ratingTxtTweens[ind] = null;
				}
			});
		}
	}

	private function onKeyPress(event:KeyboardEvent):Void
	{
		if (!cpuControlled && !paused) {
			var eventKey:FlxKey = event.keyCode;
			var key:Int = getKeyFromEvent(eventKey);

			if (key > -1 && !cpuControlled && startedCountdown && !paused && key > -1 && (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || isUsingGamepad))
			{
				if ((inEditor || !playerChar.members[0].stunned) && generatedMusic && !endingSong)
				{
					var lastTime:Float = Conductor.songPosition;
					if (FlxG.sound.music.time > 500) {
						//more accurate hit time for the ratings?
						Conductor.songPosition = FlxG.sound.music.time / playbackRate;
					}

					var canMiss:Bool = !ClientPrefs.ghostTapping;

					// heavily based on my own code LOL if it aint broke dont fix it
					var pressNotes:Array<Note> = [];
					var notesStopped:Bool = false;

					var sortedNotesList:Array<Note> = [];
					notes.forEachAlive(function(daNote:Note)
					{
						if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote)
						{
							if (daNote.noteData == key)
							{
								sortedNotesList.push(daNote);
							}
							canMiss = true;
						}
					});
					sortedNotesList.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

					if (sortedNotesList.length > 0) {
						for (epicNote in sortedNotesList)
						{
							for (doubleNote in pressNotes) {
								if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1) {
									doubleNote.kill();
									notes.remove(doubleNote, true);
									doubleNote.destroy();
								} else
									notesStopped = true;
							}
								
							// eee jack detection before was not super good
							if (!notesStopped) {
								goodNoteHit(epicNote, [eventKey]);
								pressNotes.push(epicNote);
							}

						}
					}
					else if (canMiss) {
						noteMissPress(key);
						callOnScripts('noteMissPress', [key]);
					}

					// I dunno what you need this for but here you go
					//									- Shubs

					// Shubs, this is for the "Just the Two of Us" achievement lol
					//									- Shadow Mario
					keysPressed[key] = true;

					//more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
					Conductor.songPosition = lastTime;
				}

				var spr:StrumNote = playerStrums.members[key];
				if (opponentChart) spr = opponentStrums.members[key];
				if (spr != null && spr.animation.curAnim.name != 'confirm')
				{
					spr.playAnim('pressed');
					spr.resetAnim = 0;
				}
				callOnScripts('onKeyPress', [key]);
			}
		}
	}
	
	private function onKeyRelease(event:KeyboardEvent):Void
	{
		if (!cpuControlled && !paused) {
			var eventKey:FlxKey = event.keyCode;
			var key:Int = getKeyFromEvent(eventKey);
			if (key > -1)
			{
				var spr:StrumNote = playerStrums.members[key];
				if (opponentChart) spr = opponentStrums.members[key];
				if (spr != null)
				{
					spr.playAnim('static');
					spr.resetAnim = 0;
				}
				callOnScripts('onKeyRelease', [key]);
			}
		}
	}

	private function getKeyFromEvent(key:FlxKey):Int
	{
		if (key != NONE)
		{
			for (i in 0...keysArray.length)
			{
				for (j in 0...keysArray[i].length)
				{
					if (key == keysArray[i][j])
					{
						return i;
					}
				}
			}
		}
		return -1;
	}

	// Hold notes + controller input
	private function keyShit():Void
	{
		// HOLDING
		var controlHoldArray:Array<Bool> = [];
		for (i in keysArray) {
			controlHoldArray.push(FlxG.keys.anyPressed(i));
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if(isUsingGamepad)
		{
			var controlArray:Array<Bool> = [];
			for (i in keysArray) {
				controlArray.push(FlxG.keys.anyJustPressed(i));
			}
			if(controlArray.contains(true))
			{
				for (i in 0...controlArray.length)
				{
					if(controlArray[i])
						onKeyPress(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, -1, keysArray[i][0]));
				}
			}
		}

		if ((inEditor || !playerChar.members[0].stunned) && generatedMusic)
		{
			// rewritten inputs???
			notes.forEachAlive(function(daNote:Note)
			{
				// hold note functions
				if (daNote.isSustainNote && controlHoldArray[daNote.noteData] && daNote.canBeHit 
				&& daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit) {
					goodNoteHit(daNote, keysArray[daNote.noteData]);
				}
			});

			if (controlHoldArray.contains(true) && !endingSong) {
				#if ACHIEVEMENTS_ALLOWED
				var achieve:String = checkForAchievement(['oversinging']);
				if (achieve != null) {
					startAchievement(achieve);
				}
				#end
			}
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now (actually coded now)
		if(isUsingGamepad)
		{
			var controlArray:Array<Bool> = [];
			for (i in keysArray) {
				controlArray.push(FlxG.keys.anyJustReleased(i));
			}
			if(controlArray.contains(true))
			{
				for (i in 0...controlArray.length)
				{
					if(controlArray[i])
						onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, keysArray[i][0]));
				}
			}
		}
	}

	function noteMiss(daNote:Note):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
	sectionComboBreaks = true;	
	//Dupe note remove
		notes.forEachAlive(function(note:Note) {
			if (daNote != note && daNote.mustPress && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 1) {
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		});
		combo = 0;

		health -= daNote.missHealth * healthLoss;
		if (instakillOnMiss)
		{
			if (opponentChart && foundDadVocals)
				vocalsDad.volume = 0;
			else
				vocals.volume = 0;
			doDeathCheck(true);
		}

		songMisses++;
		doRatingTween(4);
		if (opponentChart && foundDadVocals)
			vocalsDad.volume = 0;
		else
			vocals.volume = 0;
		if (!practiceMode) songScore -= 10;
		
		totalPlayed++;
		recalculateRating();

		if (!inEditor) {
			var charGroup = playerChar;
			if (daNote.gfNote) {
				charGroup = gfGroup;
			}

			for (char in daNote.characters) {
				if (char < charGroup.members.length && charGroup.members[char] != null && charGroup.members[char].hasMissAnimations)
				{
					var daAlt = '';
					if (daNote.noteType == 'Alt Animation') daAlt = '-alt';

					var animToPlay:String = '${playerSingAnimations[daNote.noteData]}miss$daAlt';
					if (charGroup.members[char].animOffsets.exists(animToPlay)) {
						charGroup.members[char].playAnim(animToPlay, true);
					}
				}
			}
		}
		switch (daNote.noteType)
	    {
			case 'Caution Note':
				health = 0;
		}

		callOnScripts('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote, daNote.characters]);
	}

	function noteMissPress(direction:Int = 1):Void //You pressed a key when there was no notes to press for this key
	{
		if (inEditor || !playerChar.members[0].stunned)
		{
			health -= 0.05 * healthLoss;
			if (instakillOnMiss)
			{
				if (opponentChart && foundDadVocals)
					vocalsDad.volume = 0;
				else
					vocals.volume = 0;
				doDeathCheck(true);
			}

			if (ClientPrefs.ghostTapping) return;

			if (combo > 5 && !inEditor)
			{
				for (gf in gfGroup) {
					if (gf.animOffsets.exists('sad')) {
						gf.playAnim('sad');
					}
				}
			}
			combo = 0;

			if (!practiceMode) songScore -= 10;
			if (!endingSong) {
				songMisses++;
			}
			totalPlayed++;
			recalculateRating();

			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));

			if (!inEditor) {
				var animToPlay = '${playerSingAnimations[direction]}miss';
				for (char in playerChar) {
					if (char.hasMissAnimations && char.animOffsets.exists(animToPlay)) {
						char.playAnim(animToPlay, true);
					}
				}
			}
			if (opponentChart && foundDadVocals)
				vocalsDad.volume = 0;
			else
				vocals.volume = 0;
		}
	}

	function opponentNoteHit(note:Note):Void
	{
		if (!opponentChart && curSong != 'tutorial') {
			camZooming = true;
			camBop = true;
		}

		if (!inEditor) {
			var charGroup = opponentChar;
			if (note.gfNote) {
				charGroup = gfGroup;
			}

			for (char in note.characters) {
				if (char < charGroup.members.length && charGroup.members[char] != null) {
					if (note.noteType == 'Hey!' && charGroup.members[char].animOffsets.exists('hey')) {
						charGroup.members[char].playAnim('hey', true);
						charGroup.members[char].specialAnim = true;
						charGroup.members[char].heyTimer = 0.6 / playbackRate;
					} else if (!note.noAnimation) {
						var altAnim:String = "";

						var curSection:Int = Conductor.getCurSection(SONG, curStep);
						if (SONG.notes[curSection] != null)
						{
							if ((SONG.notes[curSection].altAnim && !opponentChart) || note.noteType == 'Alt Animation') {
								altAnim = '-alt';
							}
						}

						var animToPlay:String = playerSingAnimations[note.noteData] + altAnim;

						if (note.noteType == 'Trail Note') {
							if (note.gfNote && doubleTrailMap.get('gf$char') != null && doubleTrailMap.get('gf$char').animOffsets.exists(animToPlay)) {
								doubleTrailMap.get('gf$char').playAnim(animToPlay, true);
								doubleTrailMap.get('gf$char').holdTimer = 0;
								doubleTrailMap.get('gf$char').lastAnim = animToPlay;
							} else if (!opponentChart && doubleTrailMap.get('dad$char').animOffsets.exists(animToPlay)) {
								doubleTrailMap.get('dad$char').playAnim(animToPlay, true);
								doubleTrailMap.get('dad$char').holdTimer = 0;
								doubleTrailMap.get('dad$char').lastAnim = animToPlay;
							} else if (doubleTrailMap.get('bf$char').animOffsets.exists(animToPlay)) {
								doubleTrailMap.get('bf$char').playAnim(animToPlay, true);
								doubleTrailMap.get('bf$char').holdTimer = 0;
								doubleTrailMap.get('bf$char').lastAnim = animToPlay;
							}
						} else if (charGroup.members[char].animOffsets.exists(animToPlay)) {
							charGroup.members[char].playAnim(animToPlay, true);
							charGroup.members[char].holdTimer = 0;
						}
					}
				}
			}
		}

		if (SONG.needsVoices) {
			if (opponentChart && foundDadVocals)
				vocalsDad.volume = ClientPrefs.voicesVolume;
			else
				vocals.volume = ClientPrefs.voicesVolume;
		}

		var time:Float = 0.15;
		if (note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
			time += 0.15;
		}
		strumPlayAnim(true, note.noteData, time);
		note.hitByOpponent = true;

		if (!note.noteSplashDisabled && !note.isSustainNote)
		{
			spawnNoteSplashOnNote(note);
		}

		callOnScripts('opponentNoteHit', [notes.members.indexOf(note), note.noteData, note.noteType, note.isSustainNote, note.characters]);

		if (!note.isSustainNote)
		{
			note.kill();
			notes.remove(note, true);
			note.destroy();
		}
		if (opponentHealthDrain)
		{	
			health = health - note.hitHealth;
			if (healthBar.percent < 15) health = health + note.hitHealth;
		}
		}

	function goodNoteHit(note:Note, ?keys:Array<FlxKey>):Void
	{
		if (keys == null) keys = [];
		if (!note.wasGoodHit)
		{
			if (cpuControlled && (note.ignoreNote || note.hitCausesMiss)) return;

			if (ClientPrefs.hitsoundVolume > 0 && !note.hitsoundDisabled && !demoMode)
			{
				FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.hitsoundVolume);
			}

			if (opponentChart && curSong != 'tutorial') {
				camZooming = true;
				camBop = true;
			}

			var charGroup = playerChar;
			if (note.gfNote) charGroup = gfGroup;

			if (note.hitCausesMiss) {
				noteMiss(note);
				if (!note.noteSplashDisabled && !note.isSustainNote) {
					spawnNoteSplashOnNote(note);
				}
				var strums = playerStrums;
				if (opponentChart) strums = opponentStrums;
				strums.forEach(function(spr:StrumNote)
				{
					if (note.noteData == spr.ID)
					{
						spr.playAnim('confirm', true);
					}
				});

				switch(note.noteType) {
					case 'Hurt Note': //Hurt note
						if (!inEditor) {
							for (i in note.characters) {
								if (i < charGroup.members.length) {
									if (charGroup.members[i] != null && charGroup.members[i].animOffsets.exists('hurt')) {
										charGroup.members[i].playAnim('hurt', true);
										charGroup.members[i].specialAnim = true;
									}
								}
							}
						}
				}
				
				note.wasGoodHit = true;
				if (!note.isSustainNote)
				{
					note.kill();
					notes.remove(note, true);
					note.destroy();
				}
				return;
			}

			if (!note.isSustainNote)
			{
				combo += 1;
				popUpScore(note);
				if (combo > 9999) combo = 9999;
			}
			else
			{
				health += note.hitHealth * healthGain; //oops forgot this
			}

			if (!note.noAnimation && !inEditor) {
				var daAlt = '';
				var curSection = Conductor.getCurSection(SONG, curStep);
				if (SONG.notes[curSection] != null) {
					if ((SONG.notes[curSection].altAnim && opponentChart) || note.noteType == 'Alt Animation')
						daAlt = '-alt';
				}
	
				var animToPlay:String = playerSingAnimations[note.noteData] + daAlt;

				for (i in note.characters) {
					if (i < charGroup.members.length) {
						if (note.noteType == 'Trail Note') {
							if (note.gfNote && doubleTrailMap.get('gf$i') != null && doubleTrailMap.get('gf$i').animOffsets.exists(animToPlay)) {
								doubleTrailMap.get('gf$i').playAnim(animToPlay, true);
								doubleTrailMap.get('gf$i').holdTimer = 0;
								doubleTrailMap.get('gf$i').lastAnim = animToPlay;
							} else if (opponentChart && doubleTrailMap.get('dad$i').animOffsets.exists(animToPlay)) {
								doubleTrailMap.get('dad$i').playAnim(animToPlay, true);
								doubleTrailMap.get('dad$i').holdTimer = 0;
								doubleTrailMap.get('dad$i').lastAnim = animToPlay;
							} else if (doubleTrailMap.get('bf$i').animOffsets.exists(animToPlay)) {
								doubleTrailMap.get('bf$i').playAnim(animToPlay, true);
								doubleTrailMap.get('bf$i').holdTimer = 0;
								doubleTrailMap.get('bf$i').lastAnim = animToPlay;
							}
						} else if (charGroup.members[i] != null && charGroup.members[i].animOffsets.exists(animToPlay)) {
							charGroup.members[i].playAnim(animToPlay, true);
							charGroup.members[i].holdTimer = 0;
							if (keys != null) charGroup.members[i].keysPressed = keys;
						}
					}
				}

				if (note.noteType == 'Hey!') {
					for (i in note.characters) {
						if (i < charGroup.members.length && charGroup.members[i] != null && charGroup.members[i].animOffsets.exists('hey')) {
							charGroup.members[i].playAnim('hey', true);
							charGroup.members[i].specialAnim = true;
							charGroup.members[i].heyTimer = 0.6 / playbackRate;
						}
					}
	
					for (gf in gfGroup) {
						if (gf.animOffsets.exists('cheer')) {
							gf.playAnim('cheer', true);
							gf.specialAnim = true;
							gf.heyTimer = 0.6 / playbackRate;
						}
					}
				}
			}

			if (cpuControlled) {
				var time:Float = 0.15;
				if (note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
					time += 0.15;
				}
				strumPlayAnim(false, note.noteData, time);
			} else {
				var strums = playerStrums;
				if (opponentChart) strums = opponentStrums;
				strums.forEach(function(spr:StrumNote)
				{
					if (note.noteData == spr.ID)
					{
						spr.playAnim('confirm', true);
					}
				});
			}
			note.wasGoodHit = true;
			if (opponentChart && foundDadVocals)
				vocalsDad.volume = ClientPrefs.voicesVolume;
			else
				vocals.volume = ClientPrefs.voicesVolume;

			callOnScripts('goodNoteHit', [notes.members.indexOf(note), note.noteData, note.noteType, note.isSustainNote, note.characters]);

			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}
	}

	function spawnNoteSplashOnNote(note:Note) {
		if (note != null && ClientPrefs.noteSplashes) {
			var strum:StrumNote = playerStrums.members[note.noteData];
			if (note.isOpponent) strum = opponentStrums.members[note.noteData];
			if (strum != null) {
				spawnNoteSplash(strum.x, strum.y, note.noteData, note);
			}
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null) {
		var skin:String = 'noteSplashes';
		var colors = playerColors;
		var keys = playerKeys;
		if (note != null && note.isOpponent) {
			colors = opponentColors;
			keys = opponentKeys;
		}
		
		var hue:Float = ClientPrefs.arrowHSV[keys - 1][data % keys][0] / 360;
		var sat:Float = ClientPrefs.arrowHSV[keys - 1][data % keys][1] / 100;
		var brt:Float = ClientPrefs.arrowHSV[keys - 1][data % keys][2] / 100;
		if (note != null) {
			skin = note.noteSplashTexture;
			hue = note.noteSplashHue;
			sat = note.noteSplashSat;
			brt = note.noteSplashBrt;
		}

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, note, skin, hue, sat, brt, keys, colors);
		grpNoteSplashes.add(splash);
	}

	var fastCarCanDrive:Bool = true;

	function resetFastCar():Void
	{
		fastCar.x = -12600;
		fastCar.y = FlxG.random.int(140, 250);
		fastCar.velocity.x = 0;
		fastCarCanDrive = true;
	}

	var carTimer:FlxTimer;
	function fastCarDrive()
	{
		FlxG.sound.play(Paths.soundRandom('carPass', 0, 1), 0.7);

		fastCar.velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
		fastCarCanDrive = false;
		carTimer = new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			resetFastCar();
			carTimer = null;
		});
	}

	var trainMoving:Bool = false;
	var trainFrameTiming:Float = 0;

	var trainCars:Int = 8;
	var trainFinishing:Bool = false;
	var trainCooldown:Int = 0;

	function trainStart():Void
	{
		trainMoving = true;
		if (!trainSound.playing)
			trainSound.play(true);
	}

	var startedMoving:Bool = false;

	function updateTrainPos():Void
	{
		if (trainSound.time >= 4700)
		{
			startedMoving = true;
			for (gf in gfGroup) {
				if (gf.animOffsets.exists('hairBlow')) {
					gf.playAnim('hairBlow');
					gf.specialAnim = true;
				}
			}
		}

		if (startedMoving)
		{
			phillyTrain.x -= 400;

			if (phillyTrain.x < -2000 && !trainFinishing)
			{
				phillyTrain.x = -1150;
				trainCars -= 1;

				if (trainCars <= 0)
					trainFinishing = true;
			}

			if (phillyTrain.x < -4000 && trainFinishing)
				trainReset();
		}
	}

	function trainReset():Void
	{
		for (gf in gfGroup) {
			if (gf.animOffsets.exists('hairFall')) {
				gf.danced = false; //Sets head to the correct position once the animation ends
				gf.playAnim('hairFall');
				gf.specialAnim = true;
			}
		}
		phillyTrain.x = FlxG.width + 200;
		trainMoving = false;
		trainCars = 8;
		trainFinishing = false;
		startedMoving = false;
	}

	function lightningStrikeShit():Void
	{
		FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
		if (ClientPrefs.gameQuality == 'Normal') halloweenBG.animation.play('halloweem bg lightning strike');

		lightningStrikeBeat = curBeat;
		lightningOffset = FlxG.random.int(8, 24);

		var chars = [boyfriendGroup, gfGroup];
		for (group in chars) {
			for (char in group) {
				if (char.animOffsets.exists('scared')) {
					char.playAnim('scared', true);
				}
			}
		}

		if (ClientPrefs.camZooms) {
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;

			if (!camZooming) { //Just a way for preventing it to be permanently zoomed until Skid & Pump hits a note
				FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.5);
				FlxTween.tween(camHUD, {zoom: 1}, 0.5);
			}
		}

		if (ClientPrefs.flashing) {
			halloweenWhite.alpha = 0.4;
			FlxTween.tween(halloweenWhite, {alpha: 0.5}, 0.075);
			FlxTween.tween(halloweenWhite, {alpha: 0}, 0.25, {startDelay: 0.15});
		}
	}

	function killHenchmen():Void
		{
			if (ClientPrefs.gameQuality == 'Normal' && curStage == 'limo') {
				if (limoKillingState < 1) {
					limoMetalPole.x = -400;
					limoMetalPole.visible = true;
					limoLight.visible = true;
					limoCorpse.visible = false;
					limoCorpseTwo.visible = false;
					limoKillingState = 1;
	
					#if ACHIEVEMENTS_ALLOWED
					Achievements.henchmenDeath++;
					FlxG.save.data.henchmenDeath = Achievements.henchmenDeath;
					var achieve:String = checkForAchievement(['roadkill_enthusiast']);
					if (achieve != null) {
						startAchievement(achieve);
					} else {
						FlxG.save.flush();
					}
					FlxG.log.add('Deaths: ${Achievements.henchmenDeath}');
					#end
				}
			}
		}

	function resetLimoKill():Void
	{
		if (curStage == 'limo') {
			limoMetalPole.x = -500;
			limoMetalPole.visible = false;
			limoLight.x = -500;
			limoLight.visible = false;
			limoCorpse.x = -500;
			limoCorpse.visible = false;
			limoCorpseTwo.x = -500;
			limoCorpseTwo.visible = false;
		}
	}

	private var preventLuaRemove:Bool = false;
	override function destroy() {
		preventLuaRemove = true;
		for (i in 0...luaArray.length) {
			luaArray[i].call('onDestroy', []);
			luaArray[i].stop();
		}
		luaArray = [];
		for (i in hscriptMap.keys()) {
			callHscript(i, 'onDestroy', []);
			var hscript = hscriptMap.get(i);
			hscriptMap.remove(i);
			hscript = null;
		}
		hscriptMap.clear();
		instance = null;

		if (inEditor)
			FlxG.sound.music.stop();
		vocals.stop();
		vocals.destroy();
		vocalsDad.stop();
		vocalsDad.destroy();

		if (!isUsingGamepad)
		{
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}

		//reset window to before lua messed with it
		Application.current.window.title = 'Friday Night Funkin\'';
		CoolUtil.setWindowIcon();

		super.destroy();
	}

	public static function cancelMusicFadeTween() {
		if (FlxG.sound.music.fadeTween != null) {
			FlxG.sound.music.fadeTween.cancel();
		}
		FlxG.sound.music.fadeTween = null;
	}

	public function removeLua(lua:FunkinLua) {
		if (luaArray != null && !preventLuaRemove) {
			luaArray.remove(lua);
		}
	}

	var lastStepHit:Int = -1;
	override function stepHit()
	{
		super.stepHit();
		if (Math.abs(FlxG.sound.music.time / playbackRate - Conductor.songPosition) > 20
			|| (SONG.needsVoices && ((Math.abs(vocals.time / playbackRate - Conductor.songPosition) > 20) 
			|| (foundDadVocals && Math.abs(vocalsDad.time / playbackRate - Conductor.songPosition) > 20))))
		{
			resyncVocals();
		}

		if (curStep == lastStepHit) {
			return;
		}

		lastStepHit = curStep;
		setOnScripts('curStep', curStep);
		callOnScripts('onStepHit', []);
		/*if (ClientPrefs.skipIntro && controls.ACCEPT)
		{
            skipCountdown = true;
		    if (FileSystem.exists(Paths.getPreloadPath('data/$curSong/dialogue.json')))
			{
				psychDialogue = null;
				dialogueJson = null;
			}
			var text = new FlxText(0, FlxG.height * 0.89 + 36, FlxG.width, "Press ACCEPT to skip intro", 20);
			text.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			text.scrollFactor.set();
			text.borderSize = 1.25;
			text.visible = true;
			add(text);
			var timer = new haxe.Timer(2000);
            var now = Date.now();
            timer.run = function() {text.visible = false; }
            timer.stop;
		}*/
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

	var lastBeatHit:Int = -1;
	
	override function beatHit()
	{
		super.beatHit();

		if (lastBeatHit >= curBeat) {
			return;
		}

		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, ClientPrefs.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		}

		var curNumeratorBeat = Conductor.getCurNumeratorBeat(SONG, curBeat);
		var curSection = Conductor.getCurSection(SONG, curStep);
		var songSection = SONG.notes[curSection];
		if (songSection != null)
		{
			if (songSection.changeBPM && songSection.bpm != Conductor.bpm)
			{
				Conductor.changeBPM(songSection.bpm, playbackRate);
				setOnScripts('curBpm', Conductor.bpm);
				setOnScripts('crochet', Conductor.crochet);
				setOnScripts('stepCrochet', Conductor.stepCrochet);
				callOnScripts('onBPMChange', []);
			}
			if (songSection.changeSignature && (songSection.timeSignature[0] != Conductor.timeSignature[0] || songSection.timeSignature[1] != Conductor.timeSignature[1]))
			{
				Conductor.changeSignature(SONG.notes[Math.floor(curSection)].timeSignature);
				setOnScripts('signatureNumerator', Conductor.timeSignature[0]);
				setOnScripts('signatureDenominator', Conductor.timeSignature[1]);
				setOnScripts('crochet', Conductor.crochet);
				setOnScripts('stepCrochet', Conductor.stepCrochet);
				callOnScripts('onSignatureChange', []);
			}
			if (songSection.changeKeys)
			{
				switchKeys(songSection.playerKeys, songSection.opponentKeys);
			}
			setOnScripts('mustHitSection', songSection.mustHitSection);
			setOnScripts('altAnim', songSection.altAnim);
			setOnScripts('gfSection', songSection.gfSection);
			setOnScripts('lengthInSteps', songSection.lengthInSteps);
			setOnScripts('changeBPM', songSection.changeBPM);
			setOnScripts('changeSignature', songSection.changeSignature);
		}

		if (!inEditor) {
			if (ClientPrefs.camZooms && camZooming && camBop && FlxG.camera.zoom < 1.35 && curNumeratorBeat % Conductor.timeSignature[0] == 0)
			{
				FlxG.camera.zoom += 0.015;
				camHUD.zoom += 0.03;
			}

			if (iconBopSpeed > 0 && curBeat % iconBopSpeed == 0) { // no.
			}
			if (curBeat % iconBopSpeed == 0) {
				curBeat % (iconBopSpeed * 2) == 0 ? {
	
					FlxTween.angle(iconP1, -15, 0, Conductor.crochet / 1300 * iconBopSpeed, {ease: FlxEase.quadOut});
					FlxTween.angle(iconP2, 30, 0, Conductor.crochet / 1300 * iconBopSpeed, {ease: FlxEase.quadOut});
					iconP2.updateHitbox();
					iconP1.updateHitbox();

				} : {
	
					FlxTween.angle(iconP2, 0, 0, Conductor.crochet / 1300 * iconBopSpeed, {ease: FlxEase.quadOut});
					FlxTween.angle(iconP1, 0, 0, Conductor.crochet / 1300 * iconBopSpeed, {ease: FlxEase.quadOut});
					iconP2.updateHitbox();
					iconP1.updateHitbox();

				}
	
				FlxTween.tween(iconP1, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 * iconBopSpeed, {ease: FlxEase.quadOut});
				FlxTween.tween(iconP2, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 * iconBopSpeed, {ease: FlxEase.quadOut});

			}
			iconP1.scale.set(1.2, 1.2);
			iconP2.scale.set(1.2, 1.2);

			iconP2.updateHitbox();
			iconP1.updateHitbox();
			// x2 bop icons lol
			// yes scale

			var chars = [boyfriendGroup, dadGroup, gfGroup];
			for (group in chars) {
				for (char in group) {
					if (char.danceEveryNumBeats > 0 && curBeat % Math.round(char.danceEveryNumBeats) == 0 && !char.stunned && char.animation.curAnim != null && !char.animation.curAnim.name.startsWith("sing") && !char.specialAnim)
					{
						char.dance();
					}
				}
			}

			if (ClientPrefs.gameQuality != 'Crappy') {
				switch (curStage)
				{
					case 'school':
						if (ClientPrefs.gameQuality == 'Normal') {
							bgGirls.dance();
						}

					case 'mall':
						if (ClientPrefs.gameQuality == 'Normal') {
							upperBoppers.dance(true);
						}

						if (heyTimer <= 0) bottomBoppers.dance(true);
						santa.dance(true);

						case 'limo':
							if (ClientPrefs.gameQuality == 'Normal') {
								grpLimoDancers.forEach(function(dancer:BackgroundDancer)
								{
									dancer.dance();
								});
							}
	
							if (FlxG.random.bool(10) && fastCarCanDrive)
								fastCarDrive();
					case "philly":
						if (!trainMoving)
							trainCooldown += 1;

						if (curNumeratorBeat % Conductor.timeSignature[0] == 0)
						{
							phillyCityLights.forEach(function(light:BGSprite)
							{
								light.visible = false;
							});

							curLight = FlxG.random.int(0, phillyCityLights.length - 1, [curLight]);

							phillyCityLights.members[curLight].visible = true;
							phillyCityLights.members[curLight].alpha = 1;
						}

						if (curNumeratorBeat % (Conductor.timeSignature[0] * 2) == Conductor.timeSignature[0] && FlxG.random.bool(30) && !trainMoving && trainCooldown > 8)
						{
							trainCooldown = FlxG.random.int(-4, 0);
							trainStart();
						}
				}
			}

			if (curStage == 'spooky' && FlxG.random.bool(10) && curBeat > lightningStrikeBeat + lightningOffset && ClientPrefs.gameQuality != 'Crappy')
			{
				lightningStrikeShit();
			}
		}
		lastBeatHit = curBeat;

		setOnScripts('curBeat', curBeat);//DAWGG?????
		setOnScripts('curNumeratorBeat', curNumeratorBeat);
		setOnScripts('curSection', curSection);
		callOnScripts('onBeatHit', []);
	}

	function switchKeys(playerKeys:Int = 4, opponentKeys:Int = 4, init:Bool = false) {
		if (bfKeys != playerKeys || init) {
			if (!playerStrumMap.exists(playerKeys)) {
				generateStaticArrows(1, playerKeys);
			}
			bfKeys = playerKeys;
			if (!opponentChart) {
				this.playerKeys = playerKeys;
			} else {
				this.opponentKeys = playerKeys;
			}
			strumLineNotes.clear();
			playerStrums = playerStrumMap.get(playerKeys);
			for (i in opponentStrums) {
				strumLineNotes.add(i);
			}
			for (i in playerStrums) {
				strumLineNotes.add(i);
			}
			resetUnderlay(underlayPlayer, playerStrums);
			setKeysArray(this.playerKeys);
			setSkins();
			setOnScripts('playerKeyAmount', playerKeys);
			for (i in 0...playerStrums.length) {
				setOnScripts('defaultPlayerStrumX$i', playerStrums.members[i].x);
				setOnScripts('defaultPlayerStrumY$i', playerStrums.members[i].y);
			}
			setOnHscripts('playerStrums', playerStrums);
		}
		if (dadKeys != opponentKeys || init) {
			if (!opponentStrumMap.exists(opponentKeys)) {
				generateStaticArrows(0, opponentKeys);
			}
			dadKeys = opponentKeys;
			if (!opponentChart) {
				this.opponentKeys = opponentKeys;
			} else {
				this.playerKeys = opponentKeys;
			}
			strumLineNotes.clear();
			opponentStrums = opponentStrumMap.get(opponentKeys);
			for (i in opponentStrums) {
				strumLineNotes.add(i);
			}
			for (i in playerStrums) {
				strumLineNotes.add(i);
			}
			resetUnderlay(underlayOpponent, opponentStrums);
			setKeysArray(this.playerKeys);
			setSkins();
			setOnScripts('opponentKeys', opponentKeys);
			for (i in 0...opponentStrums.length) {
				setOnScripts('defaultOpponentStrumX$i', opponentStrums.members[i].x);
				setOnScripts('defaultOpponentStrumY$i', opponentStrums.members[i].y);
			}
			setOnHscripts('opponentStrums', opponentStrums);
		}
	}

	function setSkins():Void {
		//PLAYER
		var uiSkin = UIData.getUIFile(SONG.uiSkin);
		if (uiSkin == null) {
			uiSkin = UIData.getUIFile('');
		}
		var maniaData:ManiaArray = null;
		for (i in uiSkin.mania) {
			if (i.keys == bfKeys) {
				maniaData = i;
				break;
			}
		}
		if (maniaData == null) {
			FlxG.log.warn('Couldn\'t get ${bfKeys}K data for ${uiSkin.name}!');
			if (uiSkin.isPixel && uiSkin.name != 'pixel') {
				uiSkin = UIData.getUIFile('pixel');
			} else {
				uiSkin = UIData.getUIFile('');
			}
			maniaData = uiSkin.mania[bfKeys - 1];
		}
		if (!opponentChart) {
			playerSingAnimations = maniaData.singAnimations;
			playerColors = maniaData.colors;
		} else {
			opponentSingAnimations = maniaData.singAnimations;
			opponentColors = maniaData.colors;
		}
		uiSkinMap.set('player', uiSkin);
		setOnScripts('playerSkin', uiSkin.name);
		
		//OPPONENT
		var uiSkin = UIData.getUIFile(SONG.uiSkinOpponent);
		if (uiSkin == null) {
			uiSkin = UIData.getUIFile('');
		}
		var maniaData:ManiaArray = null;
		for (i in uiSkin.mania) {
			if (i.keys == dadKeys) {
				maniaData = i;
				break;
			}
		}
		if (maniaData == null) {
			FlxG.log.warn('Couldn\'t get ${dadKeys}K data for ${uiSkin.name}!');
			if (uiSkin.isPixel && uiSkin.name != 'pixel') {
				uiSkin = UIData.getUIFile('pixel');
			} else {
				uiSkin = UIData.getUIFile('');
			}
			maniaData = uiSkin.mania[dadKeys - 1];
		}
		if (opponentChart) {
			playerSingAnimations = maniaData.singAnimations;
			playerColors = maniaData.colors;
		} else {
			opponentSingAnimations = maniaData.singAnimations;
			opponentColors = maniaData.colors;
		}
		uiSkinMap.set('opponent', uiSkin);
		setOnScripts('opponentSkin', uiSkin.name);

		var imagesToCheck = [
			'shit',
			'bad',
			'good',
			'sick',
			'combo',
			'ready',
			'set',
			'go',
			'healthBar',
			'timeBar'
		];
		for (i in 0...10) {
			imagesToCheck.push('num$i');
		} 

		for (i in imagesToCheck) {
			uiSkinMap.set(i, UIData.checkSkinFile(i, opponentChart ? uiSkinMap.get('opponent') : uiSkinMap.get('player')));
		}
	}

	function makeDoubleTrail(char:Character, name:String, flipped:Bool = false, id:Int = 0, charGroup:FlxTypedSpriteGroup<Character>) {
		if (doubleTrailMap.exists(name)) {
			doubleTrailMap.get(name).kill();
			remove(doubleTrailMap.get(name));
			doubleTrailMap.get(name).destroy();
			doubleTrailMap.remove(name);
		}
		var doubleTrail:Character = new Character(char.x, char.y, char.curCharacter, flipped);
		doubleTrail.ID = id;
		insert(members.indexOf(charGroup) + 1, doubleTrail);
		doubleTrailMap.set(name, doubleTrail);
	}

	public var closeLuas:Array<FunkinLua> = [];
	public var closeHscripts:Array<String> = [];
	public function callOnScripts(event:String, args:Array<Dynamic>):Dynamic {
		var returnVal:Dynamic = FunkinLua.Function_Continue;
		if (!inEditor) {
			#if LUA_ALLOWED
			for (i in 0...closeLuas.length) {
				luaArray.remove(closeLuas[i]);
				closeLuas[i].stop();
			}
			
			for (i in 0...luaArray.length) {
				var ret:Dynamic = luaArray[i].call(event, args);
				if (ret != FunkinLua.Function_Continue) {
					returnVal = ret;
				}
			}
			#end

			#if HSCRIPT_ALLOWED
			for (i in 0...closeHscripts.length) {
				var hscript = hscriptMap.get(closeHscripts[i]);
				hscriptMap.remove(closeHscripts[i]);
				hscript = null;
			}

			for (i in hscriptMap.keys()) {
				var ret:Dynamic = callHscript(i, event, args);
				if (ret != FunkinLua.Function_Continue) {
					returnVal = ret;
				}
			}
			#end
		}
		return returnVal;
	}

	public function setOnScripts(variable:String, arg:Dynamic) {
		if (!inEditor) {
			#if LUA_ALLOWED
			for (i in 0...luaArray.length) {
				luaArray[i].set(variable, arg);
			}
			#end

			#if HSCRIPT_ALLOWED
			setOnHscripts(variable, arg);
			#end
		}
	}

	function strumPlayAnim(isDad:Bool, id:Int, time:Float) {
		var spr:StrumNote = null;
		if (isDad != opponentChart) {
			spr = opponentStrums.members[id];
		} else {
			spr = playerStrums.members[id];
		}

		if (spr != null) {
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	public var ratingName:String = '?';
	public var ratingPercent:Float;
	public var ratingFC:String;
	public function recalculateRating() {
		setOnScripts('score', songScore);
		setOnScripts('misses', songMisses);
		setOnScripts('hits', songHits);

		var ret:Dynamic = callOnScripts('onRecalculateRating', []);
		if (ret != FunkinLua.Function_Stop)
		{
			if (totalPlayed < 1) //Prevent divide by 0
				ratingName = '?';
			else
			{
				// Rating Percent
				ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));

				// Rating Name
				if (ratingPercent >= 1)
				{
					ratingName = ratingStuff[ratingStuff.length - 1][0]; //Uses last string
				}
				else
				{
					for (i in 0...ratingStuff.length - 1)
					{
						if (ratingPercent < ratingStuff[i][1])
						{
							ratingName = ratingStuff[i][0];
							break;
						}
					}
				}
			}


			// Rating FC
			ratingFC = "";
			if (sicks > 0) ratingFC = "SFC";
			if (goods > 0) ratingFC = "GFC";
			if (bads > 0 || shits > 0) ratingFC = "FC";
			if (songMisses > 0 && songMisses < 10) ratingFC = "SDCB";
			else if (songMisses >= 10) ratingFC = "Clear";
			//if (songMisses = 0) {noteCombo();}
		}
		setOnScripts('rating', ratingPercent);
		setOnScripts('ratingName', ratingName);
		setOnScripts('ratingFC', ratingFC);
	}

	#if ACHIEVEMENTS_ALLOWED
	private function checkForAchievement(achievesToCheck:Array<String> = null):String
	{
		if (chartingMode || cpuControlled) return null;

		var usedPractice:Bool = practiceMode;
		for (i in 0...achievesToCheck.length) {
			var achievementName:String = achievesToCheck[i];
			if(!Achievements.isAchievementUnlocked(achievementName)) {
				var unlock:Bool = false;
				switch(achievementName)
				{
					case 'week1_nomiss' | 'week2_nomiss' | 'week3_nomiss' | 'week4_nomiss' | 'week5_nomiss' | 'week6_nomiss' | 'week7_nomiss':
						if(isStoryMode && campaignMisses + songMisses < 1 && CoolUtil.difficultyString() == 'HARD' && storyPlaylist.length <= 1 && !changedDifficulty && !usedPractice)
						{
							var weekName:String = WeekData.getWeekFileName();
							switch(weekName) //I know this is a lot of duplicated code, but it's easier readable and you can add weeks with different names than the achievement tag
							{
								case 'week1':
									if(achievementName == 'week1_nomiss') unlock = true;
								case 'week2':
									if(achievementName == 'week2_nomiss') unlock = true;
								case 'week3':
									if(achievementName == 'week3_nomiss') unlock = true;
								case 'week4':
									if(achievementName == 'week4_nomiss') unlock = true;
								case 'week5':
									if(achievementName == 'week5_nomiss') unlock = true;
								case 'week6':
									if(achievementName == 'week6_nomiss') unlock = true;
								case 'week7':
									if(achievementName == 'week7_nomiss') unlock = true;
							}
						}
					case 'ur_bad':
						if (totalPlayed > 0 && ratingPercent < 0.2 && !usedPractice) {
							unlock = true;
						}
					case 'ur_good':
						if (totalPlayed > 0 && ratingPercent >= 1 && !usedPractice) {
							unlock = true;
						}
					case 'roadkill_enthusiast':
						if (Achievements.henchmenDeath >= 100) {
							unlock = true;
						}
					case 'oversinging':
						if (playerChar.members[0].holdTimer >= 10 && !usedPractice) {
							unlock = true;
						}
					case 'hype':
						if (!boyfriendIdled && !usedPractice) {
							unlock = true;
						}
					case 'two_keys':
						if (!usedPractice) {
							var howManyPresses:Int = 0;
							for (j in 0...keysPressed.length) {
								if (keysPressed[j]) howManyPresses++;
							}

							if (howManyPresses <= 2) {
								unlock = true;
							}
						}
					case 'toastie':
						
					    if (ClientPrefs.gameQuality != 'Normal' && !ClientPrefs.globalAntialiasing) {
							unlock = true;
						}
					case 'debugger':
						if (curSong == 'test' && !usedPractice) {
							unlock = true;
						}
				}

				if (unlock) {
					Achievements.unlockAchievement(achievementName);
					return achievementName;
				}
			}
		}
		return null;
	}
	#end

	var curLight:Int = 0;
	var curLightEvent:Int = 0;
	var traced:Bool = false;
}
