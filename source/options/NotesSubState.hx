package options;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.util.FlxColor;

using StringTools;

class NotesSubState extends MusicBeatSubState
{
	var curSelected:Int = 0;
	private static var typeSelected:Int = 0;
	private var grpNumbers:FlxTypedGroup<Alphabet>;
	private var grpNotes:FlxTypedGroup<FlxSprite>;
	private var shaderArray:Array<ColorSwap> = [];
	var curValue:Float = 0;
	var holdTime:Float = 0;
	var nextAccept:Int = 5;
	var keyAmount:Int = 4;
	var currentData:Array<Array<Int>>;

	var blackBG:FlxSprite;
	var hsbText:Alphabet;

	var camFollow:FlxObject;
	var camFollowPos:FlxObject;

	var posX = 230;
	public function new(keyAmount:Int = 4) {
		super();
		this.keyAmount = keyAmount;
		currentData = ClientPrefs.arrowHSV[keyAmount - 1];
	}

	override function create()
	{
		resetCameraOnClose = true;
		
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFFea71fd;
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		bg.scrollFactor.set();
		add(bg);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);
		FlxG.camera.follow(camFollowPos, null, 1);
		
		blackBG = new FlxSprite(posX - 25).makeGraphic(870, 200, FlxColor.BLACK);
		blackBG.alpha = 0.4;
		blackBG.scrollFactor.set(0, 1);
		add(blackBG);

		grpNotes = new FlxTypedGroup<FlxSprite>();
		add(grpNotes);
		grpNumbers = new FlxTypedGroup<Alphabet>();
		add(grpNumbers);

		for (i in 0...currentData.length) {
			var offset:Float = 35 - (Math.max(currentData.length, 4) - 4) * 90;
			var yPos:Float = (165 * i) + offset;
			for (j in 0...3) {
				var optionText:Alphabet = new Alphabet(0, yPos + 60, Std.string(currentData[i][j]), true);
				optionText.x = posX + (225 * j) + 250;
				optionText.scrollFactor.set(0, 1);
				grpNumbers.add(optionText);
			}

			var note:FlxSprite = new FlxSprite(posX, yPos);
			note.frames = Paths.getSparrowAtlas('uiskins/default/notes/NOTE_assets');
			var animations:Array<String> = UIData.getUIFile('').mania[keyAmount - 1].colors;
			note.animation.addByPrefix('idle', '${animations[i]}0');
			note.animation.play('idle');
			note.antialiasing = ClientPrefs.globalAntialiasing;
			note.scrollFactor.set(0, 1);
			grpNotes.add(note);

			var newShader:ColorSwap = new ColorSwap();
			note.shader = newShader.shader;
			newShader.hue = currentData[i][0] / 360;
			newShader.saturation = currentData[i][1] / 100;
			newShader.brightness = currentData[i][2] / 100;
			shaderArray.push(newShader);
		}

		hsbText = new Alphabet(0, 0, "Hue    Saturation  Brightness", false, false, 0, 0.65);
		hsbText.x = posX + 240;
		hsbText.scrollFactor.set(0, 1);
		add(hsbText);

		changeSelection();
		super.create();
	}

	var changingNote:Bool = false;
	override function update(elapsed:Float) {
		var lerpVal:Float = CoolUtil.boundTo(elapsed * 7.5, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
		
		if (changingNote) {
			if (holdTime < 0.5) {
				if (controls.UI_LEFT_P || FlxG.mouse.wheel < 0) {
					updateValue(-1);
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
				} else if (controls.UI_RIGHT_P || FlxG.mouse.wheel > 0) {
					updateValue(1);
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
				} else if (controls.RESET) {
					resetValue(curSelected, typeSelected);
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
				}
				if (controls.UI_LEFT_R || controls.UI_RIGHT_R) {
					holdTime = 0;
				} else if (controls.UI_LEFT || controls.UI_RIGHT) {
					holdTime += elapsed;
				}
			} else {
				var add:Float = 90;
				switch(typeSelected) {
					case 1 | 2: add = 50;
				}
				if (controls.UI_LEFT) {
					updateValue(elapsed * -add);
				} else if (controls.UI_RIGHT) {
					updateValue(elapsed * add);
				}
				if (controls.UI_LEFT_R || controls.UI_RIGHT_R) {
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
					holdTime = 0;
				}
			}
		} else {
			if (currentData.length > 1) {
				if (controls.UI_UP_P || (!FlxG.keys.pressed.SHIFT && FlxG.mouse.wheel > 0)) {
					changeSelection(-1);
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
				}
				if (controls.UI_DOWN_P || (!FlxG.keys.pressed.SHIFT && FlxG.mouse.wheel < 0)) {
					changeSelection(1);
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
				}
			}
			if (controls.UI_LEFT_P || (FlxG.keys.pressed.SHIFT && FlxG.mouse.wheel < 0)) {
				changeType(-1);
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			}
			if (controls.UI_RIGHT_P || (FlxG.keys.pressed.SHIFT && FlxG.mouse.wheel > 0)) {
				changeType(1);
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			}
			if (controls.RESET) {
				for (i in 0...3) {
					resetValue(curSelected, i);
				}
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			}
			if ((controls.ACCEPT || FlxG.mouse.justPressed) && nextAccept <= 0) {
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
				changingNote = true;
				holdTime = 0;
				for (i in 0...grpNumbers.length) {
					var item = grpNumbers.members[i];
					item.alpha = 0;
					if ((curSelected * 3) + typeSelected == i) {
						item.alpha = 1;
					}
				}
				for (i in 0...grpNotes.length) {
					var item = grpNotes.members[i];
					item.alpha = 0;
					if (curSelected == i) {
						item.alpha = 1;
					}
				}
				super.update(elapsed);
				return;
			}
		}

		if (controls.BACK || (changingNote && (controls.ACCEPT || FlxG.mouse.justPressed))) {
			if (!changingNote) {
				close();
			} else {
				changeSelection();
			}
			changingNote = false;
			FlxG.sound.play(Paths.sound('cancelMenu'), 0.7);
		}

		if (nextAccept > 0) {
			nextAccept -= 1;
		}
		super.update(elapsed);
	}

	function changeSelection(change:Int = 0) {
		curSelected += change;
		if (curSelected < 0)
			curSelected = currentData.length-1;
		if (curSelected >= currentData.length)
			curSelected = 0;

		curValue = currentData[curSelected][typeSelected];
		updateValue();

		for (i in 0...grpNumbers.length) {
			var item = grpNumbers.members[i];
			item.alpha = 0.6;
			if ((curSelected * 3) + typeSelected == i) {
				item.alpha = 1;
			}
		}
		for (i in 0...grpNotes.length) {
			var item = grpNotes.members[i];
			item.alpha = 0.6;
			item.scale.set(0.75, 0.75);
			if (curSelected == i) {
				item.alpha = 1;
				item.scale.set(1, 1);
				hsbText.y = item.y - 70;
				blackBG.y = item.y - 20;
				camFollow.setPosition(item.getGraphicMidpoint().x, item.getGraphicMidpoint().y);
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	}

	function changeType(change:Int = 0) {
		typeSelected += change;
		if (typeSelected < 0)
			typeSelected = 2;
		if (typeSelected > 2)
			typeSelected = 0;

		curValue = currentData[curSelected][typeSelected];
		updateValue();

		for (i in 0...grpNumbers.length) {
			var item = grpNumbers.members[i];
			item.alpha = 0.6;
			if ((curSelected * 3) + typeSelected == i) {
				item.alpha = 1;
			}
		}
	}

	function resetValue(selected:Int, type:Int) {
		curValue = 0;
		ClientPrefs.arrowHSV[keyAmount - 1][selected][type] = 0;
		switch(type) {
			case 0: shaderArray[selected].hue = 0;
			case 1: shaderArray[selected].saturation = 0;
			case 2: shaderArray[selected].brightness = 0;
		}

		var item = grpNumbers.members[(selected * 3) + type];
		item.changeText('0');
		item.offset.x = (40 * (item.lettersArray.length - 1)) / 2;
	}
	function updateValue(change:Float = 0) {
		curValue += change;
		var roundedValue:Int = Math.round(curValue);
		var max:Float = 180;
		switch(typeSelected) {
			case 1 | 2: max = 100;
		}

		if (roundedValue < -max) {
			curValue = -max;
		} else if (roundedValue > max) {
			curValue = max;
		}
		roundedValue = Math.round(curValue);
		ClientPrefs.arrowHSV[keyAmount - 1][curSelected][typeSelected] = roundedValue;

		switch(typeSelected) {
			case 0: shaderArray[curSelected].hue = roundedValue / 360;
			case 1: shaderArray[curSelected].saturation = roundedValue / 100;
			case 2: shaderArray[curSelected].brightness = roundedValue / 100;
		}

		var item = grpNumbers.members[(curSelected * 3) + typeSelected];
		item.changeText(Std.string(roundedValue));
		item.offset.x = (40 * (item.lettersArray.length - 1)) / 2;
		if (roundedValue < 0) item.offset.x += 10;
	}
}