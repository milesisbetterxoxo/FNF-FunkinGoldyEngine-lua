package editors;

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import UIData;

class SkinEditorState extends MusicBeatState {
    var uiSkin:SkinFile;

    var camEditor:FlxCamera;
	var camMenu:FlxCamera;

    var gridBG:FlxSprite;
    var noteLayer:FlxTypedGroup<FlxSprite>;
    var ratingLayer:FlxTypedGroup<FlxSprite>;
    var comboLayer:FlxTypedGroup<FlxSprite>;
    var countdownLayer:FlxTypedGroup<FlxSprite>;

    var notes:FlxTypedGroup<Note>;
    var strumNotes:FlxTypedGroup<StrumNote>;

    var UI_box:FlxUITabMenu;

    private var blockPressWhileTypingOn:Array<FlxUIInputText> = [];
	private var blockPressWhileTypingOnStepper:Array<FlxUINumericStepper> = [];
	private var blockPressWhileScrolling:Array<FlxUIDropDownMenuCustom> = [];

    var curMania:Int = 4;

    public function new(fileName:String = '') {
        super();
        if (fileName != null) {
            uiSkin = UIData.getUIFile(fileName);
        }
        if (uiSkin == null) {
            uiSkin = UIData.getUIFile('');
        }
    }

    override function create() {
        camEditor = new FlxCamera();
        camMenu = new FlxCamera();
        camMenu.bgColor.alpha = 0;

        FlxG.cameras.reset(camEditor);
		FlxG.cameras.setDefaultDrawTarget(camEditor, true);
		FlxG.cameras.add(camMenu);
		FlxG.cameras.setDefaultDrawTarget(camMenu, false);

        gridBG = FlxGridOverlay.create(40, 40);
        add(gridBG);

        noteLayer = new FlxTypedGroup<FlxSprite>();
		add(noteLayer);
        ratingLayer = new FlxTypedGroup<FlxSprite>();
		add(ratingLayer);
        comboLayer = new FlxTypedGroup<FlxSprite>();
		add(comboLayer);
        countdownLayer = new FlxTypedGroup<FlxSprite>();
		add(countdownLayer);

        notes = new FlxTypedGroup<Note>();
        strumNotes = new FlxTypedGroup<StrumNote>();

        Conductor.changeBPM(100);
        Conductor.changeSignature([4, 4]);

        reloadNotes(); 

        var tabs = [
			{name: 'Skin', label: 'Skin'},
			{name: 'Mania', label: 'Mania'},
		];
		UI_box = new FlxUITabMenu(null, tabs, true);
		UI_box.cameras = [camMenu];

		UI_box.resize(350, 250);
		UI_box.x = FlxG.width - 400;
		UI_box.y = FlxG.height - 300;
		UI_box.scrollFactor.set();
		add(UI_box);

        addSkinUI();
        addManiaUI();

        UI_box.selected_tab_id = 'Skin';

        FlxG.mouse.visible = true;

        #if DISCORD_ALLOWED
		DiscordClient.changePresence("UI Skin Editor", null);
		#end

        super.create();
    }

    var UI_skinName:FlxUIInputText;
    var check_noAntialiasing:FlxUICheckBox;
    var scaleStepper:FlxUINumericStepper;
    var noteScaleStepper:FlxUINumericStepper;
    var sustainYScaleStepper:FlxUINumericStepper;
    function addSkinUI() {
        var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Skin";

        UI_skinName = new FlxUIInputText(10, 10, 70, uiSkin.name, 8);
		blockPressWhileTypingOn.push(UI_skinName);

        var reloadSkin:FlxButton = new FlxButton(UI_skinName.x + UI_skinName.width, UI_skinName.y, "Reload Skin", function()
		{
            uiSkin = UIData.getUIFile(UI_skinName.text);
            if (uiSkin == null) {
                FlxG.log.warn('Failed to load skin!');
                uiSkin = UIData.getUIFile('');
            }
            loadFromSkin();
		});

        check_noAntialiasing = new FlxUICheckBox(UI_skinName.x, UI_skinName.y + UI_skinName.height, null, null, "No Antialiasing", 100);
		check_noAntialiasing.checked = uiSkin.noAntialiasing;
		check_noAntialiasing.callback = function()
		{
            uiSkin.noAntialiasing = check_noAntialiasing.checked;
			reloadNotes();
		};

        scaleStepper = new FlxUINumericStepper(check_noAntialiasing.x + check_noAntialiasing.width, check_noAntialiasing.y, 0.1, 1, 0.01, 100, 2);
        blockPressWhileTypingOnStepper.push(scaleStepper);

        noteScaleStepper = new FlxUINumericStepper(scaleStepper.x + scaleStepper.width, check_noAntialiasing.y, 0.1, 1, 0.01, 100, 2);
        blockPressWhileTypingOnStepper.push(noteScaleStepper);

        sustainYScaleStepper = new FlxUINumericStepper(noteScaleStepper.x + noteScaleStepper.width, check_noAntialiasing.y, 0.1, 1, 0.01, 100, 2);
        blockPressWhileTypingOnStepper.push(sustainYScaleStepper);

        tab_group.add(UI_skinName);
        tab_group.add(reloadSkin);
        tab_group.add(check_noAntialiasing);
        tab_group.add(scaleStepper);
        tab_group.add(noteScaleStepper);
        tab_group.add(sustainYScaleStepper);
        tab_group.add(new FlxText(scaleStepper.x, scaleStepper.y - 15, 0, 'Overall Scale:'));
        tab_group.add(new FlxText(noteScaleStepper.x, noteScaleStepper.y - 15, 0, 'Note Scale:'));
        tab_group.add(new FlxText(sustainYScaleStepper.x - 15, sustainYScaleStepper.y - 15, 0, 'Sustain Y Scale:'));
        UI_box.addGroup(tab_group);
    }

    function addManiaUI() {
        var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Mania";

        UI_box.addGroup(tab_group);
    }

    function reloadNotes() {
        for (spr in noteLayer.members) {
			spr.destroy();
		}
        noteLayer.clear();
        strumNotes.clear();
        notes.clear();
        for (i in 0...curMania) {
            var strum:StrumNote = new StrumNote(PlayState.STRUM_X, 50, i, 0, curMania, uiSkin);
            strum.scrollFactor.set();
            noteLayer.add(strum);
            strumNotes.add(strum);
            strum.postAddedToGroup();

            var note:Note = new Note(0, i, null, false, false, curMania, uiSkin);
            note.scrollFactor.set();
            noteLayer.add(note);
            notes.add(note);
            note.distance = (-0.45 * (-400 - note.strumTime));
            var angleDir = 90 * Math.PI / 180;
            note.x = strumNotes.members[i].x + note.offsetX;
            note.y = strumNotes.members[i].y + note.offsetY + Math.sin(angleDir) * note.distance;

            var oldNote:Note = note;
            for (j in 0...4) {
                var sustainNote:Note = new Note(0 + (Conductor.stepCrochet * j) + Conductor.stepCrochet, i, oldNote, true, false, curMania, uiSkin);
                sustainNote.scrollFactor.set();
                noteLayer.insert(noteLayer.members.indexOf(note) - 1, sustainNote);
                notes.add(sustainNote);

                sustainNote.distance = (-0.45 * (-400 - sustainNote.strumTime));
				var angleDir = 90 * Math.PI / 180;
				sustainNote.x = strumNotes.members[i].x + sustainNote.offsetX + Math.cos(angleDir) * sustainNote.distance;
				sustainNote.y = strumNotes.members[i].y + sustainNote.offsetY  + Math.sin(angleDir) * sustainNote.distance;

                oldNote = sustainNote;
            }
        }

        for (i in 0...curMania) {
            var strum:StrumNote = new StrumNote(PlayState.STRUM_X, 50, i, 1, curMania, uiSkin);
            strum.scrollFactor.set();
            noteLayer.add(strum);
            strumNotes.add(strum);
            strum.postAddedToGroup();

            var note:Note = new Note(0, i, null, false, false, curMania, uiSkin);
            note.scrollFactor.set();
            noteLayer.add(note);
            notes.add(note);
            note.distance = (-0.45 * (-400 - note.strumTime));
            var angleDir = 90 * Math.PI / 180;
            note.x = strumNotes.members[i].x + note.offsetX;
            note.y = strumNotes.members[i].y + note.offsetY + Math.sin(angleDir) * note.distance;
        }
    }

    override function update(elapsed:Float) {
        var blockInput:Bool = false;
		for (inputText in blockPressWhileTypingOn) {
			if (inputText.hasFocus) {
				FlxG.sound.muteKeys = [];
				FlxG.sound.volumeDownKeys = [];
				FlxG.sound.volumeUpKeys = [];
				blockInput = true;
				break;
			}
		}

        if (!blockInput) {
			for (stepper in blockPressWhileTypingOnStepper) {
				@:privateAccess
				var leText:Dynamic = stepper.text_field;
				var leText:FlxUIInputText = leText;
				if (leText.hasFocus) {
					FlxG.sound.muteKeys = [];
					FlxG.sound.volumeDownKeys = [];
					FlxG.sound.volumeUpKeys = [];
					blockInput = true;
					break;
				}
			}
		}

        if (!blockInput) {
            FlxG.sound.muteKeys = TitleState.muteKeys;
			FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
			FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;
            if (FlxG.keys.justPressed.ESCAPE) {
                MusicBeatState.switchState(new editors.MasterEditorMenu());
                FlxG.sound.playMusic(Paths.music('freakyMenu'));
                FlxG.mouse.visible = false;
                return;
            }

            if (FlxG.keys.pressed.SPACE) {
                for (spr in strumNotes.members) {
                    spr.playAnim('confirm');
                }
            } else if (FlxG.keys.justPressed.SHIFT) {
                for (spr in strumNotes.members) {
                    spr.playAnim('pressed');
                }
            }
            
            if (!FlxG.keys.pressed.SHIFT && !FlxG.keys.pressed.SPACE) {
                for (spr in strumNotes.members) {
                    if (spr.animation.curAnim != null && !(spr.animation.curAnim.name == 'confirm' && !spr.animation.finished)) {
                        spr.playAnim('static', true);
                    }
                }
            }
        }

        super.update(elapsed);
    }

    override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>) {
		if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper)) {
			if (sender == scaleStepper) {
				uiSkin.scale = sender.value;
                reloadNotes();
			} else if (sender == noteScaleStepper) {
				uiSkin.noteScale = sender.value;
                reloadNotes();
			} else if (sender == sustainYScaleStepper) {
				uiSkin.sustainYScale = sender.value;
                reloadNotes();
			}
		}
	}

    function loadFromSkin() {
        check_noAntialiasing.checked = uiSkin.noAntialiasing;
        scaleStepper.value = uiSkin.scale;
        noteScaleStepper.value = uiSkin.noteScale;
        sustainYScaleStepper.value = uiSkin.sustainYScale;
        reloadNotes();
    }
}