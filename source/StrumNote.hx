package;

import flixel.FlxG;
import flixel.FlxSprite;
import UIData;

using StringTools;

class StrumNote extends FlxSprite
{
	private var colorSwap:ColorSwap;
	public var resetAnim:Float = 0;
	private var noteData:Int = 0;
	public var direction:Float = 90;
	public var downScroll:Bool = false;
	public var sustainReduce:Bool = true;

	private var player:Int;
	var originalX:Float = 0;
	var postAdded:Bool = false;

	var keyAmount:Int = 4;
	var directions:Array<String> = ['LEFT', 'DOWN', 'UP', 'RIGHT'];
	var colors:Array<String> = ['left', 'down', 'up', 'right'];
	public var swagWidth:Float = 160 * 0.7;
	var xOff:Float = 54;
	public var noteSize:Float = 0.7;
	
	public var texture(default, set):String = null;
	private function set_texture(value:String):String {
		if (texture != value) {
			texture = value;
			reloadNote();
		}
		return value;
	}

	public var uiSkin(default, set):SkinFile = null;
	private function set_uiSkin(value:SkinFile):SkinFile {
		if (texture != null) value = UIData.checkSkinFile('notes/$texture', value);
		uiSkin = value;

		var maniaData:ManiaArray = null;
		for (i in uiSkin.mania) {
			if (i.keys == keyAmount) {
				maniaData = i;
				break;
			}
		}
		if (maniaData == null) {
			var bad:SkinFile = UIData.getUIFile('');
			if (uiSkin.isPixel && uiSkin.name != 'pixel') {
				bad = UIData.getUIFile('pixel');
			}
			for (i in bad.mania) {
				if (i.keys == keyAmount) {
					maniaData = i;
					break;
				}
			}
		}

		directions = maniaData.directions;
		colors = maniaData.colors;
		swagWidth = maniaData.noteSpacing;
		xOff = maniaData.xOffset;
		noteSize = maniaData.noteSize;
		if (texture != null) {
			reloadNote();
			if (postAdded) {
				x = originalX;
				postAddedToGroup();
			}
		}
		return value;
	}

	public function new(x:Float, y:Float, leData:Int, player:Int, ?keyAmount:Int = 4, ?uiSkin:SkinFile = null) {
		colorSwap = new ColorSwap();
		shader = colorSwap.shader;
		noteData = leData;
		if (uiSkin == null) {
			uiSkin = UIData.getUIFile('');
		}
		this.player = player;
		this.noteData = leData % keyAmount;
		this.keyAmount = keyAmount;
		this.uiSkin = uiSkin;
		super(x, y);
		originalX = x;

		var skin:String = 'NOTE_assets';
		if(PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1) skin = PlayState.SONG.arrowSkin;
		texture = skin; //Load texture and anims

		scrollFactor.set();
	}

	public function reloadNote()
	{
		var lastAnim:String = null;
		if (animation.curAnim != null) lastAnim = animation.curAnim.name;

		var blahblah = texture;
		if (uiSkin.isPixel) {
			blahblah = 'pixelUI/$texture';
		}
		if (!Paths.fileExists('images/$blahblah.xml', TEXT)) { //assume it is pixel notes
			loadGraphic(Paths.image(blahblah));
			width = width / 4;
			height = height / 5;
			loadGraphic(Paths.image(blahblah), true, Math.floor(width), Math.floor(height));
			
			switch (noteData)
			{
				case 0:
					animation.add('static', [0]);
					animation.add('pressed', [4, 8], 12, false);
					animation.add('confirm', [12, 16], 24, false);
				case 1:
					animation.add('static', [1]);
					animation.add('pressed', [5, 9], 12, false);
					animation.add('confirm', [13, 17], 24, false);
				case 2:
					animation.add('static', [2]);
					animation.add('pressed', [6, 10], 12, false);
					animation.add('confirm', [14, 18], 12, false);
				case 3:
					animation.add('static', [3]);
					animation.add('pressed', [7, 11], 12, false);
					animation.add('confirm', [15, 19], 24, false);
			}
		} else {
			frames = Paths.getSparrowAtlas(blahblah);
			animation.addByPrefix('static', 'arrow${directions[noteData]}0');
			animation.addByPrefix('pressed', '${colors[noteData]} press', 24, false);
			animation.addByPrefix('confirm', '${colors[noteData]} confirm', 24, false);
		}

		antialiasing = ClientPrefs.globalAntialiasing && !uiSkin.noAntialiasing;
		setGraphicSize(Std.int((width * noteSize) * uiSkin.scale * uiSkin.noteScale));
		updateHitbox();

		if (lastAnim != null)
		{
			playAnim(lastAnim, true);
		}
	}

	public function postAddedToGroup() {
		playAnim('static');
		x += swagWidth * noteData;
		x += xOff;
		x += ((FlxG.width / 2) * player);
		ID = noteData;
		postAdded = true;
	}

	override function update(elapsed:Float) {
		if (resetAnim > 0) {
			resetAnim -= elapsed;
			if (resetAnim <= 0) {
				playAnim('static');
				resetAnim = 0;
			}
		}
		if (animation.curAnim != null) { //my bad i was upset
			if (animation.curAnim.name == 'confirm') {
				centerOrigin();
			}
		}

		super.update(elapsed);
	}

	public function playAnim(anim:String, ?force:Bool = false) {
		animation.play(anim, force);
		centerOffsets();
		centerOrigin();
		if (animation.curAnim == null || animation.curAnim.name == 'static') {
			colorSwap.hue = 0;
			colorSwap.saturation = 0;
			colorSwap.brightness = 0;
		} else {
			colorSwap.hue = ClientPrefs.arrowHSV[keyAmount - 1][noteData][0] / 360;
			colorSwap.saturation = ClientPrefs.arrowHSV[keyAmount - 1][noteData][1] / 100;
			colorSwap.brightness = ClientPrefs.arrowHSV[keyAmount - 1][noteData][2] / 100;
		}
	}
}
