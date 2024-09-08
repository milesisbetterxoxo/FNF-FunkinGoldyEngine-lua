@echo off
cls
color 0a
echo Setting up necessary stuff for Goldy Engine.. (P.S this is not a virus. Code made by @milesisbetterxoxo.)
echo Installing Visual Studio..
echo Please install Visual Studio Community 2022, then select these Individual Components:
echo MSVC v143 - VS 2022 C++ x64/86 build tools (latest)
echo Windows Universal C Runtime
echo Windows SDK (any latest version available)
pause

:: Start Visual Studio installer with URL parameters properly encoded
start "" "https://visualstudio.microsoft.com/thank-you-downloading-visual-studio/?sku=Community&channel=Release&version=VS2022&source=VSLandingPage&passive=false&cid=2030"

pause
echo Would you like to install Haxe? (Y/N)
set /p choice= 
if /i "%choice%"=="Y" (
    echo Please run the installation. After entering any key, you will be redirected to the Haxe download page.
    pause
    start "" "https://haxe.org/download/version/4.3.2/"
) else (
    echo Skipping Haxe installation.
)

echo Sit back and relax. We'll be done soon.
echo Installing libraries via HMM..
echo This command prompt will exit later. Check install_log.txt for details.

:: Capture output and errors from haxelib and hmm commands
haxelib install hmm > install_log.txt 2>&1
if %ERRORLEVEL% neq 0 (
    echo Failed to install hmm. >>install_log.txt 2>&1
)

hmm install >> install_log.txt 2>&1
if %ERRORLEVEL% neq 0 (
    echo Failed to install libraries using hmm. >>install_log.txt 2>&1
)