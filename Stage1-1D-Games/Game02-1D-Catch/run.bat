@echo off
REM Catch the Firefly runner — double-click or run from a terminal.
REM The game reads stdin, so it must run in a real console.
cd /d "%~dp0"
set "GODOT=E:\Godot_v4.7.2-stable_win64_console.exe"
if not exist "%GODOT%" (
    echo Godot console build not found at: %GODOT%
    echo Edit the GODOT path at the top of this file.
    echo Use the *_console.exe build — the regular exe cannot read stdin.
    pause
    exit /b 1
)
"%GODOT%" --headless --script main.gd
pause
