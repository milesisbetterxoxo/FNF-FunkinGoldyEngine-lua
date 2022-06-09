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
        PlayState.instance.removeObject(PlayState.instance.gf);
        else if (group == 'bf' || group == 'boyfriend' || group == 'player2')
        PlayState.instance.removeObject(PlayState.instance.boyfriend);
        else if (group == 'dad' || group == 'player1')
        PlayState.instance.removeObject(PlayState.instance.dad);
    }
    public static function addGroup(group:String)
    {
        if (group == 'gf' || group == 'girlfriend' || group == 'player3')
        PlayState.instance.addObject(PlayState.instance.gf);
        else if (group == 'bf' || group == 'boyfriend' || group == 'player2')
        PlayState.instance.addObject(PlayState.instance.boyfriend);
        else if (group == 'dad' || group == 'player1')
        PlayState.instance.addObject(PlayState.instance.dad);
    }
}
