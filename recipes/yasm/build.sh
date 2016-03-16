pkgname="yasm"
pkgdesc="TODO"
pkgver="51af4082cc898b122b88f11fd34033fc00fad81e"

sources=(
    "yasm-${pkgver}.tar.gz::https://github.com/yasm/yasm/archive/${pkgver}.tar.gz"
)
sums=(
    "d55ad25599863a1a48bba623b6dec7dbe73e4c8b0859697a54abd26bb8a66bf1"
)

library=false
binary=true

dependencies=()

# Common variables.
_builddir="$BBUILD_SOURCE_DIR/$pkgname-$pkgver"


function prepare() {
    cd "$_builddir"

    info2 "Fixing config.sub"
    replace_config_sub || return 1
}


function build() {
    cd "$_builddir"

    CFLAGS="${CFLAGS:-} ${BBUILD_STATIC_FLAGS}" \
    CXXFLAGS="${CXXFLAGS:-} ${BBUILD_STATIC_FLAGS} -static-libstdc++" \
    ./autogen.sh \
        --disable-nls \
        --host=${BBUILD_CROSS_PREFIX} \
        --build=i686 \
        || return 1

    make || return 1
}


function package() {
    cd "$_builddir"

    for f in yasm vsyasm ytasm; do
        strip_helper \
            "${f}${BBUILD_BINARY_EXT}" \
            "$BBUILD_OUT_DIR"/ \
            || return 1
    done
}
