@echo off
REM Payano Backend - Node.js Express Server on port 5000
echo.
echo ========================================
echo   Payano Backend API (Node.js)
echo   Starting on http://localhost:5000
echo ========================================
echo.

cd /d "%~dp0functions"

REM Verify Node.js is installed
node --version >nul 2>&1
IF ERRORLEVEL 1 (
    echo [ERROR] Node.js is not found in PATH!
    pause
    exit /b 1
)

node index.js
pause
