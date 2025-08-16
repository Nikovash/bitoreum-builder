# Notes on Cross Compiling:

## Important
Currently this has only been tested using an x86 system Ubuntu 18.04 as a base, and cross compiling to other targets with great success.

# Install the ARM 32-bit cross toolchain (Ubuntu/Debian)

sudo apt-get update
sudo apt-get install \
	gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf \
	binutils-arm-linux-gnueabihf libc6-dev-armhf-cross \

# x86_64 - i686 (32-bit Linux)

## Fix (Ubuntu 18.04, GCC 7.5):

sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get install \
	gcc-7-multilib g++-7-multilib libc6-dev-i386 \
	lib32stdc++-7-dev libstdc++-7-dev:i386

## Fix (newer Ubuntu, GCC 9/10/11+):

sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get install \
	g++-multilib libc6-dev-i386 lib32stdc++-dev
	
# x86_64 -> aarch64 (64-bit ARM)

sudo apt-get update
sudo apt-get install \
	gcc-aarch64-linux-gnu g++-aarch64-linux-gnu libc6-dev-arm64-cross
	

Some of these have already been added into the script some have not this is merely a starting point to help you on your cross compile journey... you know, don't stop... believeing....
