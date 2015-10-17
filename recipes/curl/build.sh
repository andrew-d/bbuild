pkgname="curl"
pkgdesc="TODO"
pkgver="7.45.0"

sources=(
    "https://github.com/bagder/curl/releases/download/curl-${pkgver//./_}/curl-${pkgver}.tar.bz2"
)
sums=(
    "65154e66b9f8a442b57c436904639507b4ac37ec13d6f8a48248f1b4012b98ea"
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
