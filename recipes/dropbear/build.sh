pkgname="dropbear"
pkgdesc="TODO"
pkgver="2016.72"

sources=(
    "https://matt.ucc.asn.au/dropbear/releases/dropbear-${pkgver}.tar.bz2"
)
sums=(
    "9323766d3257699fd7d6e7b282c5a65790864ab32fd09ac73ea3d46c9ca2d681"
)

library=false
binary=true

dependencies=("zlib")

# Common variables.
_builddir="$BBUILD_SOURCE_DIR/$pkgname-$pkgver"
_zlib_version=
_zlib_dir=


function prepare() {
    _zlib_version="$(cat "$BBUILD_DEPCONF_DIR"/zlib/.version)"
    _zlib_dir="$(cat "$BBUILD_DEPCONF_DIR"/zlib/.source-dir)"
    _zlib_dir="$_zlib_dir"/"zlib-${_zlib_version}"
}


function build() {
    cd "$_builddir"

    CFLAGS="${BBUILD_STATIC_FLAGS} ${CFLAGS:-}" \
    CXXFLAGS="${BBUILD_STATIC_FLAGS} ${CXXFLAGS:-}" \
    LDFLAGS="${BBUILD_STATIC_FLAGS} ${LDFLAGS:-}" \
    ./configure \
        --enable-bundled-libtom \
        --host=${BBUILD_CROSS_PREFIX} \
        --build=i686 \
        --with-zlib="${_zlib_dir}" \
        || return 1

    make || return 1
}


function package() {
    cd "$_builddir"

    for f in dropbear dbclient dropbearkey dropbearconvert; do
        strip_helper \
            "${f}${BBUILD_BINARY_EXT}" \
            "$BBUILD_OUT_DIR"/ \
            || return 1
    done
}
