package;

import flixel.FlxSprite;
import flixel.FlxG;

class RingNoteThing extends MusicBeatSubState
{
    var counter:FlxSprite;
    var x:Int = 42;
    var y:Int = -100;
    var amount:Alphabet;
    var elapsed:Float;
    var rings:Int; // literally the amount
    public function new(rings:Int) {
        this.rings = rings;
        super();
        if (ClientPrefs.downScroll) {
            y = FlxG.height - 210; // i hope it wont be fucked up
        }
        counter = new FlxSprite(x, y);
        counter.screenCenter();
        if (Paths.fileExists('images/Counter.png', IMAGE)) {
            counter.loadGraphic(Paths.image('images/Counter'));
        }
        add(counter);
        amount = new Alphabet(counter.x - 100, counter.y, '$rings', false, false, 1);
        amount.color = 0xffffff00; // funi
        
    }
    override function update(elapsed:Float) {
        this.elapsed = elapsed;
        super.update(elapsed);
    }
}