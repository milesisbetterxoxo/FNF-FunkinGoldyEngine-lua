package options;

class DeveloperSubstate extends BaseOptionsMenu
{
    public function new() {
        title = 'Developer Settings State';
        rpcTitle = 'Developer Settings State';
        
        var songs:Array<String> = [];
        var instance:FreeplayState = new FreeplayState();
        instance.create(); // make it do stuff LOL

        for (song in instance.songsOG) {
            songs.push(song.songName);
        }
    
        var option:Option = new Option('Default Song', //Name
			'Sets the default song if some chart is not found.', //Description
			'defaultSong', //Save data varifable name
			'string', //Variable type
            'Tutorial',
            songs); //Default value
		addOption(option);

        super();

        // probs gonna add more here XD
    }
}