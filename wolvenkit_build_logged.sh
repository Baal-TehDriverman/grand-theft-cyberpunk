#!/bin/bash
set -euo pipefail
MOD_BUILD_DIR="/home/tehlappy/.local/share/Steam/steamapps/common/Cyberpunk 2077/r6/mods/gtc_total_rebuild"
STEAM_MODS_DIR="/home/tehlappy/.local/share/Steam/steamapps/common/Cyberpunk 2077/r6/mods"
INSTALL_NAME="gtc_total_rebuild_wip"
LOG="/home/tehlappy/Desktop/AI/Pub/logs/gtc_redmod_build.log"
mkdir -p "$(dirname "$LOG")"

cd "$MOD_BUILD_DIR"
/home/tehlappy/.local/bin/wolvenkit/WolvenKit.CLI project build > "$LOG" 2>&1 || true

if grep -qiE 'build (finished|complete|succeeded)|no errors|Completed' "$LOG"; then
  set +e
  find "$MOD_BUILD_DIR" -maxdepth 4 -type f \( -iname '*.redmod' -o -name '*.archive' \) | head -n 50
  set -e
else
  echo 'Build likely failed; log follows:'
  tail -n 120 "$LOG"
fi
