pkgname="libpcap"
pkgdesc="TODO"
pkgver="1.7.3"

sources=(
    "http://www.tcpdump.org/release/libpcap-${pkgver}.tar.gz"
)
sums=(
    "dd9f85213dc8e948068405b55dd20f8b32e3083e9e0e186f833bd0372e559e2f"
)

library=true
binary=false

dependencies=("libnl-tiny")

# Common variables.
_builddir="$BBUILD_SOURCE_DIR/$pkgname-$pkgver"


function build() {
    cd "$_builddir"

    CC="${CC} -static" \
    CFLAGS="${CFLAGS:-} -D_GNU_SOURCE -D_BSD_SOURCE -DIPPROTO_HOPOPTS=0" \
    ./configure \
        --disable-canusb \
        --with-pcap=linux \
        --host=${BBUILD_CROSS_PREFIX} \
        --build=i686 \
        LD="${LD}" \
        || return 1

    make libpcap.a || return 1
}

function setup_env() {
    echo "-I${_builddir}"        > "$depdir"/CPPFLAGS
    echo "-L${_builddir} -lpcap" > "$depdir"/LDFLAGS
}
