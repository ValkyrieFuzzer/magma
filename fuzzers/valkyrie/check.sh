#!/bin/bash

# Prints out all shared libraries referenced by each fuzz target
for t in ../../targets/*
do
    lib=$(basename $t)
    # Get $PROGRAMS
    source $t/configrc
    for p in ${PROGRAMS[@]}
    do
        echo "***$lib/$p***"
        docker run -it --rm --entrypoint /bin/bash magma/valkyrie/$lib -c \
        "ldd /magma_out/valkyrie-fast/$p | cut -d' ' -f1 | xargs | tr ' ' '\n'"
        echo ""
    done
done

# Grep for dataflow sanitizer warning in track programs
for t in ../../targets/*
do
    lib=$(basename $t)
    source $t/configrc
    for p in ${PROGRAMS[@]}
    do
        echo "***$lib/$p***"
        args=${p}_ARGS
        args=${!args}
        if [ -z "$args" ]
        then
            args="@@"
        fi

        # Randomly pick a seed from magma's corpus
        seed=$(ls ../../targets/$lib/corpus/$p | shuf -n 1)
        args=$(echo $args | sed "s/@@/$seed/g")
        echo "***$args***"

        docker run -it --rm --entrypoint /bin/bash magma/valkyrie/$lib -c \
        "export LD_LIBRARY_PATH=\$FUZZER/llvm_install/clang+llvm/lib; \
        timeout -s KILL 8s /magma_out/valkyrie-track/$p $args 2>&1 \
        | grep 'WARNING\|timeout' | sort -u"
        echo ""
    done
done
