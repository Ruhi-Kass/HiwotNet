@echo off
title HIWONET-RESPONSE Test Suite Runner
color 0A

echo ========================================================================
echo   HIWONET-RESPONSE : MULTI-TIER AUTOMATED TEST RUNNER (479 TESTS)
echo ========================================================================
echo.

where node >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Node.js is not found in your PATH.
    echo Please install Node.js from https://nodejs.org/
    pause
    exit /b 1
)

cd /d "%~dp0hiwonet_firebase"
node test/master_test_suite.js

echo.
echo ========================================================================
echo Testing completed. Press any key to close this window.
echo ========================================================================
pause >nul
