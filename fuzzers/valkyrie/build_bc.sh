# Given bytecode as `$1`, compile it.
#
# Note that you don't have to explictly link `magma.o` or any fuzzer driver,
# as those are already in the bytecode.
#
# This script exists to link correct other runtime libraries, for example,
# in poppler, we need to add `-ljpeg`, '-lpng', etc.
# Other popular that probably all bc needs are `-lz`, `-lm`, `-lrt`, etc.
build_bc(){
    if [ $1 == "libpng_read_fuzzer" ]
    then
        $CXX $CXXFLAGS -std=c++11 \
        $OUT/../bc/$1.bc -o $OUT/libpng_read_fuzzer \
        -lz -lrt\
        $LDFLAGS
    fi
    if [ $1 == "tiff_read_rgba_fuzzer" ]
    then
        $CXX $CXXFLAGS -v -std=c++11 \
            $OUT/../bc/$1.bc -o $OUT/$1 \
            -lz -ljpeg -Wl,-Bstatic -llzma -Wl,-Bdynamic -lrt  \
            $LDFLAGS
    fi
    if [ $1 == "tiffcp" ]
    then
        $CC $CFLAGS -v \
            $OUT/../bc/$1.bc -o $OUT/$1 \
            -lz -lm -ljpeg -llzma -lrt\
            $LDFLAGS
    fi

    if [ $1 == "xmllint" ]
    then
        $CC $CFLAGS \
            $OUT/../bc/$1.bc -o $OUT/$1 \
            -lm -lz -llzma -lrt \
            $LDFLAGS
    fi
    if [ $1 == "libxml2_xml_read_memory_fuzzer" ]  || [ $1 == "libxml2_xml_reader_for_file_fuzzer" ]
    then
        $CXX $CXXFLAGS -std=c++11  \
            $OUT/../bc/$1.bc -o $OUT/$1 \
            -lz -llzma -lrt \
            $LDFLAGS
    fi
    if [ $1 == "asn1" ] || [ $1 == "asn1parse" ] || [ $1 == "bignum" ] || [ $1 == "server" ] || [ $1 == "client" ] || [ $1 == "x509" ]
    then
        $CC $CFLAGS \
            $OUT/../bc/$1.bc  -o $OUT/$1 \
            -L$TARGET/repo \
            -lutil -lcrypto -lssl -lrt -lm -ldl -pthread \
            $LDFLAGS
    fi
    if [ $1 == "json" ] || [ $1 == "exif" ] || [ $1 == "unserialize" ] || [ $1 == "parser" ]
    then
        $CXX $CXXFLAGS -std=c++11 \
            $OUT/../bc/$1.bc -o $OUT/$1 \
            -lutil -lrt -lm -ldl -licuio -licui18n -licuuc -licudata -lcrypt -lresolv -lpthread \
            $LDFLAGS
    fi
    if [ $1 == "pdf_fuzzer" ] || [ $1 == "pdfimages" ] || [ $1 == "pdftoppm" ]
    then
        $CXX $CXXFLAGS -std=c++11  \
            $OUT/../bc/$1.bc -o $OUT/$1 \
            -lz -lm -lrt -ldl -ljpeg -lopenjp2 -lpng -ltiff -llcms2 -lpthread -pthread \
            $LDFLAGS
    fi
    if [ $1 == "sqlite3_fuzz" ]
    then
        $CC $CFLAGS \
            $OUT/../bc/$1.bc -o $OUT/$1 \
            -lm -lz -ldl -lrt -lpthread \
            $LDFLAGS
    fi
}
