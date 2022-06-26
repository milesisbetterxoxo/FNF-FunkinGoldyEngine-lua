package;

import editors.CharacterEditorState;
import flixel.FlxG;
import flixel.FlxSprite;
import sys.FileSystem;
import haxe.Json;

using StringTools;

typedef IconConfig = 
{
	isPixel:Bool,
    scale:Float
}

class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;
	private var isOldIcon:Bool = false;
	private var isPlayer:Bool = false;
	public var char:String = ''; // for freeplay win shit
	var originalChar:String = 'bf-old';
	public var hasWinIcon:Bool;
	public var hasLoseIcon:Bool;
	public var iconExists:Bool;
	public var iconConfig:IconConfig;
	
	public function new(char:String = 'face', isPlayer:Bool = false)
	{
		if (Paths.fileExists('images/icons/$char/win.png', IMAGE))
		{
			hasWinIcon = true;
		}
		else
	    {
			hasWinIcon = false;
		}
		if (Paths.fileExists('images/icons/$char/lose.png', IMAGE))
		{
			hasLoseIcon = true;
		}
		else 
		{
			hasLoseIcon = false;
		}
		if (!Paths.fileExists('images/icons/$char/win.png', IMAGE) && !Paths.fileExists('images/icons/$char/lose.png', IMAGE) && !Paths.fileExists('images/icons/$char/default.png', IMAGE))
		{
			iconExists = false;
		}
		if (!iconExists)
		{
			FlxG.log.warn('Couldn\'t find icon $char! Using the crash prevent icon instead.');
			char == 'face';
		}
		super();
		isOldIcon = (char == 'bf-old');
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

	public function swapOldIcon() {
		if (!isOldIcon) changeIcon('bf-old', 'default');
		else changeIcon(originalChar, 'default');
	}

	private var iconOffsets:Array<Float> = [0, 0];
	/*public function changeIcon(char:String) {
		if (this.char != char) {
			var name:String = 'icons/$char';
			if (!Paths.fileExists('images/$name.png', IMAGE)) {
				name = 'icons/icon-$char'; //Older versions of psych engine's support
			}
			if (!Paths.fileExists('images/$name.png', IMAGE)) {
				name = 'icons/icon-face'; //Prevents crash from missing icon
				if (!CharacterEditorState.inEditor)
					FlxG.log.warn('Couldn\'t find icon file for $char!');
				    FlxG.log.warn('Using the crash prevent icon, which is icon-face!');
			}
			var file = Paths.image(name);

			loadGraphic(file); //Load stupidly first for getting the file size
			loadGraphic(file, true, Math.floor(width / 3), Math.floor(height)); //Then load it fr
			iconOffsets[0] = (width - 150) / 3;
			iconOffsets[1] = (width - 150) / 3;
		    iconOffsets[2] = (width - 150) / 3;
			updateHitbox();

			animation.add(char, [0, 1, 2], 0, false, isPlayer);

			animation.play(char);
			this.char = char;
			if (char != 'bf-old') originalChar = char;

			antialiasing = ClientPrefs.globalAntialiasing;
			if (char.endsWith('-pixel')) {
				antialiasing = false;
			}

			isOldIcon = (char == 'bf-old');
		}
	}*/
	public function changeIcon(char:String, curAnim:String = "default") // NEW VERSION
	{
		var name:String = 'icons/$char/$curAnim';
		var file = Paths.image(name);

		var configExists = Paths.fileExists('images/icons/$char/config.json', TEXT);
		if (configExists)
		iconConfig = Json.parse(Paths.getTextFromFile('images/icons/$char/config.json')); // icon config?!?!?

		loadGraphic(file);
		updateHitbox();

		this.char = char;
		if (char != 'bf-old') originalChar = char;
		
		switch (this.char)
	    {
			default:
			    if (configExists && iconConfig.isPixel)
				{
					antialiasing = false;
				}
				else if (configExists)
				{
					scale.set(iconConfig.scale, iconConfig.scale);
				}
				if (configExists && !iconConfig.isPixel)
				{
					antialiasing = true;
				}
				if (!configExists)
				{
					antialiasing = ClientPrefs.globalAntialiasing;
					scale.set(1, 1);
				}
				// anyway
				if (isPlayer)
				{
				    flipX = true;
				}
		}

			isOldIcon = (char == 'bf-old');
	}

	override function updateHitbox()
	{
		super.updateHitbox();
		offset.x = iconOffsets[0];
		offset.y = iconOffsets[1];
	}

	public function getCharacter():String {
		return char;
	}
}
