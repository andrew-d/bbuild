pkgname="libssh2"
pkgdesc="TODO"
pkgver="1.7.0"

sources=(
    "https://www.libssh2.org/download/libssh2-${pkgver}.tar.gz"
)
sums=(
    "e4561fd43a50539a8c2ceb37841691baf03ecb7daf043766da1b112e4280d584"
)

library=true
binary=false

dependencies=("openssl" "zlib")

# Common variables.
_builddir="$BBUILD_SOURCE_DIR/$pkgname-$pkgver"


function prepare() {
    cd "$_builddir"
    replace_config_sub || return 1
}


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
        --disable-examples-build \
        --with-ssl="${openssl_dir}" \
        || return 1

    make || return 1
}


function setup_env() {
    echo "-I${_builddir}/include"          > "$depdir"/CPPFLAGS
    echo "-L${_builddir}/src/.libs -lssh2" > "$depdir"/LDFLAGS
}
