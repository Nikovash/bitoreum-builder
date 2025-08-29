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

# Version 1.1
- Cleaned up code of weird formatting errors, likely carry-over from copy and paste on Windows
- Removed most debugging code
- Corrected Artifact naming for consistency

# Version 1.2
- Production Version
- created bakery.sh - the batch release maker
- Corrected Version Init on first run
- Added universal script versioning
- Added Release archive to match Github Runner Actions
- Added notes on cross compile OS packages
- `upload` utility is now shipped as executable
- Updated `upload`'s README.md
- Added `bakery.sh` usage 

# Version 1.8
- Rolled back code to a time when things worked, at some point we copied old code into new code and broke things previously working
- Removed Debian code, newer `GCC` blew up on QT so either QT needs to be updated or patched outside the scope of `bake` and `bakery`
- Improved `dishy.sh` by making the cleaning process more robust and inclusive of the fact that `bakery.sh` always calls on its dishy
- Code cleaning for readability and remove stray text
- Improved [INFO] and [ERROR] readability for 'less chatty' log(s)
- Improved `bake.sh` AND `bakery.sh` script logic
- Updated `bakery.sh` Usage Guide
- Tuning code to be in line with future goal of this system being multi-coin supported
- In `bakery.sh` When QT is flagged `n` depends is build with `NO_QT=1` this should improve build times significantly
- On `bakery.sh` run, if `dishy.sh` is not found locally, attempts to download it from GitHub

# Version 1.9
- `bakery.sh` now supports multi-coin building
- Documents have been updated to reflect new Repository naming
- `dishy.sh` Usage has changed to accommodate multi-coin usage

