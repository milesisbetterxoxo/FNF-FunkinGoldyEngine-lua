package;

import flixel.system.FlxAssets.FlxShader;
import flixel.FlxG;
import flixel.FlxSprite;
import haxe.Json;
import openfl.Assets;

using StringTools;

typedef IconConfig =
{
	isPixel:Bool,
	scale:Array<Float>,
	flipX:Bool,
	shader:String // idfk???
}

class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;

	private var isOldIcon:Bool = false;

	public var isPlayer:Bool = false;
	public var char:String = ''; // for freeplay win shit

	var originalChar:String = 'bf-old';

	public var hasWinIcon:Bool;
	public var hasLoseIcon:Bool;
	public var iconExists:Bool;
	public var config:IconConfig;
	public var curAnim:String = 'default';

	public function new(char:String = 'face', isPlayer:Bool = false)
	{
		super();

		this.isPlayer = isPlayer;

		changeIcon(char, 'default');

		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);
	}

	public function swapOldIcon()
	{
		if (!isOldIcon)
			changeIcon('bf-old', 'default');
		else
			changeIcon(originalChar, 'default');
	}

	public var iconOffsets:Array<Float> = [0, 0];

	public function changeIcon(char:String, curAnim:String = 'default') // NEW VERSION
	{
		var name:String = Paths.getPath('icons/$char/$curAnim', null);
		var imageExists:Bool = true;

		if (!Assets.exists('$name.png', IMAGE))
		{
			FlxG.log.warn('$name does not exist! Trying to use the default icon instead.');
			name = 'icons/$char/default';
		}

		if (!Assets.exists('$name.png', IMAGE) && name == 'icons/$char/default')
		{
			FlxG.log.warn('$name does not exist! Trying to use the default icon instead.');
			name = 'icons/face/$curAnim';
		}

		if (!Assets.exists('$name.png', IMAGE) && name == 'icons/face/$curAnim')
		{
			FlxG.log.warn('$name does not exist! Using nothing instead.');
			imageExists = false;
		}

		var file = Paths.image(name);

		var configExists = Paths.fileExists('images/icons/$char/config.json', TEXT);

		if (configExists) {
			config = Json.parse(Paths.getTextFromFile('images/icons/$char/config.json')); // icon config?!?!?
			antialiasing = ClientPrefs.globalAntialiasing;
			if (config.isPixel) {
				antialiasing = false;
			}
			if (config.scale.length > 0 && config.scale != null) {
				scale.set(config.scale[0], config.scale[1]);
				updateHitbox();
			}
			if (config.shader.length > 0 && config.shader != null) {
				shader = getShaderFromString(config.shader); // yeah, im very kool
			}
		}
		else {
            antialiasing = ClientPrefs.globalAntialiasing;
			scale.set(1, 1);
			updateHitbox();
		}

		if (imageExists) {
			loadGraphic(file);
		}
		updateHitbox();

		this.char = char;

		// anyway
		if (isPlayer)
			flipX = true;

		isOldIcon = (char == 'bf-old');
	}

	public function getShaderFromString(shader:String):FlxShader {
		switch (shader) {
            case 'building-shader':
                return new Shaders.BuildingShader();
            case 'chromatic-aberration-shader':
                return new Shaders.ChromaticAberrationShader();
            case 'scanline':
                return new Shaders.Scanline();
            case 'tiltshift':
                return new Shaders.Tiltshift();
            case 'greyscale':
                return new Shaders.GreyscaleShader();
            case 'grain':
                return new Shaders.Grain();
            case 'vcr-distortion-shader':
                return new Shaders.VCRDistortionShader();
            case '3D' | '3D-shader' | 'ThreeD':
                return new Shaders.ThreeDShader();
            case 'fucking-triangle' | 'triangle': // i dont think ppl will use this but whatever
                return new Shaders.FuckingTriangle();
            case 'bloom':
                return new Shaders.BloomShader();
            case 'glitch' | 'glitch-effect':
                return new Shaders.GlitchShader(); // I LOVE BANUD 
            case 'pulse':
                return new Shaders.PulseShader();
            case 'distort' | 'distortBG':
                return new Shaders.DistortBGShader();
            case 'invert':
                return new Shaders.InvertShader();
            // im too lazy to make it be customizable
        }
        return null;
	}

	override function updateHitbox()
	{
		super.updateHitbox();

		offset.x = iconOffsets[0];
		offset.y = iconOffsets[1];
	}

	public function getCharacter():String
		return char;
}
