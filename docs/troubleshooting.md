# 🛠️ Troubleshooting

This guide helps you diagnose and fix issues when running the `build-bitoreum.sh` script.

---

## 🚫 Common Problems & Fixes

### ❓ Nothing happens after running the script

- Make sure the script is executable:
  ```bash
  chmod +x build-bitoreum.sh
  ```
- Ensure you're using `./build-bitoreum.sh` to run it (not just `build-bitoreum.sh`).

---

### 🧱 Build Fails Midway

- Look for output like:
  ```
  make[2]: *** [target] Error
  ```
- Scroll up for the first error message.
- Check `build.log` and `config.log` for detailed failure reasons.

---

### 🔐 Permission Denied

- If you see `Permission denied`:
  - Ensure you’re in a user-writable directory (like your home folder).
  - Do not run the entire script with `sudo` — only the system install steps use it internally.

---

### ⚠️ “Missing binaries” or “Skipping compression” errors

- This means the expected binary files were not created.
- Possible causes:
  - A build error occurred, but you missed it (check `build.log`)
  - `strip` was run before binaries were placed (unlikely in recent versions)

Check inside:

```bash
~/bitoreum-build/build/bitoreum-build
```

If that folder is empty, the build did not succeed.

---

### 🧪 "configure: error: Something failed"

- This means a required dependency is missing or not found.
- Review the lines above the error.
- You may need to install missing `-dev` packages manually.

---

### 🔁 Rebuilding After Failure

If a build fails or you change targets:

```bash
make clean && make distclean
./autogen.sh
./configure --prefix=...  # match your original config
make -j$(nproc)
```

Or simply re-run the script.

---

### 🧵 Not Enough RAM / System Freezes

If you’re on a small VPS or embedded system:

- Add swap space:
  ```bash
  sudo fallocate -l 4G /swapfile
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
  ```
- Reduce `make` threads:
  ```bash
  make -j2
  ```

---

### 📜 Log Files

All major build stages are logged:

- `build.log` — Release build output
- `build_debug.log` — Debug build output
- `config.log` — Release config output
- `config_debug.log` — Debug config output

Use `less` or `grep` to find problems:

```bash
less build.log
grep error build_debug.log
```

---

## 📬 Still Stuck?

- Open an issue on GitHub:  
  [https://github.com/Nikovash/bitoreum-builder/issues](https://github.com/Nikovash/bitoreum-builder/issues)
- Include:
  - Your OS and architecture
  - A copy of the error output
  - Any relevant log files

We'll help you get up and building!

