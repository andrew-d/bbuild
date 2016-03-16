pkgname="socat"
pkgdesc="TODO"
pkgver="1.7.3.1"

sources=(
    "http://www.dest-unreach.org/socat/download/socat-${pkgver}.tar.gz"
)
sums=(
    "a8cb07b12bcd04c98f4ffc1c68b79547f5dd4e23ddccb132940f6d55565c7f79"
)

library=false
binary=true

dependencies=("ncurses" "openssl" "readline")

# Common variables.
_builddir="$BBUILD_SOURCE_DIR/$pkgname-$pkgver"


function build() {
    cd "$_builddir"

    CC="${CC} ${BBUILD_STATIC_FLAGS}" \
    CFLAGS="-fPIC ${BBUILD_STATIC_FLAGS}" \
    CPPFLAGS="${CPPFLAGS:-} -DNETDB_INTERNAL=-1" \
    ./configure \
        --host=${BBUILD_CROSS_PREFIX} \
        --build=i686 \
        || return 1

    make || return 1
}


function package() {
    cd "$_builddir"

    cp socat "$BBUILD_OUT_DIR"/socat
    ${STRIP} "$BBUILD_OUT_DIR"/socat
}
