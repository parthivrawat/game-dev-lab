@echo off
REM 1D Pong test runner — double-click or run from a terminal.
cd /d "%~dp0"
set "GODOT=E:\Godot_v4.7.2-stable_win64_console.exe"
if not exist "%GODOT%" (
    echo Godot console build not found at: %GODOT%
    echo Edit the GODOT path at the top of this file.
    pause
    exit /b 1
)
"%GODOT%" --headless --script test_main.gd
pause
