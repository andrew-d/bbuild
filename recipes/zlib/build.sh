pkgname="zlib"
pkgdesc="TODO"
pkgver="1.2.8"

sources=( \
	"http://zlib.net/zlib-${pkgver}.tar.gz" \
	"test-file.txt" \
)
sums=( \
    "36658cb768a54c1d4dec43c3116c27ed893e88b02ecfcb44f2166f9c0b7f2a0d" \
    "91751cee0a1ab8414400238a761411daa29643ab4b8243e9a91649e25be53ada" \
)

library=true
binary=false

dependencies=()

# Common variables.
_builddir="$source_dir/$pkgname-$pkgver"

function build() {
    cd "$_builddir"

    CHOST=${BBUILD_CROSS_PREFIX} \
    CFLAGS=${BBUILD_STATIC_FLAGS} \
    CC="${CC} ${BBUILD_STATIC_FLAGS}" \
    ./configure \
		--static

    if [[ "${BBUILD_TARGET_PLATFORM}" = "darwin" ]]; then
        sed -i \
            -e "s|AR=/usr/bin/libtool|AR=${AR}|g" \
            -e 's|ARFLAGS=-o|ARFLAGS=rc|g'
    fi

    make || return 1
}

function setup_env() {
    echo "Would set up environment here"
}
