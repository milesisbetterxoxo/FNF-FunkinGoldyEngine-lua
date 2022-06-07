package options;

import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;

using StringTools;

class ControlsSubState extends MusicBeatSubState {
	private static var curSelected:Int = -1;
	private static var curAlt:Bool = false;

	private static var defaultKey:String = 'Reset to Default Keys';
	private var bindLength:Int = 0;

	var optionShit:Array<Array<String>> = [
		['NOTES (1K)'],
		['Center', 'note1_0'],
		[''],
		['NOTES (2K)'],
		['Left', 'note2_0'],
		['Right', 'note2_1'],
		[''],
		['NOTES (3K)'],
		['Left', 'note3_0'],
		['Center', 'note3_1'],
		['Right', 'note3_2'],
		[''],
		['NOTES (4K)'],
		['Left', 'note4_0'],
		['Down', 'note4_1'],
		['Up', 'note4_2'],
		['Right', 'note4_3'],
		[''],
		['NOTES (5K)'],
		['Left', 'note5_0'],
		['Down', 'note5_1'],
		['Center', 'note5_2'],
		['Up', 'note5_3'],
		['Right', 'note5_4'], 
		[''],
		['NOTES (6K)'],
		['Left', 'note6_0'],
		['Up', 'note6_1'],
		['Right', 'note6_2'],
		['Left 2', 'note6_3'],
		['Down', 'note6_4'],
		['Right 2', 'note6_5'],
		[''],
		['NOTES (7K)'],
		['Left', 'note7_0'],
		['Up', 'note7_1'],
		['Right', 'note7_2'],
		['Center', 'note7_3'],
		['Left 2', 'note7_4'],
		['Down', 'note7_5'],
		['Right 2', 'note7_6'],
		[''],
		['NOTES (8K)'],
		['Left', 'note8_0'],
		['Down', 'note8_1'],
		['Up', 'note8_2'],
		['Right', 'note8_3'],
		['Left 2', 'note8_4'],
		['Down 2', 'note8_5'],
		['Up 2', 'note8_6'],
		['Right 2', 'note8_7'],
		[''],
		['NOTES (9K)'],
		['Left', 'note9_0'],
		['Down', 'note9_1'],
		['Up', 'note9_2'],
		['Right', 'note9_3'],
		['Center', 'note9_4'],
		['Left 2', 'note9_5'],
		['Down 2', 'note9_6'],
		['Up 2', 'note9_7'],
		['Right 2', 'note9_8'],
		[''],
		['NOTES (10K)'],
		['Left', 'note10_0'],
		['Down', 'note10_1'],
		['Up', 'note10_2'],
		['Right', 'note10_3'],
		['Left 2', 'note10_4'],
		['Right 2', 'note10_5'],
		['Left 3', 'note10_6'],
		['Down 3', 'note10_7'],
		['Up 3', 'note10_8'],
		['Right 3', 'note10_9'],
		[''],
		['NOTES (11K)'],
		['Left', 'note11_0'],
		['Down', 'note11_1'],
		['Up', 'note11_2'],
		['Right', 'note11_3'],
		['Left 2', 'note11_4'],
		['Center', 'note11_5'],
		['Right 2', 'note11_6'],
		['Left 3', 'note11_7'],
		['Down 3', 'note11_8'],
		['Up 3', 'note11_9'],
		['Right 3', 'note11_10'],
		[''],
		['NOTES (12K)'],
		['Left', 'note12_0'],
		['Down', 'note12_1'],
		['Up', 'note12_2'],
		['Right', 'note12_3'],
		['Left 2', 'note12_4'],
		['Down 2', 'note12_5'],
		['Up 2', 'note12_6'],
		['Right 2', 'note12_7'],
		['Left 3', 'note12_8'],
		['Down 3', 'note12_9'],
		['Up 3', 'note12_10'],
		['Right 3', 'note12_11'],
		[''],
		['NOTES (13K)'],
		['Left', 'note13_0'],
		['Down', 'note13_1'],
		['Up', 'note13_2'],
		['Right', 'note13_3'],
		['Left 2', 'note13_4'],
		['Down 2', 'note13_5'],
		['Center', 'note13_6'],
		['Up 2', 'note13_7'],
		['Right 2', 'note13_8'],
		['Left 3', 'note13_9'],
		['Down 3', 'note13_10'],
		['Up 3', 'note13_11'],
		['Right 3', 'note13_12'],
		[''],
		['UI'],
		['Left', 'ui_left'],
		['Down', 'ui_down'],
		['Up', 'ui_up'],
		['Right', 'ui_right'],
		[''],
		['Reset', 'reset'],
		['Accept', 'accept'],
		['Back', 'back'],
		['Pause', 'pause'],
		[''],
		['VOLUME'],
		['Mute', 'volume_mute'],
		['Up', 'volume_up'],
		['Down', 'volume_down'],
		[''],
		['DEBUG'],
		['Key 1', 'debug_1'],
		['Key 2', 'debug_2']
	];

	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var grpInputs:Array<AttachedText> = [];
	private var grpInputsAlt:Array<AttachedText> = [];
	var rebindingKey:Bool = false;
	var nextAccept:Int = 5;

	public function new() {
		super();

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFFea71fd;
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		optionShit.push(['']);
		optionShit.push([defaultKey]);

		for (i in 0...optionShit.length) {
			var isCentered:Bool = false;
			var isDefaultKey:Bool = (optionShit[i][0] == defaultKey);
			if (unselectableCheck(i, true)) {
				isCentered = true;
			}

			var optionText:Alphabet = new Alphabet(0, (10 * i), optionShit[i][0], (!isCentered || isDefaultKey), false);
			optionText.isMenuItem = true;
			if (isCentered) {
				optionText.screenCenter(X);
				optionText.forceX = optionText.x;
				optionText.yAdd = -55;
			} else {
				optionText.forceX = 200;
			}
			optionText.yMult = 60;
			optionText.targetY = i;
			grpOptions.add(optionText);

			if (!isCentered) {
				addBindTexts(optionText, i);
				bindLength++;
				if (curSelected < 0) curSelected = i;
			}
		}
		changeSelection();
	}

	var leaving:Bool = false;
	var bindingTime:Float = 0;
	override function update(elapsed:Float) {
		if (!rebindingKey) {
			var shiftMult:Int = 1;
			if (FlxG.keys.pressed.SHIFT) shiftMult = 5;
			if (controls.UI_UP_P || (!FlxG.keys.pressed.SHIFT && FlxG.mouse.wheel > 0)) {
				changeSelection(-shiftMult);
			}
			if (controls.UI_DOWN_P || (!FlxG.keys.pressed.SHIFT && FlxG.mouse.wheel < 0)) {
				changeSelection(shiftMult);
			}
			if (controls.UI_LEFT_P || controls.UI_RIGHT_P || (FlxG.keys.pressed.SHIFT && FlxG.mouse.wheel != 0)) {
				changeAlt();
			}

			if (controls.BACK) {
				ClientPrefs.reloadControls();
				close();
				FlxG.sound.play(Paths.sound('cancelMenu'), 0.7);
			}

			if ((controls.ACCEPT || FlxG.mouse.justPressed) && nextAccept <= 0) {
				if (optionShit[curSelected][0] == defaultKey) {
					ClientPrefs.keyBinds = ClientPrefs.defaultKeys.copy();
					reloadKeys();
					changeSelection();
					FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
				} else if (!unselectableCheck(curSelected)) {
					bindingTime = 0;
					rebindingKey = true;
					if (curAlt) {
						grpInputsAlt[getInputTextNum()].alpha = 0;
					} else {
						grpInputs[getInputTextNum()].alpha = 0;
					}
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
				}
			}
		} else {
			var keyPressed:Int = FlxG.keys.firstJustPressed();
			if (keyPressed > -1) {
				var keysArray:Array<FlxKey> = ClientPrefs.keyBinds.get(optionShit[curSelected][1]);
				keysArray[curAlt ? 1 : 0] = keyPressed;

				var opposite:Int = (curAlt ? 0 : 1);
				if (keysArray[opposite] == keysArray[1 - opposite]) {
					keysArray[opposite] = NONE;
				}
				ClientPrefs.keyBinds.set(optionShit[curSelected][1], keysArray);

				reloadKeys();
				FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
				rebindingKey = false;
			}

			bindingTime += elapsed;
			if (bindingTime > 5) {
				if (curAlt) {
					grpInputsAlt[curSelected].alpha = 1;
				} else {
					grpInputs[curSelected].alpha = 1;
				}
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
				rebindingKey = false;
				bindingTime = 0;
			}
		}

		if (nextAccept > 0) {
			nextAccept -= 1;
		}
		super.update(elapsed);
	}

	function getInputTextNum() {
		var num:Int = 0;
		for (i in 0...curSelected) {
			if (optionShit[i].length > 1) {
				num++;
			}
		}
		return num;
	}
	
	function changeSelection(change:Int = 0) {
		do {
			curSelected += change;
			if (curSelected < 0)
				curSelected = optionShit.length - 1;
			if (curSelected >= optionShit.length)
				curSelected = 0;
		} while(unselectableCheck(curSelected));

		var bullShit:Int = 0;

		for (i in 0...grpInputs.length) {
			grpInputs[i].alpha = 0.6;
		}
		for (i in 0...grpInputsAlt.length) {
			grpInputsAlt[i].alpha = 0.6;
		}

		for (item in grpOptions.members) {
			item.targetY = bullShit - curSelected;

			if (!unselectableCheck(bullShit)) {
				item.alpha = 0.6;
				if (item.targetY == 0) {
					item.alpha = 1;
					if (curAlt) {
						for (i in 0...grpInputsAlt.length) {
							if (grpInputsAlt[i].sprTracker == item) {
								grpInputsAlt[i].alpha = 1;
								break;
							}
						}
					} else {
						for (i in 0...grpInputs.length) {
							if (grpInputs[i].sprTracker == item) {
								grpInputs[i].alpha = 1;
								break;
							}
						}
					}
				}
			}

			bullShit++;
		}
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	}

	function changeAlt() {
		curAlt = !curAlt;
		for (i in 0...grpInputs.length) {
			if (grpInputs[i].sprTracker == grpOptions.members[curSelected]) {
				grpInputs[i].alpha = 0.6;
				if (!curAlt) {
					grpInputs[i].alpha = 1;
				}
				break;
			}
		}
		for (i in 0...grpInputsAlt.length) {
			if (grpInputsAlt[i].sprTracker == grpOptions.members[curSelected]) {
				grpInputsAlt[i].alpha = 0.6;
				if (curAlt) {
					grpInputsAlt[i].alpha = 1;
				}
				break;
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	}

	private function unselectableCheck(num:Int, ?checkDefaultKey:Bool = false):Bool {
		if (optionShit[num][0] == defaultKey) {
			return checkDefaultKey;
		}
		return optionShit[num].length < 2 && optionShit[num][0] != defaultKey;
	}

	private function addBindTexts(optionText:Alphabet, num:Int) {
		var keys = ClientPrefs.keyBinds.get(optionShit[num][1]);
		var text1 = new AttachedText(InputFormatter.getKeyName(keys[0]), 400, -55);
		text1.setPosition(optionText.x + 400, optionText.y - 55);
		text1.sprTracker = optionText;
		grpInputs.push(text1);
		add(text1);

		var text2 = new AttachedText(InputFormatter.getKeyName(keys[1]), 650, -55);
		text2.setPosition(optionText.x + 650, optionText.y - 55);
		text2.sprTracker = optionText;
		grpInputsAlt.push(text2);
		add(text2);
	}

	function reloadKeys() {
		while(grpInputs.length > 0) {
			var item:AttachedText = grpInputs[0];
			item.kill();
			grpInputs.remove(item);
			item.destroy();
		}
		while(grpInputsAlt.length > 0) {
			var item:AttachedText = grpInputsAlt[0];
			item.kill();
			grpInputsAlt.remove(item);
			item.destroy();
		}

		for (i in 0...grpOptions.length) {
			if (!unselectableCheck(i, true)) {
				addBindTexts(grpOptions.members[i], i);
			}
		}

		var bullShit:Int = 0;
		for (i in 0...grpInputs.length) {
			grpInputs[i].alpha = 0.6;
		}
		for (i in 0...grpInputsAlt.length) {
			grpInputsAlt[i].alpha = 0.6;
		}

		for (item in grpOptions.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;

			if (!unselectableCheck(bullShit-1)) {
				item.alpha = 0.6;
				if (item.targetY == 0) {
					item.alpha = 1;
					if (curAlt) {
						for (i in 0...grpInputsAlt.length) {
							if (grpInputsAlt[i].sprTracker == item) {
								grpInputsAlt[i].alpha = 1;
							}
						}
					} else {
						for (i in 0...grpInputs.length) {
							if (grpInputs[i].sprTracker == item) {
								grpInputs[i].alpha = 1;
							}
						}
					}
				}
			}
		}
	}
}