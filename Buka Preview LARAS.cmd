@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0fostifest_companion\preview_laras.ps1"
if errorlevel 1 pause
