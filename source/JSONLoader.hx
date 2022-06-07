package;

import editors.StageEditorState.StageJSON;
import haxe.Json;
import sys.io.File;

using StringTools;

/**
 * A Simple Tools For Saving/Loding Json
 *
 * `WARNING: THIS ONLY FOR STAGEJSON!!`
 */
class JSONMenu
{
    /**
    * loades a StageJson File.
    */
    public static function load(path:String):StageJSON
    {
        var json:String = path;
        if (!path.contains('.json')) json = path + '.json';
        trace(json);
        var why = File.getContent(json);
        trace(why);
        var jsonFile:StageJSON = Json.parse(why);
        trace(jsonFile);
        return jsonFile;
    }
}