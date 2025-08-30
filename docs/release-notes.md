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
- Added option to build or skip the QT wallet (resource-intensive, not always needed)  
- Updated and expanded documentation  

# Version 1.0
- Added universal build logic  
- Corrected Pi4 parameters (works as long as a 64-bit OS is installed)  
- Removed Pi 32-bit Support — 32-bit ARM support is now the standard  
- Resolved numerous cross-compile issues and logic faults  
- Fixed compression naming logic  
- Fixed cross-compile `strip` logic  
- Updated documentation  
- Increased testing hosts and targets to ensure reliability across Ubuntu, Mint Linux, AlmaLinux, Oracle Linux, and, to a lesser extent, Debian  
- Completed `dishy.sh`  

# Version 1.1
- Cleaned up code formatting errors (likely from copy-paste on Windows)  
- Removed most debugging code  
- Corrected artifact naming for consistency  

# Version 1.2
- Production version  
- Created `bakery.sh` (batch release maker)  
- Corrected version init on first run  
- Added universal script versioning  
- Added release archive naming to match GitHub Runner Actions  
- Added notes on cross-compile OS packages  
- `upload` utility now shipped as executable  
- Updated `upload`’s README.md  
- Added `bakery.sh` usage guide  

# Version 1.8
- Rolled back code to a working baseline (previous merge introduced regressions)  
- Removed Debian support (newer `GCC` fails with QT — requires patching outside scope of `bake`/`bakery`)  
- Improved `dishy.sh` cleanup routine (aware that `bakery.sh` always invokes it)  
- Code cleanup for readability and removal of stray text  
- Improved `[INFO]` and `[ERROR]` formatting for less chatty logs  
- Improved `bake.sh` and `bakery.sh` logic  
- Updated `bakery.sh` usage guide  
- Aligned code with future multi-coin support goals  
- When QT is flagged `n`, `depends` is built with `NO_QT=1` (faster builds)  
- If `dishy.sh` is not found locally, `bakery.sh` attempts to fetch it from GitHub  

# Version 1.9
- `bakery.sh` now supports multi-coin building  
- Documentation updated to reflect new repository naming  
- `dishy.sh` usage updated for multi-coin support  
