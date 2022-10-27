package;

import flixel.FlxSprite;
import flixel.FlxText;

class ErrorState extends MusicBeatState
{
    private var error:String;
    public function new(error:String = "???") {
        this.error = error;
        super();
    }
    override function create() {
        var bg:FlxSprite = new FlxSprite();
        bg.loadGraphic(Paths.image('menuBG'));
        bg.color = 0x2C2B2B;
        bg.setGraphicSize(Std.int(bg.width * 1.175));
        add(bg);

        var errorText:FlxText = new FlxText(0, 0, 'THIS IS CANCELED. IDK HOW YOU GOT HERE, \n BUT PLEASE PRESS YOUR BACK CONTROLS');
        errorText.screenCenter();
        add(errorText);
        

        super.create();
    }
    override function update(elapsed:Float) {
        if (controls.BACK) {
            MusicBeatState.switchState(new MainMenuStateGoldy());
        }

        super.update(elapsed);
    }
}