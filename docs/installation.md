# 📥 Installation Guide

This guide walks you through the prerequisites and steps for installing and preparing the Bitoreum Builder environment.

## 🧾 Requirements

 * A Linux system (tested on Ubuntu 18.04)
 * `sudo` privileges
 * Internet connection

## 🔧 Recommended Packages

These packages are installed automatically by the script, but you can install them manually if needed:
  ```bash
  sudo apt update
  sudo apt dist-upgrade -y
  sudo apt install -y \
      git curl build-essential libtool autotools-dev automake pkg-config \
      python3 bsdmainutils cmake libdb-dev libdb++-dev screen zlib1g-dev \
      libx11-dev libxext-dev libxrender-dev libxft-dev libxrandr-dev libffi-dev
  ```

## 🐍 Python 3.10.17 (First-Time Only)

If Python 3.10.17 is not found in /usr/src, the script will install it automatically:

  ```bash
  cd /usr/src
  sudo wget https://www.python.org/ftp/python/3.10.17/Python-3.10.17.tgz
  sudo tar -xzf Python-3.10.17.tgz
  cd Python-3.10.17
  sudo ./configure --enable-optimizations
  sudo make -j$(nproc)
  sudo make altinstall
  ```

Once installed, aliases are created:

  ```bash
  alias python=python3.10
  alias python3=python3.10
  ```

## 📦 Cloning Bitoreum Builder

  ```bash
  git clone https://github.com/Nikovash/bitoreum-builder.git
  cd bitoreum-builder
  chmod +x bake.sh
  ```

## 🖥️ (Optional) Use screen

We recommend launching a screen session before building:

  ```bash
  screen -S build
  ```
Launch the script (may or may not need to call with `sudo`):
  ```bash
  ./bake.sh
  ```
Detach the session with:

  ```bash
  Ctrl+A then D
  ```

Reattach later with:

  ```bash
  screen -r
  ```

✅ You're now ready to run the build script and begin the interactive process.

  Continue to: [Usage Guide](usage-guide.md)


