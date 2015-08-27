pkgname="openssl"
pkgdesc="TODO"
pkgver="1.0.2d"

sources=(
    "https://openssl.org/source/openssl-${pkgver}.tar.gz"
)
sums=(
    "671c36487785628a703374c652ad2cebea45fa920ae5681515df25d9f2c9a8c8"
)

library=true
binary=false

dependencies=()

# Common variables.
_builddir="$BBUILD_SOURCE_DIR/$pkgname-$pkgver"


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
    cd "$_builddir"

    local target
    case "${BBUILD_TARGET_PLATFORM}-${BBUILD_TARGET_ARCH}" in
        linux-x86_64)
            target="linux-x86_64"
            ;;
        linux-arm)
            target="linux-armv4"
            ;;
        android-*)
            target="android-armv7"
            ;;
        darwin-x86_64)
            target="darwin64-x86_64-cc"
            ;;
        darwin-x86)
            target="darwin-i386-cc"
            ;;
        *)
            error "cannot build openssl for platform/arch: ${BBUILD_TARGET_PLATFORM}-${BBUILD_TARGET_ARCH}"
            return 1
            ;;
    esac

    CFLAGS="${BBUILD_STATIC_FLAGS}" \
    CXXFLAGS="${BBUILD_STATIC_FLAGS}" \
    perl ./Configure \
        no-shared \
        enable-ec_nistp_64_gcc_12 \
        "$target" \
        || return 1


    make build_libs || return 1
}

function setup_env() {
    echo "-I${_builddir}/include"        > "$depdir"/CPPFLAGS
    echo "-L${_builddir} -lcrypto -lssl" > "$depdir"/LDFLAGS
}
