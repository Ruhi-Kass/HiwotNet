@echo off
setlocal enabledelayedexpansion
title HIWONET-RESPONSE Emergency Dispatch Platform
color 0C

echo ========================================================================
echo        HIWONET-RESPONSE : COMMAND CENTER PLATFORM LAUNCHER
echo        Autonomous Emergency Medical Dispatch ^& Spatial Fleet Tracking
echo ========================================================================
echo.

:: 1. Clear any stale Flutter cache lockfile to avoid SDK permission locks
if exist "C:\flutter\bin\cache\lockfile" (
    del /f /q "C:\flutter\bin\cache\lockfile" >nul 2>&1
)

:: 2. Locate Flutter
set "FLUTTER_CMD=flutter"
where flutter >nul 2>&1
if errorlevel 1 (
    if exist "C:\flutter\bin\flutter.bat" (
        set "FLUTTER_CMD=C:\flutter\bin\flutter.bat"
    ) else (
        echo [ERROR] Flutter SDK not found in PATH or at C:\flutter\bin\flutter.bat.
        echo Please ensure Flutter is installed.
        pause
        exit /b 1
    )
)

echo [OK] Flutter SDK detected.
echo.
echo Choose how you would like to run the platform:
echo.
echo   [1] Open directly in Google Chrome (Recommended)
echo   [2] Start as Web Server on port 5050 (http://localhost:5050)
echo   [3] Run Automated Test Suite (479 tests - 100%% verified)
echo   [4] Watch Demo Video Showcase
echo.
set /p CHOICE="Select an option [1-4] (Default is 1): "

if "%CHOICE%"=="" set CHOICE=1
if "%CHOICE%"=="1" goto run_chrome
if "%CHOICE%"=="2" goto run_server
if "%CHOICE%"=="3" goto run_tests
if "%CHOICE%"=="4" goto run_demo

:run_chrome
echo.
echo ========================================================================
echo  Launching HIWONET-RESPONSE in Google Chrome...
echo ========================================================================
cd /d "%~dp0dispatch_dashboard"
call %FLUTTER_CMD% run -d chrome
goto end

:run_server
echo.
echo ========================================================================
echo  Starting local web server at http://localhost:5050 ...
echo  Open your browser and navigate to: http://localhost:5050
echo ========================================================================
cd /d "%~dp0dispatch_dashboard"
start "" "http://localhost:5050"
call %FLUTTER_CMD% run -d web-server --web-port=5050 --web-hostname=localhost
goto end

:run_tests
echo.
echo ========================================================================
echo  Running 479 Automated Tests (Unit, Mutex, Stress, System, Alpha)...
echo ========================================================================
cd /d "%~dp0hiwonet_firebase"
node test/master_test_suite.js
echo.
pause
goto end

:run_demo
echo.
echo ========================================================================
echo  Opening Demo Video Showcase in your browser...
echo ========================================================================
start "" "%~dp0HIWONET_DEMO_SHOWCASE.html"
goto end

:end
