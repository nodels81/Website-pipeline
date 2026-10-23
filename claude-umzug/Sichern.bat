@echo off
rem Startet Sichern.ps1 per Doppelklick (PowerShell 7, falls vorhanden, sonst Windows PowerShell)
chcp 65001 >nul
cd /d "%~dp0"
where pwsh >nul 2>nul
if %errorlevel%==0 (set "PSEXE=pwsh") else (set "PSEXE=powershell")
%PSEXE% -NoProfile -ExecutionPolicy Bypass -File "%~dp0Sichern.ps1" %*
echo.
pause
