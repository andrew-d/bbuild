pkgname="lzma"
pkgdesc="TODO"
pkgver="5.0.8"

sources=(
    "http://tukaani.org/xz/xz-${pkgver}.tar.gz"
)
sums=(
    "cac71b31ed322a487f1da1f10dfcf47f8855f97ff2c23b92680c7ae7be58babb"
)

library=true
binary=false

dependencies=()

# Common variables.
_builddir="$BBUILD_SOURCE_DIR/xz-$pkgver"


# Prepare the build.
function prepare() {
    cd "$_builddir"

    # Apply all patches in our sources
    for i in $sources; do
        case $i in
            *.patch)
                msg $i
                patch -p1 -i "$BBUILD_SOURCE_DIR"/$i || return 1
                ;;
        esac
    done
}


function build() {
    ./configure \
		--enable-static \
        --host=${BBUILD_CROSS_PREFIX} \
		--build=i686 || return 1

    make || return 1
}

function setup_env() {
    echo "-I${_builddir}/src/liblzma/api"          > "$depdir"/CPPFLAGS
    echo "-L${_builddir}/src/liblzma/.libs -llzma" > "$depdir"/LDFLAGS
}
