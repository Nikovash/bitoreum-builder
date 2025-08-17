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

## 📝Logging & 🔐Configure

Logs are written to:

```
/var/log/upload-builds.log
```

Each upload entry includes:
- Timestamp
- Project name
- Filename
- Upload result (`SUCCESS` or `FAIL` with HTTP code)

Before we run the app the first time we can create and take ownership of the log file
```bash
sudo touch /var/log/upload-builds.log
sudo chown $USER /var/log/upload-builds.log
```

In this block there is only one thing that needs changing:
```bash
LOG_FILE="/var/log/upload-builds.log"
WEBDAV_URL="web address of ownCloud server"
COMPRESS_DIR=""
SHARE_TOKEN=""
PROJECT=""
```
The `WEBDAV_URL=""` has to point to your own ownCloud or Nextcloud server! DO not fill out other sectiosn we will change the token at a later time and place! This `URL` follows a special format:

```bash
WEBDAV_URL="https://yourownCloudServer.cc/public.php/webdav"
```

You create a folder and set sharing on with an upload only option. This will give you a long url string ending in a random strin of letters and numbers such as:
```bash
https://yourownCloudServer.cc/index.php/s/Ub2XVo2zzc6A6gG
```
The "`Ub2XVo2zzc6A6gG`" is the part we want and it goes in the following block:
```bash
elif [[ "$1" == "--bitoreum" ]]; then
    PROJECT="bitoreum"
    COMPRESS_DIR="$HOME/bitoreum-build/compressed"
    SHARE_TOKEN="Ub2XVo2zzc6A6gG"
```
Save & exit by:
```bash
CNTL+o
CNTL+x
```
> **Note:** Ensure your token has upload permission

## 🚀 Usage

Make the script executable and make it system wide executable:

```bash
sudo cp upload /usr/bin
```
script should be executable on default, but if not simplly run
```bash
sudo chmod +x /usr/bin/upload
```
Then run:

```bash
upload --yerbas
```

or

```bash
upload --bitoreum
```

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
