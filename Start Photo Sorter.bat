@echo off
title Photo Sorter
cd /d "%~dp0"

echo For more information click on https://github.com/settdy/photo-sorter/blob/main/README.md
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "%~dp0PhotoSorter.ps1"

if errorlevel 1 (
    echo.
    echo The Photo Sorter encountered an error.
    pause
)