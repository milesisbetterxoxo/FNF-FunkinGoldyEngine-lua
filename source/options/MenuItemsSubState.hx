package options;

import options.BaseOptionsMenu;
import options.Option;
import flixel.FlxG;

class MenuItemsSubState extends BaseOptionsMenu
{
    public function new() {
        title = 'Menu Item Settings';
		rpcTitle = 'Menu Item Settings'; //for Discord Rich Presence

        var option:Option = new Option('Story Mode Visible',
        'If unchecked, hides Story Mode in Main Menu. (why would you need to do that)',
        'storyModeVisible',
        'bool',
        'true');
        addOption(option);
        
        var option:Option = new Option('Freeplay Visible',
        'If unchecked, hides Freeplay in Main Menu. (why would you need to do that)',
        'freeplayVisible',
        'bool',
        'true');
        addOption(option);

        var option:Option = new Option('Mods Visible',
        'If unchecked, hides Mods in Main Menu.',
        'modsVisible',
        'bool',
        'true');
        addOption(option);

        var option:Option = new Option('Credits Visible',
        'If unchecked, hides Credits in Main Menu.',
        'creditsVisible',
        'bool',
        'true');
        addOption(option);

        var option:Option = new Option('Achievements Visible',
        'If unchecked, hides Achievements in Main Menu.',
        'awardsVisible',
        'bool',
        'true');
        addOption(option);

        #if !switch
        var option:Option = new Option('Donate Visible',
        'If unchecked, hides Donate in Main Menu.',
        'donateVisible',
        'bool',
        'true');
        addOption(option);
        #end

        var option:Option = new Option('Options Visible',
        'If unchecked, hides Options in Main Menu. (why would you need to do that)',
        'optionsVisible',
        'bool',
        'true');
        addOption(option);
        super();
    }
}