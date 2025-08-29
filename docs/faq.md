# ❓ Frequently Asked Questions (FAQ)

---

### Q: Why the name change from `build-bitoreum.sh` to `bake.sh`?

A: There are a couple of reasons, 

- **B**itoreum m**ake** = `bake.sh`
- Fewer characters to type, leading to hopefully less errors
- Future plan to add other coins making this more a semi-universal builder

### 🔧 Q: What platforms can I build for?

A: The script supports Debian fork Linux Distributions with the following architecture types:

- Linux 64-bit		(`x86_64-pc-linux-gnu`)
- Linux 32-bit		(`i686-pc-linux-gnu`)
- Linux ARM 32-bit	(`arm-linux-gnueabihf`)
- Linux ARM 64-bit	(`aarch64-linux-gnu`)
- Raspberry Pi 4+	(`aarch64-linux-gnu`)
- Ampere		(`aarch64-linux-gnu`)
- Windows 64-bit	(`x86_64-w64-mingw32`) Cross compile

---

### 🐍 Q: Why does it install Python 3.10.17?

A: Crystal Bitoreum was forked from, Bitoreum, which was forked from Raptoreum, which was forked from Dash, which was based on Bitcoin, some of these dependecies require Python 3.10. Modern OS's have moved onto Python 3.12+. This script installs the last version of Python 3.10 as an alt install. This does not disrupt the python required for your OS and can be called relative to the instance of a terminal window, hence the use of screen.

---

### 📦 Q: Where are the final `.tar.gz` and/or `*.zip` files?

A: Compressed binaries are placed in:

```bash
~/bitoreum-build/compressed/
```

Each `.tar.gz` or `*.zip` archive includes binaries and a checksum file.

---

### 🔁 Q: Can I run the script multiple times?

A: No, you have delete the `bitoreum-build` folder this is a bug that needs to be addressed for later use, for a simplified cleaning process we have included your very own `dishy.sh` a cleaning script that resets everything back for a clean kitchen!

---

### 📁 Q: What are the different build directories?

- `build/bitoreum-build`: Standard release (stripped)
- `build_debug/bitoreum-build`: Debug build (symbols included)
- `build_not_strip/bitoreum-build`: Non-stripped release build

Each gets its own compressed archive.

---

### 🖥️ Q: Can I run this on a VPS?

A: Yes, but you may need to:

- Add swap space if you have <2GB RAM
- Reduce the number of build threads (e.g., `make -j2`)

---

### 📉 Q: The build is slow — what can I do?

A:

- Use a machine with more CPU cores (`make -j$(nproc)`)
- Ensure you’re not building inside a low-power container or VM
- Add RAM or swap for large builds

---

### 🔑 Q: Can I build with my own fork?

A: Absolutely. You just need to modify the bake.sh file to add in your own GitHub repository URL. You may also need build dependancies that I do not so be aware of that!

---

### 📜 Q: How do I verify checksums?

Inside each build folder or `.tar.gz` or `*.zip` archive:

```bash
sha256sum -c checksums-<version>.txt
```
---

### 🧼 Q: How do I clean up old builds?

Within the `bake` folder is a new helper, every good kitchen needs a dishy! This action is destructive, so use with caution!!!
```bash
$HOME/bake/./dishy.sh [<coin-name>] # Defaults to bitoreum if no coin is passed
```
---

Still have questions?  
Open an issue at: [https://github.com/Nikovash/bake/issues](https://github.com/Nikovash/bake/issues)