@echo off
rem ALTER RECHNER: Bestandsaufnahme + Sicherung von allem, ohne Rueckfragen
chcp 65001 >nul
cd /d "%~dp0"
echo.
echo   CLAUDE-UMZUG: ALLES SICHERN
echo   Claude Desktop und Claude Code werden gleich geschlossen.
echo   Vorher offene Arbeit in Claude abschliessen.
echo   Mitgenommen werden auch Schluessel und Anmeldedaten (SSH, .env, Erweiterungen).
echo.
pause
where pwsh >nul 2>nul
if %errorlevel%==0 (set "PSEXE=pwsh") else (set "PSEXE=powershell")
%PSEXE% -NoProfile -ExecutionPolicy Bypass -File "%~dp0Inventur.ps1"
%PSEXE% -NoProfile -ExecutionPolicy Bypass -File "%~dp0Sichern.ps1" -Schnell
echo.
echo   FERTIG. Ergebnis steht in pruefung.txt. Platte abziehen, am neuen Rechner 2-ALLES-WIEDERHERSTELLEN.bat starten.
pause
