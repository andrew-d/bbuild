pkgname="tar"
pkgdesc="TODO"
pkgver="1.28"

sources=(
    "https://ftp.gnu.org/gnu/tar/tar-${pkgver}.tar.xz"
    "tar-0001-fix-build-failure.patch"
    "darwin-gnutar-configure-xattrs.patch"
)
sums=(
    "64ee8d88ec1b47a0961033493f919d27218c41b580138fd6802327462aff22f2"
    "48594df98ceadb628dfce93641cee41a27f35448da33afe75a62be3e5f8c4600"
    "f2e56bb8afd1c641a7e5b81e35fdbf36b6fb66434b1e35caa8b55196b30c3ad9"
)

library=false
binary=true

dependencies=("libiconv")

# Common variables.
_builddir="$BBUILD_SOURCE_DIR/$pkgname-$pkgver"


function prepare() {
    cd "$_builddir"

    # Apply all patches in our sources
    for i in "${sources[@]}"; do
        case $i in
            darwin-*.patch)
                if [[ "$BBUILD_TARGET_PLATFORM" = "darwin" ]]; then
                    info2 $i
                    patch -p1 -i "$BBUILD_SOURCE_DIR"/$i || return 1
                fi
                ;;

            *.patch)
                info2 $i
                patch -p1 -i "$BBUILD_SOURCE_DIR"/$i || return 1
                ;;
        esac
    done
}


function build() {
    cd "$_builddir"

    CFLAGS="${BBUILD_STATIC_FLAGS}" \
    ./configure \
        --host=${BBUILD_CROSS_PREFIX} \
        --build=i686 \
        || return 1

    make || return 1
}


function package() {
    cd "$_builddir"

    cp src/tar "$BBUILD_OUT_DIR"/tar
    ${STRIP} "$BBUILD_OUT_DIR"/tar
}
