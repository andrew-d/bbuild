pkgname="lua"
pkgdesc="TODO"
pkgver="5.2.4"

_lpeg_version="0.12.2"
_luafilesystem_version="6d039ff3854db74c1b32ab3f14377bd5f49e2119"
_luasocket_version="4110e4125dace9df3a744067066e5dee62670561"

sources=(
    "http://www.lua.org/ftp/lua-${pkgver}.tar.gz"
    "lua-5.2.0-advanced_readline.patch"
    "darwin-lua-5.2.3-sig_catch.patch"
    "linit.patch"

    "luafilesystem-${_luafilesystem_version}.tar.gz::https://github.com/keplerproject/luafilesystem/archive/${_luafilesystem_version}.tar.gz"
    "http://webserver2.tecgraf.puc-rio.br/~lhf/ftp/lua/5.2/lcomplex.tar.gz"
    'http://www.inf.puc-rio.br/~roberto/lpeg/lpeg-0.12.2.tar.gz'
    "luasocket-${_luasocket_version}.tar.gz::https://github.com/diegonehab/luasocket/archive/${_luasocket_version}.tar.gz"
)
sums=(
    "b9e2e4aad6789b3b63a056d442f7b39f0ecfca3ae0f1fc0ae4e9614401b69f4b"
    "33d32d11fce4f85b88ce8f9bd54e6a6cbea376dfee3dbf8cdda3640e056bc29d"
    "f2e77f73791c08169573658caa3c97ba8b574c870a0a165972ddfbddb948c164"
    "SKIP"

    "5d3493fc12905baa336a32d31fb339a0338eb5c0c28433602ae537ee7083def1"
    "46f5086b4d5098db53adff90fd701b794dc8531abdea9b8cbda1d42789e21259"
    "6aad270b91d1b1c6fd75f68e162329a04a644e50e917d55f46cc8384b7120004"
    "8d294306a0865037cf9c93f492aab7a8bd0dd3b685af4cd99b8430f4eaad1933"
)

library=false
binary=true

dependencies=("readline" "ncurses")

# Common variables.
_builddir="$BBUILD_SOURCE_DIR/$pkgname-$pkgver"
declare -a _lib_objs=()


function prepare() {
    cd "$_builddir"

    info2 "Applying advanced readline patch"
    patch -p1 -i "$BBUILD_SOURCE_DIR"/lua-5.2.0-advanced_readline.patch

    if [[ "$BBUILD_TARGET_PLATFORM" = "darwin" ]]; then
        info2 "Applying sig_catch patch"
        patch -p1 -i "$BBUILD_SOURCE_DIR"/darwin-lua-5.2.3-sig_catch.patch
    fi
}


function _build_luafilesystem() {
    declare -r dir="$BBUILD_SOURCE_DIR"/"luafilesystem-${_luafilesystem_version}"
    cd "$dir"

    # Compilation flags from the makefile.
    declare -r flags="-O2 -Wall -fPIC -W -Waggregate-return -Wcast-align -Wmissing-prototypes -Wnested-externs -Wshadow -Wwrite-strings -pedantic"
    declare -r luainc="-I${_builddir}/src"

    info2 "Building LuaFileSystem"
    ${CC} -c -o "${dir}"/luafilesystem.o \
        ${flags} ${luainc} ${BBUILD_STATIC_FLAGS} \
        src/lfs.c \
        || return 1

    _lib_objs+=("${dir}/luafilesystem.o")
}


function _build_lcomplex() {
    declare -r dir="$BBUILD_SOURCE_DIR"/complex
    cd "$dir"

    # Compilation flags from the makefile.
    declare -r flags="-O2 -std=c99 -pedantic -Wall -Wextra"
    declare -r luainc="-I${_builddir}/src"

    info2 "Building lcomplex"
    ${CC} -c -o "${dir}"/lcomplex.o \
        ${flags} ${luainc} ${BBUILD_STATIC_FLAGS} \
        lcomplex.c \
        || return 1

    _lib_objs+=("${dir}/lcomplex.o")
}


function _build_lpeg() {
    declare -r dir="$BBUILD_SOURCE_DIR"/"lpeg-$_lpeg_version"
    cd "$dir"

    declare -r srcs=( *.c )
    declare -r objs=("${srcs[@]/%.c/.o}")

    info2 "Building LPeg"
    make \
        CC="${CC} ${BBUILD_STATIC_FLAGS}" \
        LUADIR="${_builddir}/src" \
        ${objs[*]} \
        || return 1

    _lib_objs+=("${objs[@]/#/$dir/}")
}


function _build_luasocket() {
    declare -r dir="$BBUILD_SOURCE_DIR"/"luasocket-$_luasocket_version"
    cd "$dir"

    sed -i \
        -e "s|MYCFLAGS=|MYCFLAGS=-I${_builddir}/src -fPIC ${BBUILD_STATIC_FLAGS}|g" \
        -e "s|MYLDFLAGS=|MYLDFLAGS=-I${_builddir}/src ${BBUILD_STATIC_FLAGS}|g" \
        -e "s|CC=\$(CC_\$(PLAT))|CC=${CC}|g" \
        -e "s|LD=\$(LD_\$(PLAT))|LD=${CC}|g" \
        -e "s|LDFLAGS=\$(MYLDFLAGS) \$(LDFLAGS_\$(PLAT))|LDFLAGS=\$(MYLDFLAGS) -o |g" \
        src/makefile || return 1

    cat <<EOF >> src/makefile

.PHONY: all-objs
all-objs: \$(SOCKET_OBJS) \$(MIME_OBJS)
EOF

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
            error "Don't know how to build LuaSocket for platform: ${BBUILD_TARGET_PLATFORM}"
            return 1
            ;;
    esac

    info2 "Building LuaSocket"
    make -C src \
        PLAT="${platform}" \
        all-objs \
        || return 1

    declare -r fout=$(find src -name "*.o")
    if [[ ! $? ]]; then
        return 1
    fi

    declare -a objs=( $fout )
    _lib_objs+=("${objs[@]/#/$dir/}")
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

    # Build 3rd-party modules
    _build_luafilesystem || return 1
    _build_lcomplex || return 1
    _build_lpeg || return 1
    _build_luasocket || return 1

    # Patch linit.c to include them.
    cd "$_builddir"
    patch -p1 -i "$BBUILD_SOURCE_DIR"/linit.patch || return 1

    debug "Additional objects: ${_lib_objs[*]}"

    # TODO: add more modules:
    #   - luaposix
    #   - win32 bindings?
    #   - sqlite3
    info2 "Building lua"
    make \
        CC="${CC}" \
        RANLIB="${RANLIB}" \
        AR="${AR} rcu " \
        MYCFLAGS="${BBUILD_STATIC_FLAGS} ${CFLAGS:-}" \
        MYLDFLAGS="${BBUILD_STATIC_FLAGS} ${LDFLAGS}" \
        MYLIBS=-lncurses \
        MYOBJS="${_lib_objs[*]}" \
        PLAT="${platform}" \
        || return 1
}


function package() {
    cd "$_builddir"

    cp src/lua "$BBUILD_OUT_DIR"/lua
    ${STRIP} "$BBUILD_OUT_DIR"/lua
}
