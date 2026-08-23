@echo off
setlocal EnableExtensions
cd /d "%~dp0\.."
call "config\server.env.bat"

if not exist "server\plugins" mkdir "server\plugins"
set "UA=GithubWebsite-MinecraftServer/1.0 (local setup)"

echo Downloading Paper %PAPER_JAR%...
curl -fL -A "%UA%" "https://fill-data.papermc.io/v1/objects/5ffef465eeeb5f2a3c23a24419d97c51afd7dbb4923ff42df9a3f58bba1ccfba/paper-1.21.11-132.jar" -o "server\%PAPER_JAR%" || exit /b 1

echo Downloading Geyser 2.11.2...
curl -fL -A "%UA%" "https://download.geysermc.org/v2/projects/geyser/versions/2.11.2/builds/latest/downloads/spigot" -o "server\plugins\Geyser-Spigot.jar" || exit /b 1

echo Downloading Floodgate 2.2.5...
curl -fL -A "%UA%" "https://download.geysermc.org/v2/projects/floodgate/versions/2.2.5/builds/latest/downloads/spigot" -o "server\plugins\floodgate-spigot.jar" || exit /b 1

echo Downloading ViaVersion 5.11.0 stable...
curl -fL -A "%UA%" "https://hangarcdn.papermc.io/plugins/ViaVersion/ViaVersion/versions/5.11.0/PAPER/ViaVersion-5.11.0.jar" -o "server\plugins\ViaVersion.jar" || exit /b 1

echo.
echo Downloads complete. Start the server once to generate plugin configs.
echo Then set auth-type: floodgate in server\plugins\Geyser-Spigot\config.yml if needed.
