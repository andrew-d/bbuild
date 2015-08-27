pkgname="netcat"
pkgdesc="TODO"
pkgver="0.7.1"

sources=(
    "https://downloads.sourceforge.net/project/netcat/netcat/${pkgver}/netcat-${pkgver}.tar.gz"
    "config.sub"
    "fix-unsigned.patch"
)
sums=(
    "30719c9a4ffbcf15676b8f528233ccc54ee6cba96cb4590975f5fd60c68a066f"
    "f4cf53ff68e5b9c3437a1e7ad3086c4c669136caebd721ffc58ef21944bd395a"
    "669907b1ff0671dc97eb3ab43dd7fe6f8c810599fd905d432c9a702783109d29"
)

library=false
binary=true

dependencies=()

# Common variables.
_builddir="$BBUILD_SOURCE_DIR/$pkgname-$pkgver"


function prepare() {
    cd "$_builddir"

    # Apply all patches in our sources
	for i in "${sources[@]}"; do
        case $i in
            *.patch)
                info2 $i
                patch -p1 -i "$BBUILD_SOURCE_DIR"/$i || return 1
                ;;
        esac
    done

    cp "$BBUILD_SOURCE_DIR"/config.sub . || return 1
}


function build() {
    cd "$_builddir"

    CFLAGS="${BBUILD_STATIC_FLAGS}" \
    ./configure \
        --host=${BBUILD_CROSS_PREFIX} \
        --build=i686 \
        || return 1

    make || return 1
}


function package() {
    cd "$_builddir"

    cp src/netcat "$BBUILD_OUT_DIR"/netcat
    ${STRIP} "$BBUILD_OUT_DIR"/netcat
}
