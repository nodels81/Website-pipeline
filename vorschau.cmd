@echo off
rem vorschau.cmd - startet einen lokalen Webserver fuer ein fertiges Projekt und oeffnet den Browser.
rem Nutzung: vorschau.cmd delatec-de     (Doppelklick ohne Projektname fragt nach)
rem Funktioniert ohne PowerShell-Skriptfreigabe. Beenden: Fenster schliessen oder Strg+C.
setlocal
cd /d "%~dp0"
set "SLUG=%~1"
if "%SLUG%"=="" (
  echo Vorhandene Projekte:
  dir /b ausgang 2^>nul ^| findstr /v /i "\.zip \.tar\.gz \.gitkeep"
  set /p "SLUG=Projektname eingeben (z. B. delatec-de): "
)
set "DIR=ausgang\%SLUG%\website"
if not exist "%DIR%\index.html" set "DIR=projekte\%SLUG%\build\dist"
if not exist "%DIR%\index.html" (
  echo Keine fertige Website fuer "%SLUG%" gefunden.
  echo Erwartet: ausgang\%SLUG%\website\index.html oder projekte\%SLUG%\build\dist\index.html
  pause
  exit /b 1
)
echo.
echo Vorschau von %DIR%
echo Adresse: http://localhost:4321   (andere Geraete im WLAN: siehe "Network" unten)
echo Beenden: dieses Fenster schliessen
echo.
start "" cmd /c "timeout /t 4 >nul & start http://localhost:4321"
npx --yes serve "%DIR%" -l 4321
