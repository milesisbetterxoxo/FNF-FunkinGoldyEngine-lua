@echo off
color 0a
cd ..
echo INSTALLING LIBRARIES
haxelib --global install hmm
haxelib --global run hmm setup
hmm install
echo BUILDING GAME
lime build windows -release
echo.
echo done.
pause
pwd
explorer.exe export\release\windows\bin