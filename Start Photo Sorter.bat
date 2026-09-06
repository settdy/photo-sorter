@echo off
cd /d "%~dp0"

powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "%~dp0PhotoSorter.ps1"

if errorlevel 1 (
    echo.
    echo The Photo Sorter encountered an error.
    pause
)