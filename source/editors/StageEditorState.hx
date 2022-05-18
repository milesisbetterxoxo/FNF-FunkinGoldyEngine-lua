package editors;

import JSONLoader.JSONMenu;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import haxe.Json;
import lime.system.System;
import openfl.net.FileReference;
import sys.FileSystem;
import sys.io.File;

using StringTools;

/**
 * @param images stage Images Name
 * @param stageX stage Image Xpos
 * @param stageY stage Image Ypos
 * @param stageScaleX stage Image Scale X
 * @param stageScaleY stage Image Scale Y
 * @param stageScollX stage Image Scroll Factor X
 * @param stageScollY stage Image Scroll Factor Y
 * @param stageAngle stage Image Angle
 * @param useAnim Use Animation or not
 * @param frameNames Animation File Names
 * @param animationNames Animation Name
 * @param animationFrame Animation Xml Name
 */
typedef StageJSON =
{
	// god fucking damnit im gonna have a bad time
	var images:Array<String>;
	var stageX:Array<Float>;
	var stageY:Array<Float>;
	var stageScrollX:Array<Float>;
	var stageScrollY:Array<Float>;
	var stageScaleX:Array<Float>;
	var stageScaleY:Array<Float>;
	var stageAngle:Array<Float>;
	var useAnim:Array<Bool>;
	var frameNames:Array<String>;
	var animationNames:Array<String>;
	var animationFrame:Array<String>; // Its like xml frame name
}

class StageEditorState
{
	public var box:FlxUITabMenu;
	var box_groups = [
		{name: "Assets", label: "Stage Assets"},
		{name: "Settings", label: "Stage Settings"},
		{name: "File", label: "Stage File"}
	];
	var stageGrp:FlxTypedGroup<FlxSprite>;
	var camHUD:FlxCamera;
	var camStage:FlxCamera;

	// JSON SHIT !!
	var spriteNames:Array<String> = [];
	var spriteAngles:Array<Float> = [];
	var spriteScaleX:Array<Float> = [];
	var spriteScaleY:Array<Float> = [];
	var spriteScrollX:Array<Float> = [];
	var spriteScrollY:Array<Float> = [];
	var spriteFrames:Array<String> = [];

	public var positionTxt:FlxText;
	var defaultCamZoom:Float = 1.08;
	public var helpTxt:FlxText;
	var useAnimation:Bool = false;
	var animations = [];
	var bg:FlxSprite;
	public static var GOD:StageJSON;

	override function create()
	{
		super.create();
		
		camStage = new FlxCamera();
		camHUD = new FlxCamera();

		GOD = {
			images: [],
			stageAngle: [],
			stageScaleY: [],
			stageScaleX: [],
			stageScrollY: [],
			stageScrollX: [],
			stageY: [],
			stageX: [],
			animationFrame: [],
			animationNames: [],
			frameNames: [],
			useAnim: []
		};

		FlxG.cameras.reset(camStage);
		FlxG.cameras.add(camHUD);
		camHUD.bgColor.alpha = 0;
		FlxCamera.defaultCameras = [camStage];

		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);

		box = new FlxUITabMenu(null, box_groups, true);
		box.resize(500, 350);
		box.x = 0;
		box.alpha = 0.8;
		box.screenCenter(Y);
		box.cameras = [camHUD];
		add(box);

		positionTxt = new FlxText(10, 10, 0, "Currect Selected Stage X/Y, ScrollFactor X/Y, Angle, Scale X/Y: Null", 16);
		positionTxt.cameras = [camHUD];
		positionTxt.color = FlxColor.RED;
		add(positionTxt);

		helpTxt = new FlxText(box.x + 10, box.y + 350 + 10, 0, "Arrow Keys - Move Image\nwith Shift - Move Fast\nwith Ctrl - Move Slow\nZ - Zoom Cam, X - Cam Zoom out", 16);
		helpTxt.cameras = [camHUD];
		add(helpTxt);

		createTabMenu('Stage Assets');
		createTabMenu('Stage Settings');
		createTabMenu('Stage Files');

	}

	var alphaLine:Float = 0;
	var curSelected:Int = 0;
	var toMove:Float = 1;
	var blockControlOnTyping:FlxTypedGroup<FlxUIInputText>;

	override function update(elapsed:Float)
	{
		alphaLine += elapsed;
			if (FlxG.keys.pressed.Z)
				defaultCamZoom += 0.01;
			if (FlxG.keys.pressed.X && defaultCamZoom >= 0)
				defaultCamZoom -= 0.01;
			var lerp:Float = FlxMath.lerp(defaultCamZoom,camStage.zoom,0.9);
			camStage.zoom=lerp;

		var blockInput:Bool = false;
		if (stageGrp != null && stageGrp.length > 0 && stageGrp.members[Std.int(stageNumStepper.value)] != null)
		{
			positionTxt.text = 'Currect Selected Stage X/Y ScrollFactor X/Y:' +
				'\nX/Y: ' + stageGrp.members[Std.int(stageNumStepper.value)].x + ', ' + stageGrp.members[Std.int(stageNumStepper.value)].y +
				'\nScroll X/Y: ' + stageGrp.members[Std.int(stageNumStepper.value)].scrollFactor.x + ', ' + stageGrp.members[Std.int(stageNumStepper.value)].scrollFactor.y +
				'\nAngle: ' + stageGrp.members[Std.int(stageNumStepper.value)].angle +
				'\nScale X/Y: ' + stageGrp.members[Std.int(stageNumStepper.value)].scale.x + ', ' + stageGrp.members[Std.int(stageNumStepper.value)].scale.y;

			for (i in 0...stageGrp.length)
			{
				stageGrp.members[i].color = FlxColor.WHITE;
			}
			stageGrp.members[Std.int(stageNumStepper.value)].color = FlxColor.BLUE;
			if (!blockInput)
			{
				// Movent Code
				if (FlxG.keys.pressed.LEFT) stageGrp.members[Std.int(stageNumStepper.value)].x -= toMove;
				if (FlxG.keys.pressed.RIGHT) stageGrp.members[Std.int(stageNumStepper.value)].x += toMove;
				if (FlxG.keys.pressed.UP) stageGrp.members[Std.int(stageNumStepper.value)].y -= toMove;
				if (FlxG.keys.pressed.DOWN) stageGrp.members[Std.int(stageNumStepper.value)].y += toMove;

				if (FlxG.keys.pressed.SHIFT) toMove = 5;
				if (FlxG.keys.pressed.CONTROL) toMove = 0.5;
				if (FlxG.keys.justReleased.SHIFT || FlxG.keys.justReleased.CONTROL) toMove = 1;
			}
		} else {
			for (i in 0...stageGrp.length)
			{
				stageGrp.members[i].color = FlxColor.WHITE;
			}
			positionTxt.text = 'Currect Selected Stage X/Y, ScrollFactor X/Y, Angle, Scale X/Y: Null';
		}

			if (usinAnimation_CB != null)
				GOD.useAnim[curSelected] = usinAnimation_CB.checked;
			if (spriteNames != null)
				GOD.images = spriteNames;
			if (stageGrp != null && stageGrp.length > 0)
			{
				GOD.stageAngle = spriteAngles;
				GOD.stageScaleX = spriteScaleX;
				GOD.stageScaleY = spriteScaleY;
				GOD.stageScrollX = spriteScrollX;
				GOD.stageScrollY = spriteScrollY;
				GOD.frameNames = spriteFrames;
				GOD.animationNames = animations;
				GOD.animationFrame = animations;
			}

		for (i in 0...blockControlOnTyping.length)
		{
			blockControlOnTyping.members[i].callback = function(text:String, action:String)
			{
				if (!blockInput && blockControlOnTyping.members[i].hasFocus)
				{
					FlxG.sound.volumeUpKeys = [];
					FlxG.sound.muteKeys = [];
					FlxG.sound.volumeDownKeys = [];
					blockInput = true;
				}
				if (!blockControlOnTyping.members[i].hasFocus)
				{
					FlxG.sound.volumeUpKeys = [PLUS, NUMPADPLUS];
					FlxG.sound.muteKeys = [ZERO, NUMPADZERO];
					FlxG.sound.volumeDownKeys = [MINUS, NUMPADMINUS];
					blockInput = false;
				}
			}
		}
		
		if (usinAnimation_CB != null)
			useAnimation = usinAnimation_CB.checked;

		super.update(elapsed);
	}

	var stageNumStepper:FlxUINumericStepper;
	var stageNumStepper2:FlxUINumericStepper;
	var scrollXInput:FlxUIInputText;
	var scrollYInput:FlxUIInputText;
	var defaultZoomInput:FlxUIInputText;
	var usinAnimation_CB:FlxUICheckBox;
	var angleInput:FlxUIInputText;
	var scalexInput:FlxUIInputText;
	var scaleyInput:FlxUIInputText;
	var imageFile:String = '';

	function createTabMenu(id:String)
	{
		if (stageGrp == null)
		{
			stageGrp = new FlxTypedGroup<FlxSprite>();
			add(stageGrp);
		}

		if (blockControlOnTyping == null)
		{
			blockControlOnTyping = new FlxTypedGroup<FlxUIInputText>();
			add(blockControlOnTyping);
		}
		
		switch (id)
		{
			case 'Stage Assets':
				var nameInput:FlxUIInputText = new FlxUIInputText(20, 40, 80, "");
				scrollXInput = new FlxUIInputText(nameInput.x, nameInput.y + 40, 60, "1");
				scrollYInput = new FlxUIInputText(nameInput.x + scrollXInput.width + 10, nameInput.y + 40, 60, "1");
				angleInput = new FlxUIInputText(nameInput.x, scrollXInput.y + 40, 100, "0");
				scalexInput = new FlxUIInputText(nameInput.x, angleInput.y + 40, 60, "1");
				scaleyInput = new FlxUIInputText(nameInput.x + scalexInput.width + 20, angleInput.y + 40, 60, "1");
				var addImageBt:FlxButton = new FlxButton(nameInput.x, scaleyInput.y + 20, "Add Image", function()
				{
					imageFile = 'stage/' + nameInput.text;
					var wowlookatthis:FlxSprite = new FlxSprite();
					wowlookatthis.loadGraphic(imageFile + '.png');
					spriteNames.push('\"' + nameInput.text + '\"');
					spriteAngles.push(Std.parseFloat(angleInput.text));
					spriteScaleX.push(Std.parseFloat(scalexInput.text));
					spriteScaleY.push(Std.parseFloat(scaleyInput.text));
					spriteScrollX.push(Std.parseFloat(scrollXInput.text));
					spriteScrollY.push(Std.parseFloat(scrollYInput.text));
					wowlookatthis.scrollFactor.set(Std.parseFloat(scrollXInput.text), Std.parseFloat(scrollYInput.text));
					wowlookatthis.scale.set(scalexInput.text == '' ? 1 : Std.parseFloat(scalexInput.text), scaleyInput.text == '' ? 1 : Std.parseFloat(scaleyInput.text));
					if (angleInput.text == '')
						wowlookatthis.angle = 0;
					else
						wowlookatthis.angle = Std.parseFloat(angleInput.text);
					wowlookatthis.cameras = [camStage];
					stageGrp.add(wowlookatthis);
				});

				stageNumStepper = new FlxUINumericStepper(nameInput.x + 150, nameInput.y, 1, 0, 0, 30);
				var removeStageBt:FlxButton = new FlxButton(stageNumStepper.x, stageNumStepper.y + 20, "Remove Image", function()
				{
					spriteNames.remove(spriteNames[Std.int(stageNumStepper.value)]);
					stageGrp.members[Std.int(stageNumStepper.value)].kill();
					stageGrp.forEachDead(function(spr:FlxSprite)
					{
						stageGrp.remove(spr);
						stageGrp.length--;
					});
				});
				
				for (i in [scrollXInput, scrollYInput, nameInput])
				{
					blockControlOnTyping.add(i);
				}

				nameInput.cameras = [camHUD];
				scrollXInput.cameras = [camHUD];
				scrollYInput.cameras = [camHUD];
				addImageBt.cameras = [camHUD];
				stageNumStepper.cameras = [camHUD];
				removeStageBt.cameras = [camHUD];
				scalexInput.cameras = [camHUD];
				scaleyInput.cameras = [camHUD];
				angleInput.cameras = [camHUD];
				
				var wow = new FlxUI(null, box);
				wow.name = 'Assets';

				wow.add(nameInput);
				wow.add(addImageBt);
				wow.add(stageNumStepper);
				wow.add(new FlxText(nameInput.x, nameInput.y - 20, 0, "Stage Image Name:"));
				wow.add(new FlxText(stageNumStepper.x, stageNumStepper.y - 20, 0, "Stage Number:"));
				wow.add(new FlxText(scrollXInput.x, scrollXInput.y - 20, 0, "Set Scroll Factor (X/Y):"));
				wow.add(new FlxText(angleInput.x, angleInput.y - 20, 0, "Angle: "));
				wow.add(new FlxText(scalexInput.x, scalexInput.y - 20, 0, "Scale X: "));
				wow.add(new FlxText(scaleyInput.x, scaleyInput.y - 20, 0, "Scale Y: "));
				wow.add(scrollXInput);
				wow.add(scrollYInput);
				wow.add(removeStageBt);
				wow.add(angleInput);
				wow.add(scalexInput);
				wow.add(scaleyInput);

				box.addGroup(wow);
			case 'Stage Settings':
				stageNumStepper2 = new FlxUINumericStepper(20, 40, 1, 0, 0, 30);

				scrollXInput = new FlxUIInputText(stageNumStepper2.x, stageNumStepper2.y + 40, 60, scrollXInput.text);
				scrollYInput = new FlxUIInputText(stageNumStepper2.x + scrollXInput.width + 10, stageNumStepper2.y + 40, 60, scrollXInput.text);

				angleInput = new FlxUIInputText(stageNumStepper2.x, scrollXInput.y + 40, 100, "0");
				scalexInput = new FlxUIInputText(stageNumStepper2.x, angleInput.y + 40, 60, "1");
				scaleyInput = new FlxUIInputText(stageNumStepper2.x + scalexInput.width + 20, angleInput.y + 40, 60, "1");

				var updateBt:FlxButton = new FlxButton(stageNumStepper2.x, scaleyInput.y + 20, "Update Image", updateImage);
				
				usinAnimation_CB = new FlxUICheckBox(stageNumStepper2.width + stageNumStepper2.x + 100, stageNumStepper2.y, null, null, 'Use Animation');
				usinAnimation_CB.checked = useAnimation;

				var animationNameInput:FlxUIInputText = new FlxUIInputText(usinAnimation_CB.x, usinAnimation_CB.y + 40, 100, "");
				var addAnimationBt:FlxButton = new FlxButton(usinAnimation_CB.x, animationNameInput.y + 40, "Add Animation", function()
				{
					if (animationNameInput.text != null)
						animations.push(animationNameInput.text);
					trace(animations);
				});

				var removeAnimBt:FlxButton = new FlxButton(addAnimationBt.x + addAnimationBt.width + 20, addAnimationBt.y, "Remove Animation", function()
				{
					if (animationNameInput.text != null)
						animations.remove(animationNameInput.text);
					stageGrp.members[Std.int(stageNumStepper2.value)].animation.remove(animationNameInput.text);
					trace(animations);
				});

				var playAnimBt:FlxButton = new FlxButton(addAnimationBt.x + addAnimationBt.width - 30, addAnimationBt.y + 30, "Play Animation", function()
				{
					if (animationNameInput != null)
						stageGrp.members[Std.int(stageNumStepper2.value)].animation.play(animationNameInput.text, true);
				});

				playAnimBt.cameras = [camHUD];
				removeAnimBt.cameras = [camHUD];
				addAnimationBt.cameras = [camHUD];
				animationNameInput.cameras = [camHUD];
				usinAnimation_CB.cameras = [camHUD];
				updateBt.cameras = [camHUD];
				scrollXInput.cameras = [camHUD];
				scrollYInput.cameras = [camHUD];
				stageNumStepper2.cameras = [camHUD];
				scalexInput.cameras = [camHUD];
				scaleyInput.cameras = [camHUD];
				angleInput.cameras = [camHUD];

				var wow = new FlxUI(null, box);
				wow.name = 'Settings';

				wow.add(new FlxText(stageNumStepper2.x, stageNumStepper2.y - 20, 0, "Stage Number:"));
				wow.add(new FlxText(scrollXInput.x, scrollXInput.y - 20, 0, "Set Scroll Factor (X/Y):"));
				wow.add(new FlxText(animationNameInput.x, animationNameInput.y - 20, 0, "Animation Name:"));
				wow.add(new FlxText(angleInput.x, angleInput.y - 20, 0, "Angle: "));
				wow.add(new FlxText(scalexInput.x, scalexInput.y - 20, 0, "Scale X: "));
				wow.add(new FlxText(scaleyInput.x, scaleyInput.y - 20, 0, "Scale Y: "));
				wow.add(stageNumStepper2);
				wow.add(scrollXInput);
				wow.add(scrollYInput);
				wow.add(updateBt);
				wow.add(usinAnimation_CB);
				wow.add(animationNameInput);
				wow.add(addAnimationBt);
				wow.add(removeAnimBt);
				wow.add(playAnimBt);
				wow.add(angleInput);
				wow.add(scalexInput);
				wow.add(scaleyInput);

				box.addGroup(wow);
			case 'Stage File' | 'Stage Files':
				var fileName:FlxUIInputText = new FlxUIInputText(20, 40, 100, "");
				var loadBt:FlxButton = new FlxButton((fileName.x + fileName.width) + 20, 20, "Load Json", function()
				{
					if (fileName != null && fileName.text != '' && fileName.text.length > 0)
					{
						GOD = JSONMenu.load('stage/data/' + fileName.text);
						trace(GOD);
						loadAllShit();
					}
				});

				var saveBt:FlxButton = new FlxButton(loadBt.x, loadBt.y + 40, "Save Json", function()
				{
					save();
				});
				var wow = new FlxUI(null, box);
				wow.name = 'File';
				wow.add(fileName);
				wow.add(loadBt);
				wow.add(saveBt);
				wow.add(new FlxText(fileName.x, fileName.y - 20, 0, "JSON File Name:"));

				box.addGroup(wow);
		}
	}

	var jsonRe:FileReference;
	private function save()
    {
        var jsonFile = PlayState.GOD;
        var newJSON = Json.stringify(jsonFile, "\t");
        trace(newJSON.trim());

        if (newJSON != null && newJSON.length > 0)
        {
            jsonRe = new FileReference();
            jsonRe.save(newJSON.trim(), "stage1.json");
        }
    }

	function loadAllShit()
	{
		//Remove Everything
		stageGrp.forEachAlive(function(self:FlxSprite)
		{
			self.kill();
			stageGrp.remove(self);
			stageGrp.length = 0;
		});
		
		// Reload All Shit
		for (i in 0...GOD.images.length)
		{
			var newSprite:FlxSprite = new FlxSprite(GOD.stageX[i], GOD.stageY[i]);
			if (GOD.useAnim[i] && (GOD.animationFrame != null && GOD.animationFrame.length > 0) && (GOD.animationNames != null && GOD.animationNames.length > 0) && (GOD.frameNames != null && GOD.frameNames.length > 0))
			{
				newSprite.frames = FlxAtlasFrames.fromSparrow('stage/' + GOD.frameNames[i] + '.png', 'stage/' + GOD.frameNames[i] + '.xml');
				for (i in 0...GOD.animationNames.length)
				{
					newSprite.animation.addByPrefix(GOD.animationNames[i].toLowerCase(), GOD.animationFrame[i], 24, false);
					newSprite.animation.play(GOD.animationNames[0], true);
				}
			} else {
				var ohfuck:Array<String> = GOD.images[i].trim().split("\"");
				for (j in 0...ohfuck.length)
				{
					ohfuck[j].trim();
					newSprite.loadGraphic('stage/' + ohfuck[j] + '.png');
				}
			}
			spriteNames = GOD.images;
			newSprite.scrollFactor.set(GOD.stageScrollX[i], GOD.stageScrollY[i]);
			newSprite.scale.set(GOD.stageScaleX[i], GOD.stageScaleY[i]);
			newSprite.angle = GOD.stageAngle[i];
			stageGrp.add(newSprite);
			trace('loaded!');
			trace('Sprite Info : (name: ' + GOD.images[i] + ', X/Y: ' + GOD.stageX[i] + ', ' + GOD.stageY[i] + ',\nScrollX/Y: ' + GOD.stageScrollX[i] + ', ' + GOD.stageScrollY[i] + ',\nScale X/Y: ' + GOD.stageScaleX + ', ' + GOD.stageScaleY + ',\nAngle: ' + GOD.stageAngle[i] + ',\nUsingAnim: ' + GOD.useAnim + ',\nAnimName: ' + GOD.animationNames + ',\nAnimName (Xml): ' + GOD.animationFrame + ')');
		}
		spriteAngles = GOD.stageAngle;
		spriteScaleX = GOD.stageScaleX;
		spriteScaleY = GOD.stageScaleY;
		spriteScrollX = GOD.stageScrollX;
		spriteScrollY = GOD.stageScrollY;
	}
	
	function updateImage()
	{
		if (stageGrp != null && stageNumStepper2 != null && stageGrp.members[Std.int(stageNumStepper2.value)] != null && stageGrp.length > 0)
		{
			trace(Std.int(stageNumStepper2.value));
			stageGrp.members[Std.int(stageNumStepper2.value)].scrollFactor.set(scrollXInput.text == '' ? 1 : Std.parseFloat(scrollXInput.text), scrollYInput.text == '' ? 1 : Std.parseFloat(scrollYInput.text));
			stageGrp.members[Std.int(stageNumStepper2.value)].angle = angleInput.text == '' ? 0 : Std.parseFloat(angleInput.text);
			stageGrp.members[Std.int(stageNumStepper2.value)].scale.set(scalexInput.text == '' ? 1 : Std.parseFloat(scalexInput.text), scaleyInput.text == '' ? 1 : Std.parseFloat(scaleyInput.text));
			if (useAnimation)
			{
				stageGrp.members[Std.int(stageNumStepper2.value)].frames = FlxAtlasFrames.fromSparrow(imageFile + '.png', imageFile + '.xml');
				for (i in 0...spriteFrames.length)
				{
					if (spriteFrames[i].contains(imageFile))
					{
						spriteFrames[i] = imageFile;
					}
				}
				if (!spriteFrames.contains(imageFile))
				{
					spriteFrames.push(imageFile);
				}
				for (i in 0...animations.length)
				{
					stageGrp.members[Std.int(stageNumStepper2.value)].animation.addByPrefix(animations[i].toLowerCase(), animations[i], 24, false);
					stageGrp.members[Std.int(stageNumStepper2.value)].animation.play(animations[i].toLowerCase(), true);
					trace(animations[i].toLowerCase() + ' ' + animations[i]);
				}
			}

			// JSON SHIT
			var yes = Std.int(stageNumStepper2.value);
			var wtf = stageGrp.members[yes];
			spriteAngles[yes] = wtf.angle;
			spriteScaleX[yes] = wtf.scale.x;
			spriteScaleY[yes] = wtf.scale.y;
			spriteScrollX[yes] = wtf.scrollFactor.x;
			spriteScrollY[yes] = wtf.scrollFactor.y;
		}
	}
}