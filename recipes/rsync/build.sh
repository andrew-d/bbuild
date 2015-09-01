pkgname="rsync"
pkgdesc="TODO"
pkgver="3.1.1"

sources=(
    "https://download.samba.org/pub/rsync/rsync-${pkgver}.tar.gz"

    "patch-fileflags.patch"
    "patch-crtimes.patch"
    "patch-hfs-compression.patch"
)
sums=(
    "7de4364fcf5fe42f3bdb514417f1c40d10bbca896abe7e7f2c581c6ea08a2621"

    "b50f0ad6d2c20e561e17b64f07545b1ecfe7d61481a6e5af192abfe21af01e73"
    "396e552b1f51ee10c21f27afc73b75b2d421272443d15d2a5539ac641c32cbb1"
    "134483ab33fdaa67d503dc4011656913321f9e405639fab96d48ef54e08dfa1f"
)

library=false
binary=true

dependencies=("zlib")
if [[ "$BBUILD_TARGET_PLATFORM" = "darwin" ]]; then
    dependencies=( "${dependencies[@]}" "libiconv" )
fi

# Common variables.
_builddir="$BBUILD_SOURCE_DIR/$pkgname-$pkgver"


function prepare() {
    cd "$_builddir"

    if [[ "$BBUILD_TARGET_PLATFORM" = "darwin" ]]; then
        # Apply all patches in our sources
        for i in "${sources[@]}"; do
            case $i in
                *.patch)
                    info2 $i
                    patch -p1 -i "$BBUILD_SOURCE_DIR"/$i || return 1
                    ;;
            esac
        done
    fi

    ./prepare-source || return 1
}


function build() {
    cd "$_builddir"

    CC="${CC} ${BBUILD_STATIC_FLAGS}" \
    CFLAGS="${CFLAGS:-} ${BBUILD_STATIC_FLAGS}" \
    ./configure \
        --host=${BBUILD_CROSS_PREFIX} \
        --build=i686 \
        || return 1

    make || return 1
}


function package() {
    cd "$_builddir"

    strip_helper \
        "rsync${BBUILD_BINARY_EXT}" \
        "$BBUILD_OUT_DIR"/"rsync${BBUILD_BINARY_EXT}" \
        || return 1
}
