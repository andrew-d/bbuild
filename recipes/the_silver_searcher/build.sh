pkgname="the_silver_searcher"
pkgdesc="TODO"
pkgver="0.30.0"

sources=(
    "${pkgname}-${pkgver}.tar.gz::https://github.com/ggreer/the_silver_searcher/archive/${pkgver}.tar.gz"
)
sums=(
    "a3b61b80f96647dbe89c7e89a8fa7612545db6fa4a313c0ef8a574d01e7da5db"
)

library=false
binary=true

dependencies=()

# Common variables.
_builddir="$source_dir/$pkgname-$pkgver"


function build() {
    cd "$_builddir"

    autoreconf -i || return 1

    CC="${CC} ${BBUILD_STATIC_FLAGS}" \
    CFLAGS="-fPIC ${BBUILD_STATIC_FLAGS}" \
    PCRE_LIBS="TODO" \
    PCRE_CFLAGS="TODO" \
    LZMA_LIBS="TODO" \
    LZMA_CFLAGS="TODO" \
    ZLIB_LIBS="TODO" \
    ZLIB_CFLAGS="TODO" \
    ./configure \
        --host=${BBUILD_CROSS_PREFIX} \
        --build=i686 \
        PKG_CONFIG=/bin/true || true

    make || return 1
}


function package() {
    echo "Would copy package files here"
}
