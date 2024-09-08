@echo off
color 0a
cd ..
@echo on
echo INSTALLING LIBRARIES
haxelib --global install hmm
haxelib --global run hmm setup
hmm install
echo BUILDING GAME
lime test html5 -debug
pause