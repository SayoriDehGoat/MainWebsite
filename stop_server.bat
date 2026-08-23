@echo off
setlocal EnableExtensions
cd /d "%~dp0"

where node >nul 2>&1
if errorlevel 1 goto :reminder

echo Sending a clean stop command to the server...
node "scripts\rcon.mjs" "stop"
if errorlevel 1 goto :reminder

echo.
echo Stop requested. Paper is saving and shutting down; the launcher will then
echo flip the site to OFFLINE and stop the playit agent automatically.
goto :eof

:reminder
echo.
echo Could not stop the server automatically. In the start_server.bat window, type:
echo   stop
echo then press Enter. Do not force-kill Java while the world is saving.
