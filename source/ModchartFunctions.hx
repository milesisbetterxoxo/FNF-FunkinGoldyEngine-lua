package;

import flixel.FlxG;
import openfl.*;

class ModchartFunctions {
    public function resizeWindow(width, height)
    {
        resizeGame(width, height);
    }
    public function moveWindow(x, y)
    {
        Lib.application.window.move(x, y);
    }
}
