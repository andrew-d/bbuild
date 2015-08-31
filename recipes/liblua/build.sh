pkgname="lua"
pkgdesc="TODO"
pkgver="5.2.4"

sources=(
    "http://www.lua.org/ftp/lua-${pkgver}.tar.gz"
)
sums=(
    "b9e2e4aad6789b3b63a056d442f7b39f0ecfca3ae0f1fc0ae4e9614401b69f4b"
)

library=true
binary=false

dependencies=()

# Common variables.
_builddir="$BBUILD_SOURCE_DIR/$pkgname-$pkgver"


function build() {
    cd "$_builddir"

    local SYSCFLAGS
    case "${BBUILD_TARGET_PLATFORM}" in
        linux|android)
            SYSCFLAGS="-DLUA_USE_LINUX"
            ;;
        darwin)
            SYSCFLAGS="-DLUA_USE_MACOSX"
            ;;
        windows)
            # Do nothing
            ;;
        *)
            error "Don't know how to build Lua for platform: ${BBUILD_TARGET_PLATFORM}"
            return 1
            ;;
    esac

    make -C "$_builddir"/src \
        CC="${CC}" \
        RANLIB="${RANLIB}" \
        AR="${AR} rcu " \
        MYCFLAGS="${BBUILD_STATIC_FLAGS} ${CFLAGS:-}" \
        MYLDFLAGS="${BBUILD_STATIC_FLAGS} ${LDFLAGS:-}" \
        SYSCFLAGS="${SYSCFLAGS:-}" \
        liblua.a \
        || return 1
}


function setup_env() {
    echo "-I${_builddir}/src"       > "$depdir"/CPPFLAGS
    echo "-L${_builddir}/src -llua" > "$depdir"/LDFLAGS
}
