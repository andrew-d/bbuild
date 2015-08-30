pkgname="libnl-tiny"
pkgdesc="TODO"
pkgver="91420e5fbbe932f93d55f0581bf43256a3dae8dc"

sources=(
    "libnl-tiny-${pkgver}.tar.gz::https://github.com/sabotage-linux/libnl-tiny/archive/${pkgver}.tar.gz"
)
sums=(
    "1a4b12d2862255062535ff97379f183860336d0600393bc83d85a409f051d759"
)

library=true
binary=false

dependencies=()

# Common variables.
_builddir="$BBUILD_SOURCE_DIR/$pkgname-$pkgver"


function prepare() {
    cd "$_builddir"

    sed -i \
        -e "s/ar rc/${AR} rc/g" \
        -e "s/ranlib /${RANLIB} /g" \
        Makefile || return 1
}


function build() {
    cd "$_builddir"

    # Build
    make \
        ALL_LIBS=libnl-tiny.a \
        CC="${CC}" \
        AR="${AR}" \
        CFLAGS="${BBUILD_STATIC_FLAGS}" \
        all \
        || return 1
}

function setup_env() {
    echo "-I${_builddir}/include"   > "$depdir"/CPPFLAGS
    echo "-L${_builddir} -lnl-tiny" > "$depdir"/LDFLAGS
}
