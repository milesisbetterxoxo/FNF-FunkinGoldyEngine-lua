package editors;

import Stage.Image;
import flixel.addons.ui.FlxUITabMenu;
import flixel.FlxObject;
import flixel.addons.ui.FlxUIInputText;
import flixel.graphics.FlxGraphic;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.ui.FlxButton;
import flixel.text.FlxText;
import flixel.system.debug.interaction.tools.Pointer.GraphicCursorCross;
import flixel.util.FlxColor;

class StageEditorState extends MusicBeatState
{
    var stage:Stage;


    var camGame:FlxCamera;
    var camUI:FlxCamera;

    var curSelectedSprite:FlxSprite;

    var changeBGbutton:FlxButton;

    var stageInputText:FlxUIInputText;

    var camFollow:FlxObject;
    var cameraFollowPointer:FlxSprite;

    var ui_box:FlxUITabMenu;

    var images:Array<Image>;

    var addImage:FlxButton;

    var imagePathInputText:FlxUIInputText;

    var imageAntialiasing:FlxButton;

    var imageColorRGB:Array<FlxUIInputText>;

    var imageColorR:FlxUIInputText;

    var imageColorG:FlxUIInputText;

    var imageColorB:FlxUIInputText;


    override function create()
    {
        FlxG.sound.playMusic(Paths.music('freakyMenu'));

        camGame = new FlxCamera();
        camUI = new FlxCamera();
        FlxG.cameras.reset(camGame);
        FlxG.cameras.add(camUI);

        FlxG.mouse.visible = true;

        stage = new Stage('');
        add(stage);
        

        stageInputText = new FlxUIInputText(15, 30, 75, "", 8);

        imageColorR = new FlxUIInputText();

        camFollow = new FlxObject();
        camFollow.screenCenter();

        var tabs =
        [
            {name: 'Image', label:'Image'},
            {name: 'Stage', label:'Stage'},
        ];

        ui_box = new FlxUITabMenu(null, tabs, true);
		ui_box.cameras = [camUI];
        ui_box.add();
        add(ui_box);
        

        super.create();
    }

    override function update(elapsed:Float)
    {
        FlxG.camera.follow(camFollow);

        if (controls.BACK)
        {
            MusicBeatState.switchState(new MasterEditorMenu());
        }

        super.update(elapsed);   
    }
}