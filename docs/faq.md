# ❓ Frequently Asked Questions (FAQ)

---

### 🔧 Q: What platforms can I build for?

A: The script supports Debian fork Linux Distrobutins wit hthe following architecture types:

- Linux 64-bit (`x86_64-pc-linux-gnu`)
- Linux 32-bit (`i686-pc-linux-gnu`)
- Linux ARM 32-bit (`arm-linux-gnueabihf`)
- Linux ARM 64-bit (`aarch64-linux-gnu`)
- Raspberry Pi 4 or better (`aarch64-linux-gnu`)
- Ampere (`aarch64-linux-gnu`)

---

### 🐍 Q: Why does it install Python 3.10.17?

A: Crystal Bitoreum was forked from, Bitoreum, which was forked from Raptoreum, hic was forked from Dash, which was based on Bitcoin, some of these dependecies require Python 3.10. Modern OS's have moved onto Python 3.12+. This script installs the last version of Python 3.10 as an alt install. This does not disrupt the python required for your OS and can be called relative to the instance of a terminal window, hence the use of screen.

---

### 📦 Q: Where are the final `.tar.gz` files?

A: Compressed binaries are placed in:

```bash
~/bitoreum-build/compressed/
```

Each `.tar.gz` archive includes binaries and a checksum file.

---

### 🔁 Q: Can I run the script multiple times?

A: Maybe... I have not yet tested it! Each run **should**:

- Cleans up previous builds
- Reconfigures based on your target
- Creates new output folders and archives

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

A: Absolutely. When prompted, enter your custom branch name.  
Just make sure it’s public or you have Git access.

---

### 📜 Q: How do I verify checksums?

Inside each build folder or `.tar.gz` archive:

```bash
sha256sum -c checksums-<version>.txt
```

---

### 🧼 Q: How do I clean up old builds?

From the project directory:

```bash
make clean && make distclean
rm -rf ~/bitoreum-build/*
```
OR (some older distros are wierd about hte use of ~):

```bash
rm -rf $HOME/bitoreum-build/*
```

---

Still have questions?  
Open an issue at: [https://github.com/Nikovash/bitoreum-builder/issues](https://github.com/Nikovash/bitoreum-builder/issues)
