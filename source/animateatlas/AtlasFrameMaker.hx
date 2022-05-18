package animateatlas;

import animateatlas.JSONData.AnimationData;
import animateatlas.JSONData.AtlasData;
import animateatlas.displayobject.SpriteAnimationLibrary;
import animateatlas.displayobject.SpriteMovieClip;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import haxe.Json;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;
#if MODS_ALLOWED
import sys.FileSystem;
#end

using StringTools;

class AtlasFrameMaker extends FlxFramesCollection
{
	static var framesLoaded:Map<String, FlxFramesCollection> = new Map(); //cache frame collections cause they take a million years to create

	/**

	* Creates Frames from TextureAtlas(very early and broken ok) Originally made for FNF HD by Smokey and Rozebud
	*
	* @param   key                 The file path.
	* @param   _excludeArray       Use this to only create selected animations. Keep null to create all of them.
	*
	*/

	public static function construct(key:String, ?_excludeArray:Array<String> = null, ?noAntialiasing:Bool = false):FlxFramesCollection
	{
		var frameCollection:FlxFramesCollection;
		var frameArray:Array<Array<FlxFrame>> = [];

		if (Paths.fileExists('images/$key/spritemap1.json', TEXT))
		{
			PlayState.instance.addTextToDebug('$key: Only Spritemaps made with Adobe Animate 2018 are supported');
			trace('$key: Only Spritemaps made with Adobe Animate 2018 are supported');
			return null;
		}

		var usedPath:String = Paths.getPath('images/$key/spritemap.png', IMAGE);
		#if MODS_ALLOWED
		if (FileSystem.exists(Paths.modsImages('$key/spritemap'))) {
			usedPath = Paths.modsImages('$key/spritemap');
		}
		#end
		if (framesLoaded.exists(usedPath)) {
			return framesLoaded.get(usedPath);
		}

		var animationData:AnimationData = Json.parse(Paths.getTextFromFile('images/$key/Animation.json'));
		var atlasData:AtlasData = Json.parse(Paths.getTextFromFile('images/$key/spritemap.json').replace("\uFEFF", ""));

		var graphic = Paths.image('$key/spritemap');
		var ss = new SpriteAnimationLibrary(animationData, atlasData, graphic.bitmap);
		var t = ss.createAnimation(noAntialiasing);
		if (_excludeArray == null)
		{
			_excludeArray = t.getFrameLabels();
		}
		trace('Creating: $_excludeArray');

		frameCollection = new FlxFramesCollection(graphic, IMAGE);
		for(x in _excludeArray)
		{
			frameArray.push(getFramesArray(t, x));
		}

		for(x in frameArray)
		{
			for(y in x)
			{
				frameCollection.pushFrame(y);
			}
		}
		framesLoaded.set(usedPath, frameCollection);
		return frameCollection;
	}

	@:noCompletion static function getFramesArray(t:SpriteMovieClip,animation:String):Array<FlxFrame>
	{
		var sizeInfo = new Rectangle(0, 0);
		t.currentLabel = animation;
		var bitMapArray:Array<BitmapData> = [];
		var daFramez:Array<FlxFrame> = [];
		var firstPass = true;
		var frameSize = new FlxPoint(0, 0);

		for (i in t.getFrame(animation)...t.numFrames)
		{
			t.currentFrame = i;
			if (t.currentLabel == animation)
			{
				sizeInfo = t.getBounds(t);
				var bitmapShit = new BitmapData(Std.int(sizeInfo.width + sizeInfo.x), Std.int(sizeInfo.height + sizeInfo.y), true, 0);
				bitmapShit.draw(t, null, null, null, null, true);
				bitMapArray.push(bitmapShit);

				if (firstPass)
				{
					frameSize.set(bitmapShit.width,bitmapShit.height);
					firstPass = false;
				}
			}
			else break;
		}

		for (i in 0...bitMapArray.length)
		{
			var b = FlxGraphic.fromBitmapData(bitMapArray[i]);
			var theFrame = new FlxFrame(b);
			theFrame.parent = b;
			theFrame.name = animation + i;
			theFrame.sourceSize.set(frameSize.x,frameSize.y);
			theFrame.frame = new FlxRect(0, 0, bitMapArray[i].width, bitMapArray[i].height);
			daFramez.push(theFrame);
		}
		return daFramez;
	}

	public static function clearCache() { //clear loaded frames cause they might've changed
		framesLoaded.clear();
	}
}