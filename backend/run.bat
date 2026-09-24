@echo off
REM Payano FastAPI Backend Startup Script
REM Usage: run.bat [port]

SET PORT=%1
IF "%PORT%"=="" SET PORT=8000

echo.
echo ========================================
echo  Payano FastAPI Backend
echo  Starting on http://localhost:%PORT%
echo ========================================
echo.

cd /d "%~dp0"

REM Check Python is available
python --version >nul 2>&1
IF ERRORLEVEL 1 (
    echo ERROR: Python is not installed or not in PATH
    pause
    exit /b 1
)

REM Install dependencies if needed
pip install -q -r requirements.txt

REM Start the server
set PORT=%PORT%
python main.py

pause
