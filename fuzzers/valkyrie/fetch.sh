#!/bin/bash
set -ex

##
# Pre-requirements:
# - env FUZZER: path to fuzzer work dir
##

git clone --no-checkout https://github.com/ValkyrieFuzzer/valkyrie.git "$FUZZER/repo"
git -C "$FUZZER/repo" checkout 399e966d299ad0f922a53c67f44e0b5d29c00e1b

cp "$FUZZER/src/valkyrie_driver.c" "$FUZZER/repo/valkyrie_driver.c"
