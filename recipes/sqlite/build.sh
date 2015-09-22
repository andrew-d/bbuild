pkgname="sqlite"
pkgdesc="TODO"
pkgver="3081101"

sources=(
    "https://www.sqlite.org/2015/sqlite-autoconf-${pkgver}.tar.gz"
)
sums=(
    "fb99b0ac038c4a7e48b44b61836cb41d4eeba36b4d0ee757beeab59031a1d3b6"
)

library=true
binary=true

dependencies=()

# Common variables.
_builddir="$BBUILD_SOURCE_DIR/sqlite-autoconf-$pkgver"


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

    # Need to do this irritating dance to get the binary linked statically
    rm "sqlite3${BBUILD_BINARY_EXT}" || return 1
    make CFLAGS=-all-static || return 1
}

function setup_env() {
    echo "-I${_builddir}"                 > "$depdir"/CPPFLAGS
    echo "-L${_builddir}/.libs -lsqlite3" > "$depdir"/LDFLAGS
}

function package() {
    strip_helper \
        "sqlite3${BBUILD_BINARY_EXT}" \
        "$BBUILD_OUT_DIR"/ \
        || return 1
}
