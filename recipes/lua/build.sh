pkgname="lua"
pkgdesc="TODO"
pkgver="5.2.4"

sources=(
    "http://www.lua.org/ftp/lua-${pkgver}.tar.gz"
    "lua-5.2.0-advanced_readline.patch"
    "darwin-lua-5.2.3-sig_catch.patch"
)
sums=(
    "b9e2e4aad6789b3b63a056d442f7b39f0ecfca3ae0f1fc0ae4e9614401b69f4b"
    "33d32d11fce4f85b88ce8f9bd54e6a6cbea376dfee3dbf8cdda3640e056bc29d"
    "f2e77f73791c08169573658caa3c97ba8b574c870a0a165972ddfbddb948c164"
)

library=false
binary=true

dependencies=("readline" "ncurses")

# Common variables.
_builddir="$BBUILD_SOURCE_DIR/$pkgname-$pkgver"


function prepare() {
    cd "$_builddir"

    info2 "Applying advanced readline patch"
    patch -p1 -i "$BBUILD_SOURCE_DIR"/lua-5.2.0-advanced_readline.patch

    if [[ "$BBUILD_TARGET_PLATFORM" = "darwin" ]]; then
        info2 "Applying sig_catch patch"
        patch -p1 -i "$BBUILD_SOURCE_DIR"/darwin-lua-5.2.3-sig_catch.patch
    fi
}


function build() {
    cd "$_builddir"

    # Remove '-l{readline,ncurses}' from LDFLAGS, since that breaks the order
    LDFLAGS="${LDFLAGS:-}"
    for v in readline ncurses; do
        LDFLAGS="${LDFLAGS/-l$v/ }"
    done

    local platform
    case "${BBUILD_TARGET_PLATFORM}" in
        linux|android)
            platform=linux
            ;;
        darwin)
            platform=macosx
            ;;
        windows)
            platform=mingw
            ;;
        *)
            error "Don't know how to build lua for platform: ${BBUILD_TARGET_PLATFORM}"
            return 1
            ;;
    esac

    # TODO: add more modules (e.g. LuaFileSystem, luaposix, lpeg, LuaSocket, etc.)
    make linux \
        CC="${CC}" \
        RANLIB="${RANLIB}" \
        AR="${AR} rcu " \
        MYCFLAGS="${BBUILD_STATIC_FLAGS} ${CFLAGS:-}" \
        MYLDFLAGS="${BBUILD_STATIC_FLAGS} ${LDFLAGS}" \
        MYLIBS=-lncurses \
        || return 1
}


function package() {
    cd "$_builddir"

    cp src/lua "$BBUILD_OUT_DIR"/lua
    ${STRIP} "$BBUILD_OUT_DIR"/lua
}
