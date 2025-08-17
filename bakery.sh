#!/bin/bash
set -euo pipefail

# ===========================
# Bitoreum Bakery (Batch bake.sh)
# - Explicit branch/tag arg required at launch
# - Uses recipe_book.conf (optional custom build matrix)
# - One-time repo clone/update
# - Cleans depends & main between bakes
# - Release-only builds (stripped)
# - Artifacts in folder special-delivery
# - bakery.log: only [INFO]/[ERROR] entries - Less chatter mode
# ===========================

# --- Where we RUN the script from ---
RUN_DIR="$(pwd -P)"
LOG_FILE="${RUN_DIR}/bakery.log"

# --- Ensure dishy.sh exists; try to fetch if missing ---
if [[ -x "${RUN_DIR}/dishy.sh" ]]; then
  "${RUN_DIR}/dishy.sh" || true
else
  fetched=""
  if command -v curl >/dev/null 2>&1; then
    for ref in main master; do
      curl -fsSL "https://raw.githubusercontent.com/Nikovash/bitoreum-builder/${ref}/dishy.sh" \
        -o "${RUN_DIR}/dishy.sh" && fetched="yes" && break || true
    done
  elif command -v wget >/dev/null 2>&1; then
    for ref in main master; do
      wget -qO "${RUN_DIR}/dishy.sh" \
        "https://raw.githubusercontent.com/Nikovash/bitoreum-builder/${ref}/dishy.sh" && fetched="yes" && break || true
    done
  fi

  if [[ "${fetched:-}" == "yes" && -s "${RUN_DIR}/dishy.sh" ]]; then
    chmod +x "${RUN_DIR}/dishy.sh"
    "${RUN_DIR}/dishy.sh" || true
  else
    echo -e "\033[1;31m[ERROR] Required employee 'dishy.sh' did not show up for work (not found locally) and could not be downloaded from GitHub (Nikovash/bitoreum-builder).\033[0m" >&2
    echo -e "\033[1;31m[ERROR] Aborting to avoid building on a dirty workspace. Place 'dishy.sh' next to bakery.sh or ensure curl/wget can fetch it.\033[0m" >&2
    exit 1
  fi
fi

# --- Facny coloring and treatment for log ---
log() {
  echo -e "\033[1;32m[INFO] $*\033[0m" >> "$LOG_FILE"
}
err() {
  echo -e "\033[1;31m[ERROR] $*\033[0m" >> "$LOG_FILE"
}

# --- bakery.sh Start Time ---
START_EPOCH="$(date +%s)"
START_HUMAN="$(date +"%Y-%m-%d %H:%M:%S %Z")"
log "Commercial Bake Start: ${START_HUMAN}"

REPO_PARENT="$HOME/bitoreum-build"
REPO_ROOT="$REPO_PARENT/bitoreum"
DEPENDSDIR="$REPO_ROOT/depends"
BUILD_BASE="$REPO_PARENT/build"
COMPRESS_DIR="$REPO_PARENT/compressed"
SPECIAL_DELIVERY="$RUN_DIR/special-delivery"
COIN_NAME="bitoreum"
RELEASE_SUFFIX="Release"
RECIPE_BOOK="${RUN_DIR}/recipe_book.conf"

# --- Load version from version.properties (fallback: dev) ---
VERSION_FILE="${RUN_DIR}/version.properties"
BAKE_VERSION="dev"
if [[ -f "$VERSION_FILE" ]]; then
  if grep -qE '^\s*BAKE_VERSION\s*=' "$VERSION_FILE"; then
    # shellcheck disable=SC1090
    source "$VERSION_FILE"
  else
    BAKE_VERSION="$(<"$VERSION_FILE")"
  fi
  BAKE_VERSION="${BAKE_VERSION//,/\.}"
fi
BAKE_INIT="/opt/bake/bake.log"

# --- Require explicit branch/tag; print to console & log ---
if [[ $# -lt 1 ]]; then
  msg="Usage: $0 <branch_or_tag>"
  # console (stderr) in red
  echo -e "\033[1;31m[ERROR] $msg\033[0m" >&2
  # log file
  echo -e "\033[1;31m[ERROR] $msg\033[0m" >> "$LOG_FILE"
  exit 1
fi
BRANCH_OR_TAG="$1"

# --- Determine if first-run ---
if [[ ! -f "$BAKE_INIT" ]]; then
    FIRST_RUN=true
else
    FIRST_RUN=false
fi
log "First run: $FIRST_RUN"

if [[ "$FIRST_RUN" == true ]]; then
    log "Performing first run setup..."
    sudo mkdir -p /opt/bake
    sudo tee "$BAKE_INIT" > /dev/null <<EOF
# Bake configuration
BAKE_VERSION=$BAKE_VERSION
SCRIPT_INSTALL=${RUN_DIR}
EOF
    log "Configuration file created at $BAKE_INIT"
    # System setup (first run)
    sudo apt update
    sudo apt dist-upgrade -y
    sudo apt-get install -y \
      git curl build-essential libtool autotools-dev automake pkg-config python3 bsdmainutils cmake \
      libdb-dev libdb++-dev screen zlib1g-dev libx11-dev libxext-dev libxrender-dev libxft-dev \
      libxrandr-dev libffi-dev g++-aarch64-linux-gnu g++-arm-linux-gnueabihf binutils-aarch64-linux-gnu \
      binutils-arm-linux-gnueabihf binutils-i686-linux-gnu zip unzip
else
    # Update config file on subsequent runs
    sudo tee "$BAKE_INIT" > /dev/null <<EOF
# Bake configuration
BAKE_VERSION=$BAKE_VERSION
SCRIPT_INSTALL=$RUN_DIR
EOF
    log "Bake version & Run_Dir has been updated"
    # System setup (subsequent runs)
    sudo apt update
    sudo apt-get install -y \
      git curl build-essential libtool autotools-dev automake pkg-config python3 bsdmainutils cmake \
      libdb-dev libdb++-dev screen zlib1g-dev libx11-dev libxext-dev libxrender-dev libxft-dev \
      libxrandr-dev libffi-dev g++-aarch64-linux-gnu g++-arm-linux-gnueabihf binutils-aarch64-linux-gnu \
      binutils-arm-linux-gnueabihf binutils-i686-linux-gnu zip unzip
fi

# --- Install Python 3.10.17 altinstall ---
PYTHON_SRC="/usr/src/Python-3.10.17"
if [ ! -d "$PYTHON_SRC" ]; then
    log "Installing Python 3.10.17..."
    cd /usr/src
    sudo wget https://www.python.org/ftp/python/3.10.17/Python-3.10.17.tgz
    sudo tar -xzf Python-3.10.17.tgz
    cd Python-3.10.17
    sudo ./configure --enable-optimizations
    sudo make -j"$(nproc)"
    sudo make altinstall
    log "Python 3.10.17 successfully installed"
else
    log "Python 3.10.17 already installed."
fi
export PATH="/usr/bin:$PATH"

# --- Temp fallback for flaky depends in v4.1.0.0 ---
if [[ "$BRANCH_OR_TAG" == "v4.1.0.0" ]]; then
    export FALLBACK_DOWNLOAD_PATH="https://bitoreum.cc/depends/"
    log "Applied bitoreum.cc fallback for bitoreum-v4.1.0.0"
fi

# --- Default recipe book (safe under set -e) ---
_DEFAULT_RECIPE_BOOK="$(cat <<'CONF'
Linux 64-bit,y,QT=y
Linux 32-bit,y,QT=y
Linux ARM 32-bit,y,QT=y
Linux ARM 64-bit,y,QT=y
Raspberry Pi 4+,n,QT=y
Oracle Ampere ARM,n,QT=n
Windows 64-bit,y,QT=y
CONF
)"

write_default_recipe_book() {
  log "Writing default recipe_book.conf -> ${RECIPE_BOOK}"
  printf '%s\n' "$_DEFAULT_RECIPE_BOOK" > "${RECIPE_BOOK}"
}

valid_recipe_line() {
  [[ "$1" =~ ^[^,]+,(y|n),QT=(y|n)$ ]]
}

ensure_recipe_ok() {
  if [[ ! -f "$RECIPE_BOOK" ]]; then
    log "recipe_book.conf not found. Creating default."
    write_default_recipe_book
    return
  fi
  local ok=true
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" ]] && continue
    valid_recipe_line "$line" || { ok=false; break; }
  done < "$RECIPE_BOOK"
  if ! $ok; then
    err "recipe_book.conf invalid. Replacing with default."
    write_default_recipe_book
  fi
}

# --- Map friendly target ---
map_target() {
  case "$1" in
    "Linux 64-bit")        echo "x86_64-pc-linux-gnu false false false";;
    "Linux 32-bit")        echo "i686-pc-linux-gnu false false false";;
    "Linux ARM 32-bit")    echo "arm-linux-gnueabihf false false false";;
    "Linux ARM 64-bit")    echo "aarch64-linux-gnu false false false";;
    "Raspberry Pi 4+")     echo "aarch64-linux-gnu true false false";;
    "Oracle Ampere ARM")   echo "aarch64-linux-gnu false true false";;
    "Windows 64-bit")      echo "x86_64-w64-mingw32 false false true";;
    *)                     echo "unknown false false false";;
  esac
}

# --- Repo clone/update ---
prepare_repo() {
  mkdir -p "$REPO_PARENT"
  if [[ -d "$REPO_ROOT/.git" ]]; then
    log "Repo exists. Updating and checking out $BRANCH_OR_TAG..."
    git -C "$REPO_ROOT" fetch --all --tags
    git -C "$REPO_ROOT" checkout -f "$BRANCH_OR_TAG"
    git -C "$REPO_ROOT" pull --rebase || true
  else
    log "Cloning branch/tag $BRANCH_OR_TAG..."
    if ! git clone -b "$BRANCH_OR_TAG" https://github.com/Nikovash/bitoreum "$REPO_ROOT"; then
      log "Branch/tag not found, cloning default then checking out $BRANCH_OR_TAG"
      git clone https://github.com/Nikovash/bitoreum "$REPO_ROOT"
      git -C "$REPO_ROOT" checkout -f "$BRANCH_OR_TAG"
    fi
  fi
}

# --- Compute version for artifact dir ---
compute_version() {
  if [[ -f "$REPO_ROOT/build.properties" ]]; then
    grep '^release-version=' "$REPO_ROOT/build.properties" | cut -d'=' -f2
  else
    date +%Y%m%d-%H%M%S
  fi
}

# --- Archive naming helpers ---
detect_os_label() {
  local os; os="$(. /etc/os-release && echo "${ID}-${VERSION_ID}")"
  [[ "$os" == "ubuntu-18.04" ]] && os="Generic-Linux"
  echo "$os"
}
arch_type_label() {
  local host="$1" is_pi="$2" is_amp="$3" is_win="$4"
  if [[ "$is_pi" == "true" ]]; then
    echo "Pi4_ARM_64"
  elif [[ "$is_amp" == "true" ]]; then
    echo "Oracle-Ampere_ARM_64"
  elif [[ "$is_win" == "true" ]]; then
    echo "Win64_x86"
  else
    case "$host" in
      x86_64-pc-linux-gnu) echo "x86_64" ;;
      i686-pc-linux-gnu)   echo "x86_32" ;;
      arm-linux-gnueabihf) echo "ARM_32" ;;
      aarch64-linux-gnu)   echo "ARM_64" ;;
      *)                   echo "$host" ;;
    esac
  fi
}

# --- Ensure Windows toolchain when needed (runs once if needed) ---
ensure_windows_toolchain() {
  log "Ensuring MinGW-w64 toolchain for Windows target..."
  sudo apt-get update -y
  sudo apt-get install -y g++-mingw-w64-x86-64 gcc-mingw-w64-x86-64 binutils-mingw-w64-x86-64 nsis
  sudo update-alternatives --set x86_64-w64-mingw32-gcc /usr/bin/x86_64-w64-mingw32-gcc-posix || true
  sudo update-alternatives --set x86_64-w64-mingw32-g++ /usr/bin/x86_64-w64-mingw32-g++-posix || true
}

# --- Build a single target (Release-only) ---
build_target() {
  local friendly="$1" host="$2" qt="$3" is_pi="$4" is_amp="$5" is_win="$6"
  log "-*- Baking goods: ${friendly} | HOST=${host} | QT=${qt} -*-"

# --- Depends clean & rebuild (honors QT=n) ---
  pushd "$DEPENDSDIR" >/dev/null
  make clean || true
  make distclean || true
  depends_flags=()
  if [[ "${qt,,}" == "n" ]]; then
    depends_flags+=(NO_QT=1)
  fi
  make -j"$(nproc)" HOST="$host" "${depends_flags[@]}"
  popd >/dev/null

# --- Main clean, autogen, configure, build ---
  pushd "$REPO_ROOT" >/dev/null
  make clean || true
  make distclean || true
  ./autogen.sh
  local cfg_flags=""
  [[ "${qt,,}" == "n" ]] && cfg_flags+=" --with-gui=no"
  ./configure --prefix="${DEPENDSDIR}/${host}" ${cfg_flags}
  make -j"$(nproc)"

# --- Determine binaries to package ---
  local binfiles=()
  if [[ "$is_win" == "true" ]]; then
    if [[ "${qt,,}" == "y" ]]; then
      binfiles=(bitoreum-cli.exe bitoreumd.exe bitoreum-tx.exe qt/bitoreum-qt.exe)
    else
      binfiles=(bitoreum-cli.exe bitoreumd.exe bitoreum-tx.exe)
    fi
  else
    if [[ "${qt,,}" == "y" ]]; then
      binfiles=(bitoreum-cli bitoreumd bitoreum-tx qt/bitoreum-qt)
    else
      binfiles=(bitoreum-cli bitoreumd bitoreum-tx)
    fi
  fi

  local bin_subdir="bitoreum-v${VERSION}"
  local out_dir="${BUILD_BASE}/${bin_subdir}"
  rm -rf "$out_dir"
  mkdir -p "$out_dir" "$COMPRESS_DIR" "$SPECIAL_DELIVERY"

  for b in "${binfiles[@]}"; do
    [[ -f "src/${b}" ]] || { err "Missing binary: src/${b}"; popd >/dev/null; return 1; }
    cp "src/${b}" "$out_dir/"
  done

# --- $HOST aware Strip ---
  case "$host" in
    x86_64-w64-mingw32) strip_tool="x86_64-w64-mingw32-strip" ;;
    arm-linux-gnueabihf) strip_tool="arm-linux-gnueabihf-strip" ;;
    aarch64-linux-gnu)   strip_tool="aarch64-linux-gnu-strip" ;;
    i686-pc-linux-gnu)   strip_tool="i686-linux-gnu-strip" ;;
    *)                   strip_tool="strip" ;;
  esac
  if ! command -v "$strip_tool" >/dev/null 2>&1; then
    err "strip tool '$strip_tool' not found; using fallback 'strip'"
    strip_tool="strip"
  fi
  "$strip_tool" "$out_dir"/* || err "strip failed (continuing)"

# --- Checksums inside tree (per-build) ---
  local checksum_file="${out_dir}/checksums-${VERSION}.txt"
  : > "$checksum_file"
  echo "sha256:" >> "$checksum_file"
  (cd "$BUILD_BASE" && find "$bin_subdir" -type f -exec shasum -a 256 {} \;) >> "$checksum_file" 2>/dev/null || true
  echo "openssl-sha256:" >> "$checksum_file"
  (cd "$BUILD_BASE" && find "$bin_subdir" -type f -exec sha256sum {} \;) >> "$checksum_file" 2>/dev/null || true

# --- Archive name and compress ---
  local os_label arch_label archive_name
  os_label="$(detect_os_label)"
  arch_label="$(arch_type_label "$host" "$is_pi" "$is_amp" "$is_win")"

  if [[ "$is_win" == "true" ]]; then
    archive_name="${COIN_NAME}-Generic-${arch_label}-${RELEASE_SUFFIX}-${VERSION}.zip"
    (cd "$BUILD_BASE" && zip -r "${COMPRESS_DIR}/${archive_name}" "$bin_subdir")
  else
    archive_name="${COIN_NAME}-${os_label}_${arch_label}-${RELEASE_SUFFIX}-${VERSION}.tar.gz"
    (cd "$BUILD_BASE" && tar -cf - "$bin_subdir" | gzip -9 > "${COMPRESS_DIR}/${archive_name}")
  fi

  mv -f "${COMPRESS_DIR}/${archive_name}" "$SPECIAL_DELIVERY/"
  log "Baked & packaged: ${SPECIAL_DELIVERY}/${archive_name}"
  popd >/dev/null
  return 0
}

# --- Main flow ---
log "Bakery batch start (branch/tag: ${BRANCH_OR_TAG})"
ensure_recipe_ok
mkdir -p "$SPECIAL_DELIVERY" "$COMPRESS_DIR" "$BUILD_BASE"
prepare_repo
VERSION="$(compute_version)"
if [[ -f "$REPO_ROOT/build.properties" ]]; then
  log "Using release-version: ${VERSION}"
else
  log "No build.properties found; using fallback version: ${VERSION}"
fi

# --- Install Windows toolchain once if any Windows target is enabled ---
if grep -E "^Windows 64-bit,y,QT=" "$RECIPE_BOOK" >/dev/null 2>&1; then
  ensure_windows_toolchain
fi

# --- Build loop ---
while IFS= read -r line || [[ -n "$line" ]]; do
  [[ -z "$line" ]] && continue
  IFS=',' read -r friendly enabled qtfield <<< "$line"
  [[ "${enabled,,}" != "y" ]] && continue
  qt="${qtfield#QT=}"
  qt="${qt,,}"
  read host is_pi is_amp is_win <<<"$(map_target "$friendly")"
  [[ "$host" == "unknown" ]] && { err "Skipping unknown: $friendly"; continue; }
  build_target "$friendly" "$host" "$qt" "$is_pi" "$is_amp" "$is_win" || {
    err "Build failed for ${friendly}; aborting."
    break
  }
done < "$RECIPE_BOOK"

# --- Final global checksums (for everything in special-delivery) ---
GLOBAL_SUM="${SPECIAL_DELIVERY}/checksums-${VERSION}.txt"
: > "$GLOBAL_SUM"
shopt -s nullglob
for f in "${SPECIAL_DELIVERY}"/*.tar.gz "${SPECIAL_DELIVERY}"/*.zip; do
  [[ -e "$f" ]] || continue
  echo "sha256: $(shasum -a 256 "$f")" >> "$GLOBAL_SUM"
  echo "openssl-sha256: $(sha256sum "$f")" >> "$GLOBAL_SUM"
done
log "Wrote global checksums -> ${GLOBAL_SUM}"

# --- Timestamps (end) ---
END_EPOCH="$(date +%s)"
END_HUMAN="$(date +"%Y-%m-%d %H:%M:%S %Z")"
RUNTIME=$((END_EPOCH-START_EPOCH))
printf -v RUNTIME_HMS '%02d:%02d:%02d' $((RUNTIME/3600)) $(((RUNTIME%3600)/60)) $((RUNTIME%60))
log "Commercial Bake End:   ${END_HUMAN}"
log "Total Kitchen Runtime: ${RUNTIME_HMS}"
log "Batch of Baked Goods Complete. Artifacts in ${SPECIAL_DELIVERY}"
