#!/bin/bash
set -e

# === Variables ===
PWD_USAGE="$(pwd)"
RUN_DIR="$(pwd -P)"
BITOREUM_DIR="$HOME/bitoreum-build/bitoreum"
BAKE_PROCESS_LOG="$RUN_DIR/bake_creampie.log"
PREVIOUS_BAKE_LOG="$RUN_DIR/previous_bake.log"

# === Logging ===
log() { echo -e "\033[1;32m[INFO] $1\033[0m" | tee -a "$BAKE_PROCESS_LOG"; }
err() { echo -e "\033[1;31m[ERROR] $1\033[0m" | tee -a "$BAKE_PROCESS_LOG" >&2; }

# Ensure log exists early
: > "$BAKE_PROCESS_LOG" || { echo "[ERROR] Can't write $BAKE_PROCESS_LOG"; exit 1; }

# === Preconditions ===
has_files="$(find "$BITOREUM_DIR" -mindepth 1 -type f -print -quit 2>/dev/null)"
if [[ -d "$BITOREUM_DIR" && -n "$has_files" && -s "$PREVIOUS_BAKE_LOG" ]]; then
    NUMBER=$(( RANDOM % 24 + 1 ))
    log "Refire Table $NUMBER"
else
    log "Something messy happened, use dishy.sh and bake again from scratch"
    exit 1
fi

# === Load previous bake variables ===
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

# === Discover safe configure flags (filters tests/bench) ===
gather_configure_flags() {
    local raw
    mapfile -t raw < <(
        ./configure --help 2>/dev/null \
        | sed -n 's/^[[:space:]]\{0,2\}\(--[^[:space:]]\+\).*/\1/p' \
        | grep -E '^(--(enable|disable|with|without)-' \
        | grep -Evi '(test|tests|bench)' \
        | sort -u
    )
    CFG_FLAGS=()
    local RE='^(--(enable|disable|with|without)-[A-Za-z0-9._+-]+)(=.*)?$'
    for f in "${raw[@]}"; do
        [[ $f =~ $RE ]] && CFG_FLAGS+=("${BASH_REMATCH[1]}")
    done
    # de-dup
    IFS=$'\n' read -r -d '' -a CFG_FLAGS < <(printf "%s\n" "${CFG_FLAGS[@]}" | sort -u && printf '\0')
}

# === Interactive picker with fallbacks ===
pick_configure_flags() {
    gather_configure_flags
    [[ ${#CFG_FLAGS[@]} -eq 0 ]] && { err "No configurable flags found."; return 1; }

    local selections=()

    if command -v fzf >/dev/null 2>&1; then
        # fzf multi-select; preselect by LAST_CONFIGURE_OPTS (optional)
        local pre=""
        [[ -n "${LAST_CONFIGURE_OPTS:-}" ]] && pre="$(printf "%s\n" $LAST_CONFIGURE_OPTS)"
        selections=($(printf "%s\n" "${CFG_FLAGS[@]}" \
            | fzf --multi --ansi --prompt="Select flags (TAB to toggle, ENTER to accept): " \
                  --preview-window=down:3:wrap \
                  --preview='echo {}' \
                  --query="${pre// / }" 2>/dev/null))
    elif command -v dialog >/dev/null 2>&1 || command -v whiptail >/dev/null 2>&1; then
        # dialog/whiptail checklist
        local ui cmd items=() tmp
        if command -v dialog >/dev/null 2>&1; then ui=dialog; else ui=whiptail; fi
        for f in "${CFG_FLAGS[@]}"; do
            if [[ " ${LAST_CONFIGURE_OPTS:-} " == *" $f "* ]]; then
                items+=("$f" "$f" "on")
            else
                items+=("$f" "$f" "off")
            fi
        done
        tmp=$(mktemp)
        if [[ $ui == dialog ]]; then
            cmd=(dialog --separate-output --checklist "Select flags" 20 90 15)
        else
            cmd=(whiptail --separate-output --checklist "Select flags" 20 90 15)
        fi
        "${cmd[@]}" "${items[@]}" 2> "$tmp" || true
        mapfile -t selections < "$tmp"
        rm -f "$tmp"
    else
        # simple numbered fallback (space-separated indices)
        echo
        log "Select configure options to APPLY (space-separated indices, Enter to skip):"
        local i
        for i in "${!CFG_FLAGS[@]}"; do
            printf "  %2d) %s\n" "$((i+1))" "${CFG_FLAGS[$i]}"
        done
        echo
        read -rp "Choice(s): " _nums
        for n in $_nums; do
            [[ $n =~ ^[0-9]+$ ]] && (( n>=1 && n<=${#CFG_FLAGS[@]} )) && selections+=("${CFG_FLAGS[$((n-1))]}")
        done
    fi

    # Build CONFIGURE_OPTS from selections + optional extra flags
    CONFIGURE_OPTS=""
    if ((${#selections[@]})); then
        CONFIGURE_OPTS="${selections[*]}"
    fi

    echo
    read -rp "Add extra flags (optional, e.g. --with-gui=qt5 --disable-zmq): " extra
    [[ -n $extra ]] && CONFIGURE_OPTS="$CONFIGURE_OPTS $extra"
    CONFIGURE_OPTS="${CONFIGURE_OPTS# }"
    CONFIGURE_OPTS="${CONFIGURE_OPTS%% }"

    # Always force these off
    local FORCE_DISABLES="--disable-tests --disable-bench --disable-gui-tests"
    CONFIGURE_OPTS="${CONFIGURE_OPTS:+$CONFIGURE_OPTS }$FORCE_DISABLES"

    log "Using configure flags: ${CONFIGURE_OPTS:-<none>}"
}

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
    pick_configure_flags || { err "Flag selection failed"; exit 1; }
	: > config.log
	: > build.log


    if [[ -n "${HOST_TRIPLE:-}" ]]; then
      ./configure --host="$HOST_TRIPLE" $CONFIGURE_OPTS
    else
      ./configure $CONFIGURE_OPTS
    fi
    
    
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
