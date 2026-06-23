#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG="$ROOT/logs/wolvenkit-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "$ROOT/logs"
cd "$ROOT"
/home/tehlappy/.local/bin/wolvenkit/WolvenKit.CLI project build 2>&1 | tee "$LOG" >/dev/null
printf '%s\n' "$LOG" > "$ROOT/.last_build_log"
