package;

import openfl.utils.Assets;
import flixel.FlxG;

class OtherPathsAndCoolStuff {
    inline public static function exists(path:String, fileType:openfl.utils.AssetType) {
        if (Paths.fileExists(path, fileType))
        {
            return true;
        }
        else
        {
            return false;
            if (ClientPrefs.safeMode)
            {
                LoadingState.loadAndSwitchState(new ErrorState());
            }
        }
    }
    public static function koolTrace(message:String, shouldBeLogged:Bool)
    {
        trace(message);
        if (shouldBeLogged && message.contains('!'))
        {
            FlxG.log.warn(message);
        }
        else if (shouldBeLogged)
        {
            FlxG.log.add(message);
        }
    }
}