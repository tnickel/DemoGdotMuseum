@echo off
title Museum Demo VR - Godot 4.3

echo Pruefe ob SteamVR laeuft...
tasklist /FI "IMAGENAME eq vrserver.exe" 2>NUL | find /I /N "vrserver.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo SteamVR laeuft bereits!
) else (
    echo SteamVR ist nicht aktiv! Starte SteamVR...
    start steam://run/250820
    echo Warte 8 Sekunden, bis SteamVR hochgefahren ist...
    timeout /t 8 /nobreak > NUL
)

echo.
echo Starte Museum Demo im VR-Modus (PSVR2 / SteamVR)...
"D:\AntiGravitySoftware\GodotEngine\godot.exe" --path "%~dp0." --xr-mode on
