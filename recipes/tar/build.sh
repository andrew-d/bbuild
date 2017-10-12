pkgname="tar"
pkgdesc="TODO"
##pkgdesc="GNU Tar is an archiver program.\n\nIt is used to create and manipulate files that are actually collections of many other files; the program provides users with an organized and systematic method of controlling a large amount of data.\n\nDespite its name, that is an acronym of 'tape archiver', GNU Tar is able to direct its output to any available devices, files or other programs, it may as well access remote devices or files.\n\nThe main areas of usage for GNU Tar are: storage, backup and transportation."
pkgver="1.29"

sources=(
    "https://ftp.gnu.org/gnu/tar/tar-${pkgver}.tar.xz"
)

sums=(
    "402dcfd0022fd7a1f2c5611f5c61af1cd84910a760a44a688e18ddbff4e9f024"
)

library=false
binary=true

dependencies=("libiconv")

# Common variables.
_builddir="$BBUILD_SOURCE_DIR/$pkgname-$pkgver"


function prepare() {
    cd "$_builddir"

    # Kept here for ease of use on future recipe updates
    # Apply all patches in our sources
    #for i in "${sources[@]}"; do
    #    case $i in
    #        darwin-*.patch)
    #            if [[ "$BBUILD_TARGET_PLATFORM" = "darwin" ]]; then
    #                info2 $i
    #                patch -p1 -i "$BBUILD_SOURCE_DIR"/$i || return 1
    #            fi
    #            ;;
    #
    #        *.patch)
    #            info2 $i
    #            patch -p1 -i "$BBUILD_SOURCE_DIR"/$i || return 1
    #            ;;
    #    esac
    #done
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

    cp src/tar "$BBUILD_OUT_DIR"/tar
    ${STRIP} "$BBUILD_OUT_DIR"/tar
}
