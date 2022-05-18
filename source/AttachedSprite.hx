package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.StrNameLabel;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxTileFrames;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.text.FlxText;
import flixel.util.FlxColor;

using StringTools;

class AttachedSprite extends FlxSprite
{
	public var sprTracker:FlxSprite;
	public var xAdd:Float = 0;
	public var yAdd:Float = 0;
	public var angleAdd:Float = 0;
	public var alphaMult:Float = 1;

	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;
	public var copyVisible:Bool = false;

	public function new(?file:String = null, ?anim:String = null, ?library:String = null, ?loop:Bool = false)
	{
		super();
		if (anim != null) {
			frames = Paths.getSparrowAtlas(file, library);
			animation.addByPrefix('idle', anim, 24, loop);
			animation.play('idle');
		} else if (file != null) {
			loadGraphic(Paths.image(file));
		}
		antialiasing = ClientPrefs.globalAntialiasing;
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null) {
			setPosition(sprTracker.x + xAdd, sprTracker.y + yAdd);
			scrollFactor.set(sprTracker.scrollFactor.x, sprTracker.scrollFactor.y);

			if (copyAngle)
				angle = sprTracker.angle + angleAdd;

			if (copyAlpha)
				alpha = sprTracker.alpha * alphaMult;

			if (copyVisible) 
				visible = sprTracker.visible;
		}
	}

	override public function loadGraphic(Graphic:FlxGraphicAsset, Animated:Bool = false, Width:Int = 0, Height:Int = 0, Unique:Bool = false, ?Key:String):AttachedSprite
	{
		var graph:FlxGraphic = FlxG.bitmap.add(Graphic, Unique, Key);
		if (graph == null)
			return this;

		if (Width == 0)
		{
			Width = Animated ? graph.height : graph.width;
			Width = (Width > graph.width) ? graph.width : Width;
		}

		if (Height == 0)
		{
			Height = Animated ? Width : graph.height;
			Height = (Height > graph.height) ? graph.height : Height;
		}

		if (Animated)
			frames = FlxTileFrames.fromGraphic(graph, FlxPoint.get(Width, Height));
		else
			frames = graph.imageFrame;

		return this;
	}

	override public function makeGraphic(Width:Int, Height:Int, Color:FlxColor = FlxColor.WHITE, Unique:Bool = false, ?Key:String):AttachedSprite
	{
		var graph:FlxGraphic = FlxG.bitmap.create(Width, Height, Color, Unique, Key);
		frames = graph.imageFrame;
		return this;
	}
}

class AttachedText extends Alphabet
{
	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var angleAdd:Float = 0;
	public var alphaMult:Float = 1;
	public var sprTracker:FlxSprite;

	public var copyVisible:Bool = true;
	public var copyAlpha:Bool = false;
	public var copyAngle:Bool = false;
	public function new(text:String = "", ?offsetX:Float = 0, ?offsetY:Float = 0, ?bold = false, ?scale:Float = 1) {
		super(0, 0, text, bold, false, 0.05, scale);
		isMenuItem = false;
		this.offsetX = offsetX;
		this.offsetY = offsetY;
	}

	override function update(elapsed:Float) {
		if (sprTracker != null) {
			setPosition(sprTracker.x + offsetX, sprTracker.y + offsetY);
			scrollFactor.set(sprTracker.scrollFactor.x, sprTracker.scrollFactor.y);

			if (copyVisible) {
				visible = sprTracker.visible;
			}
			if (copyAlpha) {
				alpha = sprTracker.alpha * alphaMult;
			}
			if (copyAngle)
				angle = sprTracker.angle + angleAdd;
		}

		super.update(elapsed);
	}
}

class AttachedFlxText extends FlxText
{
	public var sprTracker:FlxSprite;
	public var xAdd:Float = 0;
	public var yAdd:Float = 0;
	public var angleAdd:Float = 0;
	public var alphaMult:Float = 1;

	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;
	public var copyVisible:Bool = false;

	public function new(X:Float = 0, Y:Float = 0, FieldWidth:Float = 0, ?Text:String, Size:Int = 8, EmbeddedFont:Bool = true) {
		super(X, Y, FieldWidth, Text, Size, EmbeddedFont);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null) {
			setPosition(sprTracker.x + xAdd, sprTracker.y + yAdd);
			scrollFactor.set(sprTracker.scrollFactor.x, sprTracker.scrollFactor.y);

			if (copyAngle)
				angle = sprTracker.angle + angleAdd;
			if (copyAlpha)
				alpha = sprTracker.alpha * alphaMult;
			if (copyVisible)
				visible = sprTracker.visible;
		}
	}
}

class AttachedInputText extends FlxUIInputText {
	public var sprTracker:FlxSprite;
	public var xAdd:Float = 0;
	public var yAdd:Float = 0;

	public var copyVisible:Bool = true;
	
	public function new(X:Float = 0, Y:Float = 0, Width:Int = 150, ?Text:String, size:Int = 8, TextColor:Int = FlxColor.BLACK, BackgroundColor:Int = FlxColor.WHITE, EmbeddedFont:Bool = true) {
		super(X, Y, Width, Text, size, TextColor, BackgroundColor, EmbeddedFont);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null) {
			setPosition(sprTracker.x + xAdd, sprTracker.y + yAdd);
			scrollFactor.set(sprTracker.scrollFactor.x, sprTracker.scrollFactor.y);

			if (copyVisible) 
				visible = sprTracker.visible;
		}
	}
}

class AttachedDropDownMenu extends FlxUIDropDownMenu {
	public var sprTracker:FlxSprite;
	public var xAdd:Float = 0;
	public var yAdd:Float = 0;

	public var copyVisible:Bool = true;
	
	public function new(X:Float = 0, Y:Float = 0, DataList:Array<StrNameLabel>, ?Callback:String->Void, ?Header:FlxUIDropDownHeader, ?DropPanel:FlxUI9SliceSprite, ?ButtonList:Array<FlxUIButton>) {
		super(X, Y, DataList, Callback, Header, DropPanel, ButtonList);
	}

	override function update(elapsed:Float)
	{
		if (sprTracker != null) {
			setPosition(sprTracker.x + xAdd, sprTracker.y + yAdd);
			setScrollFactor(sprTracker.scrollFactor.x, sprTracker.scrollFactor.y);

			if (copyVisible) 
				visible = sprTracker.visible;
		}

		super.update(elapsed);
	}
}