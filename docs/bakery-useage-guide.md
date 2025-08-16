# Bakery Usage Guide

this is an extremely streamlined batch maker basic usage is just:

./bakery.sh <Brach_OR_Tag> Example:
```bash
./bakery.sh v4.1.0.0
```
The script will attempt to go unless it hits cross compile errors and exits

## Recipie Book

There is one other piece of data that if it isnt there it will create a `recipe_book.conf` for what builds it will attempt and if a QT will be built
```diff
Linux 64-bit,y,QT=y
Linux 32-bit,y,QT=y
Linux ARM 32-bit,y,QT=y
Linux ARM 64-bit,y,QT=y
Raspberry Pi 4+,n,QT=y
Oracle Ampere ARM,n,QT=n
Windows 64-bit,y,QT=y
```
The order is important. **Item 1** is the build name or $TRIPLE_HOST. **Item 2** is if this is going to be built with y|n flags. **Item 3** is if QT is going to be built

### This script will likey fail unless you have all the headers for corss copile installed on your system, that is outside the socpe of this script
