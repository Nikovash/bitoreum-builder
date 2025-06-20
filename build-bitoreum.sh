#!/bin/bash

set -e

log() {
    echo -e "\033[1;32m[INFO] $1\033[0m"
}

err() {
    echo -e "\033[1;31m[ERROR] $1\033[0m" >&2
}

if [[ "$1" != "--in-screen" ]]; then
    if ! screen -list | grep -q "\.Build"; then
        log "Launching a screen session named 'Build'..."
        screen -dmS Build bash -c "$0 --in-screen"
        exit 0
    else
        log "Screen session 'Build' is already running or attached."
        exit 1
    fi
fi

log "Inside screen session 'Build'..."
sudo apt update
sudo apt dist-upgrade -y
sudo apt-get install -y git curl build-essential libtool autotools-dev automake pkg-config python3 bsdmainutils cmake libdb-dev libdb++-dev screen zlib1g-dev libx11-dev libxext-dev libxrender-dev libxft-dev libxrandr-dev libffi-dev

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
fi

alias python=python3.10
alias python3=python3.10
export PATH="/usr/bin:$PATH"

mkdir -p ~/bitoreum-build
cd ~/bitoreum-build

read -rp "Clone from 'main' or specify a branch name (case-sensitive)? [main/branch-name]: " CHOICE

if [ "$CHOICE" = "main" ]; then
    git clone https://github.com/Nikovash/bitoreum
else
    git clone https://github.com/Nikovash/bitoreum -b "$CHOICE"
fi

cd bitoreum/depends
touch build.log
make -j$(nproc) HOST=aarch64-linux-gnu 2>&1 | tee build.log

cd ..
touch build.log config.log
./autogen.sh
./configure --prefix="$(pwd)/depends/aarch64-linux-gnu" 2>&1 | tee config.log
make -j$(nproc) 2>&1 | tee build.log

BUILD_DIR="$HOME/bitoreum-build/build"
COMPRESS_DIR="$HOME/bitoreum-build/compressed"
mkdir -p "${BUILD_DIR}/bitoreum-build" "${BUILD_DIR}_not_strip/bitoreum-build" "${BUILD_DIR}_debug/bitoreum-build" "$COMPRESS_DIR"

cp src/{bitoreum-cli,bitoreumd,bitoreum-tx,qt/bitoreum-qt} "${BUILD_DIR}/bitoreum-build"
mv src/{bitoreum-cli,bitoreumd,bitoreum-tx,qt/bitoreum-qt} "${BUILD_DIR}_not_strip/bitoreum-build"
strip "${BUILD_DIR}/bitoreum-build/"*

make clean && make distclean
touch build_debug.log config_debug.log
./autogen.sh
./configure --prefix="$(pwd)/depends/aarch64-linux-gnu" --disable-tests --enable-debug 2>&1 | tee config_debug.log
make -j$(nproc) 2>&1 | tee build_debug.log
mv src/{bitoreum-cli,bitoreumd,bitoreum-tx,qt/bitoreum-qt} "${BUILD_DIR}_debug/bitoreum-build"

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
