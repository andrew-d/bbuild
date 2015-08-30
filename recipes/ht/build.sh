pkgname="ht"
pkgdesc="TODO"
pkgver="ef68e1674867a44060a22b944263491b586c1d52"

sources=(
    "ht-${pkgver}.tar.gz::https://github.com/sebastianbiallas/ht/archive/${pkgver}.tar.gz"
)
sums=(
    "266d0a216b65bfb1abf154a588125d5003867aae96b87b0c7556b4ce0771e42e"
)

library=false
binary=true

dependencies=("ncurses")

# Common variables.
_builddir="$BBUILD_SOURCE_DIR/$pkgname-$pkgver"


function build() {
    cd "$_builddir"

    info2 "Running autogen.sh"
    ./autogen.sh || return 1

    info2 "Building host binary"
    # Build and copy the host-local bin2c binary
    cc -o "${BBUILD_SOURCE_DIR}/bin2c" tools/bin2c.c || return 1

    info2 "Building target binary"
    CC="${CC} ${BBUILD_STATIC_FLAGS}" \
    CXX="${CXX} ${BBUILD_STATIC_FLAGS}" \
    AR="${AR}" \
    CFLAGS="${BBUILD_STATIC_FLAGS} ${CFLAGS:-}" \
    CXXFLAGS="${BBUILD_STATIC_FLAGS} ${CXXFLAGS:-}" \
    ./configure \
        --host=${BBUILD_CROSS_PREFIX} \
        --build=i686 \
        || return 1

    # Patch 'bin2c' in the Makefile.
    sed -i \
        -e "s|tools/bin2c|${BBUILD_SOURCE_DIR}/bin2c|g" \
        Makefile \
        || return 1

    # Actually run the build.
    make || true
    make htdoc.h || return 1
    make || return 1
}


function package() {
    cd "$_builddir"

    cp "ht${BBUILD_BINARY_EXT}" "$BBUILD_OUT_DIR"/"ht${BBUILD_BINARY_EXT}"
    ${STRIP} "$BBUILD_OUT_DIR"/"ht${BBUILD_BINARY_EXT}"
}
