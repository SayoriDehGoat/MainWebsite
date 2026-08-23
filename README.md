# Minecraft Crossplay Server

This folder contains a Paper Java Edition server with Geyser and Floodgate for Java + Bedrock crossplay, plus a GitHub Pages status dashboard.

## Layout

- `index.html`, `style.css`, `script.js`: GitHub Pages dashboard
- `status.json`: status data published by the launcher and watchdog
- `server/`: local server runtime and plugins; large/runtime files are ignored by Git
- `start_server.bat`: starts the server and the playit agent
- `stop_server.bat`: reminds you how to perform a clean server stop
- `.github/workflows/status-watchdog.yml`: scheduled status checker

## Before first start

1. Install Java 21 or newer. Java 25 is installed on the setup machine.
2. Review and accept the Minecraft EULA by changing `server/eula.txt` from `eula=false` to `eula=true`.
3. playit.gg: this server reuses the existing Wither Storm agent and its Java tunnel (`ireland-dis.gl.joinmc.link`) since only one server runs at a time on port 25565. In the same playit.gg dashboard, add a **Minecraft Bedrock** tunnel for UDP `127.0.0.1:19132`, enable `proxy-protocol-v2`, and note its public allocation port.
4. Set `PLAYIT_JAVA_ADDRESS`, `PLAYIT_BEDROCK_ADDRESS`, and `PLAYIT_BEDROCK_PUBLIC_PORT` in `config/server.env.bat`.
5. Set `GITHUB_REPO_URL` in the same file after creating the GitHub repository.
6. Run `scripts/download-server.bat` once to fetch Paper, Geyser, Floodgate, and ViaVersion.
7. The launcher automatically applies `auth-type: floodgate` and the configured Bedrock UDP port after Paper has generated the Geyser config during its first clean shutdown. Once `PLAYIT_BEDROCK_PUBLIC_PORT` is set, it also applies the Playit broadcast port and HAProxy protocol setting.

The launcher references `E:\TheWitherStorm\playit.exe` by default and does not copy, modify, or kill that existing server. It uses `E:\TheWitherStorm` as the playit working directory so the existing agent configuration can be reused. If either path differs, update `PLAYIT_EXE` and `PLAYIT_WORKING_DIR` in `config/server.env.bat`.

## Starting

Run `start_server.bat`. It updates `status.json`, starts the playit agent, and launches Paper. The status is set to offline when Paper exits. The launcher uses a dedicated playit process PID file, so it does not terminate unrelated playit agents.

Run `stop_server.bat` only as a reminder, then type `stop` in the visible `start_server.bat` console for a clean shutdown. Do not force-kill Java while the world is saving; the GitHub Actions watchdog is intended to correct a stale website status after an unexpected exit.

## GitHub Pages

Publish this folder as a repository (or configure Pages to serve this folder through your chosen repository layout). Set the Pages source to the branch/folder containing `index.html`.

The launcher needs a GitHub remote configured and a credential that can push `status.json`. The watchdog needs repository write permission. In the repository settings, enable **Settings -> Actions -> General -> Workflow permissions -> Read and write permissions**, or provide a fine-grained token as `STATUS_REPO_TOKEN` if your organization disallows the default token.

Set these repository variables for the watchdog:

- `MC_JAVA_ADDRESS`: the public playit Java hostname, optionally with `:port`
- `MC_BEDROCK_ADDRESS`: the public playit Bedrock hostname and port for display
- `GITHUB_REPO_URL`: repository URL displayed by the dashboard

The watchdog checks the Java Server List Ping endpoint every five minutes and commits status changes. GitHub Actions cannot directly test Bedrock UDP from the hosted runner, so the Bedrock address is displayed but online status is based on the Java endpoint.

## Important limitation

A GitHub Pages site is static. It cannot directly query the Minecraft server from the browser. The page reads the committed `status.json`; the launcher and watchdog are the processes that update it.

Minecraft is a trademark of Mojang Studios. This project is not affiliated with Mojang or Microsoft.
