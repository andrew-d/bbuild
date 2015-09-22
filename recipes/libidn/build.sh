pkgname="libidn"
pkgdesc="TODO"
pkgver="1.32"

sources=(
    "https://ftp.gnu.org/gnu/libidn/libidn-${pkgver}.tar.gz"
)
sums=(
    "ba5d5afee2beff703a34ee094668da5c6ea5afa38784cebba8924105e185c4f5"
)

library=true
binary=false

dependencies=("libiconv")

# Common variables.
_builddir="$BBUILD_SOURCE_DIR/$pkgname-$pkgver"


function build() {
    cd "$_builddir"

    CFLAGS="${BBUILD_STATIC_FLAGS}" \
    CXXFLAGS="${BBUILD_STATIC_FLAGS}" \
    ./configure \
        --disable-shared \
		--enable-static \
        --host=${BBUILD_CROSS_PREFIX} \
		--build=i686 || return 1

    # Don't build anything except the library
    sed -i \
        -e 's|SUBDIRS = gl lib/gl lib po|SUBDIRS = gl lib/gl lib # po|g' \
        Makefile

    make || return 1
}

function setup_env() {
    echo "-I${_builddir}/lib"             > "$depdir"/CPPFLAGS
    echo "-L${_builddir}/lib/.libs -lidn" > "$depdir"/LDFLAGS
}
