#!/bin/bash

##
# Pre-requirements:
# - env FUZZER: path to fuzzer work dir
# - env TARGET: path to target work dir
# - env OUT: path to directory where artifacts are stored
# - env SHARED: path to directory shared with host (to store results)
# - env PROGRAM: name of program to run (should be found in $OUT)
# - env ARGS: extra arguments to pass to the program
# - env FUZZARGS: extra arguments to pass to the fuzzer
##

# Required for llvm-config
export PATH="$FUZZER/llvm_install/clang+llvm/bin:$PATH"
export LD_LIBRARY_PATH="$FUZZER/llvm_install/clang+llvm/lib:$LD_LIBRARY_PATH"
export ANGORA_DISABLE_CPU_BINDING=1

"$FUZZER/repo/target/release/fuzzer" -M 200 -i "$TARGET/corpus/$PROGRAM" -o "$SHARED/findings" \
    -t "$OUT/valkyrie-track/$PROGRAM" -s "$OUT/valkyrie-asan/$PROGRAM" $FUZZARGS -- "$OUT/valkyrie-fast/$PROGRAM" $ARGS 2>&1
