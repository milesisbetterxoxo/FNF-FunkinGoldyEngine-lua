package;

import editors.CharacterEditorState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import haxe.Json;

using StringTools;

typedef HealthIconConfig =
{
	//var ?flipX:Bool; no more
	//var ?color:FlxColor; no more
	var ?scale:Array<Float>;
	var ?antialiasing:Bool;
}

class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;
	private var isOldIcon:Bool = false;
	public var isPlayer:Bool = false;
	public var char:String = '';
	var originalChar:String = 'bf-old';
	var type:String = 'default'; // can be 'default' or 'classic' (psych)

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

		//selfUpdate(); // omfg
		// self expanatory
		// nvm doesnt work LFMAOFsdk
	}

	public function swapOldIcon() {
		if (!isOldIcon) changeIcon('bf-old', 'default');
		else changeIcon(originalChar, 'default');
	}

	private var iconOffsets:Array<Float> = [0, 0];
	public function changeIcon(char:String, curAnim:String = 'default') {
		if (this.char != char) {
			var config:HealthIconConfig;
			if (Paths.fileExists('images/icons/$char/config.json', TEXT)) {
				config = Json.parse(Paths.getTextFromFile('images/icons/$char/config.json'));
				if (config.antialiasing != null) {
					antialiasing = config.antialiasing;
					if (config.antialiasing == true) {
						antialiasing = ClientPrefs.globalAntialiasing;
					}
				}

			}
            var imageExists:Bool = true;
			var name:String = 'icons/$char/$curAnim';
			if (!Paths.fileExists('images/$name.png', IMAGE)) {
				name = 'icons/$char/$curAnim'; //Older versions of psych engine's support
			}
			if (!Paths.fileExists('images/$name.png', IMAGE)) {
				name = 'icons/$char/default'; //Prevents crash from missing icon
				if (!CharacterEditorState.inEditor) {
					FlxG.log.warn('Couldn\'t find icon file for $char!');
				    FlxG.log.warn('Using the default animation...');
				}
			}
			if (!Paths.fileExists('images/$name.png', IMAGE)) {
				name = 'icons/face/$curAnim';
				if (!CharacterEditorState.inEditor) {
					FlxG.log.warn('Couldn\'t find icon file for $char!');
				    FlxG.log.warn('Using the face icon...');
				}
			}
			if (!Paths.fileExists('images/$name.png', IMAGE)) {
				name = 'placeholder';
				if (!CharacterEditorState.inEditor) {
					FlxG.log.warn('funee placeholder'); // so true
				}
				setGraphicSize(150, 150); // real
				updateHitbox();
			}
			if (!Paths.fileExists('images/$name.png', IMAGE)) {
				imageExists = false;
			}
			var file = Paths.image(name);

			if (imageExists) {
				loadGraphic(file); //Load stupidly first for getting the file size
			    iconOffsets[0] = (width - 150) / 2;
			    iconOffsets[1] = (width - 150) / 2;
			    iconOffsets[2] = (width - 150) / 2;
			    updateHitbox();
			}

			this.char = char;
			if (char != 'bf-old') originalChar = char;

			antialiasing = ClientPrefs.globalAntialiasing;
			if (char.endsWith('-pixel')) {
				antialiasing = false;
			}

			flipX = isPlayer;

			isOldIcon = (char == 'bf-old');
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
