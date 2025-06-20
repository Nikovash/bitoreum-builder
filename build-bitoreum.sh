#!/bin/bash
set -e

log() {
    echo -e "\033[1;32m[INFO] $1\033[0m"
}
err() {
    echo -e "\033[1;31m[ERROR] $1\033[0m" >&2
}

# === Launch screen if not already inside ===
if [[ "$1" != "--in-screen" ]]; then
    if ! screen -list | grep -q "\.Build"; then
        log "Opening screen session 'Build' (attached)..."
        exec screen -S Build bash -c "$0 --in-screen"
    else
        log "Screen session 'Build' already exists. You can reattach with:"
        echo "    screen -r Build"
        exit 1
    fi
fi

log "Inside screen session 'Build'..."

# === System setup ===
sudo apt update
sudo apt dist-upgrade -y
sudo apt-get install -y git curl build-essential libtool autotools-dev automake pkg-config \
    python3 bsdmainutils cmake libdb-dev libdb++-dev screen zlib1g-dev libx11-dev libxext-dev \
    libxrender-dev libxft-dev libxrandr-dev libffi-dev

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
echo "5) ❌ Cancel and exit"
echo

ARCH_NATIVE=$(uname -m)
case "$ARCH_NATIVE" in
  x86_64) SUGGESTED="1" ;;
  i686|i386) SUGGESTED="2" ;;
  armv7l) SUGGESTED="3" ;;
  aarch64) SUGGESTED="4" ;;
  *) SUGGESTED="1" ;;
esac

read -rp "Enter your choice [1-5] (default: $SUGGESTED): " ARCH_CHOICE
ARCH_CHOICE=${ARCH_CHOICE:-$SUGGESTED}

case "$ARCH_CHOICE" in
  1) HOST_TRIPLE="x86_64-pc-linux-gnu" ;;
  2) HOST_TRIPLE="i686-pc-linux-gnu" ;;
  3) HOST_TRIPLE="arm-linux-gnueabihf" ;;
  4) HOST_TRIPLE="aarch64-linux-gnu" ;;
  5)
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
touch build.log config.log
./autogen.sh
./configure --prefix="$(pwd)/depends/${HOST_TRIPLE}" 2>&1 | tee config.log
make -j$(nproc) 2>&1 | tee build.log

# === Copy and organize outputs ===
BUILD_DIR="$HOME/bitoreum-build/build"
COMPRESS_DIR="$HOME/bitoreum-build/compressed"
mkdir -p "${BUILD_DIR}/bitoreum-build" "${BUILD_DIR}_not_strip/bitoreum-build" "${BUILD_DIR}_debug/bitoreum-build" "$COMPRESS_DIR"

cp src/{bitoreum-cli,bitoreumd,bitoreum-tx,qt/bitoreum-qt} "${BUILD_DIR}/bitoreum-build"
mv src/{bitoreum-cli,bitoreumd,bitoreum-tx,qt/bitoreum-qt} "${BUILD_DIR}_not_strip/bitoreum-build"
strip "${BUILD_DIR}/bitoreum-build/"*

# === Build debug version ===
make clean && make distclean
touch build_debug.log config_debug.log
./autogen.sh
./configure --prefix="$(pwd)/depends/${HOST_TRIPLE}" --disable-tests --enable-debug 2>&1 | tee config_debug.log
make -j$(nproc) 2>&1 | tee build_debug.log
mv src/{bitoreum-cli,bitoreumd,bitoreum-tx,qt/bitoreum-qt} "${BUILD_DIR}_debug/bitoreum-build"

# === Version & packaging ===
VERSION=$(grep '^release-version=' build.properties | cut -d'=' -f2)
COIN_NAME=bitoreum
ARCH_TYPE=$(uname -m)
OS="$(. /etc/os-release && echo "${ID}-${VERSION_ID}")"

for TYPE in "" "_debug" "_not_strip"; do
    OUT_DIR="${BUILD_DIR}${TYPE}"
    cd "$OUT_DIR"
    CHECKSUM_FILE="checksums-${VERSION}.txt"
    echo "sha256:" > "$CHECKSUM_FILE"
    shasum * >> "$CHECKSUM_FILE"
    echo "openssl-sha256:" >> "$CHECKSUM_FILE"
    sha256sum * >> "$CHECKSUM_FILE"
    tar -cf - -C "$OUT_DIR" . | gzip -9 > "${COMPRESS_DIR}/${COIN_NAME}-${OS}_${ARCH_TYPE}${TYPE}-${VERSION}.tar.gz"
done

cd "$COMPRESS_DIR"
for FILE in *.tar.gz; do
    echo "sha256: $(shasum "$FILE")" >> "checksums-${VERSION}.txt"
    echo "openssl-sha256: $(sha256sum "$FILE")" >> "checksums-${VERSION}.txt"
done

log "✅ Build completed and ready for upload!"
