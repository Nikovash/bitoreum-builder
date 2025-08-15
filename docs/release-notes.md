# Version 0.1
- Initial release
- Tested and works on Ubuntu 22.04, 24.04 & Mint Linux 22.1

# Version 0.2
- Added Pi support

# Version 0.5
- Fixed Pi issuance
- Tested on Ubuntu 18.04
- Added ownCloud uploader app

# Version 0.9
- Added first-run provision so the script does not attempt to update the OS on each run, only the first time
- Added better & simplified logging for this app in `bake_bread.log`
- Added Pi 32-bit support
- Added Windows 64-bit cross-compile function
- Fixed Pi commands for Ubuntu related to C++ hardening
- Changed script name from `build-bitoreum.sh` to `bake.sh`
- Added improved `Ampere` detection logic (still not all-inclusive)
- Added improved `Pi4+` detection logic
- `.tar.gz` for Linux builds
- `.zip` for Windows builds
- Logic cleanup
- Added option to build or skip the QT wallet, as it is not always needed and is resource-intensive
- Updated and expanded documentation

# Version 1.0
- Added universal build logic
- Corrected Pi4 parameters (works as long as you have a 64-bit OS installed)
- Removed Pi 32_bit Support - 32-bit ARM Support is now the standard
- Resolved numerous cross-compile issues and logic faults
- Fixed compression naming logic
- Fixed cross-compile `strip` logic
- Updated documents
- Increased testing hosts and targets to ensure extreme confidence when used on Ubuntu, Mint Linux, AlmaLinux, Oracle Linux, and, to a lesser extent, Debian
- Completed `dishy.sh`
