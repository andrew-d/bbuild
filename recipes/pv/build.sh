pkgname="pv"
pkgdesc="TODO"
pkgver="1.6.6"

sources=(
    "https://www.ivarch.com/programs/sources/pv-${pkgver}.tar.bz2"
)
sums=(
    "608ef935f7a377e1439c181c4fc188d247da10d51a19ef79bcdee5043b0973f1"
)

library=false
binary=true

dependencies=()

# Common variables.
_builddir="$BBUILD_SOURCE_DIR/$pkgname-$pkgver"

function build() {
    cd "$_builddir"

    CC="${CC} ${BBUILD_STATIC_FLAGS}" \
    CFLAGS="${BBUILD_STATIC_FLAGS}" \
    ./configure \
        --host=${BBUILD_CROSS_PREFIX} \
        --build=i686 \
        || return 1

    # Need to fix linker in Makefile.
    sed -i "/^CC =/a LD = ${LD}" "$_builddir"/Makefile || return 1

    make || return 1
}


function package() {
    cd "$_builddir"

    cp "pv${BBUILD_BINARY_EXT}" "$BBUILD_OUT_DIR"/"pv${BBUILD_BINARY_EXT}"
    ${STRIP} "$BBUILD_OUT_DIR"/"pv${BBUILD_BINARY_EXT}"
}
