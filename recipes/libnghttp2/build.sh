pkgname="libnghttp2"
pkgdesc="TODO"
pkgver="1.8.0"

sources=(
    "https://github.com/tatsuhiro-t/nghttp2/releases/download/v${pkgver}/nghttp2-${pkgver}.tar.xz"
)
sums=(
    "61a545299171893a918d5b3c3cedc6540e73bdaa25dd1fb588eb291819743aec"
)

library=true
binary=false

dependencies=()

# Common variables.
_builddir="$BBUILD_SOURCE_DIR/nghttp2-$pkgver"
_destdir="${BBUILD_SOURCE_DIR}/dest"


# Prepare the build.
function prepare() {
    cd "$_builddir"
}


function build() {
    cd "$_builddir"

    ./configure \
        --disable-shared \
        --enable-static \
        --disable-app \
        --disable-examples \
        --disable-dependency-tracking \
        --host=${BBUILD_CROSS_PREFIX} \
        --build=i686 \
        --prefix=/usr \
        || return 1

    make || return 1

    # Install the library somewhere we can point at
    make \
        DESTDIR="$_destdir" \
        install \
        || return 1
}

function setup_env() {
    echo "-I${_destdir}/usr/include"       > "$depdir"/CPPFLAGS
    echo "-L${_destdir}/usr/lib -lnghttp2" > "$depdir"/LDFLAGS
}
