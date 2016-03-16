pkgname="pcre"
pkgdesc="TODO"
pkgver="8.38"

sources=(
    "http://downloads.sourceforge.net/project/pcre/pcre/${pkgver}/pcre-${pkgver}.tar.bz2"
)
sums=(
    "b9e02d36e23024d6c02a2e5b25204b3a4fa6ade43e0a5f869f254f49535079df"
)

library=true
binary=false

dependencies=()

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

    make || return 1
}

function setup_env() {
    echo "-I${_builddir}"              > "$depdir"/CPPFLAGS
    echo "-L${_builddir}/.libs -lpcre" > "$depdir"/LDFLAGS
}
