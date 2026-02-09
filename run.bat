@echo off
REM Quick start script for PC Tweaks

echo ========================================
echo PC Tweaks System - Quick Start
echo ========================================
echo.

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python is not installed
    echo.
    echo Please install Python 3.8 or higher from:
    echo https://www.python.org/downloads/
    echo.
    echo Make sure to check "Add Python to PATH" during installation
    echo.
    pause
    exit /b 1
)

echo Python is installed
echo.

REM Check if dependencies are installed
python -c "import psutil" >nul 2>&1
if errorlevel 1 (
    echo Installing dependencies...
    pip install -r requirements.txt
    if errorlevel 1 (
        echo ERROR: Failed to install dependencies
        pause
        exit /b 1
    )
    echo.
)

echo Starting PC Tweaks...
echo.
echo ========================================
echo.

REM Run the application
python main.py

echo.
echo ========================================
echo Application closed
echo ========================================
pause
