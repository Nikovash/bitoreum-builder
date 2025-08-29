# 🚀 Usage Guide

This document walks you through using the `bake.sh` script to compile Bitoreum or related forks for multiple platforms.

---

## 🧱 Basic Setup

Before running the script:

```bash
git clone https://github.com/Nikovash/bake.git
cd bake
(chmod +x bake.sh) // Optional, starting in version 1.0 all scripts are deployed with executable flags
```

(Optional but recommended)

```bash
screen -S build
```

---

## ▶️ Running the Script

Launch the build process:

```bash
./bake.sh
```

On all runs, the version and location of the script are written to a safe posstion to see what version of the script(s) were last run. You can view this by:

```bash
cat /opt/bake/bake.log
```

The script will prompt you with several options:

---

## 📌 Step-by-Step Prompts

### 1 | Clone Target

You will be asked:

```
Clone from a specific a branch or  tag name (case-sensitive) [branch OR tag-name]:
```
- Default is `main` branch
- Type any valid branch name EXAMPLE `dev`
- Or enter any valid branch name (case-sensitive) to use a specific branch
- Tags are also now valid EXAMPLE `v4.1.0.0`

---

### 2 | Select Build Target

```
1) Linux 64-bit        (x86_64-pc-linux-gnu)
2) Linux 32-bit        (i686-pc-linux-gnu)
3) Linux ARM 32-bit    (arm-linux-gnueabihf)
4) Linux ARM 64-bit    (aarch64-linux-gnu)
5) Raspberry Pi 4+     (aarch64-linux-gnu)
6) Oracle Ampere ARM   (aarch64-linux-gnu)
7) Windows 64-bit      (x86_64-w64-mingw32)
8) Cancel and exit
```

- Choose the number corresponding to your platform
- Option 8 will exit the script
---

### 3 | Determine if you want QT (GUI) Wallet
```
Y|n prompt
```

## 🛠️ What the Script Does

- Installs Python 3.10.17 if missing
- Sets up build dependencies
- Runs the `depends/` system
- Configures, compiles, and links
- Builds three binary types:
  - ✅ Stripped binary
  - ✅ Not-stripped binary
  - ✅ Debug binary
- Generates checksums for each
- Compresses each build directory into `.tar.gz` or `*.zip` in the case of a Windows build

---

## 📦 Where to Find Results

You’ll find the build output and compressed files in:

```bash
~/bitoreum-build/compressed/
```

Each `.tar.gz` or `*.zip` (for Windows builds) archive will contain:

- Compiled binaries
- Matching `checksums-<version>.txt` file

---

## 🧹 Cleaning Up

After the build, once you have stored the files you want safely you can just erase the bitoreum-build folder by utilizing your very own `dishy.sh`

```bash
$HOME/bake/./dishy.sh [<coin-name>] # Default is bitoreum
```
## Command above is destructive so make sure you have moved the file(s) you want out of the `bake` folder FIRST!
---

> Next: [Advanced Options](advanced-options.md)
