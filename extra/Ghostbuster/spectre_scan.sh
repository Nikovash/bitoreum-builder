#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================
# Smartnode/Ghost Probe with optional handshake
#  - wallet {coin-cli} must be installed globally in /usr/bin
#  - Default coin: Bitoreum (coin=bitoreum, rpc=8900, p2p=15168)
#  - Other coins: MUST pass --rpc-port and --p2p-port
#
#  Categories:
#    GOOD            -> open + (banner OR handshake response)
#    OPEN-NO-BANNER  -> open, but silent within timeout
#    GHOST           -> connect failed
# ============================================

# ---- Defaults ----
COIN="${COIN:-bitoreum}"
RPC_PORT="${RPC_PORT:-8900}"
P2P_PORT="${P2P_PORT:-15168}"

# Probe timing
CONNECT_TIMEOUT="${CONNECT_TIMEOUT:-5}"     # TCP connect timeout (s)
BANNER_TIMEOUT="${BANNER_TIMEOUT:-4}"       # read-after-connect timeout (s)
BANNER_READ="${BANNER_READ:-64}"            # bytes to try reading in banner mode
HANDSHAKE_TIMEOUT="${HANDSHAKE_TIMEOUT:-8}" # timeout waiting for handshake response (s)

CONCURRENCY="${CONCURRENCY:-16}"
OUTPUT_FILE="${OUTPUT_FILE:-$HOME/$COIN_node_report.txt}"

# Optional: 4-byte network magic to trigger full handshake (hex)
MAGIC_HEX="${MAGIC_HEX:-}"   # e.g. 7a72642c

usage() {
  cat <<'USAGE'
Usage: spectre_scan.sh [options]

Options:
  -c, --coin NAME            Coin name/prefix for <coin>-cli (default: bitoreum)
  --rpc-port N               RPC port (default: 8900 for bitoreum; REQUIRED for others)
  --p2p-port N               P2P service port (default: 15168 for bitoreum; REQUIRED for others)
  -o, --output PATH          Report output file path
  -j, --concurrency N        Parallel probes (default: 16)
  --connect-timeout SECS     TCP connect timeout (default: 5)
  --banner-timeout SECS      Read-after-connect timeout (default: 4)
  --banner-read BYTES        Bytes to attempt to read (default: 64)
  --handshake-timeout SECS   Timeout waiting for handshake response (default: 8)
  --magic-hex HEX            4-byte network magic (hex) to enable handshake mode
  -h, --help                 Show this help

Notes:
- By default (no --magic-hex), peers that require a version handshake will show as OPEN-NO-BANNER.
- With --magic-hex, a valid "version" packet is sent; any response marks the node GOOD.
- Expects Dash/Bitcoin-like 'smartnodelist' structure.
USAGE
}

# ---- Parse args ----
while (( "$#" )); do
  case "$1" in
    -c|--coin)              COIN="$2"; shift 2;;
    --rpc-port)             RPC_PORT="$2"; shift 2;;
    --p2p-port)             P2P_PORT="$2"; shift 2;;
    -o|--output)            OUTPUT_FILE="$2"; shift 2;;
    -j|--concurrency)       CONCURRENCY="$2"; shift 2;;
    --connect-timeout)      CONNECT_TIMEOUT="$2"; shift 2;;
    --banner-timeout)       BANNER_TIMEOUT="$2"; shift 2;;
    --banner-read)          BANNER_READ="$2"; shift 2;;
    --handshake-timeout)    HANDSHAKE_TIMEOUT="$2"; shift 2;;
    --magic-hex)            MAGIC_HEX="$2"; shift 2;;
    -h|--help)              usage; exit 0;;
    --) shift; break;;
    -*)
      echo "Unknown option: $1" >&2
      usage; exit 2;;
    *)
      echo "Unexpected argument: $1" >&2
      usage; exit 2;;
  esac
done

# ---- Enforce ports for non-bitoreum ----
if [[ "$COIN" != "bitoreum" ]]; then
  if [[ -z "${RPC_PORT}" || -z "${P2P_PORT}" || ( "$RPC_PORT" == "8900" && "$P2P_PORT" == "15168" ) ]]; then
    echo "Error: For coin '$COIN', pass --rpc-port and --p2p-port." >&2
    exit 1
  fi
fi

CLI_BIN="${COIN}-cli"

# ---- Logging ----
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/runtime_${COIN}.log"
: > "$LOG_FILE"

# ---- Dependencies ----
need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1" >&2; exit 127; }; }
need jq
need awk
need timeout
need bash
need nc
need openssl
need xxd
if ! command -v "$CLI_BIN" >/dev/null 2>&1; then
  echo "Cannot find '${CLI_BIN}' in PATH. Set COIN correctly or adjust PATH." >&2
  exit 127
fi

# ---- Time ----
START_TS=$(date +%s)
RUN_DATE=$(date '+%Y-%m-%d %H:%M:%S')
NEXT_RUN=$(date -d '+60 minutes' '+%Y-%m-%d %H:%M:%S')

# ---- Temps ----
TMP_GOOD="$(mktemp)"
TMP_OPEN_NB="$(mktemp)"
TMP_GHOST="$(mktemp)"
cleanup(){ rm -f "$TMP_GOOD" "$TMP_OPEN_NB" "$TMP_GHOST"; }
trap cleanup EXIT

echo "[$RUN_DATE] [$COIN] Starting node status check (mode: $([[ -n "$MAGIC_HEX" ]] && echo handshake || echo banner))..." >> "$LOG_FILE"

# ---- Pull ENABLED nodes ----
if ! MAP_JSON="$("$CLI_BIN" -rpcport="$RPC_PORT" smartnodelist 2>/dev/null)"; then
  echo "Error: '${CLI_BIN} -rpcport=$RPC_PORT smartnodelist' failed." >&2
  exit 1
fi

mapfile -t IPS < <(jq -r '
  to_entries[]
  | select(.value.status == "ENABLED")
  | .value.address
' <<<"$MAP_JSON" \
  | cut -d: -f1 \
  | sort -u)

# Early exit if no IPs
if (( ${#IPS[@]} == 0 )); then
  {
    echo "Node Status Report (${COIN}) - $RUN_DATE"
    echo
    echo "GOOD (responded):"
    echo
    echo "OPEN-NO-BANNER (open, silent):"
    echo
    echo "GHOST (connect failed):"
    echo
    echo "Counts:"
    echo "  GOOD:           0"
    echo "  OPEN-NO-BANNER: 0"
    echo "  GHOST:          0"
    echo "  TOTAL:          0"
    echo
    echo "Percentages:"
    echo "  GOOD:           0.00%"
    echo "  OPEN-NO-BANNER: 0.00%"
    echo "  GHOST:          0.00%"
    echo
    echo "Parameters:"
    echo "  P2P Port:             $P2P_PORT"
    echo "  Connect Timeout:      ${CONNECT_TIMEOUT}s"
    echo "  Banner Timeout:       ${BANNER_TIMEOUT}s"
    echo "  Banner Read Bytes:    ${BANNER_READ}"
    echo "  Handshake Timeout:    ${HANDSHAKE_TIMEOUT}s"
    echo "  Magic (handshake):    ${MAGIC_HEX:-<none>}"
    echo
    echo "Time spent running: 00:00:00"
    echo "Report will run again at: $NEXT_RUN"
  } | sudo tee "$OUTPUT_FILE" >/dev/null
  exit 0
fi

# ---- Build a minimal "version" packet (hex) ----
build_version_hex() {
  local magic_hex="$1"  # e.g., 7a72642c

  # version (int32 LE) = 70015 -> 0x0001117F -> 7f110100
  local version_le="7f110100"

  # services (uint64 LE) = 1
  local services="0100000000000000"

  # timestamp (int64 LE)
  local ts_dec ts_hex ts_le
  ts_dec="$(date +%s)"
  ts_hex="$(printf "%016x" "$ts_dec")"
  ts_le="$(echo "$ts_hex" | sed -E 's/../& /g' | awk '{ for(i=NF;i>0;i--) printf $i }')"

  # addr_recv (26 bytes): services(8) + IPv6-mapped IPv4(16) + port(2 big-endian)
  local ipv6_mapped_ipv4="00000000000000000000ffff00000000"   # ::ffff:0.0.0.0
  local port_be="0000"
  local addr_recv="${services}${ipv6_mapped_ipv4}${port_be}"

  # addr_from (26 bytes): same placeholders
  local addr_from="${services}${ipv6_mapped_ipv4}${port_be}"

  # nonce (uint64) random
  local nonce_hex
  nonce_hex="$(openssl rand -hex 8)"

  # user_agent (varstr) empty -> 0x00
  local ua="00"

  # start_height (int32) = 0
  local start_height="00000000"

  # relay (bool) = 0x00
  local relay="00"

  local payload_hex="${version_le}${services}${ts_le}${addr_recv}${addr_from}${nonce_hex}${ua}${start_height}${relay}"

  # payload length (uint32 LE)
  local payload_len_bytes=$(( ${#payload_hex} / 2 ))
  local len_hex
  len_hex="$(printf "%08x" "$payload_len_bytes")"
  local len_le
  len_le="$(echo "$len_hex" | sed -E 's/../& /g' | awk '{ for(i=NF;i>0;i--) printf $i }')"

  # checksum = first 4 bytes of double-SHA256(payload)
  local checksum_hex
  checksum_hex="$(
    echo -n "$payload_hex" \
      | xxd -r -p \
      | openssl dgst -sha256 -binary \
      | openssl dgst -sha256 -binary \
      | xxd -p -c 1000 \
      | cut -c1-8
  )"

  # command "version" (12 bytes total, null-padded) -> "version"(7) + 5 zeros
  local cmd_hex
  cmd_hex="$(printf 'version' | xxd -p -c 1000)"; cmd_hex="${cmd_hex}0000000000"

  # header = magic(4) + command(12) + length(4, LE) + checksum(4)
  local header_hex="${magic_hex}${cmd_hex}${len_le}${checksum_hex}"

  echo "${header_hex}${payload_hex}"
}

# ---- Probe ----
probe() {
  local ip="$1"

  printf '[%s] [%s] Connect %s:%s\n' "$(date '+%H:%M:%S')" "$COIN" "$ip" "$P2P_PORT" >> "$LOG_FILE"

  # Stage 1: CONNECT
  if ! nc -z -w "$CONNECT_TIMEOUT" "$ip" "$P2P_PORT" >/dev/null 2>&1; then
    printf '[%s] %s -> GHOST (connect failed)\n' "$(date '+%H:%M:%S')" "$ip" >> "$LOG_FILE"
    echo "$ip" >> "$TMP_GHOST"
    return
  fi

  # Stage 2A: Handshake mode if MAGIC_HEX is set
  if [[ -n "$MAGIC_HEX" ]]; then
    local msg_hex bytes_read
    msg_hex="$(build_version_hex "$MAGIC_HEX")"

    bytes_read="$(
      timeout "$HANDSHAKE_TIMEOUT" bash -c "
        exec 3<>/dev/tcp/$ip/$P2P_PORT
        # send version
        printf '%s' '$msg_hex' | xxd -r -p >&3
        # brief pause to allow response
        sleep 0.2
        # read up to 128 bytes
        dd bs=1 count=128 <&3 2>/dev/null | wc -c
      " || true
    )"

    if [[ -n "$bytes_read" && "$bytes_read" -gt 0 ]]; then
      printf '[%s] %s -> GOOD (handshake %s bytes)\n' "$(date '+%H:%M:%S')" "$ip" "$bytes_read" >> "$LOG_FILE"
      echo "$ip" >> "$TMP_GOOD"
      return
    fi
    # fall through to banner read if nothing came back
  fi

  # Stage 2B: Banner mode (try to read some bytes without sending)
  local b_read
  b_read="$(timeout "$BANNER_TIMEOUT" bash -c "exec 3<>/dev/tcp/$ip/$P2P_PORT; dd bs=1 count=$BANNER_READ <&3 2>/dev/null | wc -c" || true)"
  if [[ -n "$b_read" && "$b_read" -gt 0 ]]; then
    printf '[%s] %s -> GOOD (banner %s bytes)\n' "$(date '+%H:%M:%S')" "$ip" "$b_read" >> "$LOG_FILE"
    echo "$ip" >> "$TMP_GOOD"
  else
    printf '[%s] %s -> OPEN-NO-BANNER\n' "$(date '+%H:%M:%S')" "$ip" >> "$LOG_FILE"
    echo "$ip" >> "$TMP_OPEN_NB"
  fi
}

# ---- Parallel runner ----
active=0
for ip in "${IPS[@]:-}"; do
  probe "$ip" &
  ((active+=1))
  if (( active >= CONCURRENCY )); then
    wait -n || true
    ((active-=1))
  fi
done
wait || true

# ---- Results ----
mapfile -t GOOD_NODES < "$TMP_GOOD" || true
mapfile -t OPEN_NB_NODES < "$TMP_OPEN_NB" || true
mapfile -t GHOST_NODES < "$TMP_GHOST" || true

COUNT_GOOD=${#GOOD_NODES[@]}
COUNT_OPEN_NB=${#OPEN_NB_NODES[@]}
COUNT_GHOST=${#GHOST_NODES[@]}
TOTAL_NODES=$((COUNT_GOOD + COUNT_OPEN_NB + COUNT_GHOST))

pct(){ awk -v a="$1" -v t="$2" 'BEGIN{ if(t==0) printf "0.00"; else printf "%.2f",(a/t)*100 }'; }
PCT_GOOD="$(pct "$COUNT_GOOD" "$TOTAL_NODES")"
PCT_OPEN_NB="$(pct "$COUNT_OPEN_NB" "$TOTAL_NODES")"
PCT_GHOST="$(pct "$COUNT_GHOST" "$TOTAL_NODES")"

# ---- Runtime ----
END_TS=$(date +%s)
RUNTIME=$((END_TS - START_TS))
RUNTIME_HMS=$(printf "%02d:%02d:%02d" $((RUNTIME/3600)) $((RUNTIME%3600/60)) $((RUNTIME%60)))

# ---- Report (never echo RPC port) ----
{
  echo "Node Status Report (${COIN}) - $RUN_DATE"
  echo
  echo "GOOD (responded):"
  for ip in "${GOOD_NODES[@]}"; do echo "- $ip"; done
  echo
  echo "OPEN-NO-BANNER (open, silent):"
  for ip in "${OPEN_NB_NODES[@]}"; do echo "- $ip"; done
  echo
  echo "GHOST (connect failed):"
  for ip in "${GHOST_NODES[@]}"; do echo "- $ip"; done
  echo
  echo "Counts:"
  echo "  GOOD:           $COUNT_GOOD"
  echo "  OPEN-NO-BANNER: $COUNT_OPEN_NB"
  echo "  GHOST:          $COUNT_GHOST"
  echo "  TOTAL:          $TOTAL_NODES"
  echo
  echo "Percentages:"
  echo "  GOOD:           $PCT_GOOD%"
  echo "  OPEN-NO-BANNER: $PCT_OPEN_NB%"
  echo "  GHOST:          $PCT_GHOST%"
  echo
  echo "Parameters:"
  echo "  P2P Port:             $P2P_PORT"
  echo "  Connect Timeout:      ${CONNECT_TIMEOUT}s"
  echo "  Banner Timeout:       ${BANNER_TIMEOUT}s"
  echo "  Banner Read Bytes:    ${BANNER_READ}"
  echo "  Handshake Timeout:    ${HANDSHAKE_TIMEOUT}s"
  echo "  Magic (handshake):    ${MAGIC_HEX:-<none>}"
  echo
  echo "Time spent running: $RUNTIME_HMS"
  echo "Report will run again at: $NEXT_RUN"
} | sudo tee "$OUTPUT_FILE" >/dev/null

printf '[%s] [%s] Wrote report to %s\n' "$(date '+%H:%M:%S')" "$COIN" "$OUTPUT_FILE" >> "$LOG_FILE"
printf '[%s] Done in %s. Next run at %s\n' "$(date '+%H:%M:%S')" "$RUNTIME_HMS" "$NEXT_RUN" >> "$LOG_FILE"
echo "---------------------------------------------" >> "$LOG_FILE"
