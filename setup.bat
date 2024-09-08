@echo off
cls
color 0a
echo Setting up necessary stuff for Goldy Engine.. (P.S this is not a virus. Code made by @milesisbetterxoxo. Check the code to verify that.)
echo Installing Visual Studio..
curl -# -O https://c2rsetup.officeapps.live.com/c2r/downloadVS.aspx?sku=community&channel=Release&version=VS2022&source=VSLandingPage&cid=2030:b332b4071b1e4db9afa13625800e8de6
vs_Community.exe --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows11SDK.26100 --add Microsoft.VisualStudio.Component.Windows10SDK.10.0.19041.0 -p
del vs_Community.exe
echo Finished installing Visual Studio.

echo Would you like to install Haxe? (Y/N)
set /p choice= 
if /i "%choice%"=="Y" (
    echo Please run the installation. After entering any key, you will be redirected to the haxe download page.
    pause
    start https://haxe.org/download/version/4.3.2/
) else (
    echo Skipping Haxe installation.
)

echo  Would you like to install HaxeFlixel and necessary libraries? (Y/N)
set /p choice=
if /i "%choice%"=="Y" (
    echo Sit back and relax. We'll be done soon.
    echo Installing libraries via HMM..
    haxelib install hmm > /dev/null 2>&1
    hmm install > /dev/null 2>&1
) else (
    echo Skipping HaxeFlixel and necessary library installation.
)

echo Done! Compile Goldy Engine using 'lime build windows'. Or, there are build.bat files in the 'art' directory.