package;

import flixel.util.FlxColor;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxSprite;
import haxe.Json;

using StringTools;

typedef StageJSON =
{
    var name:String;
    var images:Array<Image>;
    var boyfriendPosition:Array<Float>;
    var girlfriendPosition:Array<Float>;
    var dadPosition:Array<Float>;
}

// specially made for mod stages lmfao

class Stage extends FlxTypedGroup<FlxSprite>
{
    public var sprites:Array<FlxSprite> = [];

    public var stage:String;

    var defaultAnimations:Array<Animation> = [];

    

    public function new(stage:String) {
        sprites = [];
        this.stage = stage;
        super();
    }

    public function newSprite(image:String, isAnimated:Bool = false, animations:Array<Animation> = null, x:Float = 0, y:Float = 0, scale:Float = 1, color:FlxColor = 0xFFFFFF):FlxSprite
    {
        var spr:FlxSprite = new FlxSprite();
        spr.setPosition(x, y);
        if (isAnimated && animations.length > 0) {
            spr.frames = Paths.getSparrowAtlas(image);
            for (anim in animations) {
                if (anim.frames != null) {
                    spr.animation.addByIndices(anim.name, anim.prefix, anim.frames, "", anim.fps, anim.loop);
                }
                else {
                    spr.animation.addByPrefix(anim.name, anim.prefix, anim.fps, anim.loop);
                }
            }
        }
        else {
            spr.loadGraphic(Paths.image(image));
        }

        spr.scale.set(scale, scale);
        spr.color = color;

        add(spr);

        return spr;

    }

    public function loadFromJson(jsonName:String)
    {
        var json:StageJSON = Json.parse(Paths.json(jsonName));
        for (sprite in json.images)
        {
            var isAnimated:Bool = false;
            isAnimated = sprite.isAnimated;
            newSprite(sprite.imagePath, isAnimated, sprite.animations, sprite.position[0], sprite.position[1], sprite.scale, sprite.color);
        }
    }
}

class Animation
{
    public var name:String;

    public var fps:Int = 24;

    public var prefix:String;

    public var frames:Array<Int> = null;

    public var loop:Bool = true;
}

typedef Image = 
{
    var imagePath:String;
    
    var ?isAnimated:Bool;

    var ?animations:Array<Animation>;

    var ?color:FlxColor;

    var position:Array<Float>;

    var scale:Float;
}