pkgname="curl"
pkgdesc="TODO"
pkgver="7.44.0"

sources=(
    "https://github.com/bagder/curl/releases/download/curl-${pkgver//./_}/curl-${pkgver}.tar.bz2"
)
sums=(
    "1e2541bae6582bb697c0fbae49e1d3e6fad5d05d5aa80dbd6f072e0a44341814"
)

library=true
binary=true

dependencies=("openssl" "zlib" "libssh2" "libidn")

# Common variables.
_builddir="$BBUILD_SOURCE_DIR/$pkgname-$pkgver"


function build() {
    cd "$_builddir"

    local openssl_version openssl_dir

    openssl_version="$(cat "$BBUILD_DEPCONF_DIR"/openssl/.version)"
    openssl_dir="$(cat "$BBUILD_DEPCONF_DIR"/openssl/.source-dir)"
    openssl_dir="$openssl_dir"/"openssl-${openssl_version}"

    ./configure \
        --host=${BBUILD_CROSS_PREFIX} \
        --build=i686 \
        --disable-shared \
        --enable-static \
        --disable-dependency-tracking \
        --enable-optimize \
        --with-ssl="${openssl_dir}" \
        || return 1

    make || return 1

    # Need to do this irritating dance to get the curl binary linked statically
    cd src
    rm "curl${BBUILD_BINARY_EXT}" || return 1
    make CFLAGS=-all-static || return 1
}


function setup_env() {
    echo "-I${_builddir}/include"           > "$depdir"/CPPFLAGS
    echo "-L${_builddir}/lib/.libs/ -lcurl" > "$depdir"/LDFLAGS
}


function package() {
    cd "$_builddir"

    strip_helper \
        "src/curl${BBUILD_BINARY_EXT}" \
        "$BBUILD_OUT_DIR"/ \
        || return 1
}
