pkgname="termcap"
pkgdesc="TODO"
pkgver="1.3.1"

sources=(
    "https://ftp.gnu.org/gnu/termcap/termcap-${pkgver}.tar.gz"
)
sums=(
    "91a0e22e5387ca4467b5bcb18edf1c51b930262fd466d5fda396dd9d26719100"
)

library=true
binary=false

dependencies=()

# Common variables.
_builddir="$BBUILD_SOURCE_DIR/$pkgname-$pkgver"


function build() {
    cd "$_builddir"

    CFLAGS="${BBUILD_STATIC_FLAGS}" \
    ./configure \
        --disable-shared \
		--enable-static \
        --host=${BBUILD_CROSS_PREFIX} \
		--build=i686 || return 1

    make || return 1
}

function setup_env() {
    echo "-I${_builddir}"           > "$depdir"/CPPFLAGS
    echo "-L${_builddir} -ltermcap" > "$depdir"/LDFLAGS
}
