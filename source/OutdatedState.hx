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

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);

		warnText = new FlxText(0, 0, FlxG.width,
			"Hey, you are using the   \n
			outdated version of Goldy Engine (" + MainMenuState.engineVersion + "),\n
			going to update to " + TitleState.updateVersion + "!\n
			Press enter or back to download it!\n
			Press back controls to prooced anyway. \n
			Thank you for using the Engine!",
			32);
		warnText.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER);
		warnText.screenCenter(Y);
		add(warnText);
	}

	override function update(elapsed:Float)
	{
		if(!leftState) {
			if (controls.ACCEPT) {
				CoolUtil.browserLoad('https://github.com/cheblol/FNF-FunkinGoldyEngine-lua/releases/download/$updateVersion/build.zip');
				FlxG.sound.play(Paths.sound('confirmMenu'));
			}
			else if (controls.BACK)
			{
				leftState = true;
				FlxTween.tween(warnText, {alpha: 0}, 1, {
					onComplete: function (twn:FlxTween) {
						MusicBeatState.switchState(new MainMenuState());
					}
				});
				FlxG.sound.play(Paths.sound('cancelMenu'));
			}
		}
		super.update(elapsed);
	}
}
