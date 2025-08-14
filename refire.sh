#!/bin/bash
set -e

# === Variables ===
PWD_USAGE="$(pwd)"
RUN_DIR="$(pwd -P)"
BITOREUM_DIR="$HOME/bitoreum-build/bitoreum"
BUILD_DIR="$HOME/bitoreum-build/build"             # where we'll stage binaries
COMPRESS_DIR="$HOME/bitoreum-build/compress"       # where we'll drop archives/checksums
BAKE_PROCESS_LOG="$RUN_DIR/bake_creampie.log"
PREVIOUS_BAKE_LOG="$RUN_DIR/previous_bake.log"

# === Logging ===
log() { echo -e "\033[1;32m[INFO] $1\033[0m" | tee -a "$BAKE_PROCESS_LOG"; }
err() { echo -e "\033[1;31m[ERROR] $1\033[0m" | tee -a "$BAKE_PROCESS_LOG" >&2; }

# Ensure log exists early
: > "$BAKE_PROCESS_LOG" || { echo "[ERROR] Can't write $BAKE_PROCESS_LOG"; exit 1; }

# Ensure base output dirs exist
mkdir -p "$BUILD_DIR" "$BUILD_DIR"_debug "$BUILD_DIR"_not_strip "$COMPRESS_DIR"

# === Preconditions ===
has_files="$(find "$BITOREUM_DIR" -mindepth 1 -type f -print -quit 2>/dev/null)"
if [[ -d "$BITOREUM_DIR" && -n "$has_files" && -s "$PREVIOUS_BAKE_LOG" ]]; then
  NUMBER=$(( RANDOM % 24 + 1 ))
  log "Refire Table $NUMBER"
else
  log "Something messy happened, use dishy.sh and bake again from scratch"
  exit 1
fi

# === Load previous bake variables (expects key=value lines) ===
if [[ -s "$PREVIOUS_BAKE_LOG" ]]; then
  # shellcheck disable=SC1090
  source "$PREVIOUS_BAKE_LOG"
else
  log "Missing or empty $PREVIOUS_BAKE_LOG — cannot load build settings"
  exit 1
fi

log "Loaded previous bake recipe:"
log "HOST_TRIPLE=$HOST_TRIPLE"
log "IS_PI4_OR_NEWER=$IS_PI4_OR_NEWER"
log "IS_AMPERE=$IS_AMPERE"
log "IS_WINDOWS=$IS_WINDOWS"
log "NO_QT=${NO_QT:-0}"

# === Ask user action ===
echo
log "Select an option:"
echo "  1) Keep Base Recipe {DEPENDS}, Modify only ./configure options (default)"
echo "  2) Start Over - Destructive"
echo "  3) Cancel / Quit"
echo

read -rp "Enter choice [1-3]: " USER_CHOICE
USER_CHOICE=${USER_CHOICE:-1}

case "$USER_CHOICE" in
  1)
    log "Keeping Depends, modifying configurable options..."


    cd "$BITOREUM_DIR" || { err "Failed to cd into $BITOREUM_DIR"; exit 1; }
    make clean || true
    make distclean || true
    ./autogen.sh

    : > config.log
    : > build.log

    if [[ -n "${HOST_TRIPLE:-}" ]]; then
      ./configure \
        --prefix="$(pwd)/depends/${HOST_TRIPLE}" \
        --host="${HOST_TRIPLE}" \
        $CONFIGURE_OPTS 2>&1 | tee config.log
    else
      ./configure $CONFIGURE_OPTS 2>&1 | tee config.log
    fi

    make -j"$(nproc)" 2>&1 | tee build.log
    ;;

  2)
    log "Delete everything and start again"
    cd "$RUN_DIR" || { err "Failed to cd into $RUN_DIR"; exit 1; }
    ./dishy.sh
    ./bake.sh
    exit 0
    ;;

  3)
    log "User chose to cancel REFIRE, Exiting without modifying anything..."
    exit 0
    ;;

  *)
    err "Invalid choice: $USER_CHOICE | quit..."
    exit 1
    ;;
esac

# === Prepare version & staging dirs ===
if [[ -f build.properties ]]; then
  VERSION="$(grep -E '^release-version=' build.properties | cut -d'=' -f2-)"
else
  VERSION="$(date +%Y%m%d-%H%M%S)"
  echo "release-version=$VERSION" > build.properties
  log "Warning, build.properties not found — using fallback version: $VERSION"
fi

BIN_SUBDIR="bitoreum-v${VERSION}"

# Ensure staging trees exist for all three variants
mkdir -p "${BUILD_DIR}/${BIN_SUBDIR}" \
         "${BUILD_DIR}_not_strip/${BIN_SUBDIR}" \
         "${BUILD_DIR}_debug/${BIN_SUBDIR}"

# === Per-target binary names ===
BINFILES=(bitoreum-cli bitoreumd bitoreum-tx qt/bitoreum-qt)
if [[ "$IS_WINDOWS" == "true" ]]; then
  BINFILES=(bitoreum-cli.exe bitoreumd.exe bitoreum-tx.exe qt/bitoreum-qt.exe)
fi

# === Copy built binaries into staging ===
for BIN in "${BINFILES[@]}"; do
  if [[ -f "src/${BIN}" ]]; then
    cp "src/${BIN}" "${BUILD_DIR}/${BIN_SUBDIR}/"
    cp "src/${BIN}" "${BUILD_DIR}_not_strip/${BIN_SUBDIR}/"
    cp "src/${BIN}" "${BUILD_DIR}_debug/${BIN_SUBDIR}/"
  else
    err "Missing built binary: src/${BIN}"
  fi
done

# === Strip 'release' tree (not the _not_strip or _debug) ===
if [[ "$IS_WINDOWS" == "true" ]]; then
  STRIP_TOOL="x86_64-w64-mingw32-strip"
elif [[ -n "${HOST_TRIPLE:-}" ]]; then
  # Try triplet strip if present; fall back to 'strip'
  STRIP_TOOL="${HOST_TRIPLE}-strip"
  command -v "$STRIP_TOOL" >/dev/null 2>&1 || STRIP_TOOL="strip"
else
  STRIP_TOOL="strip"
fi

if compgen -G "${BUILD_DIR}/${BIN_SUBDIR}/*" >/dev/null; then
  "$STRIP_TOOL" "${BUILD_DIR}/${BIN_SUBDIR}/"* || err "strip failed"
fi

# === Archive naming helpers ===
COIN_NAME="bitoreum"
if [[ "$IS_PI4_OR_NEWER" == "true" ]]; then
  ARCH_TYPE="pi4"
elif [[ "$IS_AMPERE" == "true" ]]; then
  ARCH_TYPE="ampere-aarch64"
elif [[ "$IS_WINDOWS" == "true" ]]; then
  ARCH_TYPE="win64"
else
  ARCH_TYPE="$(uname -m)"
fi
OS="$(. /etc/os-release && echo "${ID}-${VERSION_ID}")"

# === Compress and checksum ===
for TYPE in "" "_debug" "_not_strip"; do
  OUTER_DIR="${BUILD_DIR}${TYPE}"
  BIN_DIR="${OUTER_DIR}/${BIN_SUBDIR}"
  CHECKSUM_FILE="${BIN_DIR}/checksums-${VERSION}.txt"

  [[ -d "$BIN_DIR" ]] || { err "Missing bin dir $BIN_DIR"; continue; }
  ( cd "$OUTER_DIR" || exit 0

    echo "sha256:" > "$CHECKSUM_FILE"
    find "$BIN_SUBDIR" -type f -exec shasum -a 256 {} \; >> "$CHECKSUM_FILE" || true
    echo "openssl-sha256:" >> "$CHECKSUM_FILE"
    find "$BIN_SUBDIR" -type f -exec sha256sum {} \; >> "$CHECKSUM_FILE"

    echo -e "\n📂 Contents of $BIN_DIR:"
    ls -lh "$BIN_DIR"

    if [[ -f "${BIN_DIR}/$(basename "${BINFILES[0]}")" ]]; then
      if [[ "$IS_WINDOWS" == "true" ]]; then
        ARCHIVE_NAME="${COIN_NAME}-${ARCH_TYPE}${TYPE}-${VERSION}.zip"
        zip -r "${COMPRESS_DIR}/${ARCHIVE_NAME}" "$BIN_SUBDIR" >/dev/null
      else
        ARCHIVE_NAME="${COIN_NAME}-${OS}_${ARCH_TYPE}${TYPE}-${VERSION}.tar.gz"
        tar -cf - "$BIN_SUBDIR" | gzip -9 > "${COMPRESS_DIR}/${ARCHIVE_NAME}"
      fi
      log "Compressed: $ARCHIVE_NAME"
    else
      err "Missing binaries in $BIN_DIR — skipping compression."
    fi
  )
done

# === Final global checksum (all archives) ===
cd "$COMPRESS_DIR"
if ls *.tar.gz >/dev/null 2>&1 || ls *.zip >/dev/null 2>&1; then
  GLOBAL_SUM="checksums-${VERSION}.txt"
  : > "$GLOBAL_SUM"
  for FILE in *.tar.gz *.zip 2>/dev/null; do
    [[ -f "$FILE" ]] || continue
    echo "sha256: $(shasum -a 256 "$FILE")" >> "$GLOBAL_SUM" || true
    echo "openssl-sha256: $(sha256sum "$FILE")" >> "$GLOBAL_SUM"
  done
  log "Compression complete. Files saved in $COMPRESS_DIR"
else
  err "No archives were created."
fi

echo
echo -e "\033[1;32mBuild process complete.\033[0m"
echo -e "Artifacts are in: \033[1;36m$COMPRESS_DIR\033[0m"
