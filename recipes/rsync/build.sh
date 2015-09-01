pkgname="rsync"
pkgdesc="TODO"
pkgver="3.1.1"

sources=(
    "https://download.samba.org/pub/rsync/rsync-${pkgver}.tar.gz"
)
sums=(
    "7de4364fcf5fe42f3bdb514417f1c40d10bbca896abe7e7f2c581c6ea08a2621"
)

library=false
binary=true

dependencies=("zlib")

# Common variables.
_builddir="$BBUILD_SOURCE_DIR/$pkgname-$pkgver"


function build() {
    cd "$_builddir"

    CC="${CC} ${BBUILD_STATIC_FLAGS}" \
    CFLAGS="${CFLAGS:-} ${BBUILD_STATIC_FLAGS}" \
    ./configure \
        --host=${BBUILD_CROSS_PREFIX} \
        --build=i686 \
        || return 1

    make || return 1
}


function package() {
    cd "$_builddir"

    strip_helper \
        "rsync${BBUILD_BINARY_EXT}" \
        "$BBUILD_OUT_DIR"/"rsync${BBUILD_BINARY_EXT}" \
        || return 1
}
