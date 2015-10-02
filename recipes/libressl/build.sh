pkgname="libressl"
pkgdesc="TODO"
pkgver="a7f031ba55ac4a69263000357eb7f6d7fb88101a"

sources=(
    "libressl-${pkgver}.tar.gz::https://github.com/libressl-portable/portable/archive/${pkgver}.tar.gz"
)
sums=(
    "a02fb005652f1e12ba88a7855bd850c129d44a62ff5f735b6d30c351acd3b345"
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
        "${BBUILD_OUT_DIR}/openssl${BBUILD_BINARY_EXT}"

    if [[ "$BBUILD_TARGET_PLATFORM" != "windows" ]]; then
        strip_helper \
            "apps/nc/nc${BBUILD_BINARY_EXT}" \
            "${BBUILD_OUT_DIR}/nc${BBUILD_BINARY_EXT}"
    fi
}


function setup_env() {
    echo "-I${_builddir}/include"         > "$depdir"/CPPFLAGS

    local ldflags
    for f in crypto ssl tls; do
        ldflags="${ldflags:-} -L${_builddir}/${f}/.libs -l${f}"
    done
    echo "$ldflags" > "$depdir"/LDFLAGS
}
