#if LUA_ALLOWED
import llua.Convert;
import llua.Lua;
import llua.LuaL;
import llua.State;
#end

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.util.FlxSave;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.app.Application;
import openfl.display.BlendMode;
import openfl.utils.Assets;
import DialogueBoxPsych;
import Type.ValueType;
import Shaders;
#if MODS_ALLOWED
import sys.FileSystem;
#end
#if DISCORD_ALLOWED
import Discord;
#end

using StringTools;

class FunkinLua {
	#if (windows || html5)
	public static var Function_Stop:Dynamic = 1;
	public static var Function_Continue:Dynamic = 0;
	#else
	public static var Function_Stop:Dynamic = 'Function_Stop';
	public static var Function_Continue:Dynamic = 'Function_Continue';
	#end

	#if LUA_ALLOWED
	public var lua:State = null;
	#end

	public var scriptName:String = '';
	var gonnaClose:Bool = false;

	public function new(script:String) {
		#if LUA_ALLOWED
		lua = LuaL.newstate();
		LuaL.openlibs(lua);
		Lua.init_callbacks(lua);

		//LuaL.dostring(lua, CLEANSE); cuz OS support is needing so freaking much
		var result:Dynamic = LuaL.dofile(lua, script);
		var resultStr:String = Lua.tostring(lua, result);
		if (resultStr != null && result != 0) {
			trace('Error on lua script! ' + resultStr);
			#if windows
			Application.current.window.alert(resultStr, 'Error on lua script!');
			#else
			luaTrace('Error loading lua script: "$script"\n' + resultStr,true,false);
			#end
			lua = null;
			return;
		}
		scriptName = script;
		trace('lua file loaded succesfully: $script');

		// Lua shit
		set('Function_Stop', Function_Stop);
		set('Function_Continue', Function_Continue);
		set('luaDebugMode', false);
		set('luaDeprecatedWarnings', true);
		set('inChartEditor', PlayState.instance.inEditor);

		// Song/Week shit
		set('curBpm', Conductor.bpm);
		set('bpm', Conductor.bpm);
		set('signatureNumerator', Conductor.timeSignature[0]);
		set('signatureDenominator', Conductor.timeSignature[1]);
		set('crochet', Conductor.crochet);
		set('stepCrochet', Conductor.stepCrochet);
		set('scrollSpeed', PlayState.SONG.speed);
		set('playerKeyAmount', PlayState.SONG.playerKeyAmount);
		set('opponentKeyAmount', PlayState.SONG.opponentKeyAmount);
		set('playerSkin', PlayState.instance.uiSkinMap.get('player').name);
		set('opponentSkin', PlayState.instance.uiSkinMap.get('opponent').name);
		set('songLength', 0);
		set('songName', PlayState.SONG.song);
		set('startedCountdown', false);

		set('isStoryMode', PlayState.isStoryMode);
		set('difficulty', PlayState.storyDifficulty);
		set('difficultyName', CoolUtil.difficulties[PlayState.storyDifficulty]);
		set('weekRaw', PlayState.storyWeek);
		set('week', WeekData.weeksLoaded.get(WeekData.weeksList[PlayState.storyWeek]).fileName);
		set('seenCutscene', PlayState.seenCutscene);

		// Camera poo
		set('cameraX', 0);
		set('cameraY', 0);
		
		// Screen stuff
		set('screenWidth', FlxG.width);
		set('screenHeight', FlxG.height);

		// PlayState cringe ass nae nae bullcrap
		set('curBeat', 0);
		set('curNumeratorBeat', 0);
		set('curStep', 0);

		set('score', 0);
		set('misses', 0);
		set('hits', 0);

		set('rating', 0);
		set('ratingName', '');
		set('ratingFC', '');
		set('version', MainMenuState.engineVersion.trim());
		
		set('inGameOver', false);
		set('curSection', 0);
		set('mustHitSection', false);
		set('altAnim', false);
		set('gfSection', false);
		set('lengthInSteps', 16);
		set('changeBPM', false);
		set('changeSignature', false);

		// Gameplay settings
		set('healthGainMult', PlayState.instance.healthGain);
		set('healthLossMult', PlayState.instance.healthLoss);
		set('instakillOnMiss', PlayState.instance.instakillOnMiss);
		set('botPlay', PlayState.instance.cpuControlled);
		set('practice', PlayState.instance.practiceMode);
		set('opponentPlay', PlayState.instance.opponentChart);
		set('playbackRate', PlayState.instance.playbackRate);

		for (i in 0...Note.MAX_KEYS) {
			set('defaultPlayerStrumX$i', 0);
			set('defaultPlayerStrumY$i', 0);
			set('defaultOpponentStrumX$i', 0);
			set('defaultOpponentStrumY$i', 0);
		}

		// Default character positions woooo
		set('defaultBoyfriendX', PlayState.instance.BF_X);
		set('defaultBoyfriendY', PlayState.instance.BF_Y);
		set('defaultOpponentX', PlayState.instance.DAD_X);
		set('defaultOpponentY', PlayState.instance.DAD_Y);
		set('defaultGirlfriendX', PlayState.instance.GF_X);
		set('defaultGirlfriendY', PlayState.instance.GF_Y);

		// Character shit
		set('boyfriendName', PlayState.SONG.player1);
		set('dadName', PlayState.SONG.player2);
		set('gfName', PlayState.SONG.gfVersion);

		// Some settings, no jokes
		set('downscroll', ClientPrefs.downScroll);
		set('middlescroll', ClientPrefs.middleScroll);
		set('framerate', ClientPrefs.framerate);
		set('ghostTapping', ClientPrefs.ghostTapping);
		set('hideHud', ClientPrefs.hideHud);
		set('timeBarType', ClientPrefs.timeBarType);
		set('scoreZoom', ClientPrefs.scoreZoom);
		set('cameraZoomOnBeat', ClientPrefs.camZooms);
		set('flashingLights', ClientPrefs.flashing);
		set('noteOffset', ClientPrefs.noteOffset);
		set('healthBarAlpha', ClientPrefs.healthBarAlpha);
		set('noResetButton', ClientPrefs.noReset);
		set('gameQuality', ClientPrefs.gameQuality);
		set('instantRestart', ClientPrefs.instantRestart);
		set('lowQuality', ClientPrefs.gameQuality != 'Normal');

		#if windows
		set('buildTarget', 'windows');
		#elseif linux
		set('buildTarget', 'linux');
		#elseif mac
		set('buildTarget', 'mac');
		#elseif html5
		set('buildTarget', 'browser');
		#elseif android
		set('buildTarget', 'android');
		#elseif windows32
		set('buildTarget', 'windows-32-bit')
		#else
		set('buildTarget', 'unknown');
		#end



		Lua_helper.add_callback(lua, "addLuaScript", function(luaFile:String, ?ignoreAlreadyRunning:Bool = false) { //would be dope asf. 
			var cervix = '$luaFile.lua';
			var doPush = false;
			if (FileSystem.exists(Paths.modFolders(cervix))) {
				cervix = Paths.modFolders(cervix);
				doPush = true;
			} else {
				cervix = Paths.getPreloadPath(cervix);
				if (FileSystem.exists(cervix)) {
					doPush = true;
				}
			}

			if (doPush)
			{
				if (!ignoreAlreadyRunning)
				{
					for (luaInstance in PlayState.instance.luaArray)
					{
						if (luaInstance.scriptName == cervix)
						{
							luaTrace('The script "$cervix" is already running!');
							return;
						}
					}
				}
				PlayState.instance.luaArray.push(new FunkinLua(cervix)); 
				return;
			}
			luaTrace("Script doesn't exist!");
		});
		Lua_helper.add_callback(lua, "removeLuaScript", function(luaFile:String, ?ignoreAlreadyRunning:Bool = false) { //would be dope asf. 
			var cervix = '$luaFile.lua';
			var doPush = false;
			if (FileSystem.exists(Paths.modFolders(cervix))) {
				cervix = Paths.modFolders(cervix);
				doPush = true;
			} else {
				cervix = Paths.getPreloadPath(cervix);
				if (FileSystem.exists(cervix)) {
					doPush = true;
				}
			}

			if (doPush)
			{
				for (luaInstance in PlayState.instance.luaArray)
				{
					if (luaInstance.scriptName == cervix)
					{
						PlayState.instance.luaArray.remove(luaInstance); 
						return;
					}
				}
				return;
			}
			luaTrace("Script doesn't exist!");
		});

		Lua_helper.add_callback(lua, "clearUnusedMemory", function() {
			Paths.clearUnusedMemory();
			return true;
		});

		Lua_helper.add_callback(lua, "changeWindowTitle", function(title:String = 'Friday Night Funkin\'') {
			Application.current.window.title = title;
		});
		Lua_helper.add_callback(lua, "changeWindowIcon", function(image:String) {
			CoolUtil.setWindowIcon(image);
		});
		Lua_helper.add_callback(lua, "windowAlert", function(message:String = 'Message Here', title:String = 'Alert') {
			Application.current.window.alert(message, title);
		});

		Lua_helper.add_callback(lua, "loadGraphic", function(variable:String, image:String) {
			var spr:FlxSprite = getObjectDirectly(variable);
			if (spr != null && image != null && image.length > 0)
			{
				spr.loadGraphic(Paths.image(image));
			}
		});
		Lua_helper.add_callback(lua, "loadFrames", function(variable:String, image:String, spriteType:String = "sparrow") {
			var spr:FlxSprite = getObjectDirectly(variable);
			if (spr != null && image != null && image.length > 0)
			{
				loadFrames(spr, image, spriteType);
			}
		});
		Lua_helper.add_callback(lua, "getProperty", function(variable:String) {
			var killMe:Array<String> = variable.split('.');
			if (killMe.length > 1) {
				return Reflect.getProperty(getPropertyLoopThingWhatever(killMe), killMe[killMe.length - 1]);
			}
			return Reflect.getProperty(getInstance(), variable);
		});
		Lua_helper.add_callback(lua, "setProperty", function(variable:String, value:Dynamic) {
			var killMe:Array<String> = variable.split('.');
			if (killMe.length > 1) {
				return Reflect.setProperty(getPropertyLoopThingWhatever(killMe), killMe[killMe.length - 1], value);
			}
			return Reflect.setProperty(getInstance(), variable, value);
		});
		Lua_helper.add_callback(lua, "getPropertyFromGroup", function(obj:String, index:Int, variable:Dynamic) {
			if (Std.isOfType(Reflect.getProperty(getInstance(), obj), FlxTypedGroup) || Std.isOfType(Reflect.getProperty(getInstance(), obj), FlxTypedSpriteGroup)) {
				trace(getGroupStuff(Reflect.getProperty(getInstance(), obj).members[index], variable));
				return getGroupStuff(Reflect.getProperty(getInstance(), obj).members[index], variable);
			}

			var leArray:Dynamic = Reflect.getProperty(getInstance(), obj)[index];
			if (leArray != null) {
				if (Type.typeof(variable) == ValueType.TInt) {
					return leArray[variable];
				}
				return getGroupStuff(leArray, variable);
			}
			luaTrace('Object #$index from group: $obj doesn\'t exist!');
			return null;
		});
		Lua_helper.add_callback(lua, "setPropertyFromGroup", function(obj:String, index:Int, variable:Dynamic, value:Dynamic) {
			if (Std.isOfType(Reflect.getProperty(getInstance(), obj), FlxTypedGroup) || Std.isOfType(Reflect.getProperty(getInstance(), obj), FlxTypedSpriteGroup)) {
				setGroupStuff(Reflect.getProperty(getInstance(), obj).members[index], variable, value);
				return;
			}

			var leArray:Dynamic = Reflect.getProperty(getInstance(), obj)[index];
			if (leArray != null) {
				if (Type.typeof(variable) == ValueType.TInt) {
					leArray[variable] = value;
					return;
				}
				setGroupStuff(leArray, variable, value);
			}
		});
		Lua_helper.add_callback(lua, "removeFromGroup", function(obj:String, index:Int, dontDestroy:Bool = false) {
			if (Std.isOfType(Reflect.getProperty(getInstance(), obj), FlxTypedGroup) || Std.isOfType(Reflect.getProperty(getInstance(), obj), FlxTypedSpriteGroup)) {
				var sex = Reflect.getProperty(getInstance(), obj).members[index];
				if (!dontDestroy)
					sex.kill();
				Reflect.getProperty(getInstance(), obj).remove(sex, true);
				if (!dontDestroy)
					sex.destroy();
				return;
			}
			Reflect.getProperty(getInstance(), obj).remove(Reflect.getProperty(getInstance(), obj)[index]);
		});

		Lua_helper.add_callback(lua, "getPropertyFromClass", function(classVar:String, variable:String) {
			var killMe:Array<String> = variable.split('.');
			if (killMe.length > 1) {
				var coverMeInPiss:Dynamic = Reflect.getProperty(Type.resolveClass(classVar), killMe[0]);
				for (i in 1...killMe.length - 1) {
					coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
				}
				return Reflect.getProperty(coverMeInPiss, killMe[killMe.length - 1]);
			}
			return Reflect.getProperty(Type.resolveClass(classVar), variable);
		});
		Lua_helper.add_callback(lua, "setPropertyFromClass", function(classVar:String, variable:String, value:Dynamic) {
			var killMe:Array<String> = variable.split('.');
			if (killMe.length > 1) {
				var coverMeInPiss:Dynamic = Reflect.getProperty(Type.resolveClass(classVar), killMe[0]);
				for (i in 1...killMe.length - 1) {
					coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
				}
				return Reflect.setProperty(coverMeInPiss, killMe[killMe.length - 1], value);
			}
			return Reflect.setProperty(Type.resolveClass(classVar), variable, value);
		});

		//shitass stuff for epic coders like me B)  *image of obama giving himself a medal*
		Lua_helper.add_callback(lua, "getObjectOrder", function(obj:String) {
			if (PlayState.instance.modchartSprites.exists(obj))
			{
				return getInstance().members.indexOf(PlayState.instance.modchartSprites.get(obj));
			}
			else if (PlayState.instance.modchartTexts.exists(obj))
			{
				return getInstance().members.indexOf(PlayState.instance.modchartTexts.get(obj));
			}

			var leObj:FlxBasic = Reflect.getProperty(getInstance(), obj);
			if (leObj != null)
			{
				return getInstance().members.indexOf(leObj);
			}
			luaTrace('Object $obj doesn\'t exist!');
			return -1;
		});
		Lua_helper.add_callback(lua, "setObjectOrder", function(obj:String, position:Int) {
			if (PlayState.instance.modchartSprites.exists(obj)) {
				var spr:ModchartSprite = PlayState.instance.modchartSprites.get(obj);
				if (spr.wasAdded) {
					getInstance().remove(spr, true);
				}
				getInstance().insert(position, spr);
				return;
			}
			if (PlayState.instance.modchartTexts.exists(obj)) {
				var spr:ModchartText = PlayState.instance.modchartTexts.get(obj);
				if (spr.wasAdded) {
					getInstance().remove(spr, true);
				}
				getInstance().insert(position, spr);
				return;
			}

			var leObj:FlxBasic = Reflect.getProperty(getInstance(), obj);
			if (leObj != null) {
				getInstance().remove(leObj, true);
				getInstance().insert(position, leObj);
				return;
			}
			luaTrace('Object $obj doesn\'t exist!');
		});

		// gay ass tweens
		Lua_helper.add_callback(lua, "doTweenX", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			var penisExam:Dynamic = tweenShit(tag, vars);
			if (penisExam != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(penisExam, {x: value}, duration, {ease: getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnScripts('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			} else {
				luaTrace('Couldnt find object: $vars');
			}
		});
		Lua_helper.add_callback(lua, "doTweenY", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			var penisExam:Dynamic = tweenShit(tag, vars);
			if (penisExam != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(penisExam, {y: value}, duration, {ease: getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnScripts('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			} else {
				luaTrace('Couldnt find object: $vars');
			}
		});
		Lua_helper.add_callback(lua, "doTweenAngle", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			var penisExam:Dynamic = tweenShit(tag, vars);
			if (penisExam != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(penisExam, {angle: value}, duration, {ease: getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnScripts('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			} else {
				luaTrace('Couldnt find object: $vars');
			}
		});
		Lua_helper.add_callback(lua, "doTweenAlpha", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			var penisExam:Dynamic = tweenShit(tag, vars);
			if (penisExam != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(penisExam, {alpha: value}, duration, {ease: getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnScripts('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			} else {
				luaTrace('Couldnt find object: $vars');
			}
		});
		Lua_helper.add_callback(lua, "doTweenZoom", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			var penisExam:Dynamic = tweenShit(tag, vars);
			if (penisExam != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(penisExam, {zoom: value}, duration, {ease: getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnScripts('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			} else {
				luaTrace('Couldnt find object: $vars');
			}
		});
		Lua_helper.add_callback(lua, "doTweenColor", function(tag:String, vars:String, targetColor:String, duration:Float, ease:String) {
			var penisExam:Dynamic = tweenShit(tag, vars);
			if (penisExam != null) {
				var color:Int = Std.parseInt(targetColor);
				if (!targetColor.startsWith('0x')) color = Std.parseInt('0xff$targetColor');

				var curColor:FlxColor = penisExam.color;
				curColor.alphaFloat = penisExam.alpha;
				PlayState.instance.modchartTweens.set(tag, FlxTween.color(penisExam, duration, curColor, color, {ease: getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.modchartTweens.remove(tag);
						PlayState.instance.callOnScripts('onTweenCompleted', [tag]);
					}
				}));
			} else {
				luaTrace('Couldnt find object: $vars');
			}
		});

		//Tween shit, but for strums
		Lua_helper.add_callback(lua, "noteTweenX", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
			cancelTween(tag);
			if (note < 0) note = 0;
			var testicle:StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];

			if (testicle != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {x: value}, duration, {ease: getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnScripts('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
		});
		Lua_helper.add_callback(lua, "noteTweenY", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
			cancelTween(tag);
			if (note < 0) note = 0;
			var testicle:StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];

			if (testicle != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {y: value}, duration, {ease: getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnScripts('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
		});
		Lua_helper.add_callback(lua, "noteTweenAngle", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
			cancelTween(tag);
			if (note < 0) note = 0;
			var testicle:StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];

			if (testicle != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {angle: value}, duration, {ease: getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnScripts('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
		});
		Lua_helper.add_callback(lua, "noteTweenAlpha", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
			cancelTween(tag);
			if (note < 0) note = 0;
			var testicle:StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];

			if (testicle != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {alpha: value}, duration, {ease: getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnScripts('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
		});
		Lua_helper.add_callback(lua, "noteTweenDirection", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
			cancelTween(tag);
			if (note < 0) note = 0;
			var testicle:StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];

			if (testicle != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {direction: value}, duration, {ease: getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnScripts('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
		});
		Lua_helper.add_callback(lua, "mouseClicked", function(button:String) {
			var boobs = FlxG.mouse.justPressed;
			switch(button) {
				case 'middle':
					boobs = FlxG.mouse.justPressedMiddle;
				case 'right':
					boobs = FlxG.mouse.justPressedRight;
			}
			
			
			return boobs;
		});
		Lua_helper.add_callback(lua, "mousePressed", function(button:String) {
			var boobs = FlxG.mouse.pressed;
			switch(button) {
				case 'middle':
					boobs = FlxG.mouse.pressedMiddle;
				case 'right':
					boobs = FlxG.mouse.pressedRight;
			}
			return boobs;
		});
		Lua_helper.add_callback(lua, "mouseReleased", function(button:String) {
			var boobs = FlxG.mouse.justReleased;
			switch(button) {
				case 'middle':
					boobs = FlxG.mouse.justReleasedMiddle;
				case 'right':
					boobs = FlxG.mouse.justReleasedRight;
			}
			return boobs;
		});

		Lua_helper.add_callback(lua, "cancelTween", function(tag:String) {
			cancelTween(tag);
		});

		Lua_helper.add_callback(lua, "runTimer", function(tag:String, time:Float = 1, loops:Int = 1) {
			cancelTimer(tag);
			PlayState.instance.modchartTimers.set(tag, new FlxTimer().start(time, function(tmr:FlxTimer) {
				if (tmr.finished) {
					PlayState.instance.modchartTimers.remove(tag);
				}
				PlayState.instance.callOnScripts('onTimerCompleted', [tag, tmr.loops, tmr.loopsLeft]);
			}, loops));
		});
		Lua_helper.add_callback(lua, "cancelTimer", function(tag:String) {
			cancelTimer(tag);
		});
		
		//stupid bietch ass functions
		Lua_helper.add_callback(lua, "addScore", function(value:Int = 0) {
			PlayState.instance.songScore += value;
			PlayState.instance.recalculateRating();
		});
		Lua_helper.add_callback(lua, "addMisses", function(value:Int = 0) {
			PlayState.instance.songMisses += value;
			PlayState.instance.recalculateRating();
		});
		Lua_helper.add_callback(lua, "addHits", function(value:Int = 0) {
			PlayState.instance.songHits += value;
			PlayState.instance.recalculateRating();
		});
		Lua_helper.add_callback(lua, "setScore", function(value:Int = 0) {
			PlayState.instance.songScore = value;
			PlayState.instance.recalculateRating();
		});
		Lua_helper.add_callback(lua, "setMisses", function(value:Int = 0) {
			PlayState.instance.songMisses = value;
			PlayState.instance.recalculateRating();
		});
		Lua_helper.add_callback(lua, "setHits", function(value:Int = 0) {
			PlayState.instance.songHits = value;
			PlayState.instance.recalculateRating();
		});
		Lua_helper.add_callback(lua, "judgeNote", function(strumTime:Float = 0) {
			return Conductor.judgeNote(Math.abs(strumTime - Conductor.songPosition + ClientPrefs.ratingOffset));
		});

		Lua_helper.add_callback(lua, "setHealth", function(value:Float = 0) {
			PlayState.instance.health = value;
		});
		Lua_helper.add_callback(lua, "addHealth", function(value:Float = 0) {
			PlayState.instance.health += value;
		});
		Lua_helper.add_callback(lua, "getHealth", function() {
			return PlayState.instance.health;
		});
		
		Lua_helper.add_callback(lua, "round", Math.round);
		Lua_helper.add_callback(lua, "isNaN", Math.isNaN);
		Lua_helper.add_callback(lua, "isFinite", Math.isFinite);
		Lua_helper.add_callback(lua, "lerp", FlxMath.lerp);
		Lua_helper.add_callback(lua, "remapToRange", FlxMath.remapToRange);
		Lua_helper.add_callback(lua, "roundDecimal", FlxMath.roundDecimal);
		Lua_helper.add_callback(lua, "boundTo", CoolUtil.boundTo);
		Lua_helper.add_callback(lua, "dominantColor", function(obj:String) {
			var sprite = getObjectDirectly(obj);
			if (sprite != null && (sprite is FlxSprite)) {
				return CoolUtil.dominantColor(sprite);
			}
			return 0xff000000;
		});
		Lua_helper.add_callback(lua, "getColorFromHex", function(color:String) {
			if (!color.startsWith('0x')) color = '0xff$color';
			return Std.parseInt(color);
		});
		Lua_helper.add_callback(lua, "keyJustPressed", function(name:String) {
			var key:Bool = false;
			switch(name) {
				case 'left': key = PlayState.instance.controlJustPressed('note4_0');
				case 'down': key = PlayState.instance.controlJustPressed('note4_1');
				case 'up': key = PlayState.instance.controlJustPressed('note4_2');
				case 'right': key = PlayState.instance.controlJustPressed('note4_3');
				case 'accept': key = PlayState.instance.controlJustPressed('accept');
				case 'back': key = PlayState.instance.controlJustPressed('back');
				case 'pause': key = PlayState.instance.controlJustPressed('pause');
				case 'reset': key = PlayState.instance.controlJustPressed('reset');
				case 'space': key = FlxG.keys.justPressed.SPACE;//an extra key for convinience
				default: key = PlayState.instance.controlJustPressed(name);
			}
			return key;
		});
		Lua_helper.add_callback(lua, "keyPressed", function(name:String) {
			var key:Bool = false;
			switch(name) {
				case 'left': key = PlayState.instance.controlPressed('note4_0');
				case 'down': key = PlayState.instance.controlPressed('note4_1');
				case 'up': key = PlayState.instance.controlPressed('note4_2');
				case 'right': key = PlayState.instance.controlPressed('note4_3');
				case 'space': key = FlxG.keys.pressed.SPACE;//an extra key for convinience
				default: key = PlayState.instance.controlPressed(name);
			}
			return key;
		});
		Lua_helper.add_callback(lua, "keyReleased", function(name:String) {
			var key:Bool = false;
			switch(name) {
				case 'left': key = PlayState.instance.controlReleased('note4_0');
				case 'down': key = PlayState.instance.controlReleased('note4_1');
				case 'up': key = PlayState.instance.controlReleased('note4_2');
				case 'right': key = PlayState.instance.controlReleased('note4_3');
				case 'space': key = FlxG.keys.justReleased.SPACE;//an extra key for convinience
				default: key = PlayState.instance.controlReleased(name);
			}
			return key;
		});
		Lua_helper.add_callback(lua, "addCharacterToList", function(name:String, type:String, ?index:Int = 0) {
			var charType:Int = 0;
			switch(type.toLowerCase()) {
				case 'dad': charType = 1;
				case 'gf' | 'girlfriend': charType = 2;
			}
			PlayState.instance.addCharacterToList(name, charType, index);
		});
		Lua_helper.add_callback(lua, "precacheImage", function(name:String) {
			Paths.returnGraphic(name);
		});
		Lua_helper.add_callback(lua, "precacheSound", function(name:String) {
			CoolUtil.precacheSound(name);
		});
		Lua_helper.add_callback(lua, "precacheMusic", function(name:String) {
			CoolUtil.precacheMusic(name);
		});
		Lua_helper.add_callback(lua, "triggerEvent", function(name:String, arg1:Dynamic, arg2:Dynamic) {
			var value1:String = arg1;
			var value2:String = arg2;
			PlayState.instance.triggerEventNote(name, value1, value2);
		});

		Lua_helper.add_callback(lua, "startCountdown", function(variable:String) {
			PlayState.instance.startCountdown();
		});
		Lua_helper.add_callback(lua, "loadSong", function(name:String = null, ?difficultyNum:Int = -1, ?skipTransition:Bool = false) {
			if (name == null) name = PlayState.SONG.song;
			if (difficultyNum < 0) difficultyNum = PlayState.storyDifficulty;

			if (skipTransition)
			{
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
			}

			if (PlayState.isStoryMode && !PlayState.instance.transitioning) {
				PlayState.campaignScore += PlayState.instance.songScore;
				PlayState.campaignMisses += PlayState.instance.songMisses;
				PlayState.storyPlaylist.remove(PlayState.storyPlaylist[0]);
				PlayState.storyPlaylist.insert(0, name);
			}

			CoolUtil.getDifficulties(name, true);
			if (difficultyNum >= CoolUtil.difficulties.length) {
				difficultyNum = CoolUtil.difficulties.length - 1;
			}
			var poop = Highscore.formatSong(name, difficultyNum, false);
			PlayState.SONG = Song.loadFromJson(poop, name);
			PlayState.storyDifficulty = difficultyNum;
			PlayState.instance.persistentUpdate = false;
			PlayState.cancelMusicFadeTween();
			PlayState.deathCounter = 0;
			FlxG.sound.music.pause();
			FlxG.sound.music.volume = 0;
			if(PlayState.instance.vocals != null)
			{
				PlayState.instance.vocals.pause();
				PlayState.instance.vocals.volume = 0;
			}
			if(PlayState.instance.vocalsDad != null)
			{
				PlayState.instance.vocalsDad.pause();
				PlayState.instance.vocalsDad.volume = 0;
			}
			LoadingState.loadAndResetState();
		});
		Lua_helper.add_callback(lua, "endSong", function() {
			PlayState.instance.killNotes();
			PlayState.instance.finishSong(true);
		});
		Lua_helper.add_callback(lua, "restartSong", function(skipTransition:Bool = false) {
			PlayState.instance.persistentUpdate = false;
			PauseSubState.restartSong(skipTransition);
		});
		Lua_helper.add_callback(lua, "exitSong", function(skipTransition:Bool = false) {
			if (skipTransition)
			{
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
			}

			PlayState.cancelMusicFadeTween();
			CustomFadeTransition.nextCamera = PlayState.instance.camOther;
			if (FlxTransitionableState.skipNextTransIn)
				CustomFadeTransition.nextCamera = null;

			if (PlayState.isStoryMode)
				MusicBeatState.switchState(new StoryMenuState());
			else
				MusicBeatState.switchState(new FreeplayState());

			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			PlayState.changedDifficulty = false;
			PlayState.chartingMode = false;
			PlayState.instance.transitioning = true;
			PlayState.deathCounter = 0;
		});
		Lua_helper.add_callback(lua, "pauseGame", function() {
			PlayState.instance.pauseGame();
		});
		Lua_helper.add_callback(lua, "openCredits", function(playMusic:Bool = true) {
			PlayState.cancelMusicFadeTween();
			CustomFadeTransition.nextCamera = PlayState.instance.camOther;
			if (FlxTransitionableState.skipNextTransIn)
				CustomFadeTransition.nextCamera = null;

			CreditsState.skipToCurrentMod = true;
			MusicBeatState.switchState(new CreditsState());

			FlxG.sound.music.stop();
			if (playMusic)
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
			PlayState.changedDifficulty = false;
			PlayState.chartingMode = false;
			PlayState.instance.transitioning = true;
			PlayState.deathCounter = 0;
		});
		Lua_helper.add_callback(lua, "getSongPosition", function() {
			return Conductor.songPosition;
		});
		Lua_helper.add_callback(lua, "setSongPosition", function(time:Float = 0) {
			if(time < Conductor.songPosition)
			{
				PlayState.startOnTime = time;
				PauseSubState.restartSong(true);
			}
			else if (time != Conductor.songPosition)
			{
				PlayState.instance.clearNotesBefore(time);
				PlayState.instance.setSongTime(time);
			}
		});

		Lua_helper.add_callback(lua, "getCharacterX", function(type:String) {
			var charData = type.split(',');
			var index = 0;
			if (charData[1] != null) index = Std.parseInt(charData[1]);
			switch(charData[0].toLowerCase()) {
				case 'dad' | 'opponent' | '1':
					return PlayState.instance.dadGroup.members[index % PlayState.instance.dadGroup.members.length].x;
				case 'gf' | 'girlfriend' | '2':
					return PlayState.instance.gfGroup.members[index % PlayState.instance.gfGroup.members.length].x;
				default:
					return PlayState.instance.boyfriendGroup.members[index % PlayState.instance.boyfriendGroup.members.length].x;
			}
		});
		Lua_helper.add_callback(lua, "setCharacterX", function(type:String, value:Float) {
			var charData = type.split(',');
			var index = 0;
			if (charData[1] != null) index = Std.parseInt(charData[1]);
			switch(charData[0].toLowerCase()) {
				case 'dad' | 'opponent' | '1':
					PlayState.instance.dadGroup.members[index % PlayState.instance.dadGroup.members.length].x = value;
				case 'gf' | 'girlfriend' | '2':
					PlayState.instance.gfGroup.members[index % PlayState.instance.gfGroup.members.length].x = value;
				default:
					PlayState.instance.boyfriendGroup.members[index % PlayState.instance.boyfriendGroup.members.length].x = value;
			}
		});
		Lua_helper.add_callback(lua, "getCharacterY", function(type:String) {
			var charData = type.split(',');
			var index = 0;
			if (charData[1] != null) index = Std.parseInt(charData[1]);
			switch(charData[0].toLowerCase()) {
				case 'dad' | 'opponent' | '1':
					return PlayState.instance.dadGroup.members[index % PlayState.instance.dadGroup.members.length].y;
				case 'gf' | 'girlfriend' | '2':
					return PlayState.instance.gfGroup.members[index % PlayState.instance.gfGroup.members.length].y;
				default:
					return PlayState.instance.boyfriendGroup.members[index % PlayState.instance.boyfriendGroup.members.length].y;
			}
		});
		Lua_helper.add_callback(lua, "setCharacterY", function(type:String, value:Float) {
			var charData = type.split(',');
			var index = 0;
			if (charData[1] != null) index = Std.parseInt(charData[1]);
			switch(charData[0].toLowerCase()) {
				case 'dad' | 'opponent' | '1':
					PlayState.instance.dadGroup.members[index % PlayState.instance.dadGroup.members.length].y = value;
				case 'gf' | 'girlfriend' | '2':
					PlayState.instance.gfGroup.members[index % PlayState.instance.gfGroup.members.length].y = value;
				default:
					PlayState.instance.boyfriendGroup.members[index % PlayState.instance.boyfriendGroup.members.length].y = value;
			}
		});
		Lua_helper.add_callback(lua, "cameraSetTarget", function(target:String) {
			var isDad:Bool = false;
			if (target == 'dad') {
				isDad = true;
			}
			PlayState.instance.moveCamera(isDad);
		});
		Lua_helper.add_callback(lua, "cameraShake", function(camera:String, intensity:Float, duration:Float) {
			cameraFromString(camera).shake(intensity, duration);
		});
		
		Lua_helper.add_callback(lua, "cameraFlash", function(camera:String, color:String, duration:Float,forced:Bool) {
			var colorNum:Int = Std.parseInt(color);
			if (!color.startsWith('0x')) colorNum = Std.parseInt('0xff$color');
			cameraFromString(camera).flash(colorNum, duration,null,forced);
		});
		Lua_helper.add_callback(lua, "cameraFade", function(camera:String, color:String, duration:Float,forced:Bool) {
			var colorNum:Int = Std.parseInt(color);
			if (!color.startsWith('0x')) colorNum = Std.parseInt('0xff$color');
			cameraFromString(camera).fade(colorNum, duration,false,null,forced);
		});
		Lua_helper.add_callback(lua, "setRatingPercent", function(value:Float) {
			PlayState.instance.ratingPercent = value;
		});
		Lua_helper.add_callback(lua, "setRatingName", function(value:String) {
			PlayState.instance.ratingName = value;
		});
		Lua_helper.add_callback(lua, "setRatingFC", function(value:String) {
			PlayState.instance.ratingFC = value;
		});
		Lua_helper.add_callback(lua, "getMouseX", function(camera:String) {
			var cam:FlxCamera = cameraFromString(camera);
			return FlxG.mouse.getScreenPosition(cam).x;
		});
		Lua_helper.add_callback(lua, "getMouseY", function(camera:String) {
			var cam:FlxCamera = cameraFromString(camera);
			return FlxG.mouse.getScreenPosition(cam).y;
		});
		Lua_helper.add_callback(lua, "getMidpointX", function(variable:String) {
			var obj:FlxObject = getObjectDirectly(variable);
			if(obj != null) return obj.getMidpoint().x;

			return 0;
		});
		Lua_helper.add_callback(lua, "getMidpointY", function(variable:String) {
			var obj:FlxObject = getObjectDirectly(variable);
			if(obj != null) return obj.getMidpoint().y;

			return 0;
		});
		Lua_helper.add_callback(lua, "getGraphicMidpointX", function(variable:String) {
			var obj:FlxSprite = getObjectDirectly(variable);
			if(obj != null) return obj.getGraphicMidpoint().x;

			return 0;
		});
		Lua_helper.add_callback(lua, "getGraphicMidpointY", function(variable:String) {
			var obj:FlxSprite = getObjectDirectly(variable);
			if(obj != null) return obj.getGraphicMidpoint().y;

			return 0;
		});
		Lua_helper.add_callback(lua, "getScreenPositionX", function(variable:String) {
			var obj:FlxObject = getObjectDirectly(variable);
			if(obj != null) return obj.getScreenPosition().x;

			return 0;
		});
		Lua_helper.add_callback(lua, "getScreenPositionY", function(variable:String) {
			var obj:FlxObject = getObjectDirectly(variable);
			if(obj != null) return obj.getScreenPosition().y;

			return 0;
		});
		Lua_helper.add_callback(lua, "characterPlayAnim", function(character:String, anim:String, ?forced:Bool = false) {
			var charData = character.split(',');
			var index = 0;
			if (charData[1] != null) index = Std.parseInt(charData[1]);
			switch(charData[0].toLowerCase()) {
				case 'dad' | '1':
					if (PlayState.instance.dadGroup.members[index % PlayState.instance.dadGroup.members.length].animOffsets.exists(anim))
						PlayState.instance.dadGroup.members[index % PlayState.instance.dadGroup.members.length].playAnim(anim, forced);
				case 'gf' | 'girlfriend' | '2':
					if (PlayState.instance.gfGroup.members[index % PlayState.instance.gfGroup.members.length] != null && PlayState.instance.gfGroup.members[index % PlayState.instance.gfGroup.members.length].animOffsets.exists(anim))
						PlayState.instance.gfGroup.members[index % PlayState.instance.gfGroup.members.length].playAnim(anim, forced);
				default: 
					if (PlayState.instance.boyfriendGroup.members[index % PlayState.instance.boyfriendGroup.members.length].animOffsets.exists(anim))
						PlayState.instance.boyfriendGroup.members[index % PlayState.instance.boyfriendGroup.members.length].playAnim(anim, forced);
			}
		});
		Lua_helper.add_callback(lua, "characterDance", function(character:String) {
			var charData = character.split(',');
			var index = 0;
			if (charData[1] != null) index = Std.parseInt(charData[1]);
			switch(charData[0].toLowerCase()) {
				case 'dad' | '1': PlayState.instance.dadGroup.members[index % PlayState.instance.dadGroup.members.length].dance();
				case 'gf' | 'girlfriend' | '2': if (PlayState.instance.gfGroup.members[index % PlayState.instance.gfGroup.members.length] != null) PlayState.instance.gfGroup.members[index % PlayState.instance.gfGroup.members.length].dance();
				default: PlayState.instance.boyfriendGroup.members[index % PlayState.instance.boyfriendGroup.members.length].dance();
			}
		});
		Lua_helper.add_callback(lua, "bopIcon", function(icon:String = '') {
			var daIcon = PlayState.instance.iconP1;
			switch (icon) {
				case 'p2' | '2' | 'dad' | 'opponent' | 'player2':
					daIcon = PlayState.instance.iconP2;
			}
			daIcon.scale.set(1.2, 1.2);
			daIcon.updateHitbox();
		});
		Lua_helper.add_callback(lua, "changeIcon", function(icon:String = '', char:String = 'bf', curAnim:String = 'default') {
			var daIcon = PlayState.instance.iconP1;
			switch (icon) {
				case 'p2' | '2' | 'dad' | 'opponent' | 'player2':
					daIcon = PlayState.instance.iconP2;
			}
			daIcon.changeIcon(char, curAnim);
		});
		Lua_helper.add_callback(lua, "setHealthBarColors", function(left:String = '0xFFFF0000', right:String = '0xFF66FF33') {
			var leftColorNum:Int = Std.parseInt(left);
			if (!left.startsWith('0x')) leftColorNum = Std.parseInt('0xff$left');
			var rightColorNum:Int = Std.parseInt(right);
			if (!right.startsWith('0x')) rightColorNum = Std.parseInt('0xff$right');

			PlayState.instance.healthBar.createFilledBar(leftColorNum, rightColorNum);
			PlayState.instance.healthBar.updateBar();
		});

		Lua_helper.add_callback(lua, "makeLuaSprite", function(tag:String, image:String, x:Float, y:Float) {
			tag = tag.replace('.', '');
			resetSpriteTag(tag);
			var leSprite:ModchartSprite = new ModchartSprite(x, y);
			if (image != null && image.length > 0)
			{
				leSprite.loadGraphic(Paths.image(image));
			}
			leSprite.antialiasing = ClientPrefs.globalAntialiasing;
			PlayState.instance.modchartSprites.set(tag, leSprite);
			leSprite.active = true;
		});
		Lua_helper.add_callback(lua, "makeAnimatedLuaSprite", function(tag:String, image:String, x:Float, y:Float, ?spriteType:String = "sparrow") {
			tag = tag.replace('.', '');
			resetSpriteTag(tag);
			var leSprite:ModchartSprite = new ModchartSprite(x, y);
			
			loadFrames(leSprite, image, spriteType);
			leSprite.antialiasing = ClientPrefs.globalAntialiasing;
			PlayState.instance.modchartSprites.set(tag, leSprite);
		});

		Lua_helper.add_callback(lua, "makeGraphic", function(obj:String, width:Int, height:Int, color:String) {
			var colorNum:Int = Std.parseInt(color);
			if (!color.startsWith('0x')) colorNum = Std.parseInt('0xff$color');

			if (PlayState.instance.modchartSprites.exists(obj)) {
				PlayState.instance.modchartSprites.get(obj).makeGraphic(width, height, colorNum);
				return;
			}

			var object:FlxSprite = Reflect.getProperty(getInstance(), obj);
			if (object != null) {
				object.makeGraphic(width, height, colorNum);
			}
		});
		Lua_helper.add_callback(lua, "addAnimationByPrefix", function(obj:String, name:String, prefix:String, framerate:Int = 24, loop:Bool = true) {
			if (PlayState.instance.modchartSprites.exists(obj)) {
				var cock:ModchartSprite = PlayState.instance.modchartSprites.get(obj);
				cock.animation.addByPrefix(name, prefix, framerate, loop);
				if (cock.animation.curAnim == null) {
					cock.animation.play(name, true);
				}
				return;
			}
			
			var cock:FlxSprite = Reflect.getProperty(getInstance(), obj);
			if (cock != null) {
				cock.animation.addByPrefix(name, prefix, framerate, loop);
				if (cock.animation.curAnim == null) {
					cock.animation.play(name, true);
				}
			}
		});
		Lua_helper.add_callback(lua, "addAnimationByIndices", function(obj:String, name:String, prefix:String, indices:String, framerate:Int = 24) {
			var strIndices:Array<String> = indices.trim().split(',');
			var die:Array<Int> = [];
			for (i in 0...strIndices.length) {
				die.push(Std.parseInt(strIndices[i]));
			}

			if (PlayState.instance.modchartSprites.exists(obj)) {
				var pussy:ModchartSprite = PlayState.instance.modchartSprites.get(obj);
				pussy.animation.addByIndices(name, prefix, die, '', framerate, false);
				if (pussy.animation.curAnim == null) {
					pussy.animation.play(name, true);
				}
				return;
			}
			
			var pussy:FlxSprite = Reflect.getProperty(getInstance(), obj);
			if (pussy != null) {
				pussy.animation.addByIndices(name, prefix, die, '', framerate, false);
				if (pussy.animation.curAnim == null) {
					pussy.animation.play(name, true);
				}
			}
		});
		Lua_helper.add_callback(lua, "objectPlayAnimation", function(obj:String, name:String, forced:Bool = false, ?startFrame:Int = 0, ?reversed:Bool = false) {
			if (PlayState.instance.modchartSprites.exists(obj)) {
				PlayState.instance.modchartSprites.get(obj).animation.play(name, forced, reversed, startFrame);
				return;
			}

			var spr:FlxSprite = Reflect.getProperty(getInstance(), obj);
			if (spr != null) {
				spr.animation.play(name, forced, reversed, startFrame);
			}
		});
		
		Lua_helper.add_callback(lua, "setScrollFactor", function(obj:String, scrollX:Float, scrollY:Float) {
			if (PlayState.instance.modchartSprites.exists(obj)) {
				PlayState.instance.modchartSprites.get(obj).scrollFactor.set(scrollX, scrollY);
				return;
			}

			var object:FlxObject = Reflect.getProperty(getInstance(), obj);
			if (object != null) {
				object.scrollFactor.set(scrollX, scrollY);
			}
		});
		Lua_helper.add_callback(lua, "addLuaSprite", function(tag:String, front:Bool = false) {
			if (PlayState.instance.modchartSprites.exists(tag)) {
				var shit:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
				if (!shit.wasAdded) {
					if (front)
					{
						getInstance().add(shit);
					}
					else
					{
						if (PlayState.instance.isDead)
						{
							GameOverSubState.instance.insert(GameOverSubState.instance.members.indexOf(GameOverSubState.instance.boyfriend), shit);
						}
						else
						{
							var position:Int = PlayState.instance.members.indexOf(PlayState.instance.gfGroup);
							if (PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup) < position) {
								position = PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup);
							} else if (PlayState.instance.members.indexOf(PlayState.instance.dadGroup) < position) {
								position = PlayState.instance.members.indexOf(PlayState.instance.dadGroup);
							}
							PlayState.instance.insert(position, shit);
						}
					}
					shit.wasAdded = true;
				}
			}
		});
		Lua_helper.add_callback(lua, "setGraphicSize", function(obj:String, x:Int, y:Int = 0) {
			if (PlayState.instance.modchartSprites.exists(obj)) {
				var shit:ModchartSprite = PlayState.instance.modchartSprites.get(obj);
				shit.setGraphicSize(x, y);
				shit.updateHitbox();
				return;
			}

			var poop:FlxSprite = Reflect.getProperty(getInstance(), obj);
			if (poop != null) {
				poop.setGraphicSize(x, y);
				poop.updateHitbox();
				return;
			}
			luaTrace('Couldnt find object: $obj');
		});
		Lua_helper.add_callback(lua, "scaleObject", function(obj:String, x:Float, y:Float) {
			if (PlayState.instance.modchartSprites.exists(obj)) {
				var shit:ModchartSprite = PlayState.instance.modchartSprites.get(obj);
				shit.scale.set(x, y);
				shit.updateHitbox();
				return;
			}

			var poop:FlxSprite = Reflect.getProperty(getInstance(), obj);
			if (poop != null) {
				poop.scale.set(x, y);
				poop.updateHitbox();
				return;
			}
			luaTrace('Couldnt find object: $obj');
		});
		Lua_helper.add_callback(lua, "updateHitbox", function(obj:String) {
			if (PlayState.instance.modchartSprites.exists(obj)) {
				var shit:ModchartSprite = PlayState.instance.modchartSprites.get(obj);
				shit.updateHitbox();
				return;
			}

			var poop:FlxSprite = Reflect.getProperty(getInstance(), obj);
			if (poop != null) {
				poop.updateHitbox();
				return;
			}
			luaTrace('Couldnt find object: $obj');
		});
		Lua_helper.add_callback(lua, "updateHitboxFromGroup", function(group:String, index:Int) {
			if (Std.isOfType(Reflect.getProperty(getInstance(), group), FlxTypedGroup) || Std.isOfType(Reflect.getProperty(getInstance(), group), FlxTypedSpriteGroup)) {
				Reflect.getProperty(getInstance(), group).members[index].updateHitbox();
				return;
			}
			Reflect.getProperty(getInstance(), group)[index].updateHitbox();
		});
		Lua_helper.add_callback(lua, "removeLuaSprite", function(tag:String, destroy:Bool = true) {
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
		});

		Lua_helper.add_callback(lua, "setObjectCamera", function(obj:String, camera:String = '') {
			if (PlayState.instance.modchartSprites.exists(obj)) {
				PlayState.instance.modchartSprites.get(obj).cameras = [cameraFromString(camera)];
				return true;
			}
			else if (PlayState.instance.modchartTexts.exists(obj)) {
				PlayState.instance.modchartTexts.get(obj).cameras = [cameraFromString(camera)];
				return true;
			}

			var object:FlxObject = Reflect.getProperty(getInstance(), obj);
			if (object != null) {
				object.cameras = [cameraFromString(camera)];
				return true;
			}
			luaTrace('Object $obj doesn\'t exist!');
			return false;
		});
		Lua_helper.add_callback(lua, "setBlendMode", function(obj:String, blend:String = '') {
			if (PlayState.instance.modchartSprites.exists(obj)) {
				PlayState.instance.modchartSprites.get(obj).blend = blendModeFromString(blend);
				return true;
			}

			var spr:FlxSprite = Reflect.getProperty(getInstance(), obj);
			if (spr != null) {
				spr.blend = blendModeFromString(blend);
				return true;
			}
			luaTrace('Object $obj doesn\'t exist!');
			return false;
		});
		Lua_helper.add_callback(lua, "screenCenter", function(obj:String, pos:String = 'xy') {
			var spr:FlxSprite = getObjectDirectly(obj);

			if (spr != null)
			{
				switch(pos.trim().toLowerCase())
				{
					case 'x':
						spr.screenCenter(X);
						return;
					case 'y':
						spr.screenCenter(Y);
						return;
					default:
						spr.screenCenter(XY);
						return;
				}
			}
			luaTrace('Object $obj doesn\'t exist!');
		});
		Lua_helper.add_callback(lua, "objectsOverlap", function(obj1:String, obj2:String) {
			var namesArray:Array<String> = [obj1, obj2];
			var objectsArray:Array<FlxSprite> = [];
			for (i in 0...namesArray.length)
			{
				objectsArray.push(getObjectDirectly(namesArray[i]));
			}

			if(!objectsArray.contains(null) && FlxG.overlap(objectsArray[0], objectsArray[1]))
			{
				return true;
			}
			return false;
		});
		Lua_helper.add_callback(lua, "getPixelColor", function(obj:String, x:Int, y:Int) {
			var spr:FlxSprite = getObjectDirectly(obj);

			if (spr != null)
			{
				if (spr.framePixels != null) return spr.framePixels.getPixel32(x, y);
				return spr.pixels.getPixel32(x, y);
			}
			return 0;
		});
		Lua_helper.add_callback(lua, "getRandomInt", function(min:Int, max:Int = FlxMath.MAX_VALUE_INT, exclude:String = '') {
			var excludeArray:Array<String> = exclude.split(',');
			var toExclude:Array<Int> = [];
			for (i in 0...excludeArray.length)
			{
				toExclude.push(Std.parseInt(excludeArray[i].trim()));
			}
			return FlxG.random.int(min, max, toExclude);
		});
		Lua_helper.add_callback(lua, "getRandomFloat", function(min:Float, max:Float = 1, exclude:String = '') {
			var excludeArray:Array<String> = exclude.split(',');
			var toExclude:Array<Float> = [];
			for (i in 0...excludeArray.length)
			{
				toExclude.push(Std.parseFloat(excludeArray[i].trim()));
			}
			return FlxG.random.float(min, max, toExclude);
		});
		Lua_helper.add_callback(lua, "getRandomBool", function(chance:Float = 50) {
			return FlxG.random.bool(chance);
		});
		Lua_helper.add_callback(lua, "startDialogue", function(dialogueFile:String, music:String = null) {
			var path:String = Paths.modsData('${Paths.formatToSongPath(PlayState.SONG.song)}/$dialogueFile');
			if (!FileSystem.exists(path)) {
				path = Paths.json('${Paths.formatToSongPath(PlayState.SONG.song)}/$dialogueFile');
			}
			luaTrace('Trying to load dialogue: $path');

			if (FileSystem.exists(path) || Assets.exists(path)) {
				var shit:DialogueFile = DialogueBoxPsych.parseDialogue(path);
				if (shit.dialogue.length > 0) {
					PlayState.instance.startDialogue(shit, music);
					luaTrace('Successfully loaded dialogue');
				} else {
					luaTrace('Your dialogue file is badly formatted!');
				}
			} else {
				luaTrace('Dialogue file not found');
				if (PlayState.instance.endingSong) {
					PlayState.instance.endSong();
				} else {
					PlayState.instance.startCountdown();
				}
			}
		});
		Lua_helper.add_callback(lua, "startVideo", function(videoFile:String) {
			#if VIDEOS_ALLOWED
			if (FileSystem.exists(Paths.video(videoFile))) {
				PlayState.instance.startVideo(videoFile);
			} else {
				luaTrace('Video file not found: $videoFile');
			}
			#else
			if (PlayState.instance.endingSong) {
				PlayState.instance.endSong();
			} else {
				PlayState.instance.startCountdown();
			}
			#end
		});
		
		Lua_helper.add_callback(lua, "changeNoteSkin", function(index:Int = 0, name:String = 'default') {
			if (PlayState.instance.notes.members[index] != null) {
				PlayState.instance.notes.members[index].uiSkin = UIData.getUIFile(name);
			}
		});
		Lua_helper.add_callback(lua, "changeUnspawnNoteSkin", function(index:Int = 0, name:String = 'default') {
			if (PlayState.instance.unspawnNotes[index] != null) {
				PlayState.instance.unspawnNotes[index].uiSkin = UIData.getUIFile(name);
			}
		});
		Lua_helper.add_callback(lua, "changeStrumNoteSkin", function(index:Int = 0, name:String = 'default') {
			if (PlayState.instance.strumLineNotes != null && PlayState.instance.strumLineNotes.members[index] != null) {
				PlayState.instance.strumLineNotes.members[index].uiSkin = UIData.getUIFile(name);
			}
		});
		
		Lua_helper.add_callback(lua, "playMusic", function(sound:String, volume:Float = 1, loop:Bool = false) {
			FlxG.sound.playMusic(Paths.music(sound), volume, loop);
		});
		Lua_helper.add_callback(lua, "playSound", function(sound:String, volume:Float = 1, ?tag:String = null) {
			if (tag != null && tag.length > 0) {
				tag = tag.replace('.', '');
				if (PlayState.instance.modchartSounds.exists(tag)) {
					PlayState.instance.modchartSounds.get(tag).stop();
				}
				PlayState.instance.modchartSounds.set(tag, FlxG.sound.play(Paths.sound(sound), volume, false, function() {
					PlayState.instance.modchartSounds.remove(tag);
					PlayState.instance.callOnScripts('onSoundFinished', [tag]);
				}));
				return;
			}
			FlxG.sound.play(Paths.sound(sound), volume);
		});
		Lua_helper.add_callback(lua, "stopSound", function(tag:String) {
			if (tag != null && tag.length > 1 && PlayState.instance.modchartSounds.exists(tag)) {
				PlayState.instance.modchartSounds.get(tag).stop();
				PlayState.instance.modchartSounds.remove(tag);
			}
		});
		Lua_helper.add_callback(lua, "pauseSound", function(tag:String) {
			if (tag != null && tag.length > 1 && PlayState.instance.modchartSounds.exists(tag)) {
				PlayState.instance.modchartSounds.get(tag).pause();
			}
		});
		Lua_helper.add_callback(lua, "resumeSound", function(tag:String) {
			if (tag != null && tag.length > 1 && PlayState.instance.modchartSounds.exists(tag)) {
				PlayState.instance.modchartSounds.get(tag).play();
			}
		});
		Lua_helper.add_callback(lua, "soundFadeIn", function(tag:String, duration:Float, fromValue:Float = 0, toValue:Float = 1) {
			if (tag == null || tag.length < 1) {
				FlxG.sound.music.fadeIn(duration, fromValue, toValue);
			} else if (PlayState.instance.modchartSounds.exists(tag)) {
				PlayState.instance.modchartSounds.get(tag).fadeIn(duration, fromValue, toValue);
			}
			
		});
		Lua_helper.add_callback(lua, "soundFadeOut", function(tag:String, duration:Float, toValue:Float = 0) {
			if (tag == null || tag.length < 1) {
				FlxG.sound.music.fadeOut(duration, toValue);
			} else if (PlayState.instance.modchartSounds.exists(tag)) {
				PlayState.instance.modchartSounds.get(tag).fadeOut(duration, toValue);
			}
		});
		Lua_helper.add_callback(lua, "soundFadeCancel", function(tag:String) {
			if (tag == null || tag.length < 1) {
				if (FlxG.sound.music.fadeTween != null) {
					FlxG.sound.music.fadeTween.cancel();
				}
			} else if (PlayState.instance.modchartSounds.exists(tag)) {
				var theSound:FlxSound = PlayState.instance.modchartSounds.get(tag);
				if (theSound.fadeTween != null) {
					theSound.fadeTween.cancel();
					PlayState.instance.modchartSounds.remove(tag);
				}
			}
		});
		Lua_helper.add_callback(lua, "getSoundVolume", function(tag:String) {
			if (tag == null || tag.length < 1) {
				if (FlxG.sound.music != null) {
					return FlxG.sound.music.volume;
				}
			} else if (PlayState.instance.modchartSounds.exists(tag)) {
				return PlayState.instance.modchartSounds.get(tag).volume;
			}
			return 0;
		});
		Lua_helper.add_callback(lua, "setSoundVolume", function(tag:String, value:Float) {
			if (tag == null || tag.length < 1) {
				if (FlxG.sound.music != null) {
					FlxG.sound.music.volume = value;
				}
			} else if (PlayState.instance.modchartSounds.exists(tag)) {
				PlayState.instance.modchartSounds.get(tag).volume = value;
			}
		});
		Lua_helper.add_callback(lua, "getSoundTime", function(tag:String) {
			if (tag != null && tag.length > 0 && PlayState.instance.modchartSounds.exists(tag)) {
				return PlayState.instance.modchartSounds.get(tag).time;
			}
			return 0;
		});
		Lua_helper.add_callback(lua, "setSoundTime", function(tag:String, value:Float) {
			if (tag != null && tag.length > 0 && PlayState.instance.modchartSounds.exists(tag)) {
				var theSound:FlxSound = PlayState.instance.modchartSounds.get(tag);
				if (theSound != null) {
					var wasResumed:Bool = theSound.playing;
					theSound.pause();
					theSound.time = value;
					if (wasResumed) theSound.play();
				}
			}
		});

		Lua_helper.add_callback(lua, "debugPrint", function(text1:Dynamic = '', text2:Dynamic = '', text3:Dynamic = '', text4:Dynamic = '', text5:Dynamic = '') {
			if (text1 == null) text1 = '';
			if (text2 == null) text2 = '';
			if (text3 == null) text3 = '';
			if (text4 == null) text4 = '';
			if (text5 == null) text5 = '';
			luaTrace('${text1 + text2 + text3 + text4 + text5}', true, false);
		});
		Lua_helper.add_callback(lua, "close", function(printMessage:Bool) {
			if (!gonnaClose) {
				if (printMessage) {
					luaTrace('Stopping lua script: $scriptName');
				}
				PlayState.instance.closeLuas.push(this);
			}
			gonnaClose = true;
		});

		Lua_helper.add_callback(lua, "changePresence", function(details:String, ?state:String, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float) {
			#if DISCORD_ALLOWED
			DiscordClient.changePresence(details, state, smallImageKey, hasStartTimestamp, endTimestamp);
			#end
		});


		// LUA TEXTS
		Lua_helper.add_callback(lua, "makeLuaText", function(tag:String, text:String, width:Int, x:Float, y:Float) {
			tag = tag.replace('.', '');
			resetTextTag(tag);
			var leText:ModchartText = new ModchartText(x, y, text, width);
			PlayState.instance.modchartTexts.set(tag, leText);
		});

		Lua_helper.add_callback(lua, "setTextString", function(tag:String, text:String) {
			var obj:FlxText = getTextObject(tag);
			if (obj != null)
			{
				obj.text = text;
			}
		});
		Lua_helper.add_callback(lua, "setTextSize", function(tag:String, size:Int) {
			var obj:FlxText = getTextObject(tag);
			if (obj != null)
			{
				obj.size = size;
			}
		});
		Lua_helper.add_callback(lua, "setTextWidth", function(tag:String, width:Float) {
			var obj:FlxText = getTextObject(tag);
			if (obj != null)
			{
				obj.fieldWidth = width;
			}
		});
		Lua_helper.add_callback(lua, "setTextBorder", function(tag:String, size:Int, color:String) {
			var obj:FlxText = getTextObject(tag);
			if (obj != null)
			{
				var colorNum:Int = Std.parseInt(color);
				if (!color.startsWith('0x')) colorNum = Std.parseInt('0xff$color');

				obj.borderSize = size;
				obj.borderColor = colorNum;
			}
		});
		Lua_helper.add_callback(lua, "setTextColor", function(tag:String, color:String) {
			var obj:FlxText = getTextObject(tag);
			if (obj != null)
			{
				var colorNum:Int = Std.parseInt(color);
				if (!color.startsWith('0x')) colorNum = Std.parseInt('0xff$color');

				obj.color = colorNum;
			}
		});
		Lua_helper.add_callback(lua, "setTextFont", function(tag:String, newFont:String) {
			var obj:FlxText = getTextObject(tag);
			if (obj != null)
			{
				obj.font = Paths.font(newFont);
			}
		});
		Lua_helper.add_callback(lua, "setTextItalic", function(tag:String, italic:Bool) {
			var obj:FlxText = getTextObject(tag);
			if (obj != null)
			{
				obj.italic = italic;
			}
		});
		Lua_helper.add_callback(lua, "setTextAlignment", function(tag:String, alignment:String = 'left') {
			var obj:FlxText = getTextObject(tag);
			if (obj != null)
			{
				obj.alignment = LEFT;
				switch(alignment.trim().toLowerCase())
				{
					case 'right':
						obj.alignment = RIGHT;
					case 'center':
						obj.alignment = CENTER;
				}
			}
		});

		Lua_helper.add_callback(lua, "getTextString", function(tag:String) {
			var obj:FlxText = getTextObject(tag);
			if (obj != null)
			{
				return obj.text;
			}
			return null;
		});
		Lua_helper.add_callback(lua, "getTextSize", function(tag:String) {
			var obj:FlxText = getTextObject(tag);
			if (obj != null)
			{
				return obj.size;
			}
			return -1;
		});
		Lua_helper.add_callback(lua, "getTextFont", function(tag:String) {
			var obj:FlxText = getTextObject(tag);
			if (obj != null)
			{
				return obj.font;
			}
			return null;
		});
		Lua_helper.add_callback(lua, "getTextWidth", function(tag:String) {
			var obj:FlxText = getTextObject(tag);
			if (obj != null)
			{
				return obj.fieldWidth;
			}
			return 0;
		});

		Lua_helper.add_callback(lua, "addLuaText", function(tag:String) {
			if (PlayState.instance.modchartTexts.exists(tag)) {
				var shit:ModchartText = PlayState.instance.modchartTexts.get(tag);
				if (!shit.wasAdded) {
					getInstance().add(shit);
					shit.wasAdded = true;
				}
			}
		});
		Lua_helper.add_callback(lua, "removeLuaText", function(tag:String, destroy:Bool = true) {
			if (!PlayState.instance.modchartTexts.exists(tag)) {
				return;
			}
			
			var pee:ModchartText = PlayState.instance.modchartTexts.get(tag);
			if (destroy) {
				pee.kill();
			}

			if (pee.wasAdded) {
				getInstance().remove(pee, true);
				pee.wasAdded = false;
			}

			if (destroy) {
				pee.destroy();
				PlayState.instance.modchartTexts.remove(tag);
			}
		});

		Lua_helper.add_callback(lua, "initSaveData", function(name:String, ?folder:String = 'psychenginemods') {
			if(!PlayState.instance.modchartSaves.exists(name))
			{
				var save:FlxSave = new FlxSave();
				save.bind(name, folder);
				PlayState.instance.modchartSaves.set(name, save);
				return;
			}
			luaTrace('Save file already initialized: ' + name);
		});
		Lua_helper.add_callback(lua, "flushSaveData", function(name:String) {
			if(PlayState.instance.modchartSaves.exists(name))
			{
				PlayState.instance.modchartSaves.get(name).flush();
				return;
			}
			luaTrace('Save file not initialized: ' + name);
		});
		Lua_helper.add_callback(lua, "getDataFromSave", function(name:String, field:String) {
			if(PlayState.instance.modchartSaves.exists(name))
			{
				var retVal:Dynamic = Reflect.field(PlayState.instance.modchartSaves.get(name).data, field);
				return retVal;
			}
			luaTrace('Save file not initialized: ' + name);
			return null;
		});
		Lua_helper.add_callback(lua, "setDataFromSave", function(name:String, field:String, value:Dynamic) {
			if(PlayState.instance.modchartSaves.exists(name))
			{
				Reflect.setField(PlayState.instance.modchartSaves.get(name).data, field, value);
				return;
			}
			luaTrace('Save file not initialized: ' + name);
		});
		Lua_helper.add_callback(lua, "setWeekCompleted", function(name:String = '') {
			if(name.length > 0)
			{
				var weekName = WeekData.formatWeek(name);
				StoryMenuState.weekCompleted.set(weekName, true);
				FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
				FlxG.save.flush();
			}
		});

		Lua_helper.add_callback(lua, "getTextFromFile", function(path:String, ?ignoreModFolders:Bool = false) {
			return Paths.getTextFromFile(path, ignoreModFolders);
		});

		//system functions
		Lua_helper.add_callback(lua, "exitGame", function(code:Int = 0) {
			Sys.exit(code);
		});
		Lua_helper.add_callback(lua, "getCPUTime", function() {
			return Sys.cpuTime();
		});
		Lua_helper.add_callback(lua, "getEnvVariable", function(variable:String = '') {
			return Sys.getEnv(variable);
		});
		Lua_helper.add_callback(lua, "getProgramPath", function() {
			return Sys.programPath();
		});
		Lua_helper.add_callback(lua, "getSystemName", function() {
			return Sys.systemName();
		});
		Lua_helper.add_callback(lua, "getUnixTime", function() {
			return Sys.time();
		});
		Lua_helper.add_callback(lua, "getWorkingDirectory", function() {
			return Sys.getCwd();
		});

		// DEPRECATED, DONT MESS WITH THESE SHITS, ITS JUST THERE FOR BACKWARD COMPATIBILITY
		Lua_helper.add_callback(lua, "luaSpriteMakeGraphic", function(tag:String, width:Int, height:Int, color:String) {
			luaTrace("luaSpriteMakeGraphic is deprecated! Use makeGraphic instead", false, true);
			if (PlayState.instance.modchartSprites.exists(tag)) {
				var colorNum:Int = Std.parseInt(color);
				if (!color.startsWith('0x')) colorNum = Std.parseInt('0xff$color');

				PlayState.instance.modchartSprites.get(tag).makeGraphic(width, height, colorNum);
			}
		});
		Lua_helper.add_callback(lua, "luaSpriteAddAnimationByPrefix", function(tag:String, name:String, prefix:String, framerate:Int = 24, loop:Bool = true) {
			luaTrace("luaSpriteAddAnimationByPrefix is deprecated! Use addAnimationByPrefix instead", false, true);
			if (PlayState.instance.modchartSprites.exists(tag)) {
				var cock:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
				cock.animation.addByPrefix(name, prefix, framerate, loop);
				if (cock.animation.curAnim == null) {
					cock.animation.play(name, true);
				}
			}
		});
		Lua_helper.add_callback(lua, "luaSpriteAddAnimationByIndices", function(tag:String, name:String, prefix:String, indices:String, framerate:Int = 24) {
			luaTrace("luaSpriteAddAnimationByIndices is deprecated! Use addAnimationByIndices instead", false, true);
			if (PlayState.instance.modchartSprites.exists(tag)) {
				var strIndices:Array<String> = indices.trim().split(',');
				var die:Array<Int> = [];
				for (i in 0...strIndices.length) {
					die.push(Std.parseInt(strIndices[i]));
				}
				var pussy:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
				pussy.animation.addByIndices(name, prefix, die, '', framerate, false);
				if (pussy.animation.curAnim == null) {
					pussy.animation.play(name, true);
				}
			}
		});
		Lua_helper.add_callback(lua, "luaSpritePlayAnimation", function(tag:String, name:String, forced:Bool = false) {
			luaTrace("luaSpritePlayAnimation is deprecated! Use objectPlayAnimation instead", false, true);
			if (PlayState.instance.modchartSprites.exists(tag)) {
				PlayState.instance.modchartSprites.get(tag).animation.play(name, forced);
			}
		});
		Lua_helper.add_callback(lua, "setLuaSpriteCamera", function(tag:String, camera:String = '') {
			luaTrace("setLuaSpriteCamera is deprecated! Use setObjectCamera instead", false, true);
			if (PlayState.instance.modchartSprites.exists(tag)) {
				PlayState.instance.modchartSprites.get(tag).cameras = [cameraFromString(camera)];
				return true;
			}
			luaTrace('Lua sprite with tag: $tag doesn\'t exist!');
			return false;
		});
		Lua_helper.add_callback(lua, "setLuaSpriteScrollFactor", function(tag:String, scrollX:Float, scrollY:Float) {
			luaTrace("setLuaSpriteScrollFactor is deprecated! Use setScrollFactor instead", false, true);
			if (PlayState.instance.modchartSprites.exists(tag)) {
				PlayState.instance.modchartSprites.get(tag).scrollFactor.set(scrollX, scrollY);
			}
		});
		Lua_helper.add_callback(lua, "scaleLuaSprite", function(tag:String, x:Float, y:Float) {
			luaTrace("scaleLuaSprite is deprecated! Use scaleObject instead", false, true);
			if (PlayState.instance.modchartSprites.exists(tag)) {
				var shit:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
				shit.scale.set(x, y);
				shit.updateHitbox();
			}
		});
		Lua_helper.add_callback(lua, "getPropertyLuaSprite", function(tag:String, variable:String) {
			luaTrace("getPropertyLuaSprite is deprecated! Use getProperty instead", false, true);
			if (PlayState.instance.modchartSprites.exists(tag)) {
				var killMe:Array<String> = variable.split('.');
				if (killMe.length > 1) {
					var coverMeInPiss:Dynamic = Reflect.getProperty(PlayState.instance.modchartSprites.get(tag), killMe[0]);
					for (i in 1...killMe.length-1) {
						coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
					}
					return Reflect.getProperty(coverMeInPiss, killMe[killMe.length-1]);
				}
				return Reflect.getProperty(PlayState.instance.modchartSprites.get(tag), variable);
			}
			return null;
		});
		Lua_helper.add_callback(lua, "setPropertyLuaSprite", function(tag:String, variable:String, value:Dynamic) {
			luaTrace("setPropertyLuaSprite is deprecated! Use setProperty instead", false, true);
			if (PlayState.instance.modchartSprites.exists(tag)) {
				var killMe:Array<String> = variable.split('.');
				if (killMe.length > 1) {
					var coverMeInPiss:Dynamic = Reflect.getProperty(PlayState.instance.modchartSprites.get(tag), killMe[0]);
					for (i in 1...killMe.length-1) {
						coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
					}
					return Reflect.setProperty(coverMeInPiss, killMe[killMe.length-1], value);
				}
				return Reflect.setProperty(PlayState.instance.modchartSprites.get(tag), variable, value);
			}
			luaTrace('Lua sprite with tag: $tag doesn\'t exist!');
		});
		Lua_helper.add_callback(lua, "musicFadeIn", function(duration:Float, fromValue:Float = 0, toValue:Float = 1) {
			FlxG.sound.music.fadeIn(duration, fromValue, toValue);
			luaTrace('musicFadeIn is deprecated! Use soundFadeIn instead.', false, true);

		});
		Lua_helper.add_callback(lua, "musicFadeOut", function(duration:Float, toValue:Float = 0) {
			FlxG.sound.music.fadeOut(duration, toValue);
			luaTrace('musicFadeOut is deprecated! Use soundFadeOut instead.', false, true);
		});

		Lua_helper.add_callback(lua, "browserLoad", CoolUtil.browserLoad);
        //Lua_helper.add_callback(lua, "loadLuaStage", PlayState.instance.loadStage);
        Lua_helper.add_callback(lua, "moveWindow", ModchartFunctions.moveWindow);
        Lua_helper.add_callback(lua, "zoomCamera", ModchartFunctions.camZoom);
        //Lua_helper.add_callback(lua, "loadStage", PlayState.loadStage);

		//SHADER SHIT

		Lua_helper.add_callback(lua, "addChromaticAbberationEffect", function(camera:String,chromeOffset:Float = 0.005) {
	
			PlayState.instance.addShaderToCamera(camera, new ChromaticAberrationEffect(chromeOffset));
			
		});
		
		Lua_helper.add_callback(lua, "addScanlineEffect", function(camera:String,lockAlpha:Bool=false) {
			
			PlayState.instance.addShaderToCamera(camera, new ScanlineEffect(lockAlpha));
			
		});
		Lua_helper.add_callback(lua, "addGrainEffect", function(camera:String,grainSize:Float,lumAmount:Float,lockAlpha:Bool=false) {
			
			PlayState.instance.addShaderToCamera(camera, new GrainEffect(grainSize,lumAmount,lockAlpha));
			
		});
		Lua_helper.add_callback(lua, "addTiltshiftEffect", function(camera:String,blurAmount:Float,center:Float) {
			
			PlayState.instance.addShaderToCamera(camera, new TiltshiftEffect(blurAmount,center));
			
		});
		Lua_helper.add_callback(lua, "addVCREffect", function(camera:String,glitchFactor:Float = 0.0,distortion:Bool=true,perspectiveOn:Bool=true,vignetteMoving:Bool=true) {
			
			PlayState.instance.addShaderToCamera(camera, new VCRDistortionEffect(glitchFactor,distortion,perspectiveOn,vignetteMoving));
			
		});
		Lua_helper.add_callback(lua, "addGlitchEffect", function(camera:String,waveSpeed:Float = 0.1,waveFrq:Float = 0.1,waveAmp:Float = 0.1) {
			
			PlayState.instance.addShaderToCamera(camera, new GlitchEffect(waveSpeed,waveFrq,waveAmp));
			
		});
		Lua_helper.add_callback(lua, "addPulseEffect", function(camera:String,waveSpeed:Float = 0.1,waveFrq:Float = 0.1,waveAmp:Float = 0.1) {
			
			PlayState.instance.addShaderToCamera(camera, new PulseEffect(waveSpeed,waveFrq,waveAmp));
			
		});
		Lua_helper.add_callback(lua, "addDistortionEffect", function(camera:String,waveSpeed:Float = 0.1,waveFrq:Float = 0.1,waveAmp:Float = 0.1) {
			
			PlayState.instance.addShaderToCamera(camera, new DistortBGEffect(waveSpeed,waveFrq,waveAmp));
			
		});
		Lua_helper.add_callback(lua, "addInvertEffect", function(camera:String,lockAlpha:Bool=false) {
			
			PlayState.instance.addShaderToCamera(camera, new InvertColorsEffect(lockAlpha));
			
		});
		Lua_helper.add_callback(lua, "addGreyscaleEffect", function(camera:String) { //for dem funkies
			
			PlayState.instance.addShaderToCamera(camera, new GreyscaleEffect());
			
		});
		Lua_helper.add_callback(lua, "addGrayscaleEffect", function(camera:String) { //for dem funkies
			
			PlayState.instance.addShaderToCamera(camera, new GreyscaleEffect());
			
		});
		Lua_helper.add_callback(lua, "add3DEffect", function(camera:String,xrotation:Float=0,yrotation:Float=0,zrotation:Float=0,depth:Float=0) { //for dem funkies
			
			PlayState.instance.addShaderToCamera(camera, new ThreeDEffect(xrotation,yrotation,zrotation,depth));
			
		});
		Lua_helper.add_callback(lua, "addBloomEffect", function(camera:String,intensity:Float = 0.35,blurSize:Float=1.0) {
			
			PlayState.instance.addShaderToCamera(camera, new BloomEffect(blurSize/512.0,intensity));
			
		});
		Lua_helper.add_callback(lua, "clearEffects", function(camera:String) {
			PlayState.instance.clearShaderFromCamera(camera);
		});

		call('onCreate', []);
		#end
	}

	inline static function getTextObject(name:String):FlxText
	{
		return PlayState.instance.modchartTexts.exists(name) ? PlayState.instance.modchartTexts.get(name) : Reflect.getProperty(PlayState.instance, name);
	}

	function loadFrames(spr:FlxSprite, image:String, spriteType:String)
	{
		switch(spriteType.toLowerCase().trim())
		{	
			case "texture" | "textureatlas" | "tex":
				spr.frames = AtlasFrameMaker.construct(image);

			case "texture_noaa" | "textureatlas_noaa" | "tex_noaa":
				spr.frames = AtlasFrameMaker.construct(image, null, true);

			case "packer" | "packeratlas" | "pac":
				spr.frames = Paths.getPackerAtlas(image);

			case "texturepacker" | "texpacker" | "packerjson" | "json":
				spr.frames = Paths.getTexturePackerAtlas(image);

			default:
				spr.frames = Paths.getSparrowAtlas(image);
		}
	}

	function getGroupStuff(leArray:Dynamic, variable:String) {
		var killMe:Array<String> = variable.split('.');
		if (killMe.length > 1) {
			var coverMeInPiss:Dynamic = Reflect.getProperty(leArray, killMe[0]);
			for (i in 1...killMe.length-1) {
				coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
			}
			return Reflect.getProperty(coverMeInPiss, killMe[killMe.length-1]);
		}
		return Reflect.getProperty(leArray, variable);
	}

	function setGroupStuff(leArray:Dynamic, variable:String, value:Dynamic) {
		var killMe:Array<String> = variable.split('.');
		if (killMe.length > 1) {
			var coverMeInPiss:Dynamic = Reflect.getProperty(leArray, killMe[0]);
			for (i in 1...killMe.length-1) {
				coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
			}
			Reflect.setProperty(coverMeInPiss, killMe[killMe.length-1], value);
			return;
		}
		Reflect.setProperty(leArray, variable, value);
	}

	function resetTextTag(tag:String) {
		if (!PlayState.instance.modchartTexts.exists(tag)) {
			return;
		}
		
		var pee:ModchartText = PlayState.instance.modchartTexts.get(tag);
		pee.kill();
		if (pee.wasAdded) {
			PlayState.instance.remove(pee, true);
		}
		pee.destroy();
		PlayState.instance.modchartTexts.remove(tag);
	}

	function resetSpriteTag(tag:String) {
		if (!PlayState.instance.modchartSprites.exists(tag)) {
			return;
		}
		
		var pee:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
		pee.kill();
		if (pee.wasAdded) {
			PlayState.instance.remove(pee, true);
		}
		pee.destroy();
		PlayState.instance.modchartSprites.remove(tag);
	}

	function cancelTween(tag:String) {
		if (PlayState.instance.modchartTweens.exists(tag)) {
			PlayState.instance.modchartTweens.get(tag).cancel();
			PlayState.instance.modchartTweens.get(tag).destroy();
			PlayState.instance.modchartTweens.remove(tag);
		}
	}
	
	function tweenShit(tag:String, vars:String) {
		cancelTween(tag);
		var variables:Array<String> = vars.replace(' ', '').split('.');
		var sexyProp:Dynamic = Reflect.getProperty(getInstance(), variables[0]);
		if (PlayState.instance.modchartSprites.exists(variables[0])) {
			sexyProp = PlayState.instance.modchartSprites.get(variables[0]);
		}
		if (PlayState.instance.modchartTexts.exists(variables[0])) {
			sexyProp = PlayState.instance.modchartTexts.get(variables[0]);
		}

		for (i in 1...variables.length) {
			sexyProp = Reflect.getProperty(sexyProp, variables[i]);
		}
		return sexyProp;
	}

	function cancelTimer(tag:String) {
		if (PlayState.instance.modchartTimers.exists(tag)) {
			var theTimer:FlxTimer = PlayState.instance.modchartTimers.get(tag);
			theTimer.cancel();
			theTimer.destroy();
			PlayState.instance.modchartTimers.remove(tag);
		}
	}

	//Better optimized than using some getProperty shit or idk
	function getFlxEaseByString(?ease:String = '') {
		switch(ease.toLowerCase().trim()) {
			case 'backin': return FlxEase.backIn;
			case 'backinout': return FlxEase.backInOut;
			case 'backout': return FlxEase.backOut;
			case 'bouncein': return FlxEase.bounceIn;
			case 'bounceinout': return FlxEase.bounceInOut;
			case 'bounceout': return FlxEase.bounceOut;
			case 'circin': return FlxEase.circIn;
			case 'circinout': return FlxEase.circInOut;
			case 'circout': return FlxEase.circOut;
			case 'cubein': return FlxEase.cubeIn;
			case 'cubeinout': return FlxEase.cubeInOut;
			case 'cubeout': return FlxEase.cubeOut;
			case 'elasticin': return FlxEase.elasticIn;
			case 'elasticinout': return FlxEase.elasticInOut;
			case 'elasticout': return FlxEase.elasticOut;
			case 'expoin': return FlxEase.expoIn;
			case 'expoinout': return FlxEase.expoInOut;
			case 'expoout': return FlxEase.expoOut;
			case 'quadin': return FlxEase.quadIn;
			case 'quadinout': return FlxEase.quadInOut;
			case 'quadout': return FlxEase.quadOut;
			case 'quartin': return FlxEase.quartIn;
			case 'quartinout': return FlxEase.quartInOut;
			case 'quartout': return FlxEase.quartOut;
			case 'quintin': return FlxEase.quintIn;
			case 'quintinout': return FlxEase.quintInOut;
			case 'quintout': return FlxEase.quintOut;
			case 'sinein': return FlxEase.sineIn;
			case 'sineinout': return FlxEase.sineInOut;
			case 'sineout': return FlxEase.sineOut;
			case 'smoothstepin': return FlxEase.smoothStepIn;
			case 'smoothstepinout': return FlxEase.smoothStepInOut;
			case 'smoothstepout': return FlxEase.smoothStepInOut;
			case 'smootherstepin': return FlxEase.smootherStepIn;
			case 'smootherstepinout': return FlxEase.smootherStepInOut;
			case 'smootherstepout': return FlxEase.smootherStepOut;
		}
		return FlxEase.linear;
	}

	function blendModeFromString(blend:String):BlendMode {
		switch(blend.toLowerCase().trim()) {
			case 'add': return ADD;
			case 'alpha': return ALPHA;
			case 'darken': return DARKEN;
			case 'difference': return DIFFERENCE;
			case 'erase': return ERASE;
			case 'hardlight': return HARDLIGHT;
			case 'invert': return INVERT;
			case 'layer': return LAYER;
			case 'lighten': return LIGHTEN;
			case 'multiply': return MULTIPLY;
			case 'overlay': return OVERLAY;
			case 'screen': return SCREEN;
			case 'shader': return SHADER;
			case 'subtract': return SUBTRACT;
		}
		return NORMAL;
	}

	function cameraFromString(cam:String):FlxCamera {
		switch(cam.toLowerCase()) {
			case 'camhud' | 'hud': return PlayState.instance.camHUD;
			case 'camother' | 'other': return PlayState.instance.camOther;
		}
		return PlayState.instance.camGame;
	}

	public function luaTrace(text:String, ignoreCheck:Bool = false, deprecated:Bool = false) {
		#if LUA_ALLOWED
		if (ignoreCheck || getBool('luaDebugMode')) {
			if (deprecated && !getBool('luaDeprecatedWarnings')) {
				return;
			}
			PlayState.instance.addTextToDebug(text);
			trace(text);
		}
		#end
	}
	
	public function call(event:String, args:Array<Dynamic>):Dynamic {
		#if LUA_ALLOWED
		if (lua == null) {
			return Function_Continue;
		}

		Lua.getglobal(lua, event);

		for (arg in args) {
			Convert.toLua(lua, arg);
		}

		var result:Null<Int> = Lua.pcall(lua, args.length, 1, 0);
		if (result != null && resultIsAllowed(lua, result)) {
			if (Lua.type(lua, -1) == Lua.LUA_TSTRING) {
				var error:String = Lua.tostring(lua, -1);
				Lua.pop(lua, 1);
				if (error == 'attempt to call a nil value') { //Makes it ignore warnings and not break stuff if you didn't put the functions on your lua file
					return Function_Continue;
				}
			}

			var conv:Dynamic = Convert.fromLua(lua, result);
			Lua.pop(lua, 1);
			return conv;
		}
		#end
		return Function_Continue;
	}

	function getPropertyLoopThingWhatever(killMe:Array<String>, ?checkForTextsToo:Bool = true):Dynamic
	{
		var coverMeInPiss:Dynamic = getObjectDirectly(killMe[0], checkForTextsToo);
		for (i in 1...killMe.length-1) {
			coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
		}
		return coverMeInPiss;
	}

	function getObjectDirectly(objectName:String, ?checkForTextsToo:Bool = true):Dynamic
	{
		var coverMeInPiss:Dynamic = null;
		if (PlayState.instance.modchartSprites.exists(objectName)) {
			coverMeInPiss = PlayState.instance.modchartSprites.get(objectName);
		} else if (checkForTextsToo && PlayState.instance.modchartTexts.exists(objectName)) {
			coverMeInPiss = PlayState.instance.modchartTexts.get(objectName);
		} else {
			coverMeInPiss = Reflect.getProperty(getInstance(), objectName);
		}
		return coverMeInPiss;
	}

	#if LUA_ALLOWED
	function resultIsAllowed(leLua:State, ?leResult:Int) { //Makes it ignore warnings
		switch(Lua.type(leLua, leResult)) {
			case Lua.LUA_TNIL | Lua.LUA_TBOOLEAN | Lua.LUA_TNUMBER | Lua.LUA_TSTRING | Lua.LUA_TTABLE:
				return true;
		}
		return false;
	}
	#end

	public function set(variable:String, data:Dynamic) {
		#if LUA_ALLOWED
		if (lua == null) {
			return;
		}

		Convert.toLua(lua, data);
		Lua.setglobal(lua, variable);
		#end
	}

	#if LUA_ALLOWED
	public function getBool(variable:String) {
		var result:String = null;
		Lua.getglobal(lua, variable);
		result = Convert.fromLua(lua, -1);
		Lua.pop(lua, 1);

		if (result == null) {
			return false;
		}

		// YES! FINALLY IT WORKS
		return (result == 'true');
	}
	#end

	public function stop() {
		#if LUA_ALLOWED
		if (lua == null) {
			return;
		}

		Lua.close(lua);
		lua = null;
		#end
	}

	inline function getInstance()
	{
		return PlayState.instance.isDead ? GameOverSubState.instance : PlayState.instance;
	}


	 // Fuck this, I can't figure out linc_lua, so I'mma set everything in Lua itself - Super
}

class ModchartSprite extends FlxSprite
{
	public var wasAdded:Bool = false;

	public function new(?x:Float = 0, ?y:Float = 0)
	{
		super(x, y);
		antialiasing = ClientPrefs.globalAntialiasing;
	}
}

class ModchartText extends FlxText
{
	public var wasAdded:Bool = false;
	public function new(x:Float, y:Float, text:String, width:Float)
	{
		super(x, y, width, text, 16);
		setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		cameras = [PlayState.instance.camHUD];
		scrollFactor.set();
		borderSize = 2;
	}
}

class DebugLuaText extends FlxText
{
	private var disableTime:Float = 6;
	public var parentGroup:FlxTypedGroup<DebugLuaText>; 
	public function new(text:String, parentGroup:FlxTypedGroup<DebugLuaText>) {
		this.parentGroup = parentGroup;
		super(10, 10, 0, text, 16);
		setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scrollFactor.set();
		borderSize = 1;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		disableTime -= elapsed;
		if (disableTime <= 0) {
			kill();
			parentGroup.remove(this);
			destroy();
		}
		else if (disableTime < 1) alpha = disableTime;
	}
}
