@echo off
title DemoGdotMuseum - Godot 4.3

echo [start.bat] Raeume alte Reste auf...
REM Wir nutzen PowerShell, um robust alle alten start.bat-cmd.exe-Fenster
REM und alle Godot-Editor-/Game-Prozesse zu beenden, OHNE uns selbst zu killen.
REM $PID = PowerShells eigene PID; dessen ParentProcessId = das cmd.exe,
REM das gerade diese start.bat ausfuehrt -> davon die Finger lassen.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$self = (Get-CimInstance Win32_Process -Filter ('ProcessId=' + $PID)).ParentProcessId; ^
  Get-CimInstance Win32_Process -Filter \"Name='cmd.exe' AND CommandLine LIKE '%%start.bat%%'\" ^| ^
    Where-Object { $_.ProcessId -ne $self } ^| ^
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }; ^
  Get-Process -ErrorAction SilentlyContinue godot, godot_console, Godot_v4_stable_win64, Godot_v4_3_stable_win64 ^| ^
    Stop-Process -Force -ErrorAction SilentlyContinue"

echo [start.bat] Starte Museum Demo...
start "" "D:\AntiGravitySoftware\GodotEngine\godot.exe" --path "%~dp0."
