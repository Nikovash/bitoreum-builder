# 🛠️ Bitoreum Builder

Automated build script for compiling Bitoreum Core or forks with debug, stripped, and not-stripped binaries — all packaged with checksums and ready for upload.

## 🚀 Features
- One-command bootstrap
- Python 3.10.17 self-installer
- `screen` session auto-launch (`Build`)
- Branch-aware cloning (`main` or any custom branch)
- Multi-output binaries (normal, debug, not_stripped)
- SHA and OpenSSL checksums
- Smart compression output by OS & arch

## 📦 Usage

```bash
git clone https://github.com/Nikovash/bitoreum-builder.git
cd bitoreum-builder
chmod +x build-bitoreum.sh
./build-bitoreum.sh
```

## 🪪 License

MIT © 2025 Ramen Wukong c/o IoVa Systems a NikoVash Empire Battalion
