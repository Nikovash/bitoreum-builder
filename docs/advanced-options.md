# ⚙️ Advanced Options

This guide covers advanced customization, troubleshooting, and optimization techniques for the Bitoreum build script.

---

## 🧩 Custom Branches

When prompted to enter a branch name, you can specify:

- A **feature branch** for testing forks
- A **tag** (e.g., `v4.0.1.1`) if tags are enabled
- Any valid remote branch name

---

## 📦 Custom Output Directories

By default:

- Binaries are placed in:
  - `~/bitoreum-build/build/bitoreum-build`
  - `~/bitoreum-build/build_debug/bitoreum-build`
  - `~/bitoreum-build/build_not_strip/bitoreum-build`

- Compressed `.tar.gz` files go to:
  - `~/bitoreum-build/compressed/`

You can change these by editing the variables at the top of `build-bitoreum.sh`:

```bash
BUILD_DIR="$HOME/bitoreum-build/build"
COMPRESS_DIR="$HOME/bitoreum-build/compressed"
```

---

## 🧪 Enable Unit Tests (Optional)

By default, unit tests are disabled to speed up the build.  
To enable them:

1. Comment out or remove the `--disable-tests` flag in the `./configure` section
2. Rerun the script

---

## 🧵 Thread Tuning

The script uses:

```bash
make -j$(nproc)
```

Which uses all available CPU cores. You can limit this by modifying:

```bash
make -j4  # for 4 threads
```

---

## 🧾 Debug Builds

Debug binaries are compiled with symbols and no optimizations:

- Useful for troubleshooting crashes or stack traces
- Stored separately in `build_debug/`

---

## 🛑 Manual Screen Use

If you use `screen`, make sure to:

```bash
screen -S build
./bake.sh
```

To detach and reattach:

```bash
Ctrl+A D      # Detach
screen -r     # Reattach
```

---

## ❗ Troubleshooting

### "Missing binaries" errors?

Ensure the script didn't fail during `make`.  
Check the log files:

- `build.log`
- `build_debug.log`
- `config.log`
- `config_debug.log`

### Permission issues?

Make sure the script is executable:

```bash
chmod +x bake.sh
```

And that you're running in a directory you own (like `~/bitoreum-build`).

---

Still stuck?  
Open an issue on [GitHub](https://github.com/Nikovash/bitoreum-builder/issues).

