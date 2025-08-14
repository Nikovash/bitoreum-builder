#!/bin/bash
set -euo pipefail
shopt -s expand_aliases
alias python=python3.10
alias python3=python3.10


# === Variables ===
BAKE_VERSION="0.9"
PWD_EXPR="$(pwd)"
REPO_ROOT="$HOME/bitoreum-build/bitoreum"

# Path to first-run marker (system-wide)
BAKE_INIT="/opt/bake/bake.log"

# Folder where the script was launched (don’t use $0; we want the run dir)
RUN_DIR="$(pwd -P)"
# Local session log
BAKE_PROCESS_LOG="$RUN_DIR/bake_bread.log"
: > "$BAKE_PROCESS_LOG"
# Previous successful depends build config
PREVIOUS_BAKE_LOG="$RUN_DIR/previous_bake.log"

log() {
    echo -e "\033[1;32m[INFO] $1\033[0m" | tee -a "$BAKE_PROCESS_LOG"
}
err() {
    echo -e "\033[1;31m[ERROR] $1\033[0m" | tee -a "$BAKE_PROCESS_LOG" >&2
}

# === Check for existing repo folder ===
if [[ -d "$HOME/bitoreum-build/bitoreum" && -n "$(ls -A "$HOME/bitoreum-build/bitoreum" 2>/dev/null)" ]]; then
    log "This script only bakes fresh recipies! To modify a previous bake, please use refire.sh"
    exit 1
fi

# === Start Build Process ===
log "Starting build..."

# === Determine First Run ===
if [[ ! -f "$BAKE_INIT" ]]; then
    FIRST_RUN=true
else
    FIRST_RUN=false
fi

log "First run: $FIRST_RUN"

# === Determine First Run ===
if [[ "$FIRST_RUN" == true ]]; then
    log "Performing first run setup..."
    sudo mkdir -p /opt/bake
    sudo tee "$BAKE_INIT" > /dev/null <<EOF
# Bake configuration
BAKE_VERSION=0.9
SCRIPT_INSTALL=${RUN_DIR}
EOF
    log "Configuration file created at $BAKE_INIT"
# === System setup (first run) ===
    log "Updating and upgrading system packages..."
    sudo apt update
    sudo apt dist-upgrade -y
    sudo apt-get install -y git curl build-essential libtool autotools-dev automake pkg-config \
        python3 bsdmainutils cmake libdb-dev libdb++-dev screen zlib1g-dev libx11-dev libxext-dev \
        libxrender-dev libxft-dev libxrandr-dev libffi-dev g++-aarch64-linux-gnu zip unzip
else
# === Update config file on subsequent runs ===
    sudo tee "$BAKE_INIT" > /dev/null <<EOF
# Bake configuration
BAKE_VERSION=$BAKE_VERSION
SCRIPT_INSTALL=$RUN_DIR
EOF
    log "Bake version & Run_Dir has been updated"
# === System setup (subsequent runs) ===
    log "Updating and installing required packages..."
    sudo apt update
    sudo apt-get install -y git curl build-essential libtool autotools-dev automake pkg-config \
        python3 bsdmainutils cmake libdb-dev libdb++-dev screen zlib1g-dev libx11-dev libxext-dev \
        libxrender-dev libxft-dev libxrandr-dev libffi-dev g++-aarch64-linux-gnu zip unzip
fi
    
# === Python 3.10.17 ===
PYTHON_SRC="/usr/src/Python-3.10.17"
if [ ! -d "$PYTHON_SRC" ]; then
    log "Installing Python 3.10.17..."
    cd /usr/src
    sudo wget https://www.python.org/ftp/python/3.10.17/Python-3.10.17.tgz
    sudo tar -xzf Python-3.10.17.tgz
    cd Python-3.10.17
    sudo ./configure --enable-optimizations
    sudo make -j$(nproc)
    sudo make altinstall
else
    log "Python 3.10.17 already installed."
fi

export PATH="/usr/bin:$PATH"

# === Clone repo ===
mkdir -p ~/bitoreum-build
cd ~/bitoreum-build

read -rp "Clone from 'main' or specify a branch name (case-sensitive)? [main/branch-name]: " CHOICE
if [ "$CHOICE" = "main" ]; then
    git clone https://github.com/Nikovash/bitoreum
else
    git clone https://github.com/Nikovash/bitoreum -b "$CHOICE"
fi

    log "Branch $CHOICE has been downloaded"
    
cd bitoreum/depends

# === Select build architecture ===
echo
echo "🔧 Select build target:"
echo "1) Linux 64-bit        (x86_64-pc-linux-gnu)"
echo "2) Linux 32-bit        (i686-pc-linux-gnu)"
echo "3) Linux ARM 32-bit    (arm-linux-gnueabihf)"
echo "4) Linux ARM 64-bit    (aarch64-linux-gnu)"
echo "5) Raspberry Pi 4+     (aarch64-linux-gnu)"
echo "6) Oracle Ampere ARM   (aarch64-linux-gnu)"
echo "7) Windows 64-bit      (x86_64-w64-mingw32)"
echo "8) Cancel and exit"
echo

ARCH_NATIVE=$(uname -m)
IS_PI4_OR_NEWER=false
IS_AMPERE=false
IS_WINDOWS=false

# === Detect Pi Model Number ===
if [[ -f /proc/device-tree/model ]]; then
    PI_MODEL=$(tr -d '\0' < /proc/device-tree/model)
    if echo "$PI_MODEL" | grep -qiE "raspberry pi ([4-9]|[1-9][0-9])"; then
        IS_PI4_OR_NEWER=true
    fi
fi

# === Detect Oracle Ampere CPU ===
if lscpu | grep -qiE "ampere|neoverse-n1"; then
    IS_AMPERE=true
fi

if $IS_PI4_OR_NEWER; then
  SUGGESTED="5"
elif $IS_AMPERE; then
  SUGGESTED="6"
else
  case "$ARCH_NATIVE" in
    x86_64) SUGGESTED="1" ;;
    i686|i386) SUGGESTED="2" ;;
    armv7l) SUGGESTED="3" ;;
    aarch64) SUGGESTED="4" ;;
    *) SUGGESTED="1" ;;
  esac
fi

read -rp "Enter your choice [1-8] (default: $SUGGESTED): " ARCH_CHOICE
ARCH_CHOICE=${ARCH_CHOICE:-$SUGGESTED}

PI4_BUILD=false
AMPERE_BUILD=false

case "$ARCH_CHOICE" in
  1) HOST_TRIPLE="x86_64-pc-linux-gnu" ;;
  2) HOST_TRIPLE="i686-pc-linux-gnu" ;;
  3) HOST_TRIPLE="arm-linux-gnueabihf" ;;
  4) HOST_TRIPLE="aarch64-linux-gnu" ;;
  5) HOST_TRIPLE="aarch64-linux-gnu"; PI4_BUILD=true ;;
  6) HOST_TRIPLE="aarch64-linux-gnu"; AMPERE_BUILD=true ;;
  7) HOST_TRIPLE="x86_64-w64-mingw32"; IS_WINDOWS=true ;;
  8) echo -e "\033[1;31m[EXIT] Build cancelled by user.\033[0m"; exit 0 ;;
  *) echo -e "\033[1;31m[ERROR] Invalid selection.\033[0m"; exit 1 ;;
esac
    log "Using HOST=${HOST_TRIPLE}"

# === Ask if QT should be built ===
read -rp "Build with QT (GUI Core Wallet)? [Y/n]: " QT_CHOICE
QT_CHOICE=${QT_CHOICE:-Y}

if [[ "$QT_CHOICE" =~ ^[Nn]$ ]]; then
#    NO_QT=1
    BUILD_QT=false
    QT_OPTS="--with-gui=no"
else
    BUILD_QT=true
    QT_OPTS=""
fi
    log "Will build QT: $BUILD_QT"
    
# === Per-target binary names (respect QT choice) ===
if $IS_WINDOWS; then
    if $BUILD_QT; then
        BINFILES=(bitoreum-cli.exe bitoreumd.exe bitoreum-tx.exe qt/bitoreum-qt.exe)
    else
        BINFILES=(bitoreum-cli.exe bitoreumd.exe bitoreum-tx.exe)
    fi
else
    if $BUILD_QT; then
        BINFILES=(bitoreum-cli bitoreumd bitoreum-tx qt/bitoreum-qt)
    else
        BINFILES=(bitoreum-cli bitoreumd bitoreum-tx)
    fi
fi

# === Windows toolchain (and proper strip) ===
if $IS_WINDOWS; then
  log "Installing MinGW-w64 toolchain..."
  sudo apt-get install -y g++-mingw-w64-x86-64 gcc-mingw-w64-x86-64 binutils-mingw-w64-x86-64 nsis
  sudo update-alternatives --set x86_64-w64-mingw32-gcc /usr/bin/x86_64-w64-mingw32-gcc-posix
  sudo update-alternatives --set x86_64-w64-mingw32-g++ /usr/bin/x86_64-w64-mingw32-g++-posix
  log "Attempting Windows_x86_64 Cross Compile Build"
fi

# === PI4 toggle ===
PI4_BUILD="${PI4_BUILD:-false}"

if [[ "$PI4_BUILD" == true ]]; then
  PWD_EXPR="`pwd`"
  CONFIGURE_HOST_OPTS="--host=depends/aarch64-linux-gnu"
  log "Attempting Raspberry 4+ build..."
else
  CONFIGURE_HOST_OPTS=""
fi

# === Build depends ===

# === Temp Export ===
export FALLBACK_DOWNLOAD_PATH=https://bitoreum.cc/depends/
# End Export Fallback ===

touch build.log
make -j$(nproc) HOST=${HOST_TRIPLE} 2>&1 | tee build.log

# Only reached if 'make depends' succeeded
{
  echo "HOST_TRIPLE=$HOST_TRIPLE"
  echo "IS_PI4_OR_NEWER=$PI4_BUILD"
  echo "IS_AMPERE=$IS_AMPERE"
  echo "IS_WINDOWS=$IS_WINDOWS"
  echo "NO_QT=${NO_QT:-0}"
} > "$PREVIOUS_BAKE_LOG"

log "Recorded Depends Build config to $PREVIOUS_BAKE_LOG"

# === Configure and build ===
cd "$REPO_ROOT"

# === Get version string ===
if [[ -f build.properties ]]; then
    VERSION=$(grep '^release-version=' build.properties | cut -d'=' -f2)
else
    VERSION=$(date +%Y%m%d-%H%M%S)
    echo "release-version=$VERSION" > build.properties
    log "Warning, build.properties not found — using fallback version: $VERSION"
fi
BIN_SUBDIR="bitoreum-v${VERSION}"

touch build.log config.log
./autogen.sh

# Report configure command for syntax
	log "./configure --prefix=\"${PWD_EXPR}/depends/${HOST_TRIPLE}\" \
	${CONFIGURE_HOST_OPTS} ${QT_OPTS} 2>&1 | tee config.log"
# End


./configure --prefix="${PWD_EXPR}/depends/${HOST_TRIPLE}" \
    ${CONFIGURE_HOST_OPTS} ${QT_OPTS} 2>&1 | tee config.log

make -j"$(nproc)" 2>&1 | tee build.log

# === Organize & Create Outputs ===
BUILD_DIR="$HOME/bitoreum-build/build"
COMPRESS_DIR="$HOME/bitoreum-build/compressed"
mkdir -p "${BUILD_DIR}/${BIN_SUBDIR}" "${BUILD_DIR}_not_strip/${BIN_SUBDIR}" "${BUILD_DIR}_debug/${BIN_SUBDIR}" "$COMPRESS_DIR"

# Copy into stripped and not_strip trees (with missing binary check)
for BIN in "${BINFILES[@]}"; do
  [[ -f "src/${BIN}" ]] || { err "Missing binary: src/${BIN}"; exit 1; }
  cp "src/${BIN}" "${BUILD_DIR}/${BIN_SUBDIR}/"
  cp "src/${BIN}" "${BUILD_DIR}_not_strip/${BIN_SUBDIR}/"
done

# === Strip ALL builds (use correct strip tool per target) ===
if $IS_WINDOWS; then
  STRIP_TOOL="x86_64-w64-mingw32-strip"
else
  STRIP_TOOL="strip"
fi
"$STRIP_TOOL" "${BUILD_DIR}/${BIN_SUBDIR}/"* || err "strip failed"

# === Build debug version (unstripped by design) ===
make clean && make distclean
touch build_debug.log config_debug.log
./autogen.sh

# Report configure command for syntax
	log "./configure --prefix=\"${PWD_EXPR}/depends/${HOST_TRIPLE}\" ${CONFIGURE_HOST_OPTS} ${QT_OPTS} --enable-debug"
# End

./configure --prefix="${PWD_EXPR}/depends/${HOST_TRIPLE}" \
    ${CONFIGURE_HOST_OPTS} ${QT_OPTS} --enable-debug 2>&1 | tee config_debug.log
make -j"$(nproc)" 2>&1 | tee build_debug.log

# Copy debug builds (with missing binary check)
for BIN in "${BINFILES[@]}"; do
  [[ -f "src/${BIN}" ]] || { err "Missing debug binary: src/${BIN}"; exit 1; }
  cp "src/${BIN}" "${BUILD_DIR}_debug/${BIN_SUBDIR}/"
done

# === Copressed file Nmae Variables ===
COIN_NAME=bitoreum
if $PI4_BUILD; then
    ARCH_TYPE="pi4"
elif $AMPERE_BUILD; then
    ARCH_TYPE="ampere-aarch64"
elif $IS_WINDOWS; then
    ARCH_TYPE="win64"
else
    ARCH_TYPE=$(uname -m)
fi
OS="$(. /etc/os-release && echo "${ID}-${VERSION_ID}")"

# === Compress and checksum ===
for TYPE in "" "_debug" "_not_strip"; do
    OUTER_DIR="${BUILD_DIR}${TYPE}"
    BIN_DIR="${OUTER_DIR}/${BIN_SUBDIR}"
    CHECKSUM_FILE="${BIN_DIR}/checksums-${VERSION}.txt"

    cd "$OUTER_DIR" || continue

    echo "sha256:" > "$CHECKSUM_FILE"
    find "$BIN_SUBDIR" -type f -exec shasum -a 256 {} \; >> "$CHECKSUM_FILE" || true
    echo "openssl-sha256:" >> "$CHECKSUM_FILE"
    find "$BIN_SUBDIR" -type f -exec sha256sum {} \; >> "$CHECKSUM_FILE"

    echo -e "\n📂 Contents of $BIN_DIR:"
    ls -lh "$BIN_DIR"

    if [[ -f "${BIN_DIR}/${BINFILES[0]}" ]]; then
        if $IS_WINDOWS; then
            ARCHIVE_NAME="${COIN_NAME}-${ARCH_TYPE}${TYPE}-${VERSION}.zip"
            (cd "$OUTER_DIR" && zip -r "${COMPRESS_DIR}/${ARCHIVE_NAME}" "$BIN_SUBDIR") || err "zip failed for $TYPE"
        else
            ARCHIVE_NAME="${COIN_NAME}-${OS}_${ARCH_TYPE}${TYPE}-${VERSION}.tar.gz"
            tar -cf - "$BIN_SUBDIR" | gzip -9 > "${COMPRESS_DIR}/${ARCHIVE_NAME}" || err "tar failed for $TYPE"
        fi
        log "Compressed: $ARCHIVE_NAME"
    else
        err "Missing binaries in $BIN_DIR — skipping compression."
    fi
done

# === Final global checksum (all archives) ===
cd "$COMPRESS_DIR"
if ls *.tar.gz >/dev/null 2>&1 || ls *.zip >/dev/null 2>&1; then
    GLOBAL_SUM="checksums-${VERSION}.txt"
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
