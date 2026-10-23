@echo off
rem NEUER RECHNER: alles einspielen, ohne Rueckfragen
chcp 65001 >nul
cd /d "%~dp0"
echo.
echo   CLAUDE-UMZUG: ALLES WIEDERHERSTELLEN
echo   Vorher bitte Claude Desktop und Claude Code hier einmal gestartet und angemeldet haben.
echo   Claude wird gleich geschlossen. Vorhandene Daten werden vorher gesichert (*.vor-umzug-DATUM).
echo.
pause
where pwsh >nul 2>nul
if %errorlevel%==0 (set "PSEXE=pwsh") else (set "PSEXE=powershell")
%PSEXE% -NoProfile -ExecutionPolicy Bypass -File "%~dp0Wiederherstellen.ps1" -Schnell
echo.
pause
