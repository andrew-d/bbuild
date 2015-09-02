pkgname="libssh2"
pkgdesc="TODO"
pkgver="1.6.0"

sources=(
    "https://github.com/libssh2/libssh2/releases/download/libssh2-${pkgver}/libssh2-${pkgver}.tar.gz"
)
sums=(
    "5a202943a34a1d82a1c31f74094f2453c207bf9936093867f41414968c8e8215"
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
