pkgname="binutils"
pkgdesc="TODO"
pkgver="2.25"

sources=(
    "https://ftp.gnu.org/gnu/binutils/binutils-${pkgver}.tar.gz"
)
sums=(
    "cccf377168b41a52a76f46df18feb8f7285654b3c1bd69fc8265cb0fc6902f2d"
)

library=false
binary=true

if [[ "$BBUILD_TARGET_PLATFORM" = "darwin" ]]; then
    dependencies=("zlib" "libiconv")
else
    dependencies=()
fi

# Common variables.
_unpackeddir="$BBUILD_SOURCE_DIR/$pkgname-$pkgver"
_builddir="$BBUILD_SOURCE_DIR/$pkgname-build"


function build() {
    mkdir -p "$_builddir"
    cd "$_builddir"

    info2 "Running ./configure to get options"
    declare -r optsfile="$BBUILD_SOURCE_DIR"/configure-help.txt
    "$_unpackeddir"/configure --help > "$optsfile"

    declare -a opts=(
        "--host=${BBUILD_CROSS_PREFIX}"
        "--build=i686"
        "--target="
    )

    local opt
    for opt in "disable-nls" "enable-static-link" "disable-shared-plugins" \
               "disable-dynamicplugin" "disable-tls" "disable-pie"; do
        if grep -q "$opt" "$optsfile"; then
            opts+=("--${opt}")
        fi
    done
    for opt in "enable-static"; do
        if grep -q "$opt" "$optsfile"; then
            opts+=("--${opt}=yes")
        fi
    done
    for opt in "enable-shared"; do
        if grep -q "$opt" "$optsfile"; then
            opts+=("--${opt}=no")
        fi
    done

    debug "Opts = ${opts[*]}"

    CFLAGS="${BBUILD_STATIC_FLAGS}" \
    CXXFLAGS="${BBUILD_STATIC_FLAGS}" \
    "$_unpackeddir"/configure \
        ${opts[@]} \
        || return 1

    # This strange dance is required to get things to be statically linked.
    info2 "Running initial build"
    make || return 1

    if [[ "$BBUILD_TARGET_PLATFORM" != "darwin" ]]; then
        info2 "Cleaning and building static binaries"
        make clean || return 1
        make LDFLAGS=-all-static || return 1
    fi
}


function package() {
    cd "$_builddir"

    local f
    for f in "ar" "nm-new" "objcopy" "objdump" "ranlib" \
        "readelf" "size" "strings"; do
        local outname
        outname="${f%-new}"

        cp binutils/"$f" "$BBUILD_OUT_DIR"/"$outname"
        ${STRIP} "$BBUILD_OUT_DIR"/"$outname"
    done

    if [[ "$BBUILD_TARGET_PLATFORM" != "darwin" ]]; then
        cp ld/ld-new "$BBUILD_OUT_DIR"/ld
        ${STRIP} "$BBUILD_OUT_DIR"/ld
    fi
}
