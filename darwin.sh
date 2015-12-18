#!/bin/bash

set -ex

BINUTILS_VERSION=2.25.1
GCC_VERSION=5.3.0
AVRLIBC_REVISION=2494
AVRDUDE_VERSION=6.2

NUMCPU=`sysctl -n hw.ncpu`

SUFFIX=`date +"%Y%m%d"`
ROOT=`pwd`

export PREFIX="$HOME/sdk/avr-$SUFFIX"
export PATH="$PREFIX/bin:$PATH"

# must
brew install gmp mpfr libmpc

# for avr-libc bootsrap (from svn head)
brew install autoconf automake

# for avrdude
brew install libusb libelf libftdi

function build_binutils() {
	binutils=binutils-$BINUTILS_VERSION

	if [ ! -e $binutils.tar.gz ]; then
		wget http://ftp.gnu.org/gnu/binutils/$binutils.tar.gz
	fi

	if [ ! -e $binutils ]; then
		tar xzvf $binutils.tar.gz
	fi

	cd $binutils

	rm -rf obj-avr
	mkdir obj-avr
	cd obj-avr
	../configure --prefix=$PREFIX --target=avr --disable-nls
	make -j $NUMCPU
	make install
}

function build_gcc() {
	gcc=gcc-$GCC_VERSION

	if [ ! -e $gcc.tar.bz2 ]; then
		wget http://ftp.tsukuba.wide.ad.jp/software/gcc/releases/$gcc/$gcc.tar.bz2
	fi

	if [ ! -e $gcc ]; then
		tar xzvf $gcc.tar.bz2
	fi

	cd $gcc

	rm -rf obj-avr
	mkdir obj-avr
	cd obj-avr
	../configure --prefix=$PREFIX --target=avr --enable-languages=c,c++ --disable-nls --disable-libssp --with-dwarf2 --with-gmp=/usr/local --with-mpfr=/usr/local --with-mpc=/usr/local
	make -j $NUMCPU
	make install
}

function build_avrlibc() {
	## avr-libc http://download.savannah.gnu.org/releases/avr-libc/

	#wget http://download.savannah.gnu.org/releases/avr-libc/avr-libc-1.8.1.tar.bz2
	#tar xzvf avr-libc-1.8.1.tar.bz2
	# 1.8.1 is failed with gcc 5.2.0
	# avr/bin/ld: cannot find crtatmega328p.o: No such file or directory

	if [ ! -e avr-libc-trunk ]; then
		svn co -r $AVRLIBC_REVISION svn://svn.savannah.nongnu.org/avr-libc/trunk avr-libc-trunk
	else
		svn update -r $AVRLIBC_REVISION
	fi

	cd avr-libc-trunk/avr-libc
	./bootstrap
	./configure --prefix=$PREFIX --build=`./config.guess` --host=avr
	make -j $NUMCPU
	make install
}

function build_avrdude() {
	avrdude=avrdude-$AVRDUDE_VERSION

	if [ ! -e $avrdude.tar.gz ]; then
		wget http://download-mirror.savannah.gnu.org/releases/avrdude/avrdude-6.2.tar.gz
	fi

	if [ ! -e $avrdude ]; then
		tar xzvf $avrdude.tar.gz
	fi

	cd $avrdude

	rm -rf obj-avr
	mkdir obj-avr
	cd obj-avr
	../configure --prefix=$PREFIX CFLAGS="-I/usr/local/include -L/usr/local/lib "
	make -j $NUMCPU
	make install
}

cd $ROOT
build_binutils

cd $ROOT
build_gcc

cd $ROOT
build_avrlibc

cd $ROOT
build_avrdude

avr-ld --version
avr-gcc --version
avrdude -?

