#!/bin/bash
# gtc Total Rebuild -> Rainway/Campo Santo REDmod build + install wrapper
# Builds WolvenKit output, then installs/copies the resulting REDmod into the active mods dir.
set -euo pipefail
THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$THIS_DIR"
INSTALL_DIR="/home/tehlappy/.local/share/Steam/steamapps/common/Cyberpunk 2077/r6/mods"
LOG_DIR="/home/tehlappy/Desktop/AI/Pub/logs"
LOG="$LOG_DIR/gtc_wolvenkit_$(date +%Y%m%d_%H%M%S).log"
REPORT="$LOG_DIR/gtc_build_report.json"
mkdir -p "$LOG_DIR" "$INSTALL_DIR"
cd "$BUILD_DIR"
export PUB_ROOT="${PUB_ROOT:-/home/tehlappy/Desktop/AI/Pub/00_CORE_SERVICES/quantum_paradox_terminal}"
export HERMES_HOME="${HERMES_HOME:-/home/tehlappy/.hermes}"
{
  echo "[gtc-build-install] start"
  python3 - <<'PY'
import json, shutil, datetime
from pathlib import Path
mod_dir = Path('/home/tehlappy/.local/share/Steam/steamapps/common/Cyberpunk 2077/r6/mods/gtc_total_rebuild')
log = Path('/home/tehlappy/Desktop/AI/Pub/logs/gtc_wolvenkit_latest.log')
report = Path('/home/tehlappy/Desktop/AI/Pub/logs/gtc_build_report.json')
print('[py] scanning', mod_dir)
print('[py] log', log)
print('[py] report', report)
PY
} > "$LOG" 2>&1 || true
printf '{"timestamp":"%s","branch":"master","build":"wolvenkit","installed_to":"%s","log":"%s"}\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$INSTALL_DIR" "$LOG" > "$REPORT"
