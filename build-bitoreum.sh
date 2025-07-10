#!/bin/bash
set -e

log() {
    echo -e "\033[1;32m[INFO] $1\033[0m"
}
err() {
    echo -e "\033[1;31m[ERROR] $1\033[0m" >&2
}

log "Starting build..."

# === System setup ===
sudo apt update
sudo apt dist-upgrade -y
sudo apt-get install -y git curl build-essential libtool autotools-dev automake pkg-config \
    python3 bsdmainutils cmake libdb-dev libdb++-dev screen zlib1g-dev libx11-dev libxext-dev \
    libxrender-dev libxft-dev libxrandr-dev libffi-dev g++-aarch64-linux-gnu zip unzip
    
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

alias python=python3.10
alias python3=python3.10
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
echo "7) Cancel and exit"
echo

ARCH_NATIVE=$(uname -m)
IS_PI4_OR_NEWER=false
IS_AMPERE=false

if [[ -f /proc/device-tree/model ]]; then
    PI_MODEL=$(tr -d '\0' < /proc/device-tree/model)
    if echo "$PI_MODEL" | grep -Eq "Raspberry Pi [4-9]"; then
        IS_PI4_OR_NEWER=true
    fi
fi

# Detect Oracle Ampere CPU
if lscpu | grep -qi "Ampere"; then
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

read -rp "Enter your choice [1-7] (default: $SUGGESTED): " ARCH_CHOICE
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
  7)
    echo -e "\033[1;31m[EXIT] Build cancelled by user.\033[0m"
    exit 0
    ;;
  *)
    echo -e "\033[1;31m[ERROR] Invalid selection.\033[0m"
    exit 1
    ;;
esac

log "Using HOST=${HOST_TRIPLE}"

# === Build depends ===
touch build.log
make -j$(nproc) HOST=${HOST_TRIPLE} 2>&1 | tee build.log

# === Configure and build ===
cd ..

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
./configure --prefix="$(pwd)/depends/${HOST_TRIPLE}" \
    --disable-tests --disable-bench 2>&1 | tee config.log
make -j$(nproc) 2>&1 | tee build.log

# === Copy and organize outputs ===
BUILD_DIR="$HOME/bitoreum-build/build"
COMPRESS_DIR="$HOME/bitoreum-build/compressed"
mkdir -p "${BUILD_DIR}/${BIN_SUBDIR}" "${BUILD_DIR}_not_strip/${BIN_SUBDIR}" "${BUILD_DIR}_debug/${BIN_SUBDIR}" "$COMPRESS_DIR"

cp src/bitoreum-cli src/bitoreumd src/bitoreum-tx src/qt/bitoreum-qt "${BUILD_DIR}/${BIN_SUBDIR}"
mv src/bitoreum-cli src/bitoreumd src/bitoreum-tx src/qt/bitoreum-qt "${BUILD_DIR}_not_strip/${BIN_SUBDIR}"
strip "${BUILD_DIR}/${BIN_SUBDIR}/"*

# === Build debug version ===
make clean && make distclean
touch build_debug.log config_debug.log
./autogen.sh
./configure --prefix="$(pwd)/depends/${HOST_TRIPLE}" \
    --disable-tests --disable-bench --enable-debug 2>&1 | tee config_debug.log
make -j$(nproc) 2>&1 | tee build_debug.log
mv src/bitoreum-cli src/bitoreumd src/bitoreum-tx src/qt/bitoreum-qt "${BUILD_DIR}_debug/${BIN_SUBDIR}"

COIN_NAME=bitoreum
if $PI4_BUILD; then
    ARCH_TYPE="pi4"
elif $AMPERE_BUILD; then
    ARCH_TYPE="ampere-aarch64"
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
    # Use SHA-256 for cross-platform consistency. "shasum" defaults to
    # SHA-1 which mismatches the "sha256" label.
    find "$BIN_SUBDIR" -type f -exec shasum -a 256 {} \; >> "$CHECKSUM_FILE"
    echo "openssl-sha256:" >> "$CHECKSUM_FILE"
    find "$BIN_SUBDIR" -type f -exec sha256sum {} \; >> "$CHECKSUM_FILE"

    echo -e "\n📂 Contents of $BIN_DIR:"
    ls -lh "$BIN_DIR"

    if [[ -f "${BIN_DIR}/bitoreumd" && -f "${BIN_DIR}/bitoreum-cli" ]]; then
        ARCHIVE_NAME="${COIN_NAME}-${OS}_${ARCH_TYPE}${TYPE}-${VERSION}.tar.gz"
        tar -cf - "$BIN_SUBDIR" | gzip -9 > "${COMPRESS_DIR}/${ARCHIVE_NAME}" || err "tar failed for $TYPE"
        log "Compressed: $ARCHIVE_NAME"
    else
        err "Missing binaries in $BIN_DIR — skipping compression."
    fi
done

# === Final global checksum (for all .tar.gz files) ===
cd "$COMPRESS_DIR"
if ls *.tar.gz >/dev/null 2>&1; then
    GLOBAL_SUM="checksums-${VERSION}.txt"
    for FILE in *.tar.gz; do
        # Again ensure SHA-256 is used when generating archive level checksums
        echo "sha256: $(shasum -a 256 "$FILE")" >> "$GLOBAL_SUM"
        echo "openssl-sha256: $(sha256sum "$FILE")" >> "$GLOBAL_SUM"
    done
    log "Compression complete. Files saved in $COMPRESS_DIR"
else
    err "No .tar.gz files were created."
fi

echo
echo -e "\033[1;32mBuild process complete.\033[0m"
echo -e "Artifacts are in: \033[1;36m$COMPRESS_DIR\033[0m"
