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

dependencies=("lzma" "pcre" "zlib")

# Common variables.
_builddir="$source_dir/$pkgname-$pkgver"


function build() {
    cd "$_builddir"

    autoreconf -i || return 1

    CC="${CC} ${BBUILD_STATIC_FLAGS}" \
    CFLAGS="-fPIC ${BBUILD_STATIC_FLAGS}" \
    LZMA_LIBS="$(cat "$depconf_dir"/lzma/LDFLAGS)" \
    LZMA_CFLAGS="$(cat "$depconf_dir"/lzma/CPPFLAGS)" \
    PCRE_LIBS="$(cat "$depconf_dir"/pcre/LDFLAGS)" \
    PCRE_CFLAGS="$(cat "$depconf_dir"/pcre/CPPFLAGS)" \
    ZLIB_LIBS="$(cat "$depconf_dir"/zlib/LDFLAGS)" \
    ZLIB_CFLAGS="$(cat "$depconf_dir"/zlib/CPPFLAGS)" \
    ./configure \
        --host=${BBUILD_CROSS_PREFIX} \
        --build=i686 \
        PKG_CONFIG=/bin/true || return 1

    make || return 1
}


function package() {
    cd "$_builddir"

    cp ag "$outdir"/ag
    ${STRIP} "$outdir"/ag
}
