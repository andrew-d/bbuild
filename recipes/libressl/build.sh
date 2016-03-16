pkgname="libressl"
pkgdesc="TODO"
pkgver="14aa5f73abc718f28097fc3e3ae5be9c7422b39c"

sources=(
    "libressl-${pkgver}.tar.gz::https://github.com/libressl-portable/portable/archive/${pkgver}.tar.gz"
)
sums=(
    "31c3144aa64a7e32ea22adf5653932efdc336908b9378c007725196f20e3f09f"
)

library=true
binary=true

dependencies=()

# Common variables.
_builddir="$BBUILD_SOURCE_DIR/portable-$pkgver"


function build() {
    cd "$_builddir"

    ./autogen.sh || return 1

    CFLAGS="${BBUILD_STATIC_FLAGS}" \
    LDFLAGS="${BBUILD_STATIC_FLAGS}" \
    ./configure \
        --disable-shared \
        --enable-static \
        --disable-dependency-tracking \
        --host=${BBUILD_CROSS_PREFIX} \
        --build=i686 \
        || return 1

    make

    # Need to do this irritating dance to get the binary linked statically
    rm "apps/openssl/openssl${BBUILD_BINARY_EXT}" || return 1
    if [[ "$BBUILD_TARGET_PLATFORM" != "windows" ]]; then
        rm "apps/nc/nc${BBUILD_BINARY_EXT}" || return 1
    fi
    make CFLAGS=-all-static || return 1
}


function package() {
    cd "$_builddir"

    strip_helper \
        "apps/openssl/openssl${BBUILD_BINARY_EXT}" \
        "${BBUILD_OUT_DIR}/openssl${BBUILD_BINARY_EXT}" \
        || return 1

    if [[ "$BBUILD_TARGET_PLATFORM" != "windows" ]]; then
        strip_helper \
            "apps/nc/nc${BBUILD_BINARY_EXT}" \
            "${BBUILD_OUT_DIR}/nc${BBUILD_BINARY_EXT}" \
            || return 1
    fi
}


function setup_env() {
    echo "-I${_builddir}/include" > "$depdir"/CPPFLAGS

    local ldflags
    for f in crypto ssl tls; do
        ldflags="${ldflags:-} -L${_builddir}/${f}/.libs -l${f}"
    done
    echo "$ldflags" > "$depdir"/LDFLAGS
}
