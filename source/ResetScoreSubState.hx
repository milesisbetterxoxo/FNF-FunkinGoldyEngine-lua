import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;

using StringTools;

class ResetScoreSubState extends MusicBeatSubState
{
	var bg:FlxSprite;
	var alphabetArray:Array<Alphabet> = [];
	var icon:HealthIcon;
	var onYes:Bool = false;
	var yesText:Alphabet;
	var noText:Alphabet;

	var song:String;
	var difficulty:Int;
	var week:String;

	var character:String;

	// Week '' = Freeplay
	public function new(song:String, difficulty:Int, character:String, week:String = '')
	{
		this.song = song;
		this.difficulty = difficulty;
		this.week = week;

		this.character = character;

		super();

		var name:String = song;
		if (week.length > 0) {
			name = WeekData.weeksLoaded.get(week).weekName;
		}
		name += ' (${CoolUtil.difficulties[difficulty]})?';

		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		var tooLong:Float = (name.length > 18) ? 0.8 : 1; //Fucking Winter Horrorland
		var text:Alphabet = new Alphabet(0, 180, "Reset the score of", true);
		text.screenCenter(X);
		alphabetArray.push(text);
		text.alpha = 0;
		add(text);
		var text:Alphabet = new Alphabet(0, text.y + 90, name, true, false, 0.05, tooLong);
		text.screenCenter(X);
		if (week.length < 1) text.x += 60 * tooLong;
		alphabetArray.push(text);
		text.alpha = 0;
		add(text);
		if (week.length < 1) {
			icon = new HealthIcon(character);
			icon.setGraphicSize(Std.int(icon.width * tooLong));
			icon.updateHitbox();
			icon.setPosition(text.x - icon.width + (10 * tooLong), text.y - 30);
			icon.alpha = 0;
			add(icon);
		}

		yesText = new Alphabet(0, text.y + 150, 'Yes', true);
		yesText.screenCenter(X);
		yesText.x -= 200;
		add(yesText);
		noText = new Alphabet(0, text.y + 150, 'No', true);
		noText.screenCenter(X);
		noText.x += 200;
		add(noText);
		updateOptions();
	}

	override function update(elapsed:Float)
	{
		bg.alpha += elapsed * 1.5;
		if (bg.alpha > 0.6) bg.alpha = 0.6;

		for (i in 0...alphabetArray.length) {
			var spr = alphabetArray[i];
			spr.alpha += elapsed * 2.5;
		}
		if (week.length < 1) icon.alpha += elapsed * 2.5;

		if (controls.UI_LEFT_P || controls.UI_RIGHT_P || FlxG.mouse.wheel != 0) {
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			onYes = !onYes;
			updateOptions();
		}
		if (controls.BACK) {
			FlxG.sound.play(Paths.sound('cancelMenu'), 0.7);
			close();
		} else if (controls.ACCEPT || FlxG.mouse.justPressed) {
			if (onYes) {
				if (week.length < 1) {
					Highscore.resetSong(song, difficulty);
				} else {
					Highscore.resetWeek(week, difficulty);
				}
			}
			FlxG.sound.play(Paths.sound('cancelMenu'), 0.7);
			close();
		}
		super.update(elapsed);
	}

	function updateOptions() {
		var scales:Array<Float> = [0.75, 1];
		var alphas:Array<Float> = [0.6, 1.25];
		var confirmInt:Int = onYes ? 1 : 0;

		yesText.alpha = alphas[confirmInt];
		yesText.scale.set(scales[confirmInt], scales[confirmInt]);
		noText.alpha = alphas[1 - confirmInt];
		noText.scale.set(scales[1 - confirmInt], scales[1 - confirmInt]);
		if (week.length < 1)
		{ 
			if (confirmInt != 0)
			icon.changeIcon(icon.char, 'lose');
			else 
			icon.changeIcon(icon.char, 'win');
		}
	}
}