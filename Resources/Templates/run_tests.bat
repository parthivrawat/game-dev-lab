@echo off
REM Test runner — copy into a game folder next to test_main.gd.
cd /d "%~dp0"
if not defined GODOT set "GODOT=E:\Godot_v4.7.2-stable_win64_console.exe"
if not exist "%GODOT%" (
    echo Godot console build not found at: %GODOT%
    echo Edit the GODOT path at the top of this file, or set a GODOT
    echo environment variable to your *_console.exe once for all games.
    pause
    exit /b 1
)
"%GODOT%" --headless --script test_main.gd
pause
