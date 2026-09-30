@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0BUILD_v1.3.ps1"
set ERR=%ERRORLEVEL%
echo.
if not "%ERR%"=="0" (
  echo Build failed. Please review the message above.
) else (
  echo Build completed. Check the dist folder.
)
echo.
pause
exit /b %ERR%
