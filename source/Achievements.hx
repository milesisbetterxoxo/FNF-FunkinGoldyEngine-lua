import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.tweens.FlxTween;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.text.FlxText;

using StringTools;

typedef AchievementFile = {
	var displayName:String; //Name
	var description:String; //Description
	var name:String; //Achievement save tag
	var hiddenUntilUnlocked:Bool; //Hidden achievement
}

class Achievements {
	public static var baseAchievements:Array<AchievementFile> = [
		{displayName: "Freaky on a Friday Night", 	description: "Play on a Friday... Night.", 						name: "friday_night_play", 		hiddenUntilUnlocked: true},
		{displayName: "She Calls Me Daddy Too", 	description: "Beat Week 1 on Hard with no misses.", 			name: "week1_nomiss", 			hiddenUntilUnlocked: false},
		{displayName: "No More Tricks", 			description: "Beat Week 2 on Hard with no misses.", 			name: "week2_nomiss", 			hiddenUntilUnlocked: false},
		{displayName: "Call Me The Hitman", 		description: "Beat Week 3 on Hard with no misses.", 			name: "week3_nomiss", 			hiddenUntilUnlocked: false},
		{displayName: "Lady Killer", 				description: "Beat Week 4 on Hard with no misses.", 			name: "week4_nomiss", 			hiddenUntilUnlocked: false},
		{displayName: "Missless Christmas", 		description: "Beat Week 5 on Hard with no misses.", 			name: "week5_nomiss", 			hiddenUntilUnlocked: false},
		{displayName: "Highscore!!", 				description: "Beat Week 6 on Hard with no misses.", 			name: "week6_nomiss", 			hiddenUntilUnlocked: false},
		{displayName: "You'll Pay For That...", 	description: "Beat Week 7 on Hard with no misses.", 			name: "week7_nomiss", 			hiddenUntilUnlocked: true},
		{displayName: "What a Funkin' Disaster!",	description: "Complete a song with a rating lower than 20%.",	name: "ur_bad", 				hiddenUntilUnlocked: false},
		{displayName: "Perfectionist",				description: "Complete a song with a rating of 100%.",			name: "ur_good", 				hiddenUntilUnlocked: false},
		{displayName: "Roadkill Enthusiast",		description: "Watch the Henchmen die over 100 times.",			name: "roadkill_enthusiast",	hiddenUntilUnlocked: false},
		{displayName: "Oversinging Much...?",		description: "Hold down a note for 10 seconds.",				name: "oversinging", 			hiddenUntilUnlocked: false},
		{displayName: "Hyperactive",				description: "Finish a song without going idle.",				name: "hype", 					hiddenUntilUnlocked: false},
		{displayName: "Just the Two of Us",			description: "Finish a song pressing only two keys.",			name: "two_keys", 				hiddenUntilUnlocked: false},
		{displayName: "Toaster Gamer",				description: "Have you tried to run the game on a toaster?",	name: "toastie", 				hiddenUntilUnlocked: false},
		{displayName: "Debugger",					description: 'Beat the "Test" stage from the Chart Editor.',	name: "debugger", 				hiddenUntilUnlocked: true}
	];
	public static var achievementsStuff:Array<AchievementFile> = [];

	public static var achievementsMap:Map<String, Bool> = new Map();

	public static var henchmenDeath:Int = 0;
	public static function unlockAchievement(name:String):Void {
		FlxG.log.add('Completed achievement "$name"');
		achievementsMap.set(name, true);
		ClientPrefs.saveSettings();
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
	}

	public static function isAchievementUnlocked(name:String) {
		if(achievementsMap.exists(name) && achievementsMap.get(name)) {
			return true;
		}
		return false;
	}

	public static function getAchievementIndex(name:String) {
		for (i in 0...achievementsStuff.length) {
			if (achievementsStuff[i].name == name) {
				return i;
			}
		}
		return -1;
	}

	public static function loadAchievements():Void {
		achievementsStuff = baseAchievements.copy();
		if (FlxG.save.data != null) {
			if (FlxG.save.data.achievementsMap != null) {
				achievementsMap = FlxG.save.data.achievementsMap;
			}
			if (FlxG.save.data.achievementsUnlocked != null) {
				FlxG.log.add("Trying to load stuff");
				var savedStuff:Array<String> = FlxG.save.data.achievementsUnlocked;
				for (i in 0...savedStuff.length) {
					achievementsMap.set(savedStuff[i], true);
				}
			}
			if (henchmenDeath == 0 && FlxG.save.data.henchmenDeath != null) {
				henchmenDeath = FlxG.save.data.henchmenDeath;
			}
		}

		// You might be asking "Why didn't you just fucking load it directly dumbass??"
		// Well, Mr. Smartass, consider that this class was made for Mind Games Mod's demo,
		// i'm obviously going to change the "Psyche" achievement's objective so that you have to complete the entire week
		// with no misses instead of just Psychic once the full release is out. So, for not having the rest of your achievements lost on
		// the full release, we only save the achievements' tag names instead. This also makes me able to rename
		// achievements later as long as the tag names aren't changed of course.

		// Edit: Oh yeah, just thought that this also makes me able to change the achievements orders easier later if i want to.
		// So yeah, if you didn't thought about that i'm smarter than you, i think

		// buffoon

		// EDIT 2: Uhh this is weird, this message was written for MInd Games, so it doesn't apply logically for Psych Engine LOL
	}
}

class AttachedAchievement extends FlxSprite {
	public var sprTracker:FlxSprite;
	private var tag:String;
	public function new(x:Float = 0, y:Float = 0, name:String) {
		super(x, y);

		changeAchievement(name);
		antialiasing = ClientPrefs.globalAntialiasing;
	}

	public function changeAchievement(tag:String) {
		this.tag = tag;
		reloadAchievementImage();
	}

	public function reloadAchievementImage() {
		if (Achievements.isAchievementUnlocked(tag)) {
			loadGraphic(Paths.image('achievementgrid'), true, 150, 150);
			animation.add('icon', [Achievements.getAchievementIndex(tag)], 0, false, false);
			animation.play('icon');
		} else {
			loadGraphic(Paths.image('lockedachievement'));
		}
		scale.set(0.7, 0.7);
		updateHitbox();
	}

	override function update(elapsed:Float) {
		if (sprTracker != null)
			setPosition(sprTracker.x - 130, sprTracker.y + 25);

		super.update(elapsed);
	}
}

class AchievementObject extends FlxSpriteGroup {
	public var onFinish:Void->Void = null;
	var alphaTween:FlxTween;
	public function new(name:String, ?camera:FlxCamera = null)
	{
		super(x, y);

		var id:Int = Achievements.getAchievementIndex(name);
		var achievementBG:FlxSprite = new FlxSprite(60, 50).makeGraphic(420, 120, FlxColor.BLACK);
		achievementBG.scrollFactor.set();

		var achievementIcon:FlxSprite = new FlxSprite(achievementBG.x + 10, achievementBG.y + 10).loadGraphic(Paths.image('achievementgrid'), true, 150, 150);
		achievementIcon.animation.add('icon', [id], 0, false, false);
		achievementIcon.animation.play('icon');
		achievementIcon.scrollFactor.set();
		achievementIcon.setGraphicSize(Std.int(achievementIcon.width * (2 / 3)));
		achievementIcon.updateHitbox();
		achievementIcon.antialiasing = ClientPrefs.globalAntialiasing;

		var achievementName:FlxText = new FlxText(achievementIcon.x + achievementIcon.width + 20, achievementIcon.y + 16, 280, Achievements.achievementsStuff[id].displayName, 16);
		achievementName.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		achievementName.scrollFactor.set();

		var achievementText:FlxText = new FlxText(achievementName.x, achievementName.y + 32, 280, Achievements.achievementsStuff[id].description, 16);
		achievementText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		achievementText.scrollFactor.set();

		add(achievementBG);
		add(achievementName);
		add(achievementText);
		add(achievementIcon);

		@:privateAccess var cam:Array<FlxCamera> = FlxG.cameras.defaults;
		if (camera != null) {
			cam = [camera];
		}
		alpha = 0;
		achievementBG.cameras = cam;
		achievementName.cameras = cam;
		achievementText.cameras = cam;
		achievementIcon.cameras = cam;
		alphaTween = FlxTween.tween(this, {alpha: 1}, 0.5, {onComplete: function (twn:FlxTween) {
			alphaTween = FlxTween.tween(this, {alpha: 0}, 0.5, {
				startDelay: 2.5,
				onComplete: function(twn:FlxTween) {
					alphaTween = null;
					remove(this);
					if (onFinish != null) onFinish();
				}
			});
		}});
	}

	override function destroy() {
		if (alphaTween != null) {
			alphaTween.cancel();
		}
		super.destroy();
	}
}