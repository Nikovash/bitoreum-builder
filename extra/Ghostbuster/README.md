# Spectre Scan

`spectre_scan.sh` is a lightweight Bash utility for monitoring Dash/Bitcoin-style masternode networks.  
It probes all **ENABLED** nodes from a coin’s `smartnodelist`, checks TCP reachability, and optionally attempts a version handshake to distinguish **GOOD nodes** from **ghost/silent nodes**.

---

## Features

- **Parallel scanning** of all enabled nodes (`smartnodelist`).
- Detects:
  - **GOOD** – Node responds (banner or handshake).
  - **OPEN-NO-BANNER** – Port open, but no response within timeout.
  - **GHOST** – Node unreachable.
- **Multi-coin support**:
  - Supports both IPv4 & IPv6
  - Default coin: **Bitoreum** (`bitoreum-cli`, RPC 8900, P2P 15168).
  - Other coins: pass `--coin`, `--rpc-port`, `--p2p-port`.
- **Handshake mode** with `--magic-hex` (send proper `version` message, mark node GOOD on any response).
- Generates human-readable reports.
- Fresh log per run (truncated automatically).

---

## Requirements

- Bash 4+
- `jq`, `nc`, `timeout`, `openssl`, `xxd`
- A working `<coin>-cli` (e.g. `bitoreum-cli`, `yerbas-cli`) in `/usr/bin`.

---

## Usage

```bash
./spectre_scan.sh [options]
```

### Options

| Flag                  | Description |
|------------------------|-------------|
| `-c, --coin NAME`      | Coin prefix (default: `bitoreum`). |
| `--rpc-port N`         | RPC port (default: `8900` is set for all coins pass whatever RPC port is set for the wallet you are using). **Required** for all coins! |
| `--p2p-port N`         | P2P service port (default: `15168` for Bitoreum). **Required** for other coins. |
| `-o, --output PATH`    | Report output file (default: `~/<coin>_node_report.txt`). |
| `-j, --concurrency N`  | Number of probes to run in parallel (default: 16). |
| `--connect-timeout N`  | TCP connect timeout in seconds (default: 5). |
| `--banner-timeout N`   | Timeout when waiting for banner bytes (default: 4). |
| `--banner-read N`      | Number of bytes to attempt reading in banner mode (default: 64). |
| `--handshake-timeout N`| Timeout waiting for handshake response (default: 8). |
| `--magic-hex HEX`      | 4-byte network magic (hex). Enables handshake mode. |
| `-6, --ipv6`           | Also probe IPv6 addresses |
| `-h, --help`           | Show usage info. |

---

## Examples

### Bitoreum (default)
```bash
./spectre_scan.sh --magic-hex 7a72642c
```

### Long Form Example
```bash
./spectre_scan.sh -c bitoreum \
  --rpc-port 8900 \
  --p2p-port 15168 \
  --magic-hex 7a72642c \
  -o ~/bitoreum_report.txt
```

---

## Output

Reports look like this:

```
Node Status Report (bitoreum) - 2025-08-30 11:00:00

GOOD (responded):
- 192.0.2.10
- 192.0.2.11

OPEN-NO-BANNER (open, silent):
- 192.0.2.12

GHOST (connect failed):
- 192.0.2.99

Counts:
  GOOD:           2
  OPEN-NO-BANNER: 1
  GHOST:          1
  TOTAL:          4

Percentages:
  GOOD:           50.00%
  OPEN-NO-BANNER: 25.00%
  GHOST:          25.00%

Parameters:
  P2P Port:             15168
  Connect Timeout:      5s
  Banner Timeout:       4s
  Banner Read Bytes:    64
  Handshake Timeout:    8s
  Magic (handshake):    7a72642c

Time spent running: 00:00:09
Report will run again at: 2025-08-30 12:00:00
```

---

## Cron Usage

Example hourly cron job for `spectre_scan.sh`:

```cron
0 * * * * /bin/bash /home/<username>/spectre_scan.sh --magic-hex 7a72642c >> /home/<username>/cron.log 2>&1
```
<username> here is whatever user the `coind` & `coin-cli` is running from, you should always install this script into that user
---

## Naming

The name **Spectre Scan** comes from its job:  
to detect **ghost (spectre) nodes** and separate them from living peers in the network.

> Next: [Magic Hex List](magic-hex.md)
