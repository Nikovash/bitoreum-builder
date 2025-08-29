# ⚙️ Advanced Options

This guide covers advanced customization, troubleshooting, and optimization techniques for the Bitoreum build script.

---

## 🧩 Custom Branches

When prompted to enter a branch name, you can specify:

- A **feature branch** for testing forks
- A **tag** (e.g., `v4.0.1.1`) if tags are enabled
- Any valid remote branch name

---

## QT Optional Build
A simple Y|n prompt that allows you do build or NOT build the QT binary, its resource intensive and not always needed

Works by defining variables on build

```diff
NO_QT=1 // Should disable QT from being built during `depends` make
BUILD_QT=false
CONFIGURE_FLAGS="--with-gui=no" // In case QT is still made in `depends` disabled build in configure stage
```
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

Ensure the script didn't fail during `make` process, thse logs are found in `~/bitoreum-build/bitoreum/depends` and `~/bitoreum-build/bitoreum` folders respectively

- `build.log`
- `build_debug.log`
- `config.log`
- `config_debug.log`

There are now script specific log(s) now too that are found in the `bake`
- `bake_bread.log` (bake.sh)
- `bake_creampie.log` (refire.sh)
- `dishy.sh` only outputs on the screen what he is doing and doesn't log anything, because dishy's just do...

### Permission issues?

Make sure the script is executable, starting in version 1.0 {bake.sh, refire.sh, & dishy.sh} come flagged executable on release, but sometimes things happen:

```bash
chmod +x bake.sh
```

And that you're running in a directory you own (like `~/bitoreum-build`).

---

Still stuck?  
Open an issue on [GitHub](https://github.com/Nikovash/bake/issues).

