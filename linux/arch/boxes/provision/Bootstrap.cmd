@echo off
rem Entry point for the provisioning CD. Re-launches itself elevated, then runs
rem provision.ps1 from whichever drive this CD happens to be mounted on.

net session >nul 2>&1
if errorlevel 1 (
    echo Requesting administrator rights...
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo.
echo  Provisioning Win11 guest from %~dp0
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0provision.ps1" %*
exit /b %errorlevel%
