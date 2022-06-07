package;

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

class CreditsState extends MusicBeatState
{
	var curSelected:Int = -1;

	var grpOptions:FlxTypedGroup<Alphabet>;
	var iconArray:Array<AttachedSprite> = [];
	var creditsStuff:Array<Array<String>> = [];

	var bg:FlxSprite;
	var descText:FlxText;
	var intendedColor:Int;
	var colorTween:FlxTween;
	var descBox:AttachedSprite;

	var offsetThing:Float = -75;

	var warningText:FlxText;
	var warningBG:FlxSprite;

	public static var skipToCurrentMod = false;

	override function create()
	{
		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		persistentUpdate = true;
		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		add(bg);
		bg.screenCenter();

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		#if MODS_ALLOWED
		var path:String = 'modsList.txt';
		if(FileSystem.exists(path))
		{
			var leMods:Array<String> = CoolUtil.coolTextFile(path);
			for (i in 0...leMods.length)
			{
				if(leMods[i].length > 0) {
					var modSplit:Array<String> = leMods[i].split('|');
					if(!Paths.ignoreModFolders.contains(modSplit[0].toLowerCase()) && !modsAdded.contains(modSplit[0]))
					{
						if(modSplit[1] == '1')
							pushModCreditsToList(modSplit[0]);
						else
							modsAdded.push(modSplit[0]);
					}
				}
			}
		}

		var arrayOfFolders:Array<String> = Paths.getModDirectories();
		arrayOfFolders.push('');
		for (folder in arrayOfFolders)
		{
			pushModCreditsToList(folder);
		}
		#end

		var pisspoop:Array<Array<String>> = [ //Name - Icon name - Description - Link - BG Color
			["Goldy Engine Team (best lua engine team)"],
			['Cheb', 'cheb', 'Have did litteraly everything for the engine. Yeah', 'https://gamejolt.com/@chebtheidk', '53E52C'],
			['talking ben real?', 'lebronjames', 'Was helping with coding, music, and art.', 'https://gamejolt.com/@ImAsimpguy', '53E52C'],
            ['Saad', 'saad', 'Epic music. Yeah', 'https://gamejolt.com/@saadthedrip', '6475F3'],
			['Artevar', 'artevar', 'Epic art.', 'https://www.youtube.com/channel/UCIns_iU4Jxeguyq2xvzGrlg', '00AAFF'],
			[''],
			['Psych Engine Team'],
			['Shadow Mario',		'shadowmario',		'Main Programmer of Psych Engine',							'https://twitter.com/Shadow_Mario_',	'444444'],
			['RiverOaken',			'riveroaken',		'Main Artist/Animator of Psych Engine',						'https://twitter.com/RiverOaken',		'C30085'],
			['shubs',				'shubs',			'Additional Programmer of Psych Engine',					'https://twitter.com/yoshubs',			'279ADC'],
			[''],
			['Former Engine Members'],
			['bb-panzu',			'bb-panzu',			'Ex-Programmer of Psych Engine',							'https://twitter.com/bbsub3',			'389A58'],
			[''],
			['Engine Contributors'],
			['iFlicky',				'iflicky',			'Composer of Psync and Tea Time\nMade the Dialogue Sounds',	'https://twitter.com/flicky_i',			'AA32FE'],
			['SqirraRNG',			'gedehari',			'Chart Editor\'s Sound Waveform base',						'https://twitter.com/gedehari',			'FF9300'],
			['PolybiusProxy',		'polybiusproxy',	'Video Loader Extension',									'https://twitter.com/polybiusproxy',	'FFEAA6'],
			['Keoiki',				'keoiki',			'Note Splash Animations',									'https://twitter.com/Keoiki_',			'FFFFFF'],
			['Smokey',				'smokey',			'Spritemap Texture Support',								'https://twitter.com/Smokey_5_',		'4D5DBD'],
			[''],
			["Funkin' Crew"],
			['ninjamuffin99',		'ninjamuffin99',	"Programmer of Friday Night Funkin'",						'https://twitter.com/ninja_muffin99',	'F73838'],
			['PhantomArcade',		'phantomarcade',	"Animator of Friday Night Funkin'",							'https://twitter.com/PhantomArcade3K',	'FFBB1B'],
			['evilsk8r',			'evilsk8r',			"Artist of Friday Night Funkin'",							'https://twitter.com/evilsk8r',			'53E52C'],
			['kawaisprite',			'kawaisprite',		"Composer of Friday Night Funkin'",							'https://twitter.com/kawaisprite',		'6475F3']
		];
		
		for(i in pisspoop) {
			creditsStuff.push(i);
		}
	
		var lastMod:String = Paths.currentModDirectory;
		var skipped = false;
		for (i in 0...creditsStuff.length)
		{
			var isSelectable:Bool = !unselectableCheck(i);
			var optionText:Alphabet = new Alphabet(0, 70 * i, creditsStuff[i][0], !isSelectable, false);
			optionText.isMenuItem = true;
			optionText.screenCenter(X);
			optionText.yAdd -= 70;
			if (isSelectable) {
				optionText.x -= 70;
			}
			optionText.forceX = optionText.x;
			optionText.targetY = i;
			grpOptions.add(optionText);

			if (isSelectable) {
				if (creditsStuff[i][5] != null)
				{
					Paths.currentModDirectory = creditsStuff[i][5];
				}

				if (skipToCurrentMod && Paths.currentModDirectory == lastMod && !skipped) {
					curSelected = i;
					skipped = true;
				}
				if (curSelected == -1) {
					curSelected = i;
				}

				var icon:AttachedSprite = new AttachedSprite('credits/${creditsStuff[i][1]}');
				icon.xAdd = optionText.width + 10;
				icon.sprTracker = optionText;
	
				// using a FlxGroup is too much fuss!
				iconArray.push(icon);
				add(icon);
				Paths.currentModDirectory = '';
			}
		}
		skipToCurrentMod = false;

		descBox = new AttachedSprite().makeGraphic(1, 1, FlxColor.BLACK);
		descBox.xAdd = -10;
		descBox.yAdd = -10;
		descBox.alphaMult = 0.6;
		descBox.alpha = 0.6;
		add(descBox);

		descText = new FlxText(50, FlxG.height + offsetThing - 25, 1180, "", 32);
		descText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		descText.scrollFactor.set();
		descBox.sprTracker = descText;
		add(descText);
		
		warningBG = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		warningBG.alpha = 0.5;
		warningBG.visible = false;
		warningBG.scrollFactor.set();
		add(warningBG);

		warningText = new FlxText(0, 0, FlxG.width, "", 48);
		warningText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		warningText.scrollFactor.set();
		warningText.borderSize = 2;
        warningText.visible = false;
		add(warningText);

		bg.color = getCurrentBGColor();
		intendedColor = bg.color;
		changeSelection();
		super.create();
	}

	var quitting:Bool = false;
	var holdTime:Float = 0;
	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		if (!quitting) {
			if (!warningText.visible) {
				var shiftMult:Int = 1;
				if (FlxG.keys.pressed.SHIFT) shiftMult = 3;

				var upP = controls.UI_UP_P;
				var downP = controls.UI_DOWN_P;

				if (upP || FlxG.mouse.wheel > 0)
				{
					changeSelection(-1 * shiftMult);
					holdTime = 0;
				}
				if (downP || FlxG.mouse.wheel < 0)
				{
					changeSelection(1 * shiftMult);
					holdTime = 0;
				}

				if(controls.UI_DOWN || controls.UI_UP)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

					if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
					{
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
					}
				}

				if ((controls.ACCEPT || FlxG.mouse.justPressed) && creditsStuff[curSelected][3] != null && creditsStuff[curSelected][3].length > 0) {
					warningText.text = 'WARNING!!!\nYOU ARE ABOUT TO GO TO: \n${creditsStuff[curSelected][3]}\nARE YOU ABSOLUTELY SURE YOU WANT TO GO TO THIS URL? \n(Y - Yes, N - No)';
					warningText.screenCenter();
					warningText.visible = true;
				}
				if (controls.BACK)
				{
					if (colorTween != null) {
						colorTween.cancel();
					}
					FlxG.sound.play(Paths.sound('cancelMenu'), 0.7);
					MusicBeatState.switchState(new MainMenuState());
					quitting = true;
				}
			} else {
				if (FlxG.keys.pressed.Y) {
					CoolUtil.browserLoad(creditsStuff[curSelected][3]);
					warningText.visible = false;
				}
				else if (FlxG.keys.pressed.N || controls.BACK) {
					warningText.visible = false;
				}
			}
		}

		for (item in grpOptions.members)
		{
			if(!item.isBold)
			{
				var lerpVal:Float = CoolUtil.boundTo(elapsed * 12, 0, 1);
				if(item.targetY == 0)
				{
					var lastX:Float = item.x;
					item.screenCenter(X);
					item.x = FlxMath.lerp(lastX, item.x - 70, lerpVal);
					item.forceX = item.x;
				}
				else
				{
					item.x = FlxMath.lerp(item.x, 200 + -40 * Math.abs(item.targetY), lerpVal);
					item.forceX = item.x;
				}
			}
		}

		warningBG.visible = warningText.visible;
		super.update(elapsed);
	}

	var moveTween:FlxTween = null;
	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		do {
			curSelected += change;
			if (curSelected < 0)
				curSelected = creditsStuff.length - 1;
			if (curSelected >= creditsStuff.length)
				curSelected = 0;
		} while(unselectableCheck(curSelected));

		var newColor:Int =  getCurrentBGColor();
		if (newColor != intendedColor) {
			if (colorTween != null) {
				colorTween.cancel();
			}
			intendedColor = newColor;
			colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {
				onComplete: function(twn:FlxTween) {
					colorTween = null;
				}
			});
		}

		var bullShit:Int = 0;

		for (item in grpOptions.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			if (!unselectableCheck(bullShit-1)) {
				item.alpha = 0.6;
				if (item.targetY == 0) {
					item.alpha = 1;
				}
			}
		}
		
		descText.text = creditsStuff[curSelected][2];
		descText.y = FlxG.height - descText.height + offsetThing - 60;

		if(moveTween != null) moveTween.cancel();
		moveTween = FlxTween.tween(descText, {y : descText.y + 75}, 0.25, {ease: FlxEase.sineOut});

		descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25));
		descBox.updateHitbox();
	}

	#if MODS_ALLOWED
	private var modsAdded:Array<String> = [];
	function pushModCreditsToList(folder:String)
	{
		if(modsAdded.contains(folder)) return;

		var creditsFile:String = null;
		if(folder != null && folder.trim().length > 0) creditsFile = Paths.mods(folder + '/data/credits.txt');
		else creditsFile = Paths.mods('data/credits.txt');

		if (FileSystem.exists(creditsFile))
		{
			var firstarray:Array<String> = File.getContent(creditsFile).split('\n');
			for(i in firstarray)
			{
				var arr:Array<String> = i.replace('\\n', '\n').split("::");
				if(arr.length >= 5) arr.push(folder);
				creditsStuff.push(arr);
			}
			creditsStuff.push(['']);
		}
		modsAdded.push(folder);
	}
	#end

	function getCurrentBGColor() {
		var bgColor:String = creditsStuff[curSelected][4];
		if (!bgColor.startsWith('0x')) {
			bgColor = '0xFF$bgColor';
		}
		return Std.parseInt(bgColor);
	}

	private function unselectableCheck(num:Int):Bool {
		return creditsStuff[num].length <= 1;
	}
}