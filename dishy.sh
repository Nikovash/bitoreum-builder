#!/bin/bash
set -Eeuo pipefail

# ===========================
# Dishy The Kitchen Helper (dishy.sh)
# - Usage: ./dishy.sh [<coin_name>]
# - Defaults to "bitoreum" if not provided
# ===========================

# --- Args / Defaults ---
COIN_NAME="${1:-bitoreum}"

# --- Variables ---
RUN_DIR="$(pwd -P)"
BUILD_DIR="$HOME/${COIN_NAME}-build"
SPECIAL_DELIVERY_DIR="$RUN_DIR/special-delivery"
BAKE_BREAD_LOG="$RUN_DIR/bake_bread.log"
BAKE_CREAMPIE_LOG="$RUN_DIR/bake_creampie.log"
BAKERY_LOG="$RUN_DIR/bakery.log"
PREVIOUS_BAKE_LOG="$RUN_DIR/previous_bake.log"

# --- Logging Color & Behavior ---
log() { printf "\033[1;32m[INFO] %s\033[0m\n" "$@*"; }
err() { printf "\033[1;31m[ERROR] %s\033[0m\n" "$@" >&2; }


# --- Optional: nicer error on exit --- 
trap 'status=$?; cmd=$BASH_COMMAND; err "dishy failed (exit $status) at line $LINENO: $cmd"' ERR

# --- Main Cleanup Routine ---
log "HEARD — coin: $COIN_NAME"

# --- Remove the BUILD_DIR if it exists ---
if [[ -d "$BUILD_DIR" ]]; then
  if [[ "$BUILD_DIR" == "$HOME/"* && "$BUILD_DIR" != "$HOME" ]]; then
    log "Removing build directory: $BUILD_DIR"
    rm -rf -- "$BUILD_DIR"
  else
    err "Refusing to remove unsafe path: $BUILD_DIR"
    exit 1
  fi
else
  log "No previous recipe loaded to remove: $BUILD_DIR"
fi

# --- Remove special-delivery folder ---
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

# --- Remove logs if present ---
log "Shredding logs & wiping whiteboard, CHEF"
rm -f -- "$BAKE_BREAD_LOG" "$BAKE_CREAMPIE_LOG" "$PREVIOUS_BAKE_LOG"
: > "$BAKERY_LOG"
log "The kitchen is clean, CHEF..."
