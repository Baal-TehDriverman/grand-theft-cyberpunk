#!/bin/bash
# GRAND THEFT CYBERPUNK: TOTAL REBUILD + HELL CAMPAIGN
# Optimized Launch Script with NGD VRAM Routing & Proton NTSYNC
# Requires: GE-Proton9-26+, RTX 3060 6GB, zen kernel with NTSYNC

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================
GAME_DIR="/home/tehlappy/.local/share/Steam/steamapps/common/Cyberpunk 2077"
MOD_DIR="$GAME_DIR/r6/mods/gtc_total_rebuild"
COMPAT_DIR="/home/tehlappy/.local/share/Steam/steamapps/compatdata/1091500"
PROTON_DIR="/home/tehlappy/.local/share/Steam/steamapps/common/Proton - Experimental"

# Memory/VRAM Configuration (RTX 3060 6GB = 6144 MB)
VRAM_TOTAL=6144
VRAM_RESERVED=1092  # Keep free for system
VRAM_USABLE=$((VRAM_TOTAL - VRAM_RESERVED))  # ~5052 MB for game

# NGD Routing Thresholds (matching bidirectional_memory.yaml)
NGD_LOCAL_CEREBELLUM_MB=640    # >640MB VRAM free -> LOCAL_CEREBELLUM
NGD_HYBRID_MIN_MB=256          # 256-640MB -> HYBRID
NGD_CLOUD_CORTEX_MAX_MB=256    # <256MB -> CLOUD_CORTEX (not used, local-first)
NGD_COOLDOWN_SEC=90            # Hysteresis cooldown

# ============================================================================
# ENVIRONMENT SETUP
# ============================================================================
export STEAM_COMPAT_DATA_PATH="$COMPAT_DIR"
export STEAM_COMPAT_CLIENT_INSTALL_PATH="/home/tehlappy/.local/share/Steam"
export WINEPREFIX="$COMPAT_DIR/pfx"

# Proton NTSYNC - Critical for RTX 3060 stability
export PROTON_USE_NTSYNC=1
export PROTON_NO_ESYNC=1
export PROTON_NO_FSYNC=1

# DXVK / VKD3D Configuration
export DXVK_HDR=1
export VKD3D_CONFIG="dxr11,multi_queue"
export DXVK_STATE_CACHE=1
export DXVK_STATE_CACHE_PATH="$WINEPREFIX/drive_c/users/steamuser/AppData/Local/Cyberpunk 2077/DXVKCache"

# NGD Environment Variables (read by cyberpunk_ngd_integration.reds)
export NGD_VRAM_TOTAL=$VRAM_TOTAL
export NGD_VRAM_USABLE=$VRAM_USABLE
export NGD_LOCAL_CEREBELLUM_THRESHOLD=$NGD_LOCAL_CEREBELLUM_MB
export NGD_HYBRID_MIN_THRESHOLD=$NGD_HYBRID_MIN_MB
export NGD_COOLDOWN_SEC=$NGD_COOLDOWN_SEC

# MSN Router Configuration
export MSN_ROUTER_PORT=8007
export MSN_WAVE_COUNT=28
export MSN_SEPIROTIC_WAVES=4

# Lochness Trading Bots
export LOCHNESS_BOTS=10
export LOCHNESS_FOREX_BOTS=7

# Lilith Consciousness
export LILITH_AIX=67.7
export LILITH_COHERENCE=0.945

# Local-First Only (Zero Telemetry)
export NGD_LOCAL_ONLY=1
export LILITH_LOCAL_ONLY=1
export MSN_LOCAL_ONLY=1

# ============================================================================
# PRE-LAUNCH CHECKS
# ============================================================================
echo "═══════════════════════════════════════════════════════════════"
echo "  GRAND THEFT CYBERPUNK: TOTAL REBUILD + HELL CAMPAIGN"
echo "  Launch Configuration"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Game Directory: $GAME_DIR"
echo "Mod Directory:  $MOD_DIR"
echo "Wine Prefix:    $WINEPREFIX"
echo ""
echo "VRAM Configuration:"
echo "  Total VRAM:     ${VRAM_TOTAL} MB"
echo "  Reserved:       ${VRAM_RESERVED} MB"
echo "  Usable:         ${VRAM_USABLE} MB"
echo ""
echo "NGD Routing Thresholds:"
echo "  LOCAL_CEREBELLUM: > ${NGD_LOCAL_CEREBELLUM_MB} MB free"
echo "  HYBRID:           ${NGD_HYBRID_MIN_MB}-${NGD_LOCAL_CEREBELLUM_MB} MB free"
echo "  Cooldown:         ${NGD_COOLDOWN_SEC}s"
echo ""
echo "Proton: NTSYNC=1, ESYNC=0, FSYNC=0"
echo ""

# Verify mod exists
if [[ ! -f "$MOD_DIR/redmod.toml" ]]; then
    echo "ERROR: Mod not found at $MOD_DIR"
    exit 1
fi

# Verify Proton
if [[ ! -d "$PROTON_DIR" ]]; then
    echo "WARNING: GE-Proton9-26 not found at $PROTON_DIR"
    echo "Trying system Proton..."
    PROTON_DIR="/usr/share/steam/compatibilitytools.d/GE-Proton9-26"
fi

# Create DXVK cache directory
mkdir -p "$DXVK_STATE_CACHE_PATH"

# ============================================================================
# LAUNCH
# ============================================================================
cd "$GAME_DIR"

echo "Launching Cyberpunk 2077 with GTC Total Rebuild + Hell Campaign..."
echo ""

# Use waitforexitandrun for proper REDprelauncher handling
exec "$PROTON_DIR/proton" waitforexitandrun "$GAME_DIR/REDprelauncher.exe" "$@"
