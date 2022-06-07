package;

import flixel.FlxG;
import flixel.FlxSprite;

class NoteSplash extends FlxSprite
{
	public var colorSwap:ColorSwap = null;
	private var idleAnim:String;
	private var textureLoaded:String = null;

	var daNote:Note = null;
	var colors:Array<String>;
	public var alphaMult:Float = 0.6;

	public function new(x:Float = 0, y:Float = 0, ?note:Note = null) {
		super(x, y);

		var skin:String = 'noteSplashes';
		if(PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) skin = PlayState.SONG.splashSkin;

		loadAnims(skin);
		
		colorSwap = new ColorSwap();
		shader = colorSwap.shader;

		antialiasing = ClientPrefs.globalAntialiasing;
	}

	public function setupNoteSplash(x:Float = 0, y:Float = 0, note:Note = null, texture:String = null, hueColor:Float = 0, satColor:Float = 0, brtColor:Float = 0, keyAmount:Int = 4, ?colors:Array<String>) {
		if (note != null) {
			daNote = note;
			setGraphicSize(Std.int(note.width * 2.68), Std.int(note.height * 2.77));
		}
		if (colors != null) {
			this.colors = colors;
		}
		updateHitbox();
		alphaMult = 0.6;

		if (texture == null || texture.length < 1 || texture == 'noteSplashes') {
			texture = 'noteSplashes';
			if(PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) texture = PlayState.SONG.splashSkin;
		}

		if(textureLoaded != texture) {
			loadAnims(texture);
		}
		colorSwap.hue = hueColor;
		colorSwap.saturation = satColor;
		colorSwap.brightness = brtColor;

		var animNum:Int = FlxG.random.int(1, 2);
		if (note != null) {
			animation.play('note${note.noteData}-$animNum', true);
		} else {
			animation.play('note0-1', true);
		}
		if (animation.curAnim != null) animation.curAnim.frameRate = 24 + FlxG.random.int(-2, 2);
		updateHitbox();
        centerOrigin();
		if (note != null) {
			setPosition(note.x - (note.width), note.y - (note.height));
			alpha = note.alpha;
			angle = note.angle;
		}
	}

	function loadAnims(skin:String) {
		if (daNote == null) {
			frames = Paths.getSparrowAtlas('noteSplashes');
			animation.addByPrefix("note0-1", "note splash left 1", 24, false);
		} else {
			var uiSkin = daNote.uiSkin;
			var blahblah = skin;
			if (uiSkin.isPixel && Paths.fileExists('images/pixelUI/$skin.png', IMAGE)) {
				blahblah = 'pixelUI/$skin';
			}
			frames = Paths.getSparrowAtlas(blahblah);
			for (i in 1...3) {
				animation.addByPrefix('note${daNote.noteData}-$i', 'note splash ${colors[daNote.noteData]} ${i}0', 24, false);
			}
			if (animation.getByName('note${daNote.noteData}-1') == null) {
				for (i in 1...3) {
					animation.addByPrefix('note0-$i', 'note splash purple ${i}0', 24, false);
					animation.addByPrefix('note1-$i', 'note splash blue ${i}0', 24, false);
					animation.addByPrefix('note2-$i', 'note splash green ${i}0', 24, false);
					animation.addByPrefix('note3-$i', 'note splash red ${i}0', 24, false);
				}
			}
			antialiasing = ClientPrefs.globalAntialiasing && !uiSkin.noAntialiasing;
		}
	}

	override function update(elapsed:Float) {
		if (animation.curAnim != null) if (animation.curAnim.finished) kill();

		if (daNote != null) {
			setPosition(daNote.x - (daNote.width), daNote.y - (daNote.height));
			alpha = daNote.alpha * alphaMult;
			angle = daNote.angle;
		} else {
			alpha = alphaMult;
		}

		super.update(elapsed);
	}
}