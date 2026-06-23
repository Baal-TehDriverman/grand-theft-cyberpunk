#!/bin/bash
# GRAND THEFT CYBERPUNK - TOTAL REBUILD + HELL CAMPAIGN
# WolvenKit Compilation Script
# Builds the complete GTC + Hell Campaign mod as a single REDmod

set -euo pipefail

MOD_DIR="/home/tehlappy/.local/share/Steam/steamapps/common/Cyberpunk 2077/r6/mods/gtc_total_rebuild"
WOLVENKIT_CLI="${WOLVENKIT_CLI:-/home/tehlappy/.local/share/Steam/steamapps/common/WolvenKit/WolvenKit.CLI}"
OUTPUT_DIR="${MOD_DIR}/dist"
RED_MOD_NAME="gtc_total_rebuild_hell.redmod"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "═══════════════════════════════════════════════════════════════"
echo "  GRAND THEFT CYBERPUNK: TOTAL REBUILD + HELL CAMPAIGN"
echo "  WolvenKit REDmod Compilation"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Check WolvenKit CLI
if [[ ! -f "$WOLVENKIT_CLI" ]]; then
    log_warn "WolvenKit CLI not found at $WOLVENKIT_CLI"
    log_warn "Searching for WolvenKit..."
    WOLVENKIT_CLI=$(find /home/tehlappy -name "WolvenKit.CLI" -type f 2>/dev/null | head -1)
    if [[ -z "$WOLVENKIT_CLI" ]]; then
        log_error "WolvenKit CLI not found. Please install WolvenKit 8.18+ or set WOLVENKIT_CLI env var"
        exit 1
    fi
    log_info "Found WolvenKit at: $WOLVENKIT_CLI"
fi

# Verify mod structure
log_info "Verifying mod structure..."

REQUIRED_DIRS=(
    "$MOD_DIR/tweakdb"
    "$MOD_DIR/tweakdb/reds"
    "$MOD_DIR/scripts"
    "$MOD_DIR/world"
    "$MOD_DIR/locales/en"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [[ ! -d "$dir" ]]; then
        log_error "Missing directory: $dir"
        exit 1
    fi
done

log_success "All required directories present"

# Count files
TWEAKDB_YAML=$(find "$MOD_DIR/tweakdb" -name "*.yaml" | wc -l)
TWEAKDB_REDS=$(find "$MOD_DIR/tweakdb/reds" -name "*.reds" | wc -l)
SCRIPTS=$(find "$MOD_DIR/scripts" -name "*.reds" | wc -l)
WORLD=$(find "$MOD_DIR/world" -name "*.yaml" | wc -l)
LOCALES=$(find "$MOD_DIR/locales" -name "*.json" -o -name "*.loc" | wc -l)

log_info "File counts:"
log_info "  TweakDB YAML: $TWEAKDB_YAML"
log_info "  TweakDB REDS: $TWEAKDB_REDS"
log_info "  Scripts: $SCRIPTS"
log_info "  World: $WORLD"
log_info "  Locales: $LOCALES"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Step 1: Compile REDscripts
log_info "Step 1/6: Compiling REDscripts..."
"$WOLVENKIT_CLI" compile scripts \
    --input "$MOD_DIR/scripts" \
    --output "$OUTPUT_DIR/scripts" \
    --game-version "2.12" \
    --red4ext-version "1.30.0"

if [[ $? -ne 0 ]]; then
    log_error "REDscript compilation failed"
    exit 1
fi
log_success "REDscripts compiled"

# Step 2: Process TweakDB YAML files
log_info "Step 2/6: Processing TweakDB YAML files..."

# Process main tweakdb files
for yaml_file in "$MOD_DIR/tweakdb"/*.yaml; do
    if [[ -f "$yaml_file" ]]; then
        basename=$(basename "$yaml_file" .yaml)
        log_info "  Processing $basename.yaml..."
        "$WOLVENKIT_CLI" tweakdb process \
            --input "$yaml_file" \
            --output "$OUTPUT_DIR/tweakdb/$basename.reds" \
            --game-version "2.12"
    fi
done

# Process per-circle REDS (already converted)
for reds_file in "$MOD_DIR/tweakdb/reds"/*.reds; do
    if [[ -f "$reds_file" ]]; then
        basename=$(basename "$reds_file")
        log_info "  Copying $basename..."
        cp "$reds_file" "$OUTPUT_DIR/tweakdb/reds/"
    fi
done

log_success "TweakDB processed"

# Step 3: Process World/Map files
log_info "Step 3/6: Processing World files..."
"$WOLVENKIT_CLI" world process \
    --input "$MOD_DIR/world" \
    --output "$OUTPUT_DIR/world" \
    --game-version "2.12"

log_success "World files processed"

# Step 4: Process Localization
log_info "Step 4/6: Processing Localization..."
"$WOLVENKIT_CLI" localization process \
    --input "$MOD_DIR/locales" \
    --output "$OUTPUT_DIR/localization" \
    --languages "en,pl,ru,fr,de,es,ja,zh,it,pt" \
    --game-version "2.12"

log_success "Localization processed"

# Step 5: Package REDmod
log_info "Step 5/6: Packaging REDmod archive..."
"$WOLVENKIT_CLI" package create \
    --input "$OUTPUT_DIR" \
    --output "$OUTPUT_DIR/$RED_MOD_NAME" \
    --manifest "$MOD_DIR/redmod.toml" \
    --compression "zlib" \
    --encryption "aes256"

if [[ $? -ne 0 ]]; then
    log_error "REDmod packaging failed"
    exit 1
fi
log_success "REDmod packaged: $OUTPUT_DIR/$RED_MOD_NAME"

# Step 6: Verify
log_info "Step 6/6: Verifying REDmod..."
"$WOLVENKIT_CLI" package verify \
    --input "$OUTPUT_DIR/$RED_MOD_NAME"

log_success "REDmod verified!"

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  BUILD COMPLETE!"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Output: $OUTPUT_DIR/$RED_MOD_NAME"
echo ""
echo "To install:"
echo "  1. Copy $RED_MOD_NAME to:"
echo "     /home/tehlappy/.local/share/Steam/steamapps/common/Cyberpunk 2077/mods/"
echo "  2. Launch with Proton NTSYNC:"
echo "     PROTON_USE_NTSYNC=1 PROTON_NO_ESYNC=1 PROTON_NO_FSYNC=1 \\"
echo "     waitforexitandrun ./REDprelauncher.exe"
echo ""
echo "NGD Routing for Hell Circles:"
echo "  Circle 1-2 (Limbo, Lust):     HYBRID_OK"
echo "  Circle 3-5 (Gluttony-Wrath):  LOCAL_REQUIRED"
echo "  Circle 6-11 (Heresy+):        LOCAL_CEREBELLUM"
echo ""
echo "Console Commands:"
echo "  hell.status          - Campaign status"
echo "  hell.descend         - Descend to next circle"
echo "  hell.lucifer.speak   - Trigger Lucifer dialogue"
echo "  hell.space.templates - List space battle templates"
echo "  hell.space.launch    - Launch space combat"
echo "  hell.quest.list      - List all Hell quests"
echo ""
