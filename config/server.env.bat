@echo off
rem Local configuration for the Minecraft Crossplay server.
rem Do not put GitHub tokens or playit secrets in this file.

set "SERVER_DIR=%~dp0..\server"
set "PAPER_JAR=paper-1.21.11-132.jar"
set "JAVA_PORT=25565"
set "BEDROCK_PORT=19132"

rem Existing playit agent executable. This file is only referenced, never modified.
rem Both servers share this agent and its Java tunnel, since only one runs at a time on port 25565.
set "PLAYIT_EXE=E:\TheWitherStorm\playit.exe"
set "PLAYIT_WORKING_DIR=E:\TheWitherStorm"

rem Public addresses shown on the website.
rem Java reuses the Wither Storm tunnel. Bedrock needs its own UDP tunnel in the playit.gg
rem dashboard (local UDP 127.0.0.1:19132); put its public address here once created.
set "PLAYIT_JAVA_ADDRESS=ireland-dis.gl.joinmc.link"
set "PLAYIT_BEDROCK_ADDRESS=CONFIGURE-PLAYIT-UDP-ADDRESS"
rem Optional: set this to the public UDP allocation port shown by playit.gg.
set "PLAYIT_BEDROCK_PUBLIC_PORT="

rem Set this to the HTTPS URL of the GitHub repository after creating it.
set "GITHUB_REPO_URL=https://github.com/SayoriDehGoat/MainWebsite"
