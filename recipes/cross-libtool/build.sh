pkgname="cross-libtool"
pkgdesc="Installs a cross-compiler libtool"
pkgver="2.4.6"

sources=(
    "http://ftpmirror.gnu.org/libtool/libtool-${pkgver}.tar.gz"
)
sums=(
    "bad"
)

library=true
binary=false

dependencies=()

# Common variables.
_builddir="$BBUILD_SOURCE_DIR/$pkgname-$pkgver"


function build() {
    cd "$_builddir"

    CFLAGS="${CFLAGS:-} ${BBUILD_STATIC_FLAGS}" \
    CXXFLAGS="${CXXFLAGS:-} ${BBUILD_STATIC_FLAGS}" \
    LDFLAGS="${LDFLAGS:-} ${BBUILD_STATIC_FLAGS}" \
    ./configure \
        --prefix="${BBUILD_SOURCE_DIR}/dest" \
        --host=${BBUILD_CROSS_PREFIX} \
        --program-prefix="${BBUILD_CROSS_PREFIX}-" \
        || return 1

    make || return 1
    make install || return 1
}


function setup_env() {
    echo "${BBUILD_SOURCE_DIR}/dest/bin/${BBUILD_CROSS_PREFIX}-libtool" > "$depdir"/.libtool-bin
}
