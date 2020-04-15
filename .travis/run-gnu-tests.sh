#!/bin/bash

# ref: https://github.com/uutils/coreutils/issues/1431
# Need `makeinfo` from 'texinfo'
sudo apt update
sudo apt --yes install autopoint gperf texinfo
# Build `uutils` and individual packages
make PROFILE=release build-uutils build-pkgs
# Clone, configure, and build GNU tests
BUILD_DIR="$PWD/target/release/"
cd ..
GNU_TESTS_DIR="$PWD/gnu-coreutils-tests"
mkdir -p "$GNU_TESTS_DIR"
cd "$GNU_TESTS_DIR"
git clone --depth 1 https://github.com/coreutils/coreutils.git
git clone https://github.com/coreutils/gnulib.git
GNULIB_SRC_DIR="$PWD/gnulib"
cd coreutils/
./bootstrap --gnulib-srcdir="$GNULIB_SRC_DIR"
./configure --quiet --disable-gcc-warnings
# * change the PATH in the Makefile to test the uutils coreutils instead of the GNU coreutils
sed -i "s/^[[:blank:]]*PATH=.*/  PATH='${BUILD_DIR//\//\\/}\$(PATH_SEPARATOR)'\"\$\$PATH\" \\\/" Makefile
ulimit -t 60; make -j "$(nproc)" check SUB_DIRS=. VERBOSE=no
## ulimit -t 60; make -j "$(nproc)" check SUB_DIRS=. RUN_EXPENSIVE_TESTS=yes VERBOSE=no
## ulimit -t 600; make -j "$(nproc)" check SUB_DIRS=. RUN_EXPENSIVE_TESTS=yes RUN_VERY_EXPENSIVE_TESTS=yes VERBOSE=no
