@echo off
REM theraME Platform Manager - Windows Launcher
REM Launches the platform manager script in Git Bash or WSL

echo ========================================
echo   theraME Platform Manager v1.1.0
echo ========================================
echo.

REM Check if Git Bash is available
where git >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo Starting Platform Manager in Git Bash...
    "C:\Program Files\Git\bin\bash.exe" platform-manager.sh %*
) else (
    REM Try WSL if Git Bash is not available
    where wsl >nul 2>nul
    if %ERRORLEVEL% EQU 0 (
        echo Starting Platform Manager in WSL...
        wsl bash platform-manager.sh %*
    ) else (
        echo ERROR: Neither Git Bash nor WSL found!
        echo Please install Git for Windows or enable WSL.
        pause
        exit /b 1
    )
)

pause