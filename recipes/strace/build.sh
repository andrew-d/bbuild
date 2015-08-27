pkgname="strace"
pkgdesc="TODO"
pkgver="4.10"

sources=(
    "http://downloads.sourceforge.net/project/strace/strace/${pkgver}/strace-${pkgver}.tar.xz"
    "fix-includes.patch"
)
sums=(
    "e6180d866ef9e76586b96e2ece2bfeeb3aa23f5cc88153f76e9caedd65e40ee2"
    "35bd06f770bac65ba1fa801b10aed911dcc45a6c8083d1893de3d7351f9e36a1"
)

library=false
binary=true

dependencies=()

# Common variables.
_builddir="$BBUILD_SOURCE_DIR/$pkgname-$pkgver"


function prepare() {
    cd "$_builddir"

    case "$BBUILD_TARGET_PLATFORM" in
        linux|android)
            ;;
        *)
            error "Cannot build strace for non-Linux platforms"
            return 1
            ;;
    esac

    patch -p2 -i "$BBUILD_SOURCE_DIR"/fix-includes.patch || return 1
}


function build() {
    cd "$_builddir"

    CFLAGS="${BBUILD_STATIC_FLAGS}" \
    ./configure \
        --host=${BBUILD_CROSS_PREFIX} \
        --build=i686 \
        || return 1

    # Need to fix linker in Makefile.
    sed -i "/^CC =/a LD = ${LD}" "$_builddir"/Makefile || return 1

    make || return 1
}


function package() {
    cd "$_builddir"

    cp strace "$BBUILD_OUT_DIR"/strace
    ${STRIP} "$BBUILD_OUT_DIR"/strace
}
