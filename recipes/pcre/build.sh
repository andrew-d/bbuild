pkgname="pcre"
pkgdesc="TODO"
pkgver="8.37"

sources=(
    "http://downloads.sourceforge.net/project/pcre/pcre/${pkgver}/pcre-${pkgver}.tar.bz2"
)
sums=(
    "51679ea8006ce31379fb0860e46dd86665d864b5020fc9cd19e71260eef4789d"
)

library=true
binary=false

dependencies=()

# Common variables.
_builddir="$source_dir/$pkgname-$pkgver"


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
}

function setup_env() {
    echo "-I${_builddir}"              > "$depdir"/CPPFLAGS
    echo "-L${_builddir}/.libs -lpcre" > "$depdir"/LDFLAGS
}
