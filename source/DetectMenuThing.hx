package;

import flixel.FlxState;

class DetectMenuThing
{
    public static function detect():MusicBeatState
    {
        switch(ClientPrefs.moreShit.toLowerCase()) {
            case 'goldy':
                return new MainMenuStateGoldy();
            case 'ice':
                return new MainMenuStateIce();
            case 'psych':
                return new MainMenuStatePsych();
        }
        return new MainMenuStateGoldy();
    }
}