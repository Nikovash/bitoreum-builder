# 🚀 Usage Guide

This document walks you through using the `bake.sh` script to compile Bitoreum or related forks for multiple platforms.

---

## 🧱 Basic Setup

Before running the script:

```bash
git clone https://github.com/Nikovash/bitoreum-builder.git
cd bitoreum-builder
chmod +x bake.sh
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

The script will prompt you with several options:

---

## 📌 Step-by-Step Prompts

### 1️⃣ Clone Target

You will be asked:

```
Clone from 'main' or specify a branch name (case-sensitive)? [main/branch-name]:
```

- Type `main` for the default branch.
- Or enter a valid branch name (case-sensitive) to use a specific fork branch.

---

### 2️⃣ Select Build Target

```
1) Linux 64-bit        (x86_64-pc-linux-gnu)
2) Linux 32-bit        (i686-pc-linux-gnu)
3) Linux ARM 32-bit    (arm-linux-gnueabihf)
4) Linux ARM 64-bit    (aarch64-linux-gnu)
5) Raspberry Pi 4+     (aarch64-linux-gnu)
6) Oracle Ampere ARM   (aarch64-linux-gnu)
7) Cancel and exit
```

- Choose the number corresponding to your platform.
- Option 7 will exit the script.

---

## 🛠️ What the Script Does

- Installs Python 3.10.17 if missing
- Sets up build dependencies
- Runs the `depends/` system
- Configures, compiles, and links
- Builds three types:
  - ✅ Stripped binary
  - ✅ Not-stripped binary
  - ✅ Debug build
- Generates checksums for each
- Compresses each build directory into `.tar.gz`

---

## 📦 Where to Find Results

You’ll find the build output and compressed files in:

```bash
~/bitoreum-build/compressed/
```

Each `.tar.gz` archive will contain:

- Compiled binaries
- Matching `checksums-<version>.txt` file

---

## 🧹 Cleaning Up

After the build, once you have stored the files you want safely you can just erase the bitoreum-build folder

```bash
cd
rm -rf bitoreum-build
```
## Command above is destructive so make sure you have moved the file(s) you want ouf of that folder FIRST!
---

> Next: [Advanced Options](advanced-options.md)
