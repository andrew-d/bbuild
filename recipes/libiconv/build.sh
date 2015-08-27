pkgname="libiconv"
pkgdesc="TODO"
pkgver="1.14"

sources=(
    "http://ftp.gnu.org/pub/gnu/libiconv/libiconv-${pkgver}.tar.gz"
    "config.sub"
    "libiconv-1.14_srclib_stdio.in.h-remove-gets-declarations.patch"
    "libiconv-build-fixes.patch"
    "patch-Makefile.devel.patch"
    "darwin-utf8mac-flags.patch"
    "darwin-utf8mac.patch"
)
sums=(
    "72b24ded17d687193c3366d0ebe7cde1e6b18f0df8c55438ac95be39e8a30613"
    "f4cf53ff68e5b9c3437a1e7ad3086c4c669136caebd721ffc58ef21944bd395a"
    "6fe0a9de9f6ac224239ad5aa943f23f856a8dbec38f4313c8cd2b48a6a399906"
    "08a9b2a5904c9798247093943ab92b2810404e84cea966d7b9d4976295e2b595"
    "ad9b6da1a82fc4de27d6f7086a3382993a0b16153bc8e8a23d7b5f9334ca0a42"
    "eb0bc64d6b605640fe356373a91a75295871e5d9e7e7afb1d5b67db7bd0050a0"
    "e8128732f22f63b5c656659786d2cf76f1450008f36bcf541285268c66cabeab"
)

library=true
binary=false

dependencies=()

# Common variables.
_builddir="$BBUILD_SOURCE_DIR/$pkgname-$pkgver"


function prepare() {
    cd "$_builddir"

    # Apply all patches in our sources
    for i in "${sources[@]}"; do
        case $i in
            darwin-*.patch)
                if [[ "$BBUILD_TARGET_PLATFORM" = "darwin" ]]; then
                    info2 $i
                    patch -p1 -i "$BBUILD_SOURCE_DIR"/$i || return 1
                fi
                ;;

            *.patch)
                info2 $i
                patch -p1 -i "$BBUILD_SOURCE_DIR"/$i || return 1
                ;;
        esac
    done

    info2 "Fixing Makefile"
    sed -i '/cd preload && /d' Makefile.in || return 1

    info2 "Fixing config.sub"
    find . -name config.sub -exec cp "$BBUILD_SOURCE_DIR"/config.sub {} \;
}


function build() {
    cd "$_builddir"

    CFLAGS="${BBUILD_STATIC_FLAGS}" \
    CXXFLAGS="${BBUILD_STATIC_FLAGS}" \
    LDFLAGS="${BBUILD_STATIC_FLAGS}" \
    ./configure \
        --disable-shared \
        --enable-static \
        --disable-debug \
        --disable-dependency-tracking \
        --enable-extra-encodings \
        --host=${BBUILD_CROSS_PREFIX} \
        --build=i686 \
        || return 1

    make || return 1
}

function setup_env() {
    echo "-I${_builddir}/include"           > "$depdir"/CPPFLAGS
    echo "-L${_builddir}/lib/.libs -liconv" > "$depdir"/LDFLAGS
}
