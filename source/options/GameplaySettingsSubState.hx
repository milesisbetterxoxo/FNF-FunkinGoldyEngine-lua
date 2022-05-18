package options;

import flixel.FlxG;

using StringTools;

class GameplaySettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Gameplay Settings';
		rpcTitle = 'Gameplay Settings Menu'; //for Discord Rich Presence

		var option:Option = new Option('Controller Mode',
			'Check this if you want to play with a controller instead of using your keyboard.',
			'controllerMode',
			'bool',
			false);
		addOption(option);


		//I'd suggest using "Downscroll" as an example for making your own option since it is the simplest here
		var option:Option = new Option('Downscroll', //Name
			'If checked, notes go down instead of up, simple enough.', //Description
			'downScroll', //Save data variable name
			'bool', //Variable type
			false); //Default value
		addOption(option);

		var option:Option = new Option('Middlescroll',
			'If checked, your notes get centered.',
			'middleScroll',
			'bool',
			false);
		addOption(option);

		var option:Option = new Option('Ghost Tapping',
			"If checked, you won't get misses from pressing keys while there are no notes able to be hit.",
			'ghostTapping',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('"Shit" Counts as Miss',
			'If checked, getting a "Shit" rating will count as a miss.',
			'shitMisses',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Disable Reset Button',
			"If checked, pressing Reset won't do anything.",
			'noReset',
			'bool',
			false);
		addOption(option);

		var option:Option = new Option('Instant Restart',
			"If checked, you will automatically restart after a game over.",
			'instantRestart',
			'bool',
			false);
		addOption(option);

		var option:Option = new Option('Instrumental Volume',
			'Sets the volume for the song instrumentals.\n(Only works if the instrumental and vocals are separate files)',
			'instVolume',
			'percent',
			1);
		addOption(option);

		var option:Option = new Option('Vocals Volume',
			'Sets the volume for the song vocals.\n(Only works if the instrumental and vocals are separate files)',
			'voicesVolume',
			'percent',
			1);
		addOption(option);

		var option:Option = new Option('Hitsound Volume',
			'A "tick" sound plays when you hit a note.',
			'hitsoundVolume',
			'percent',
			0);
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);

		var option:Option = new Option('Rating Offset',
			'Changes how late/early you have to hit for a "Sick!"\nHigher values mean you have to hit later.',
			'ratingOffset',
			'int',
			0);
		option.displayFormat = '%vms';
		option.scrollSpeed = 20;
		option.minValue = -30;
		option.maxValue = 30;
		addOption(option);

		var option:Option = new Option('Sick! Hit Window',
			'Changes the amount of time you have for hitting a "Sick!" in milliseconds.',
			'sickWindow',
			'int',
			45);
		option.displayFormat = '%vms';
		option.scrollSpeed = 15;
		option.minValue = 15;
		option.maxValue = 45;
		addOption(option);

		var option:Option = new Option('Good Hit Window',
			'Changes the amount of time you have for hitting a "Good" in milliseconds.',
			'goodWindow',
			'int',
			90);
		option.displayFormat = '%vms';
		option.scrollSpeed = 30;
		option.minValue = 15;
		option.maxValue = 90;
		addOption(option);

		var option:Option = new Option('Bad Hit Window',
			'Changes the amount of time you have for hitting a "Bad" in milliseconds.',
			'badWindow',
			'int',
			135);
		option.displayFormat = '%vms';
		option.scrollSpeed = 60;
		option.minValue = 15;
		option.maxValue = 135;
		addOption(option);

		var option:Option = new Option('Safe Frames',
			'Changes how many frames you have for hitting a note earlier or late.',
			'safeFrames',
			'float',
			10);
		option.scrollSpeed = 5;
		option.minValue = 2;
		option.maxValue = 10;
		option.changeValue = 0.1;
		addOption(option);

		var option:Option = new Option('Flashing Amount',
		    'Depends on the value, how hard it should flash on game, or title.',
			'flashingAmount',
			10);
		option.scrollSpeed = 1;
		option.minValue = 0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		addOption(option);

		var option:Option = new Option('Auto Pause',
			"If checked, the game will be frozen when it loses focus.",
			'autoPause',
			'bool',
			#if html5
			false
			#else
			true
			#end
			);
		option.onChange = function() {
			FlxG.autoPause = ClientPrefs.autoPause;
		}
		addOption(option);

		var option:Option = new Option('Pause Game When Focus is Lost',
			"If checked, the pause menu will automatically open when focus is lost while playing a song.",
			'focusLostPause',
			'bool',
			true
			);
		addOption(option);

		super();
	}
}