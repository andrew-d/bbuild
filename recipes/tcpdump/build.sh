pkgname="tcpdump"
pkgdesc="TODO"
pkgver="4.7.4"

sources=(
    "http://www.tcpdump.org/release/tcpdump-${pkgver}.tar.gz"
)
sums=(
    "6be520269a89036f99c0b2126713a60965953eab921002b07608ccfc0c47d9af"
)

library=false
binary=true

dependencies=("libpcap" "openssl")

# Common variables.
_builddir="$BBUILD_SOURCE_DIR/$pkgname-$pkgver"


function build() {
    cd "$_builddir"

    CC="${CC} ${BBUILD_STATIC_FLAGS}" \
    CPPFLAGS="-D_GNU_SOURCE -D_BSD_SOURCE ${CPPFLAGS:-}" \
    LDFLAGS="${BBUILD_STATIC_FLAGS} ${LDFLAGS:-}" \
    LIBS='-lpcap' \
    ./configure \
        --host=${BBUILD_CROSS_PREFIX} \
        --build=i686 \
        --enable-ipv6 \
        --disable-universal \
        || return 1

    make || return 1
}


function package() {
    cd "$_builddir"

    cp "tcpdump${BBUILD_BINARY_EXT}" "$BBUILD_OUT_DIR"/"tcpdump${BBUILD_BINARY_EXT}"
    ${STRIP} "$BBUILD_OUT_DIR"/"tcpdump${BBUILD_BINARY_EXT}"
}
