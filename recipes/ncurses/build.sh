pkgname="ncurses"
pkgdesc="TODO"
pkgver="5.9"

sources=(
    "${pkgname}-${pkgver}.tar.gz::http://invisible-island.net/datafiles/release/ncurses.tar.gz"
    "config.sub"
    "darwin-compile-flags-1.patch"
    "darwin-compile-flags-2.patch"
    "darwin-constructor-types-1.patch"
    "ncurses-5.9-gcc-5.patch"
)
sums=(
    "9046298fb440324c9d4135ecea7879ffed8546dd1b58e59430ea07a4633f563b"
    "f4cf53ff68e5b9c3437a1e7ad3086c4c669136caebd721ffc58ef21944bd395a"
    "4bdbdb35c4dcd65b96222a207a670ac8fccf0cc0c0c1e42cd72b9dc1ab8a2b13"
    "b77e1de5cceec904bf9065c0832f302822de3b9da7e98aab604351d2b08512e3"
    "9eff1f585fd012cff88f6a386c6160324e9c89155470ac865fdeeb687fd88e4e"
    "c9033021022979a02621af43883e6ca5a4df14d2c3a5a821e4c67923d13d5e78"
)

library=true
binary=false

dependencies=()

# Common variables.
_builddir="$BBUILD_SOURCE_DIR/$pkgname-$pkgver"


# Prepare the build.
function prepare() {
    cd "$_builddir"

    info2 "ncurses-5.9-gcc-5.patch"
    patch -p1 -i "$BBUILD_SOURCE_DIR"/ncurses-5.9-gcc-5.patch || return 1

    if [[ "$BBUILD_TARGET_PLATFORM" = "darwin" ]]; then
        for i in $sources; do
            case $i in
                darwin-*.patch)
                    info2 $i
                    patch -p1 -i "$BBUILD_SOURCE_DIR"/$i || return 1
                    ;;
            esac
        done
    fi

    cp "$BBUILD_SOURCE_DIR"/config.sub . || return 1
}


function build() {
    cd "$_builddir"

    CFLAGS="${BBUILD_STATIC_FLAGS}" \
    CXXFLAGS="${BBUILD_STATIC_FLAGS}" \
    ./configure \
        --disable-shared \
        --enable-static \
        --with-normal \
        --without-debug \
        --without-ada \
        --host=${BBUILD_CROSS_PREFIX} \
        --build=i686 \
        || return 1

    make || return 1
}

function setup_env() {
    echo "-I${_builddir}"               > "$depdir"/CPPFLAGS
    echo "-L${_builddir}/lib -lncurses" > "$depdir"/LDFLAGS
}
