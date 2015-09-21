pkgname="the_silver_searcher"
pkgdesc="TODO"
pkgver="0.31.0"

sources=(
    "${pkgname}-${pkgver}.tar.gz::https://github.com/ggreer/the_silver_searcher/archive/${pkgver}.tar.gz"
)
sums=(
    "61bc827f4557d8108e91cdfc9ba31632e2568b26884c92426417f58135b37da8"
)

library=false
binary=true

dependencies=("lzma" "pcre" "zlib")

# Common variables.
_builddir="$BBUILD_SOURCE_DIR/$pkgname-$pkgver"


function build() {
    cd "$_builddir"

    autoreconf -i || return 1

    CC="${CC} ${BBUILD_STATIC_FLAGS}" \
    CFLAGS="-fPIC ${BBUILD_STATIC_FLAGS}" \
    LZMA_LIBS="$(cat "$BBUILD_DEPCONF_DIR"/lzma/LDFLAGS)" \
    LZMA_CFLAGS="$(cat "$BBUILD_DEPCONF_DIR"/lzma/CPPFLAGS)" \
    PCRE_LIBS="$(cat "$BBUILD_DEPCONF_DIR"/pcre/LDFLAGS)" \
    PCRE_CFLAGS="$(cat "$BBUILD_DEPCONF_DIR"/pcre/CPPFLAGS)" \
    ZLIB_LIBS="$(cat "$BBUILD_DEPCONF_DIR"/zlib/LDFLAGS)" \
    ZLIB_CFLAGS="$(cat "$BBUILD_DEPCONF_DIR"/zlib/CPPFLAGS)" \
    ./configure \
        --host=${BBUILD_CROSS_PREFIX} \
        --build=i686 \
        PKG_CONFIG=/bin/true || return 1

    make || return 1
}


function package() {
    cd "$_builddir"

    cp ag "$BBUILD_OUT_DIR"/ag
    ${STRIP} "$BBUILD_OUT_DIR"/ag
}
