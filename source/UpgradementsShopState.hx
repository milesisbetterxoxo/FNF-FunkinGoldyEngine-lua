package;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.text.FlxText;

/**
 * what am i doing with my life
 */

class UpgradementsShopState extends MusicBeatState
{
    var coins:Int = CoinStuff.coins;
    var bg:FlxSprite;
    var scrollers:FlxTypedGroup<FlxSprite>;
    var scrollersAmount:Int = 2;
    var items:FlxTypedGroup<Item>;
    
    override function create()
    {
        bg = new FlxSprite();
        bg.loadGraphic(Paths.image('menuBG'));
        bg.screenCenter();
        add(bg);
        for (i in 0...scrollersAmount) {
            var scrollerStuff:FlxSprite = new FlxSprite();
            scrollerStuff.frames = Paths.getSparrowAtlas('campaign_menu_UI_assets');
            scrollerStuff.animation.addByPrefix('default-left', 'arrow left');
            scrollerStuff.animation.addByPrefix('default-right', 'arrow right');
            scrollerStuff.animation.addByPrefix('pressed-left', 'arrow push left');
            scrollerStuff.animation.addByPrefix('pressed-right', 'arrow push right');
            scrollerStuff.ID = i;
            scrollers.add(scrollerStuff);
            add(scrollerStuff);
            if (scrollerStuff.ID == 1) {
                scrollerStuff.animation.play('default-left');
            }
            else {
                scrollerStuff.animation.play('default-right');
            }
        }

        super.create();
    }
}

class CoinStuff {
    public static var coins:Int = 0;

    public static function save() {
        FlxG.save.data.coins = coins;
    }
    
    public static function load() {
        if (FlxG.save.data.coins != null) {
            coins = FlxG.save.data.coins;
        }
    }
}

class Item extends FlxText
{
    public var cost:Int = 0;
    public var id:Int = 0;

    public function new() {
        switch (id) {
            case 0:
                text = 'More health per note!';
            case 1:
                text = 'Funk-Shield';
            case 2:
                text = 'Auto-Funk for 2 bars';
        }

        super();
    }
}