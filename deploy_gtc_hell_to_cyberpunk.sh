#!/bin/bash
set -euo pipefail
MOD_BUILD_DIR="/home/tehlappy/.local/share/Steam/steamapps/common/Cyberpunk 2077/r6/mods/gtc_total_rebuild"
STEAM_MODS_DIR="/home/tehlappy/.local/share/Steam/steamapps/common/Cyberpunk 2077/r6/mods"
INSTALL_NAME="gtc_total_rebuild_wip"
LOG_DIR="/home/tehlappy/Desktop/AI/Pub/logs"
LOG="$LOG_DIR/gtc_redmod_build.log"
REPORT="$LOG_DIR/gtc_build_report.json"
mkdir -p "$LOG_DIR"
export PUB_ROOT="${PUB_ROOT:-/home/tehlappy/Desktop/AI/Pub/00_CORE_SERVICES/quantum_paradox_terminal}"
export HERMES_HOME="${HERMES_HOME:-/home/tehlappy/.hermes}"
cd "$MOD_BUILD_DIR"
if [[ -x "$MOD_BUILD_DIR/bin/build.sh" ]]; then
  "$MOD_BUILD_DIR/bin/build.sh" > "$LOG" 2>&1 || true
else
  /home/tehlappy/.local/bin/wolvenkit/WolvenKit.CLI project build > "$LOG" 2>&1 || true
fi
python3 - <<'PY'
import json, os
from pathlib import Path
report = {
    "status": "attempted",
    "build_dir": "/home/tehlappy/.local/share/Steam/steamapps/common/Cyberpunk 2077/r6/mods/gtc_total_rebuild",
    "install_dir": "/home/tehlappy/.local/share/Steam/steamapps/common/Cyberpunk 2077/r6/mods",
    "attempt": os.path.exists("/home/tehlappy/Desktop/AI/Pub/logs/gtc_redmod_build.log"),
}
print(json.dumps(report, indent=2))
PY
true
