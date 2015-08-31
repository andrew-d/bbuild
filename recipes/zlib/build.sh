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
_builddir="$BBUILD_SOURCE_DIR/$pkgname-$pkgver"

function build() {
    cd "$_builddir"

    if [[ "$BBUILD_TARGET_PLATFORM" = "windows" ]]; then
        make -f win32/Makefile.gcc \
            PREFIX="${BBUILD_CROSS_PREFIX}-" \
            libz.a \
            || return 1
    else
        CHOST=${BBUILD_CROSS_PREFIX} \
        CFLAGS=${BBUILD_STATIC_FLAGS} \
        CC="${CC} ${BBUILD_STATIC_FLAGS}" \
        ./configure --static || return 1

        if [[ "${BBUILD_TARGET_PLATFORM}" = "darwin" ]]; then
            info2 "Fixing AR path"
            sed -i \
                -e "s|AR=/usr/bin/libtool|AR=${AR}|g" \
                -e 's|ARFLAGS=-o|ARFLAGS=rc|g' \
                Makefile
        fi

        make || return 1
    fi
}

function setup_env() {
    echo "-I${_builddir}"     > "$BBUILD_DEP_DIR"/CPPFLAGS
    echo "-L${_builddir} -lz" > "$BBUILD_DEP_DIR"/LDFLAGS
}
