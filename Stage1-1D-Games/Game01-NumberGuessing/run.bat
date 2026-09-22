@echo off
REM Number Guessing runner — double-click or run from a terminal.
REM The game reads stdin, so it must run in a real console.
cd /d "%~dp0"
godot --headless --script main.gd
if errorlevel 9009 (
    echo.
    echo 'godot' was not found on PATH. Either add it, or run with the full path:
    echo   "E:\Games\Godot\Godot_v4.x.x_win64.exe" --headless --script main.gd
)
pause
