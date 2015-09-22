pkgname="file"
pkgdesc="TODO"
pkgver="5.25"

sources=(
    "${pkgname}-${pkgver}.tar.gz::https://github.com/file/file/archive/FILE${pkgver/./_}.tar.gz"
)
sums=(
    "5c1c25ad065dbfb1457914462a7d6959502b810d95badbc3cc03f30f74c55e5e"
)

library=false
binary=true

dependencies=()

# Common variables.
_builddir="$BBUILD_SOURCE_DIR/$pkgname-FILE${pkgver/./_}"


function prepare() {
    cd "$_builddir"

    info2 "Preventing tests"
    echo "all:\n\ttrue\n\ninstall:\n\ttrue\n\n" > tests/Makefile.in || return 1

    info2 "Fixing headers"
    sed -i 's/memory.h/string.h/' src/encoding.c src/ascmagic.c || return 1
}


function build() {
    cd "$_builddir"

    info2 "Reconfiguring"
    autoreconf -i || return 1

    info2 "Configuring for native"
    ./configure \
        --disable-shared || return 1

    info2 "Building for native"
    make || return 1

    local nativePath
    nativePath="$BBUILD_SOURCE_DIR"/file
    cp src/file "$nativePath"
    chmod +x "$nativePath"

    info2 "Cleaning"
    make distclean || return 1

    info2 "Configuring for cross-compilation"

    local ourCFLAGS
    ourCFLAGS="${BBUILD_STATIC_FLAGS}"
    if [[ "$BBUILD_TARGET_PLATFORM" != "darwin" ]]; then
        ourCFLAGS="$ourCFLAGS -Wl,-static -static-libgcc"
    fi

    CC="${CC} ${BBUILD_STATIC_FLAGS}" \
    CFLAGS="${ourCFLAGS}" \
    CPPFLAGS="${CPPFLAGS:-} -D_GNU_SOURCE -D_BSD_SOURCE" \
    ./configure \
        --host=${BBUILD_CROSS_PREFIX} \
        --build=i686 \
        || return 1

    info2 "Patching Makefile to use native binary"
    sed -i "s|FILE_COMPILE = file\${EXEEXT}|FILE_COMPILE = ${nativePath}|" \
        magic/Makefile || return 1

    info2 "Building"
    make || return 1
}


function package() {
    cd "$_builddir"

    cp src/file "$BBUILD_OUT_DIR"/file
    ${STRIP} "$BBUILD_OUT_DIR"/file

    cp magic/magic.mgc "$BBUILD_OUT_DIR"/magic.mgc
}
