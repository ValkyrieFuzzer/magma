#!/bin/bash
set -ex

##
# Pre-requirements:
# - env FUZZER: path to fuzzer work dir
# - env TARGET: path to target work dir
# - env MAGMA: path to Magma support files
# - env OUT: path to directory where artifacts are stored
# - env CFLAGS and CXXFLAGS must be set to link against Magma instrumentation
##

export CARGO_HOME="$HOME/.cargo/"
export PATH="$CARGO_HOME/bin:$PATH"
export PATH="$FUZZER/llvm_install/clang+llvm/bin:$PATH"
export PATH="~/go/bin:$PATH"
export LD_LIBRARY_PATH="$FUZZER/llvm_install/clang+llvm/lib:$LD_LIBRARY_PATH"

mkdir -p $OUT/valkyrie-asan
mkdir -p $OUT/valkyrie-fast
mkdir -p $OUT/valkyrie-track

export LIBS="-lc++ $LIBS"
export CFLAGS="-fpie -fpic -g $CFLAGS"
export CXXFLAGS="-fpie -fpic -g -stdlib=libc++ $CXXFLAGS"

create_rule_list() {

    # Create taint rule list for track target
    cd $1
    source "$TARGET/configrc"

    # Don't create taint rule list for the following libraries
    LIB_BLACKLIST=(linux-vdso libc++abi libgcc_s libc libc-2\.27 ld-2\.27 ld-linux-x86-64)

    # Discard taint for all linked libraries
    for P in "${PROGRAMS[@]}"; do
        # Command ldd prints all shared librarie referenced by binary
        for L in $(ldd "./$P" | awk 'NF == 4 {print $3}; NF == 2 {print $1}'); do
            # Canonicalize symbol links to shared libraries
            L=$(readlink -f $L)
            # Extract library name and regex match against blacklist
            LIB_NAME=$(basename $L | sed 's/\.so[.0-9]*//')
            if [[ ! " ${LIB_BLACKLIST[@]} " =~ " $LIB_NAME " ]]; then
                "$FUZZER/repo/tools/gen_library_abilist.sh" $L discard >> "$TARGET/repo/abilist.txt"
            fi
        done
    done
}

instrument_gclang() {
# Build using gclang first.
(
    export CC="/home/go/bin/gclang -g"
    export CXX="/home/go/bin/gclang++ -g"
    export OUT="$OUT/bc"
    export LDFLAGS="$LDFLAGS -L$OUT"
    export LIBS="$LIBS -l:valkyrie_driver.o -lc++"

    "$MAGMA/build.sh"
    "$TARGET/build.sh"

    source "$TARGET/configrc"
    cd $OUT
    for P in "${PROGRAMS[@]}"; do
        get-bc -o $P-orig.bc $P
        opt -break-crit-edges -o $P.bc $P-orig.bc
    done
    cd ../..
)
create_rule_list "$OUT/bc"

source $FUZZER/build_bc.sh
# Build fast and track target based on `$TARGET/build.sh`.
# We have to manually port build script to `build_bc.sh` because
# there is no post-build action script we can use.
source "$TARGET/configrc"

# Build track target
(
    export CC="$FUZZER/repo/bin/angora-clang"
    export CXX="$FUZZER/repo/bin/angora-clang++"
    export OUT=$OUT/valkyrie-track
    export LDFLAGS="$LDFLAGS -L$OUT/../bc -L$FUZZER/repo/bin/lib"

    export USE_TRACK=1
    export ANGORA_TAINT_RULE_LIST="$TARGET/repo/abilist.txt"

    for P in "${PROGRAMS[@]}"; do
        build_bc $P &
    done
    wait
)
# Build fast target
(
    export CC="$FUZZER/repo/bin/angora-clang"
    export CXX="$FUZZER/repo/bin/angora-clang++"
    export OUT=$OUT/valkyrie-fast
    export LDFLAGS="$LDFLAGS -L$OUT/../bc"

    export USE_FAST=1

    for P in "${PROGRAMS[@]}"; do
        build_bc $P &
    done
    wait
)

# Build asan
(
    export CC="clang"
    export CXX="clang++"
    export OUT=$OUT/valkyrie-asan
    export LDFLAGS="$LDFLAGS -L$OUT/../bc"
    export LIBS="-lc++ $LIBS -fsanitize=address -U_FORTIFY_SOURCE -lrt"

    for P in "${PROGRAMS[@]}"; do
        build_bc $P &
    done
    wait
)

# NOTE: We pass $OUT directly to the target build.sh script, since the artifact
#       itself is the fuzz target. In the case of Angora, we might need to
#       replace $OUT by $OUT/fast and $OUT/track, for instance.

}

instrument_lto() {
# Build fast and track target based on `$TARGET/build.sh`.
export CC="$FUZZER/repo/bin/angora-clang"
export CXX="$FUZZER/repo/bin/angora-clang++"
source "$TARGET/configrc"

# Build fast target
(
    export OUT=$OUT/valkyrie-fast
    export LDFLAGS="$LDFLAGS -L$OUT"

    export USE_FAST=1
    export LIBS="$LIBS -l:valkyrie_driver.o"

    LD=ld.lld "$MAGMA/build.sh"
    "$TARGET/build.sh"
)

create_rule_list "$OUT/valkyrie-fast"

# Build track target
(
    export OUT=$OUT/valkyrie-track
    export LDFLAGS="$LDFLAGS -L$OUT -L$FUZZER/repo/bin/lib"
    export LIBS="$LIBS -l:valkyrie_driver.o"

    export USE_TRACK=1
    export ANGORA_TAINT_RULE_LIST="$TARGET/repo/abilist.txt"

    LD=ld.lld "$MAGMA/build.sh"
    "$TARGET/build.sh"
)

# Build asan
(
    export OUT=$OUT/valkyrie-asan
    export LDFLAGS="$LDFLAGS -L$OUT/../bc"
    export CC="clang"
    export CXX="clang++"
    export LIBS="$LIBS -l:valkyrie_driver.o -fsanitize=address -U_FORTIFY_SOURCE -lrt"

    "$MAGMA/build.sh"
    "$TARGET/build.sh"
)

# NOTE: We pass $OUT directly to the target build.sh script, since the artifact
#       itself is the fuzz target. In the case of Angora, we might need to
#       replace $OUT by $OUT/fast and $OUT/track, for instance.
}

instrument_gclang
