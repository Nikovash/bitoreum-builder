<p align="center">
  <img src="BB_logo.png" alt="Project Logo" width="200"/>
</p>

# 🛠️ Bitoreum Builder

A fully automated build script for compiling [Crystal Bitoreum](https://github.com/Nikovash/bitoreum) or other forks.  
Supports multiple target architectures and generates stripped, not-stripped, and debug builds, each with full checksums and compressed archives.

---

## 🚀 Features

- ✅ System `update` & `upgrade`
- ✅ Dependency check & `install`
- ✅ Python 3.10.17 setup (if missing)
- ✅ Clone from `main` or custom branch
- ✅ Platform selection:
  - 🖥️ Linux 64-bit
  - 🖥️ Linux 32-bit
  - 📱 Linux ARM 32-bit
  - 📱 Linux ARM 64-bit
  - ❌ Cancel and exit
- ✅ Fully separate debug build
- ✅ Stripped and unstripped binaries
- ✅ Per-build and archive-level SHA + OpenSSL-style checksums
- ✅ `.tar.gz` compression (max level)

---

## 📦 Requirements

- Linux (Ubuntu 20.04+ recommended)
- `sudo` privileges
- Internet connection
- Optional: `screen` (for remote session safety)

---

## 📥 Usage

### 🔹 1. Clone and prepare

```bash
git clone https://github.com/Nikovash/bitoreum-builder.git
cd bitoreum-builder
chmod +x build-bitoreum.sh
```
Launch a screen (Optional but reccomended):
```bash
screen -S build
```
Once insides the screen we can now run the app:
```bash
./build-bitoreum.sh
```
You can disconnect the screen at any time by pressing:
```bash
CNTL+A then D
```
And recooenct at any time with:
```bash
screen -r
```
If this is a remote session and the screen is still attached to a screen that was from a dropped connection you can force detact and reattach it to your current session with:
```bash
screen -D -r
```

<p align="center">* Screen changed from automatic to manual usage, due to weird behavior on older Distros</p>
