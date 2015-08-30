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

dependencies=("libpcap")

# Common variables.
_builddir="$BBUILD_SOURCE_DIR/$pkgname-$pkgver"


function build() {
    cd "$_builddir"

    CC="${CC} -static" \
    CPPFLAGS="-D_GNU_SOURCE -D_BSD_SOURCE ${CPPFLAGS:-}" \
    LDFLAGS="-static ${LDFLAGS:-}" \
    LIBS='-lpcap' \
    ./configure \
        --without-crypto \
        --host=${BBUILD_CROSS_PREFIX} \
        --build=i686 \
        ac_cv_linux_vers=3 \
        || return 1

    make || return 1
}


function package() {
    cd "$_builddir"

    cp "tcpdump${BBUILD_BINARY_EXT}" "$BBUILD_OUT_DIR"/"tcpdump${BBUILD_BINARY_EXT}"
    ${STRIP} "$BBUILD_OUT_DIR"/"tcpdump${BBUILD_BINARY_EXT}"
}
