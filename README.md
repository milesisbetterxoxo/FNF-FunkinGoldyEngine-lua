# : Its done. Stable and stuff.


# Friday Night Funkin' - Goldy engine
modified epic psych engine with epic fucking shits

## Credits:
* cheb -- coding and shit
* ben?!?! -- coding music shit
* artevar -- pretty cool art
* saad - pretty cool music

* Shadow Mario - Coding
* RiverOaken - Arts and Animations
* shubs - Assistant Coder
* bbpanzu - Former Coder

### Special Thanks
* KadeDev & GitHub Contributors - Made Kade Engine (some code is from there)
* Leather128 & GitHub Contributors - Made Leather Engine (some code is from there)
* srPerez - Made VS Shaggy & original 9K notes

* SqirraRNG - Chart Editor's Sound Waveform base code
* iFlicky - Delay/Combo Menu Song Composer + Dialogue Sounds
* PolybiusProxy - Video Loader Extension
* Keoiki - Note Splash Animations
* Smokey - Spritemap Texture Atlas support
_____________________________________

# New Features
* Custom key amounts (1K to 13K)
* Custom time signatures (1-99/1-64)
* Custom UI skins (customize rating sprites, countdown sprites, etc.)
* Character groups (more than one player, opponent, or GF)
* Hscript compatibility
* Separate voices for the player and opponent (by adding a 'VoicesDad' file)
* Gameplay Changers: Play opponent's chart, demo mode
* Go to options menu from in-game (go right back to game after you're done!)
* More Lua functions

# New Options
* Note underlays
* Instant restart after dying
* Show number of ratings
* "Crappy" quality option (no stage)
* Change instrumentals and voices volume
* Toggle autopause when not focused on the game
* "Shit" counts as a miss
* Smooth health bar
* Save Data menu where you can clear your save data

# Minor Touches
* Camera bump in Freeplay (from @Stilic)
* Difficulty dropdown in charting menu (from @CerBor)
_____________________________________

## Build Instructions:
### Installing the Required Programs
First, you need to install the **latest** Haxe and HaxeFlixel. I'm too lazy to write and keep updated with that setup (which is pretty simple). 
1. [Install Haxe](https://haxe.org/download/)
2. [Install HaxeFlixel](https://haxeflixel.com/documentation/install-haxeflixel/) after downloading Haxe (make sure to do `haxelib run lime setup flixel` to install the necessary libraries, basically just follow the whole guide)

You should make sure to keep Haxe & Flixel updated. If there is a compilation error, it might be due to having an outdated version.

You'll also need to install a couple things that involve Gits. To do this, you need to do a few things first.
1. Download [git-scm](https://git-scm.com/downloads). Works for Windows, Mac, and Linux, just select your build.
2. Follow instructions to install the application properly.
3. Run `haxelib git discord_rpc https://github.com/Aidan63/linc_discord-rpc` to install Discord RPC.
4. Run `haxelib git linc_luajit https://github.com/AndreiRudenko/linc_luajit` to install LuaJIT. (If you don't want your mod to be able to run .lua scripts, delete the "LUA_ALLOWED" line on Project.xml)
5. Run `haxelib git hscript https://github.com/HaxeFoundation/hscript` to install hscript. After that, run `haxelib git hscript-ex https://github.com/ianharrigan/hscript-ex` to install hscript-ex. (If you don't want your mod to be able to run .hscript scripts, delete the "HSCRIPT_ALLOWED" line on Project.xml)

You should have everything ready for compiling the game! Follow the guide below to continue!

### Compiling game
NOTE: If you see any messages relating to deprecated packages, ignore them. They're just warnings that don't affect compiling

#### HTML5
Compiling to browser is very simple. You just need to run `lime test html5 -debug` (remove "-debug" for official releases) in the root of the project to build and run the HTML5 version. (command prompt navigation guide can be found [here](https://ninjamuffin99.newgrounds.com/news/post/1090480))

Do note that modpacks and Lua scripts are unavailable in HTML5.

#### Desktop
To run it from your desktop (Windows, Mac, Linux) it can be a bit more involved.

For Windows, you need to install [Visual Studio Community](https://visualstudio.microsoft.com/downloads/). While installing VSC, don't click on any of the options to install workloads. Instead, go to the individual components tab and choose the following:
* MSVC v142 - VS 2019 C++ x64/x86 build tools (Latest)
* Windows 10 SDK (10.0.17763.0)

This will take a while and requires about 4GB of space. Once that is done you can open up a command line in the project's directory and run `lime test windows -debug` (remove "-debug" for official releases). Once that command finishes (it takes forever even on a higher end PC), it will automatically run the game. The .exe file will be under export\release\windows\bin.

For Mac, you need to install [Xcode](https://apps.apple.com/us/app/xcode/id497799835). After that, run `lime test mac -debug` (remove "-debug" for official releases) in the project's directory. The .exe file will be in export/release/mac/bin.

For Linux, you only need to open a terminal in the project directory and run `lime test linux -debug` (remove "-debug" for official releases). The executable file will be in export/release/linux/bin.

To build for 32-bit, add `-32 -D 32bits` to the `lime test` command:

`lime test windows -32 -D 32bits`


