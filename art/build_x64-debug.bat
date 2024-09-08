@echo off
color 0a
cd ..
echo INSTALLING LIBRARIES
haxelib --global install hmm
haxelib --global run hmm setup
hmm install
echo BUILDING GAME
lime build windows -debug
echo.
echo done.
pause
pwd
explorer.exe export\debug\windows\bin