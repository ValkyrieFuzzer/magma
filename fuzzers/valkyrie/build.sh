#!/bin/bash
set -ex

##
# Pre-requirements:
# - env FUZZER: path to fuzzer work dir
##

if [ ! -d "$FUZZER/repo" ]; then
    echo "fetch.sh must be executed first."
    exit 1
fi

cd "$FUZZER/repo"

# Install Rust
export RUSTUP_HOME="$HOME/.cargo/"
export CARGO_HOME="$HOME/.cargo/"
export PATH="$CARGO_HOME/bin:$PATH"
./build/install_rust.sh

# Install gllvm
go get github.com/SRI-CSL/gllvm/cmd/...
export PATH="~/go/bin:$PATH"

# Install LLVM
if [ ! -d $FUZZER/llvm_install ]
then
    mkdir -p "$FUZZER/llvm_install"
    PREFIX="$FUZZER/llvm_install" ./build/install_llvm.sh
fi
export PATH="$FUZZER/llvm_install/clang+llvm/bin:$PATH"
export LD_LIBRARY_PATH="$FUZZER/llvm_install/clang+llvm/lib:$LD_LIBRARY_PATH"

# Build Angora
# Specifying C flags as empty does nothing when build docker image.
# But it helps when debugging in a container where these flags are set
# to fuzzing parameters.
CLIBS="" CFLAGS="" CXXFLAGS="" CC=clang CXX=clang++ ./build/build.sh

# Compile valkyrie_driver.c

# Only used when LTO
#mkdir -p "$OUT/valkyrie-fast"
#USE_FAST=1 "./bin/angora-clang" -Wl,--demangle $CFLAGS -c "valkyrie_driver.c" -fPIC -o "$OUT/valkyrie-fast/valkyrie_driver.o"

#mkdir -p "$OUT/valkyrie-track"
#USE_TRACK=1 "./bin/angora-clang" -Wl,--demangle $CFLAGS -c "valkyrie_driver.c" -fPIC -o "$OUT/valkyrie-track/valkyrie_driver.o"

mkdir -p "$OUT/bc"
"gclang" $CFLAGS -c "valkyrie_driver.c" -fPIC -o "$OUT/bc/valkyrie_driver.o"
