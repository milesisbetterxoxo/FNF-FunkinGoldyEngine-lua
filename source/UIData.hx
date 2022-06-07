package;

import haxe.Json;
#if MODS_ALLOWED
import sys.io.File;
import sys.FileSystem;
#end
import lime.utils.Assets;

using StringTools;

typedef SkinFile = {
	var mania:Array<ManiaArray>; //data for key amounts
    var scale:Float; //overall scale (added ontop of all other scales)
    var noteScale:Float; //additional note scale
    var sustainYScale:Float; //additional sustain note height scale
    var countdownScale:Float; //countdown sprites scale
    var ratingScale:Float; //rating and 'combo' sprites scale
    var comboNumScale:Float; //combo numbers scale
    var sustainXOffset:Float; //sustain note x offset
    var ?downscrollTailYOffset:Float; //sustain end y offset (for downscroll only)
    var noAntialiasing:Bool; //whether to always have antialiasing disabled
    var ?isPixel:Bool; //if this skin is based off the week 6 one
    var introSoundsSuffix:String; //suffix for the countdown sounds

    var name:String; //just an internal filename to make things easier
}

typedef ManiaArray = {
    var keys:Int; //key amount to be attached to [so you don't need to have every single key amount in a skin]
    var noteSize:Float; //note scale for this key amount
    var noteSpacing:Float; //x spacing between each note
    var xOffset:Float; //extra x offset for the strums
    var colors:Array<String>; //name order for the colors
    var directions:Array<String>; //name order for the strum directions
    var singAnimations:Array<String>; //name order for the sing animations
}

class UIData {
    public static function getUIFile(skin:String):SkinFile {
        if (skin == null || skin.length < 1) skin = 'default';
        var daFile:SkinFile = null;
        var rawJson:String = null;
        var path:String = Paths.getPreloadPath('images/uiskins/$skin.json');
    
        #if MODS_ALLOWED
        var modPath:String = Paths.modFolders('images/uiskins/$skin.json');
        if (FileSystem.exists(modPath)) {
            rawJson = File.getContent(modPath);
        } else if (FileSystem.exists(path)) {
            rawJson = File.getContent(path);
        }
        #else
        if (Assets.exists(path)) {
            rawJson = Assets.getText(path);
        }
        #end
        else
        {
            return null;
        }
        daFile = cast Json.parse(rawJson);
        daFile.name = skin;
        
        return daFile;
    }

    public static function checkImageFile(file:String, uiSkin:SkinFile):String {
        if (Paths.fileExists('images/$file.png', IMAGE)) {
            return file;
        }
        var path:String = 'uiskins/${uiSkin.name}/$file';
		if (!Paths.fileExists('images/$path.png', IMAGE) && !Paths.fileExists('images/$file.png', IMAGE)) {
            if (uiSkin.isPixel && Paths.fileExists('images/uiskins/pixel/$file.png', IMAGE)) {
                path = 'uiskins/pixel/$file';
            } else {
                path = 'uiskins/default/$file';
            }
		}
        return path;
    }

    public static function checkSkinFile(file:String, uiSkin:SkinFile):SkinFile {
        if (Paths.fileExists('images/$file.png', IMAGE)) {
            return uiSkin;
        }
        var path:String = 'uiskins/${uiSkin.name}/$file';
		if (!Paths.fileExists('images/$path.png', IMAGE) && !Paths.fileExists('images/$file.png', IMAGE)) {
            if (uiSkin.isPixel && Paths.fileExists('images/uiskins/pixel/$file.png', IMAGE)) {
                return getUIFile('pixel');
            } else {
                return getUIFile('');
            }
		}
        return uiSkin;
    }
}