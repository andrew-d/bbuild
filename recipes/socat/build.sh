pkgname="socat"
pkgdesc="TODO"
pkgver="1.7.3.0"

sources=(
    "http://www.dest-unreach.org/socat/download/socat-${pkgver}.tar.gz"
)
sums=(
    "f8de4a2aaadb406a2e475d18cf3b9f29e322d4e5803d8106716a01fd4e64b186"
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
