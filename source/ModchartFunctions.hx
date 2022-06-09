package;

import flixel.FlxG;
import openfl.*;
import PlayState;

class ModchartFunctions {
    public static function camZoom(width:Int, height:Int)
    {
        FlxG.resizeGame(width, height);
    }
    public static function moveWindow(x:Int, y:Int)
    {
        Lib.application.window.move(x, y);
    }
    public static function removeGroup(group:String)
    {
        if (group == 'gf' || group == 'girlfriend' || group == 'player3')
        PlayState.instance.removeObject(PlayState.gf);
        else if (group == 'bf' || group == 'boyfriend' || group == 'player2')
        PlayState.instance.removeObject(PlayState.boyfriend);
        else if (group == 'dad' || group == 'player1')
        PlayState.instance.removeObject(PlayState.dad);
    }
    public static function addGroup(group:String)
    {
        if (group == 'gf' || group == 'girlfriend' || group == 'player3')
        PlayState.instance.addObject(PlayState.gf);
        else if (group == 'bf' || group == 'boyfriend' || group == 'player2')
        PlayState.instance.addObject(PlayState.boyfriend);
        else if (group == 'dad' || group == 'player1')
        PlayState.instance.addObject(PlayState.dad);
    }
}
