package;

import editors.CharacterEditorState;
import flixel.FlxG;
import flixel.FlxSprite;
import sys.FileSystem;

using StringTools;

class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;
	private var isOldIcon:Bool = false;
	private var isPlayer:Bool = false;
	public var char:String = ''; // makin it public cuz for playstate support
	var originalChar:String = 'bf-old';
	public var psychIcon:Bool = false;
	var Any:Any; // cuz idk $ cant load abstract only var
	public var hasWinIcon = true;
	public var hasLoseIcon = true;

	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
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
		else changeIcon(originalChar);
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
	public function changeIcon(char:String, curAnim:String = 'default') // NEW VERSION
	{
		if (this.char != char) {
			var name:String = 'icons/$char/$curAnim';
			if (!Paths.fileExists('images/$name.png', IMAGE)) {
				name = 'icons/icon-$char'; //Older versions of psych engine's support
			}
			if (!Paths.fileExists('images/$name.png', IMAGE)) {
				name = 'icons/face/default'; //Prevents crash from missing icon
				if (!CharacterEditorState.inEditor)
					FlxG.log.warn('Couldn\'t find icon file for $char!');
				    FlxG.log.warn('Using the crash prevent icon, which is face!');
			}
			var file = Paths.image(name);

			loadGraphic(file); //Load stupidly first for getting the file size
			loadGraphic(file, true, 150, 150); //Then load it fr
			iconOffsets[0] = (width - 150) / 1;
			updateHitbox();

			animation.add(char, [0], 0, false, isPlayer);

			animation.play(char);
			this.char = char;
			if (char != 'bf-old') originalChar = char;

			antialiasing = ClientPrefs.globalAntialiasing;
			if (char.endsWith('-pixel')) {
				antialiasing = false;
			}

			isOldIcon = (char == 'bf-old');

			if (!FileSystem.exists('assets/images/icons/$char/win.png') /*|| !FileSystem.exists('mods/images/icons/$char/win.png')*/)
			{
				hasWinIcon = false;
			}
			if (!FileSystem.exists('assets/images/icons/$char/lose.png')/*|| !FileSystem.exists('mods/images/icons/$char/lose.png')*/)
			{
				hasLoseIcon = false;
			}
		}
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
