package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.effects.FlxFlicker;
import lime.app.Application;
import flixel.addons.transition.FlxTransitionableState;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;

class OutdatedState extends MusicBeatState
{
	public static var leftState:Bool = false;

	var updateVersion = TitleState.updateVersion;

	var warnText:FlxText;
	override function create()
	{
		super.create();

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0x2C2B2B;
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		add(bg);

		warnText = new FlxText(0, 0, FlxG.width,
			"Hey, you are using the   \n
			outdated version of Goldy Engine (" + MainMenuStateGoldy.engineVersion + "),\n
			going to update to " + TitleState.updateVersion + "!\n
			Press enter to download it!\n
			Press back controls to prooced anyway. \n
			Thank you for using the Engine!",
			32);
		warnText.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER);
		warnText.screenCenter(Y);
		add(warnText);

		FlxG.sound.music = null;
		FlxG.sound.playMusic(Paths.music('freakyMenuEdited2'));
	}

	override function update(elapsed:Float)
	{
		if(!leftState) {
			if (controls.ACCEPT) {
				leftState = true;
				CoolUtil.browserLoad('https://github.com/cheblol/FNF-FunkinGoldyEngine-lua/releases/download/${TitleState.updateVersion}/build.rar');
			    FlxG.sound.play(Paths.sound('confirmMenu'));
			}
			else if (controls.BACK)
			{
				leftState = true;
				FlxTween.tween(FlxG.camera, {alpha: 0}, 1, {
					onComplete: function (twn:FlxTween) {
						MusicBeatState.switchState(new MainMenuStateGoldy());
					}
				});
				FlxG.sound.play(Paths.sound('cancelMenu'));
				FlxG.sound.music.stop();
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
			}
		}
		super.update(elapsed);
	}
}
