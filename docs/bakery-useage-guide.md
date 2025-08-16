# Bakery Usage Guide

This is an extremely streamlined batch maker. Basic usage:

```bash
./bakery.sh <branch_or_tag>
# Example:
```
```bash
./bakery.sh v4.1.0.0
```

This script will run until it complets or encounters a cross-compile errors, at which point it exits.

## The Recipe Book

If `recipe_book.conf` is missing or corrupted, the script will (re)create it. THe following is a visual example, which can also be found in `recipe_book.sample`

```text
Linux 64-bit,y,QT=y
Linux 32-bit,y,QT=y
Linux ARM 32-bit,y,QT=y
Linux ARM 64-bit,y,QT=y
Raspberry Pi 4+,n,QT=y
Oracle Ampere ARM,n,QT=n
Windows 64-bit,y,QT=y
```

The order above is important. The comma-delimited items are defined:

- **Item 1**: Build name or `$TRIPLE_HOST`
- **Item 2**: Whether this target will be built (`y|n`)
- **Item 3**: Whether QT will be built

> **Note:** This script will likely fail unless you have all headers for cross-compiling installed on your system. Installing those is outside the scope of this script and project.
