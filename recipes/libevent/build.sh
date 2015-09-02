pkgname="libevent"
pkgdesc="TODO"
pkgver="2.0.22-stable"

sources=(
    "https://downloads.sourceforge.net/project/levent/libevent/libevent-${pkgver%.*}/libevent-${pkgver}.tar.gz"
)
sums=(
    "71c2c49f0adadacfdbe6332a372c38cf9c8b7895bb73dabeaa53cdcc1d4e1fa3"
)

library=true
binary=false

dependencies=("openssl" "zlib")

# Common variables.
_builddir="$BBUILD_SOURCE_DIR/$pkgname-$pkgver"
_destdir="$BBUILD_SOURCE_DIR/dest"


function build() {
    cd "$_builddir"

    ./autogen.sh || return 1

    ./configure \
        --disable-shared \
		--enable-static \
        --disable-dependency-tracking \
        --disable-debug-mode \
        --prefix=/usr \
        --host=${BBUILD_CROSS_PREFIX} \
		--build=i686 || return 1

    local myLDFLAGS="${LDFLAGS:-}"
    if [[ "$BBUILD_TARGET_PLATFORM" != "darwin" ]]; then
        myLDFLAGS="${myLDFLAGS} -all-static"
    fi

    make LDFLAGS="$myLDFLAGS" || return 1
    make DESTDIR="$_destdir" install || return 1
}

function setup_env() {
    echo "-I${_destdir}/usr/include"     > "$depdir"/CPPFLAGS
    echo "-L${_destdir}/usr/lib -levent" > "$depdir"/LDFLAGS
}
