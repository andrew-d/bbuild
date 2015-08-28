pkgname="lua"
pkgdesc="TODO"
pkgver="5.2.4"

sources=(
    "http://www.lua.org/ftp/lua-${pkgver}.tar.gz"
)
sums=(
    "b9e2e4aad6789b3b63a056d442f7b39f0ecfca3ae0f1fc0ae4e9614401b69f4b"
)

library=false
binary=true

dependencies=("readline" "ncurses")

# Common variables.
_builddir="$BBUILD_SOURCE_DIR/$pkgname-$pkgver"


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
