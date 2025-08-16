#!/bin/bash
set -Eeuo pipefail

# === Variables ===
RUN_DIR="$(pwd -P)"
BITOREUM_DIR="$HOME/bitoreum-build"
SPECIAL_DELIVERY_DIR="$RUN_DIR/special-delivery"

BAKE_BREAD_LOG="$RUN_DIR/bake_bread.log"
BAKE_CREAMPIE_LOG="$RUN_DIR/bake_creampie.log"
BAKERY_LOG="$RUN_DIR/bakery.log"
PREVIOUS_BAKE_LOG="$RUN_DIR/previous_bake.log"

log() { echo -e "\033[1;32m[INFO] $1\033[0m"; }
err() { echo -e "\033[1;31m[ERROR] $1\033[0m" >&2; }

# Optional: nicer error on exit
trap 'err "Cleanup failed at line $LINENO."' ERR

# === Cleanup ===
# Remove the build dir if it exists (safety: ensure it lives under $HOME)
if [[ -d "$BITOREUM_DIR" ]]; then
  if [[ "$BITOREUM_DIR" == "$HOME/"* ]]; then
    log "Removing build directory: $BITOREUM_DIR"
    rm -rf -- "$BITOREUM_DIR"
  else
    err "Refusing to remove non-home path: $BITOREUM_DIR"
    exit 1
  fi
else
  log "No build directory to remove: $BITOREUM_DIR"
fi

# Remove special-delivery under the current RUN_DIR (safety: exact path match)
if [[ -d "$SPECIAL_DELIVERY_DIR" ]]; then
  if [[ "$SPECIAL_DELIVERY_DIR" == "$RUN_DIR/special-delivery" ]]; then
    log "Removing special-delivery directory: $SPECIAL_DELIVERY_DIR"
    rm -rf -- "$SPECIAL_DELIVERY_DIR"
  else
    err "Refusing to remove unexpected path: $SPECIAL_DELIVERY_DIR"
    exit 1
  fi
else
  log "No special-delivery directory to remove: $SPECIAL_DELIVERY_DIR"
fi

# Remove logs if present
log "Removing logs if present."
rm -f -- "$BAKE_BREAD_LOG" "$BAKE_CREAMPIE_LOG" "$PREVIOUS_BAKE_LOG" "$BAKERY_LOG"

log "The Kitchen is clean CHEF..."
