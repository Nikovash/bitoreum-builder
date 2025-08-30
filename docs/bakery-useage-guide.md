# Bakery Usage Guide

This is an extremely streamlined batch maker. Basic usage:

```bash
./bakery.sh <branch_or_tag> [<coin name> <Github Repo>]
# Example:
```
```bash
./bakery.sh v4.1.0.0 #Defaults to Bitoreum branch 4.1.0.0
```
OR
```bash
./bakery.sh 3.1.4.20 yerbas https://github.com/The-Yerbas-Endeavor/yerbas #Should build Yerbas Coin in branch 3.1.4.20
```

This script will run until it completes or encounters a cross-compilation error, at which point it should exit...

## The Recipe Book

If `recipe_book.conf` is missing or corrupted, the script will (re)create it. The following is a visual example, which can also be found in `recipe_book.sample`

```diff
Linux 64-bit,y,QT=y
Linux 32-bit,y,QT=y
Linux ARM 32-bit,y,QT=y
Linux ARM 64-bit,y,QT=y
Raspberry Pi 4+,n,QT=y
Oracle Ampere ARM,n,QT=n
Windows 64-bit,y,QT=y
```
Valid `$HOST` Names:
``` diff
Linux 64-bit
Linux 32-bit
Linux ARM 32-bit
Linux ARM 64-bit
Raspberry Pi 4+
Oracle Ampere ARM
Windows 64-bit
```

The line order above is not important, but the comma-delimited order IS critical. The comma-delimited items are defined:
```bash
<Item 1>,<Item 2>,<Item 3> # No space after commas
```
- **Item 1**: Build name or `$HOST` // These must match EXACTLY to the example or the matrix is considered corrupt
- **Item 2**: Whether this target will be built (`y|n`)
- **Item 3**: Whether QT will be built

> **Note:** This script will likely fail unless you have all headers for cross-compiling installed on your system. Installing those is outside the scope of this script and project
