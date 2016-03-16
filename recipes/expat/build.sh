pkgname="expat"
pkgdesc="TODO"
pkgver="2.1.1"

sources=(
    "http://downloads.sourceforge.net/project/expat/expat/${pkgver}/expat-${pkgver}.tar.bz2"
)
sums=(
    "aff584e5a2f759dcfc6d48671e9529f6afe1e30b0cd6a4cec200cbe3f793de67"
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
