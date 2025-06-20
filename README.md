<p align="center"><img src="BB_logo.png" alt="Project Logo" width="200"/></p>


# 🛠️ Bitoreum Builder

A fully automated build script for compiling Crystal Bitoreum (or other forks) with support for multiple platforms and output formats. Includes debug, stripped, and not-stripped binaries with full checksum and compression automation.

---

## 🚀 Features

- ✅ Auto-attached `screen` session for interactive use
- ✅ Python 3.10.17 installer (first-run only)
- ✅ Clone from `main` or any custom branch
- ✅ Select build target:
  - Linux 64-bit (`x86_64-pc-linux-gnu`)
  - Linux 32-bit (`i686-pc-linux-gnu`)
  - ARM 32-bit (`arm-linux-gnueabihf`)
  - ARM 64-bit (`aarch64-linux-gnu`)
  - ❌ Cancel & Exit
- ✅ Full debug build
- ✅ Binary strip & not-strip modes
- ✅ SHA + OpenSSL-style checksums
- ✅ Auto `.tar.gz` compression for each output

---

## 📦 Requirements

- Linux (Ubuntu 20.04+ recommended)
- sudo privileges
- Internet access

---

## 📥 Usage

### 🔹 1. Clone and run

```bash
git clone https://github.com/Nikovash/bitoreum-builder.git
cd bitoreum-builder
chmod +x build-bitoreum.sh
./build-bitoreum.sh
