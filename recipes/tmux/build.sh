pkgname="tmux"
pkgdesc="TODO"
pkgver="2.0"

sources=(
    "https://github.com/tmux/tmux/releases/download/${pkgver}/tmux-${pkgver}.tar.gz"
)
sums=(
    "795f4b4446b0ea968b9201c25e8c1ef8a6ade710ebca4657dd879c35916ad362"
)

library=false
binary=true

dependencies=("libevent" "ncurses")
if [[ "${BBUILD_TARGET_PLATFORM}" != "darwin" ]]; then
    dependencies=( "${dependencies[@]}" "bsd-compat-headers" )
fi

# Common variables.
_builddir="$BBUILD_SOURCE_DIR/$pkgname-$pkgver"


function build() {
    cd "$_builddir"

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
        "tmux${BBUILD_BINARY_EXT}" \
        "$BBUILD_OUT_DIR"/ \
        || return 1
}
