# 📤 Upload Utility Script

A simple Bash utility to upload compressed build files for either the **Yerbas** or **Bitoreum** project to an ownCloud server using WebDAV.

## 🔧 Features

- Supports both Yerbas and Bitoreum projects.
- Uploads all files from a specified `compressed` build directory.
- Logs upload activity to `/var/log/upload-builds.log`.
- Uses WebDAV with ownCloud-compatible tokens.

## 📁 Directory Structure

Your project directories should be structured as follows:

```
$HOME/
├── yerbas-build/
│   └── compressed/
└── bitoreum-build/
    └── compressed/
```

## 🚀 Usage

Make the script executable and make it system wide executable:

```bash
chmod +x upload
sudo cp upload /usr/bin
```

Then run:

```bash
upload --yerbas
```

or

```bash
upload --bitoreum
```

## 🔐 Setup

Before using the script, make sure to:

1. Set your `WEBDAV_URL` to the **full** path of the ownCloud WebDAV endpoint (e.g., `https://example.com/public.php/webdav/`).
2. Set the correct `SHARE_TOKEN` for each project in the script.

Example:

```bash
WEBDAV_URL="https://your.owncloud.server/public.php/webdav/"
SHARE_TOKEN="YourOwnCloudShareToken"
```

> **Note:** Ensure your token has upload permission.

## 📝 Logging

Logs are written to:

```
/var/log/upload-builds.log
```

Each upload entry includes:
- Timestamp
- Project name
- Filename
- Upload result (`SUCCESS` or `FAIL` with HTTP code)

## 📦 Dependencies

This script requires:

- `curl`
- Bash (v4+)

Ensure they're installed and available in your PATH.

## ⚠️ Troubleshooting

- Make sure the upload directory exists and contains files.
- Confirm the WebDAV URL and token are correct.
- Check permissions if `/var/log/upload-builds.log` fails to write (consider running with `sudo`).

## 📄 License

MIT License – feel free to use and modify.

---

> Created with ❤️ for Yerbas and Bitoreum build automation.
