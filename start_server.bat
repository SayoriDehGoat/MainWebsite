@echo off
setlocal EnableExtensions
cd /d "%~dp0"
call "config\server.env.bat"

if not exist "%SERVER_DIR%\%PAPER_JAR%" (
  echo Paper is not installed yet. Run scripts\download-server.bat first.
  exit /b 1
)
if not exist "%PLAYIT_EXE%" (
  echo playit.exe was not found at "%PLAYIT_EXE%".
  echo Update PLAYIT_EXE in config\server.env.bat.
  exit /b 1
)

call :write_status online
call :start_playit
if errorlevel 1 (
  call :write_status offline
  exit /b 1
)

echo Starting Paper on Java port %JAVA_PORT%...
cd /d "%SERVER_DIR%"
java -Xms2G -Xmx4G -jar "%PAPER_JAR%" --nogui
set "SERVER_EXIT=%ERRORLEVEL%"
cd /d "%~dp0"
if defined PLAYIT_BEDROCK_PUBLIC_PORT (
  powershell -NoProfile -ExecutionPolicy Bypass -File "scripts\configure-geyser.ps1" -ConfigPath "%SERVER_DIR%\plugins\Geyser-Spigot\config.yml" -BedrockPort "%BEDROCK_PORT%" -BroadcastPort "%PLAYIT_BEDROCK_PUBLIC_PORT%"
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -File "scripts\configure-geyser.ps1" -ConfigPath "%SERVER_DIR%\plugins\Geyser-Spigot\config.yml" -BedrockPort "%BEDROCK_PORT%"
)

call :stop_owned_playit
call :write_status offline
exit /b %SERVER_EXIT%

:start_playit
if not exist "playit" mkdir "playit"
powershell -NoProfile -ExecutionPolicy Bypass -File "scripts\start-playit.ps1" -Executable "%PLAYIT_EXE%" -WorkingDirectory "%PLAYIT_WORKING_DIR%" -PidPath "%~dp0playit\playit.pid" -OwnershipPath "%~dp0playit\ownership.txt"
exit /b %ERRORLEVEL%

:stop_owned_playit
powershell -NoProfile -ExecutionPolicy Bypass -File "scripts\stop-playit.ps1" -Executable "%PLAYIT_EXE%" -PidPath "%~dp0playit\playit.pid" -OwnershipPath "%~dp0playit\ownership.txt"
exit /b 0

:write_status
powershell -NoProfile -ExecutionPolicy Bypass -Command "$status = '%~1'; $path = Join-Path (Get-Location) 'status.json'; $data = [ordered]@{ status=$status; javaAddress=$env:PLAYIT_JAVA_ADDRESS; bedrockAddress=$env:PLAYIT_BEDROCK_ADDRESS; players=@{online=0;max=0}; lastChecked=(Get-Date).ToUniversalTime().ToString('o'); responseMs=$null; version='Paper 1.21.11 + Geyser'; githubUrl=$env:GITHUB_REPO_URL }; $json = $data | ConvertTo-Json -Depth 4; [IO.File]::WriteAllText($path, $json, (New-Object Text.UTF8Encoding($false)))"
if not "%GITHUB_REPO_URL%"=="https://github.com/REPLACE-ME/minecraft-server" (
  git add status.json >nul 2>&1
  git diff --cached --quiet status.json >nul 2>&1 || git commit -m "Server %~1" -- status.json >nul 2>&1
  git push >nul 2>&1
)
exit /b 0
