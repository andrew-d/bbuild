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

case "${BBUILD_TARGET_PLATFORM}" in
    linux|android)
        dependencies=("libnl-tiny")
        ;;
    *)
        dependencies=()
        ;;
esac

# Common variables.
_builddir="$BBUILD_SOURCE_DIR/$pkgname-$pkgver"


function build() {
    cd "$_builddir"

    local pcapty
    case "${BBUILD_TARGET_PLATFORM}" in
        linux|android)
            pcapty=linux
            ;;
        darwin)
            pcapty=bpf
            ;;
        *)
            error "Don't know what pcap type to use for platform: ${BBUILD_TARGET_PLATFORM}"
            return 1
            ;;
    esac

    CC="${CC} ${BBUILD_STATIC_FLAGS}" \
    CFLAGS="${CFLAGS:-} -D_GNU_SOURCE -D_BSD_SOURCE -DIPPROTO_HOPOPTS=0" \
    ./configure \
        --host=${BBUILD_CROSS_PREFIX} \
        --build=i686 \
        --disable-shared \
        --enable-ipv6 \
        --disable-universal \
        --with-pcap="${pcapty}" \
        LD="${LD}" \
        || return 1

    make libpcap.a || return 1
}


function setup_env() {
    echo "-I${_builddir}"        > "$depdir"/CPPFLAGS
    echo "-L${_builddir} -lpcap" > "$depdir"/LDFLAGS
}
