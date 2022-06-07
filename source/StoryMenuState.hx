package;

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.graphics.FlxGraphic;
import WeekData;

using StringTools;

class StoryMenuState extends MusicBeatState
{
	public static var weekCompleted:Map<String, Bool> = new Map();

	var scoreText:FlxText;

	private static var lastDifficultyName:String = '';
	var curDifficulty:Int = 1;

	var txtWeekTitle:FlxText;
	var bgSprite:FlxSprite;

	private static var curWeek:Int = 0;

	var txtTracklist:FlxText;

	var grpWeekText:FlxTypedGroup<MenuItem>;
	var grpWeekCharacters:FlxTypedGroup<MenuCharacter>;

	var grpLocks:FlxTypedGroup<AttachedSprite>;

	var difficultySelectors:FlxGroup;
	var sprDifficulty:FlxSprite;
	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;

	var loadedWeeks:Array<WeekData> = [];

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		AtlasFrameMaker.clearCache();

		PlayState.isStoryMode = true;
		WeekData.reloadWeekFiles(true);
		if (curWeek >= WeekData.weeksList.length) curWeek = 0;
		persistentUpdate = true;

		scoreText = new FlxText(10, 10, 0, "SCORE: 49324858", 36);
		scoreText.setFormat("VCR OSD Mono", 32);

		txtWeekTitle = new FlxText(FlxG.width * 0.7, 10, 0, "", 32);
		txtWeekTitle.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, RIGHT);
		txtWeekTitle.alpha = 0.7;

		var rankText:FlxText = new FlxText(0, 10);
		rankText.text = 'RANK: GREAT';
		rankText.setFormat(Paths.font("vcr.ttf"), 32);
		rankText.size = scoreText.size;
		rankText.screenCenter(X);

		var ui_tex = Paths.getSparrowAtlas('campaign_menu_UI_assets');
		var bgYellow:FlxSprite = new FlxSprite(0, 56).makeGraphic(FlxG.width, 386, 0xFFF9CF51);
		bgSprite = new FlxSprite(0, 56);
		bgSprite.antialiasing = ClientPrefs.globalAntialiasing;

		grpWeekText = new FlxTypedGroup<MenuItem>();
		add(grpWeekText);

		grpLocks = new FlxTypedGroup<AttachedSprite>();
		add(grpLocks);

		var blackBarThingie:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 56, FlxColor.BLACK);
		add(blackBarThingie);

		grpWeekCharacters = new FlxTypedGroup<MenuCharacter>();

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the menus", null);
		#end

		var num:Int = 0;
		for (i in 0...WeekData.weeksList.length)
		{
			var weekFile:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			WeekData.setDirectoryFromWeek(weekFile);
			var isLocked:Bool = weekIsLocked(WeekData.weeksList[i]);
			if(!isLocked || !weekFile.hiddenUntilUnlocked)
			{
				loadedWeeks.push(weekFile);
				var weekThing:MenuItem = new MenuItem(0, bgSprite.y + 396, weekFile.fileName);
				weekThing.y += ((weekThing.height + 20) * num);
				weekThing.targetY = num;
				grpWeekText.add(weekThing);

				weekThing.screenCenter(X);

				// Needs an offset thingie
				if (isLocked)
				{
					var lock:AttachedSprite = new AttachedSprite();
					lock.frames = ui_tex;
					lock.animation.addByPrefix('lock', 'lock');
					lock.animation.play('lock');
					lock.xAdd = weekThing.width + 10;
					lock.sprTracker = weekThing;
					lock.ID = i;
					grpLocks.add(lock);
				}
				num++;
			}
		}

		if (loadedWeeks.length > 0) {
			WeekData.setDirectoryFromWeek(loadedWeeks[0]);
			var charArray:Array<String> = loadedWeeks[0].weekCharacters;
			for (char in 0...3)
			{
				var weekCharacterThing:MenuCharacter = new MenuCharacter((FlxG.width * 0.25) * (1 + char) - 150, charArray[char]);
				weekCharacterThing.y += 70;
				grpWeekCharacters.add(weekCharacterThing);
			}
		}

		difficultySelectors = new FlxGroup();
		add(difficultySelectors);

		var startX = 861.5;
		var startY = bgSprite.y + 396;
		leftArrow = new FlxSprite(startX + 10, startY + 10);
		leftArrow.frames = ui_tex;
		leftArrow.animation.addByPrefix('idle', "arrow left");
		leftArrow.animation.addByPrefix('press', "arrow push left");
		leftArrow.animation.play('idle');
		leftArrow.antialiasing = ClientPrefs.globalAntialiasing;
		difficultySelectors.add(leftArrow);

		CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();
		if (lastDifficultyName == '')
		{
			lastDifficultyName = CoolUtil.defaultDifficulty;
		}
		curDifficulty = FlxMath.maxInt(0, CoolUtil.defaultDifficulties.indexOf(lastDifficultyName));
		
		sprDifficulty = new FlxSprite(0, leftArrow.y);
		sprDifficulty.antialiasing = ClientPrefs.globalAntialiasing;

		difficultySelectors.add(sprDifficulty);

		rightArrow = new FlxSprite(leftArrow.x + 376, leftArrow.y);
		rightArrow.frames = ui_tex;
		rightArrow.animation.addByPrefix('idle', 'arrow right');
		rightArrow.animation.addByPrefix('press', "arrow push right", 24, false);
		rightArrow.animation.play('idle');
		rightArrow.antialiasing = ClientPrefs.globalAntialiasing;
		difficultySelectors.add(rightArrow);

		add(bgYellow);
		add(bgSprite);
		add(grpWeekCharacters);

		var tracksSprite:FlxSprite = new FlxSprite(FlxG.width * 0.07, bgSprite.y + 425).loadGraphic(Paths.image('Menu_Tracks'));
		tracksSprite.antialiasing = ClientPrefs.globalAntialiasing;
		add(tracksSprite);

		txtTracklist = new FlxText(FlxG.width * 0.05, tracksSprite.y + 60, 0, "", 32);
		txtTracklist.alignment = CENTER;
		txtTracklist.font = rankText.font;
		txtTracklist.color = 0xFFe55777;
		add(txtTracklist);
		add(scoreText);
		add(txtWeekTitle);

		changeWeek();
		changeDifficulty();

		super.create();
	}

	override function closeSubState() {
		persistentUpdate = true;
		changeWeek();
		super.closeSubState();
	}

	var holdTime:Float = 0;
	override function update(elapsed:Float)
	{
		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, CoolUtil.boundTo(elapsed * 30, 0, 1)));
		if (Math.abs(intendedScore - lerpScore) < 10) lerpScore = intendedScore;

		scoreText.text = 'WEEK SCORE:$lerpScore';

		super.update(elapsed);

		if (!movedBack && !selectedWeek)
		{
			if (loadedWeeks.length > 0) {
				if (loadedWeeks.length > 1) {
					var shiftMult:Int = 1;
					if (FlxG.keys.pressed.SHIFT) shiftMult = 3;
					var upP = controls.UI_UP_P;
					var downP = controls.UI_DOWN_P;
					if (upP || (!FlxG.keys.pressed.SHIFT && FlxG.mouse.wheel > 0))
					{
						changeWeek(-shiftMult);
						FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
						holdTime = 0;
					}

					if (downP || (!FlxG.keys.pressed.SHIFT && FlxG.mouse.wheel < 0))
					{
						changeWeek(shiftMult);
						FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
						holdTime = 0;
					}

					if (controls.UI_DOWN || controls.UI_UP)
					{
						var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
						holdTime += elapsed;
						var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

						if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
						{
							changeWeek((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
						}
					}
				}

				if (controls.UI_RIGHT)
					rightArrow.animation.play('press')
				else
					rightArrow.animation.play('idle');

				if (controls.UI_LEFT)
					leftArrow.animation.play('press');
				else
					leftArrow.animation.play('idle');

				if (controls.UI_RIGHT_P || (FlxG.keys.pressed.SHIFT && FlxG.mouse.wheel > 0))
					changeDifficulty(1);
				else if (controls.UI_LEFT_P || (FlxG.keys.pressed.SHIFT && FlxG.mouse.wheel < 0))
					changeDifficulty(-1);

				if (controls.RESET)
				{
					persistentUpdate = false;
					openSubState(new ResetScoreSubState('', curDifficulty, '', WeekData.formatWeek(loadedWeeks[curWeek].fileName)));
				}
				else if (controls.ACCEPT || FlxG.mouse.justPressed)
				{
					selectWeek();
				}
			}

			if (FlxG.keys.justPressed.CONTROL)
			{
				persistentUpdate = false;
				openSubState(new GameplayChangersSubState());
			}
		}

		if (controls.BACK && !movedBack && !selectedWeek)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'), 0.7);
			movedBack = true;
			MusicBeatState.switchState(new MainMenuState());
		}
	}

	var movedBack:Bool = false;
	var selectedWeek:Bool = false;
	var stopspamming:Bool = false;

	function selectWeek()
	{
		if (!weekIsLocked(WeekData.formatWeek(loadedWeeks[curWeek].fileName)))
		{
			if (stopspamming == false)
			{
				FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);

				grpWeekText.members[curWeek].startFlashing();
				
				var bf:MenuCharacter = grpWeekCharacters.members[1];
				if(bf.character != '' && bf.hasConfirmAnimation) grpWeekCharacters.members[1].animation.play('confirm');
				stopspamming = true;
			}

			// We can't use Dynamic Array .copy() because that crashes HTML5, here's a workaround.
			var songArray:Array<String> = [];
			var leWeek = loadedWeeks[curWeek].songs;
			for (i in 0...leWeek.length) {
				songArray.push(leWeek[i][0]);
			}

			// Nevermind that's stupid lmao
			PlayState.storyPlaylist = songArray;
			PlayState.isStoryMode = true;
			selectedWeek = true;

			var diffic = CoolUtil.getDifficultyFilePath(curDifficulty);
			if (diffic == null) diffic = '';

			PlayState.storyDifficulty = curDifficulty;

			PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + diffic, PlayState.storyPlaylist[0]);
			PlayState.campaignScore = 0;
			PlayState.campaignMisses = 0;
			new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				LoadingState.loadAndSwitchState(new PlayState(), true);
				#if PRELOAD_ALL
				FreeplayState.destroyFreeplayVocals();
				#end
			});
		} else {
			FlxG.sound.play(Paths.sound('cancelMenu'), 0.7);
		}
	}

	var tweenDifficulty:FlxTween;
	function changeDifficulty(change:Int = 0):Void
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = CoolUtil.difficulties.length - 1;
		if (curDifficulty >= CoolUtil.difficulties.length)
			curDifficulty = 0;

		if (loadedWeeks.length > 0) {
			WeekData.setDirectoryFromWeek(loadedWeeks[curWeek]);

			var diff:String = CoolUtil.difficulties[curDifficulty];
			var newImage:FlxGraphic = Paths.image('menudifficulties/' + Paths.formatToSongPath(diff));
			
			if(sprDifficulty.graphic != newImage)
			{
				sprDifficulty.loadGraphic(newImage);
				sprDifficulty.x = leftArrow.x + 60;
				sprDifficulty.x += (308 - sprDifficulty.width) / 3;
				sprDifficulty.alpha = 0;
				sprDifficulty.y = leftArrow.y - 15;

				if (tweenDifficulty != null) tweenDifficulty.cancel();
				tweenDifficulty = FlxTween.tween(sprDifficulty, {y: leftArrow.y + 15, alpha: 1}, 0.07, {onComplete: function(twn:FlxTween)
				{
					tweenDifficulty = null;
				}});
			}
			lastDifficultyName = diff;

			#if HIGHSCORE_ALLOWED
			intendedScore = Highscore.getWeekScore(loadedWeeks[curWeek].fileName, curDifficulty);
			#end
		} else {
			sprDifficulty.visible = false;
		}
	}

	var lerpScore:Int = 0;
	var intendedScore:Int = 0;
	function changeWeek(change:Int = 0):Void
	{
		curWeek += change;

		if (curWeek >= loadedWeeks.length)
			curWeek = 0;
		if (curWeek < 0)
			curWeek = loadedWeeks.length - 1;

		if (loadedWeeks.length > 0) {
			var leWeek:WeekData = loadedWeeks[curWeek];
			WeekData.setDirectoryFromWeek(leWeek);

			var leName:String = leWeek.storyName;
			txtWeekTitle.text = leName.toUpperCase();
			txtWeekTitle.x = FlxG.width - (txtWeekTitle.width + 10);

			var bullShit:Int = 0;

			var unlocked:Bool = !weekIsLocked(WeekData.formatWeek(leWeek.fileName));
			for (item in grpWeekText.members)
			{
				item.targetY = bullShit - curWeek;
				if (item.targetY == Std.int(0) && unlocked)
					item.alpha = 1;
				else
					item.alpha = 0.6;
				bullShit++;
			}

			bgSprite.visible = true;
			var assetName:String = leWeek.weekBackground;
			if (assetName == null || assetName.length < 1) {
				bgSprite.visible = false;
			} else {
				bgSprite.loadGraphic(Paths.image('menubackgrounds/menu_$assetName'));
			}
			PlayState.storyWeek = curWeek;

			CoolUtil.getDifficulties();
			leftArrow.visible = rightArrow.visible = CoolUtil.difficulties.length > 1;
			difficultySelectors.visible = unlocked && loadedWeeks.length > 0;
			
			updateText();
		} else {
			bgSprite.visible = false;
		}

		if(CoolUtil.difficulties.contains(CoolUtil.defaultDifficulty))
		{
			curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(CoolUtil.defaultDifficulty)));
		}
		else
		{
			curDifficulty = 0;
		}
		
		var newPos:Int = CoolUtil.difficulties.indexOf(lastDifficultyName);
		if (newPos < 0) newPos = CoolUtil.difficulties.indexOf(lastDifficultyName.charAt(0).toUpperCase() + lastDifficultyName.substr(1));
		if (newPos < 0) newPos = CoolUtil.difficulties.indexOf(lastDifficultyName.toLowerCase());
		if (newPos < 0) newPos = CoolUtil.difficulties.indexOf(lastDifficultyName.toUpperCase());
		if (newPos > -1)
		{
			curDifficulty = newPos;
		}

		if (change != 0) {
			changeDifficulty();
		}
	}

	function weekIsLocked(name:String):Bool {
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && !Highscore.completedWeek(leWeek.weekBefore));
	}

	function updateText()
	{
		var weekArray:Array<String> = loadedWeeks[curWeek].weekCharacters;
		for (i in 0...grpWeekCharacters.length) {
			grpWeekCharacters.members[i].changeCharacter(weekArray[i]);
		}

		var leWeek:WeekData = loadedWeeks[curWeek];
		var stringThing:Array<String> = [];
		for (i in 0...leWeek.songs.length) {
			stringThing.push(leWeek.songs[i][0]);
		}

		txtTracklist.text = '';
		for (i in 0...stringThing.length)
		{
			txtTracklist.text += '${stringThing[i]}\n';
		}

		txtTracklist.text = txtTracklist.text.toUpperCase();

		txtTracklist.screenCenter(X);
		txtTracklist.x -= FlxG.width * 0.35;

		#if HIGHSCORE_ALLOWED
		intendedScore = Highscore.getWeekScore(loadedWeeks[curWeek].fileName, curDifficulty);
		#end
	}
}
