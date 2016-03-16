pkgname="libnl-tiny"
pkgdesc="TODO"
pkgver="edf21ef7aa9423b95aa49e2018eacfbcf1f3eac9"

sources=(
    "libnl-tiny-${pkgver}.tar.gz::https://github.com/sabotage-linux/libnl-tiny/archive/${pkgver}.tar.gz"
)
sums=(
    "97bb212ef0995a507bdd1a8605c5716d44a5e080e19b5ed5bbbb1b303442c468"
)

library=true
binary=false

dependencies=()

# Common variables.
_builddir="$BBUILD_SOURCE_DIR/$pkgname-$pkgver"


function build() {
    cd "$_builddir"

    # Build
    make \
        ALL_LIBS=libnl-tiny.a \
        CC="${CC}" \
        AR="${AR}" \
        RANLIB="${RANLIB}" \
        CFLAGS="${BBUILD_STATIC_FLAGS}" \
        all \
        || return 1
}

function setup_env() {
    echo "-I${_builddir}/include"   > "$depdir"/CPPFLAGS
    echo "-L${_builddir} -lnl-tiny" > "$depdir"/LDFLAGS
}
