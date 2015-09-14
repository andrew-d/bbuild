pkgname="expat"
pkgdesc="TODO"
pkgver="2.1.0"

sources=(
    "http://downloads.sourceforge.net/project/expat/expat/${pkgver}/expat-${pkgver}.tar.gz"
)
sums=(
    "823705472f816df21c8f6aa026dd162b280806838bb55b3432b0fb1fcca7eb86"
)

library=true
binary=false

dependencies=()

# Common variables.
_builddir="$BBUILD_SOURCE_DIR/$pkgname-$pkgver"


function prepare() {
    cd "$_builddir"

    replace_config_sub || return 1
}

function build() {
    cd "$_builddir"

    CFLAGS="${BBUILD_STATIC_FLAGS}" \
    CXXFLAGS="${BBUILD_STATIC_FLAGS}" \
    ./configure \
        --disable-shared \
		--enable-static \
        --host=${BBUILD_CROSS_PREFIX} \
		--build=i686 || return 1

    make || return 1
    rm libexpat.la .libs/libexpat*
    make CFLAGS=-all-static || return 1
}

function setup_env() {
    echo "-I${_builddir}"              > "$depdir"/CPPFLAGS
    echo "-L${_builddir}/.libs -lexpat" > "$depdir"/LDFLAGS
}
