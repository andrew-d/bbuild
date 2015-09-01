pkgname="yasm"
pkgdesc="TODO"
pkgver="7160679eee91323db98b0974596c7221eeff772c"

sources=(
    "yasm-${pkgver}.tar.gz::https://github.com/yasm/yasm/archive/${pkgver}.tar.gz"
)
sums=(
    "db2887c40b926d9235fe76941bb2a14c5dcc759d37da7ec7e9998b289bf5dc24"
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
