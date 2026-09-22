@echo off
REM Dungeon Corridor runner — double-click or run from a terminal.
REM The game reads stdin, so it must run in a real console.
cd /d "%~dp0"
set "GODOT=E:\Godot_v4.7.2-stable_win64_console.exe"
if not exist "%GODOT%" set "GODOT=godot"
"%GODOT%" --headless --script main.gd
if errorlevel 1 (
    echo.
    echo Failed to launch Godot. Edit the GODOT path at the top of this file.
)
pause
