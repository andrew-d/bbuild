pkgname="lua"
pkgdesc="TODO"
pkgver="5.2.4"

_lpeg_version="0.12.2"
_luafilesystem_version="6d039ff3854db74c1b32ab3f14377bd5f49e2119"
_luasocket_version="4110e4125dace9df3a744067066e5dee62670561"
_luaposix_version="5536f10d63e7c55c82e3a6b8a18d29de4380c007"

sources=(
    "http://www.lua.org/ftp/lua-${pkgver}.tar.gz"
    "lua-5.2.0-advanced_readline.patch"
    "darwin-lua-5.2.3-sig_catch.patch"
    "linit.patch"

    "luafilesystem-${_luafilesystem_version}.tar.gz::https://github.com/keplerproject/luafilesystem/archive/${_luafilesystem_version}.tar.gz"
    "luasocket-${_luasocket_version}.tar.gz::https://github.com/diegonehab/luasocket/archive/${_luasocket_version}.tar.gz"
    "luaposix-${_luaposix_version}.tar.gz::https://github.com/luaposix/luaposix/archive/${_luaposix_version}.tar.gz"
    "https://github.com/keplerproject/lua-compat-5.2/raw/master/lbitlib.c"

    # From: http://webserver2.tecgraf.puc-rio.br/~lhf/ftp/lua/5.2/lcomplex.tar.gz
    "lcomplex.tar.gz"

    # From: http://www.inf.puc-rio.br/~roberto/lpeg/lpeg-0.12.2.tar.gz
    "lpeg-0.12.2.tar.gz"
)
sums=(
    "b9e2e4aad6789b3b63a056d442f7b39f0ecfca3ae0f1fc0ae4e9614401b69f4b"
    "33d32d11fce4f85b88ce8f9bd54e6a6cbea376dfee3dbf8cdda3640e056bc29d"
    "f2e77f73791c08169573658caa3c97ba8b574c870a0a165972ddfbddb948c164"
    "SKIP"

    "5d3493fc12905baa336a32d31fb339a0338eb5c0c28433602ae537ee7083def1"
    "8d294306a0865037cf9c93f492aab7a8bd0dd3b685af4cd99b8430f4eaad1933"
    "d3e91fd7390d8e8692f4bee01acb73e35447e7dfd8483c5132f58002b36b5247"
    "b18af72c11725abf52431d89ee856a3b78c7b56b6cb8463cbfd68c293aabf4ad"
    "46f5086b4d5098db53adff90fd701b794dc8531abdea9b8cbda1d42789e21259"
    "6aad270b91d1b1c6fd75f68e162329a04a644e50e917d55f46cc8384b7120004"
)

library=false
binary=true

dependencies=("readline" "ncurses")

# Common variables.
_builddir="$BBUILD_SOURCE_DIR/$pkgname-$pkgver"
declare -r luainc="-I${_builddir}/src"
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


function build() {
    cd "$_builddir"

    # Native build
    _build_native || return 1

    # Remove '-l{readline,ncurses}' from LDFLAGS, since that breaks the order
    LDFLAGS="${LDFLAGS:-}"
    for v in readline ncurses; do
        LDFLAGS="${LDFLAGS/-l$v/ }"
    done

    local SYSCFLAGS SYSLIBS SYSLDFLAGS
    case "${BBUILD_TARGET_PLATFORM}" in
        linux|android)
            SYSCFLAGS="-DLUA_USE_LINUX"
            SYSLIBS="-Wl,-E -ldl -lreadline"
            ;;
        darwin)
            SYSCFLAGS="-DLUA_USE_MACOSX"
            SYSLIBS="-lreadline"
            ;;
        windows)
            # TODO: finish me
            error "Building Lua for Windows doesn't work yet"
            ;;
        *)
            error "Don't know how to build Lua for platform: ${BBUILD_TARGET_PLATFORM}"
            return 1
            ;;
    esac

    # Build 3rd-party modules
    #_build_lbitlib || return 1   # Unnecessary?
    _build_lcomplex || return 1
    _build_lpeg || return 1
    _build_luafilesystem || return 1
    #_build_luaposix || return 1
    _build_luasocket || return 1

    # Patch linit.c to include them.
    cd "$_builddir"

    # Update linit.c
    declare -a openfuncs=(
        # Format library name/luaopen_{name}
        "complex/complex"
        "lfs/lfs"
        "lpeg/lpeg"
        "mime/mime_core"
        "socket/socket_core"

        # luaposix libraries
        # NOTE: these aren't currently included because we have no 'nice' way
        # of bundling .lua files with the interpreter just yet.
        #"posix.stdlib/posix_stdlib"
        #"posix.pwd/posix_pwd"
        #"posix.time/posix_time"
        #"posix.unistd/posix_unistd"
    )

    local libname openname
    for spec in "${openfuncs[@]}"; do
        libname=${spec%/*}
        openname=${spec#*/}

        sed -i \
            -e "/^static const luaL_Reg preloadedlibs.*\$/a \\ \\ {\"${libname}\", luaopen_${openname}}," \
            -e "/^\#include \"lauxlib.h\"\$/a int luaopen_${openname} \(lua_State \*L\);" \
            src/linit.c
    done

    #debug "Additional objects: ${_lib_objs[*]}"

    # TODO: add more modules:
    #   - luaposix (finish me)
    #   - win32 bindings?
    #   - sqlite3
    info2 "Building lua"
    make clean
    make -C "$_builddir"/src \
        CC="${CC}" \
        RANLIB="${RANLIB}" \
        AR="${AR} rcu " \
        MYCFLAGS="${BBUILD_STATIC_FLAGS} ${CFLAGS:-}" \
        MYLDFLAGS="${BBUILD_STATIC_FLAGS} ${LDFLAGS:-}" \
        MYLIBS="-lncurses" \
        MYOBJS="${_lib_objs[*]}" \
        SYSCFLAGS="${SYSCFLAGS:-}" \
        SYSLDFLAGS="${SYSLDFLAGS:-}" \
        SYSLIBS="${SYSLIBS:-}" \
        all \
        || return 1
}


function package() {
    cd "$_builddir"

    for f in lua luac; do
        cp src/"$f" "$BBUILD_OUT_DIR"/"$f"
        ${STRIP} "$BBUILD_OUT_DIR"/"$f"
    done
}

# Helper that runs and prints something
function printrun() {
    echo "$@"
    $@
    return $?
}

function _build_native() {
    cd "$_builddir"

    # Build locally, and copy the interpreter.
    info2 "Building local copy of interpreter"
    LDFLAGS="" \
    make \
        PLAT=posix \
        all \
        || return 1
    cp src/lua "${BBUILD_SOURCE_DIR}/lua"
}

######################################################################
## Per-Module Build Functions

function _build_lbitlib() {
    cd "$BBUILD_SOURCE_DIR"

    info2 "Building lbitlib"
    printrun ${CC} -c -o lbitlib.o \
        ${luainc} ${BBUILD_STATIC_FLAGS} \
        lbitlib.c \
        || return 1

    _lib_objs+=("${BBUILD_SOURCE_DIR}/lbitlib.o")
}


function _build_lcomplex() {
    declare -r dir="$BBUILD_SOURCE_DIR"/complex
    cd "$dir"

    # Compilation flags from the makefile.
    declare -r flags="-O2 -std=c99 -pedantic -Wall -Wextra"

    info2 "Building lcomplex"
    printrun ${CC} -c -o "${dir}"/lcomplex.o \
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


function _build_luafilesystem() {
    declare -r dir="$BBUILD_SOURCE_DIR"/"luafilesystem-${_luafilesystem_version}"
    cd "$dir"

    # Compilation flags from the makefile.
    declare -r flags="-O2 -Wall -fPIC -W -Waggregate-return -Wcast-align -Wmissing-prototypes -Wnested-externs -Wshadow -Wwrite-strings -pedantic"

    info2 "Building LuaFileSystem"
    printrun ${CC} -c -o "${dir}"/luafilesystem.o \
        ${flags} ${luainc} ${BBUILD_STATIC_FLAGS} \
        src/lfs.c \
        || return 1

    _lib_objs+=("${dir}/luafilesystem.o")
}


function _build_luaposix() {
    declare -r dir="$BBUILD_SOURCE_DIR"/"luaposix-$_luaposix_version"
    cd "$dir"

    info2 "Building luaposix"
    ./bootstrap --skip-rock-checks || return 1

    CC="${CC}" \
    CFLAGS="${BBUILD_STATIC_FLAGS} ${CFLAGS:-}" \
    CPPFLAGS="-I${_builddir}/src ${CPPFLAGS:-}" \
    LUA="${BBUILD_SOURCE_DIR}/lua" \
    ./configure \
        --disable-shared \
        --enable-static \
        --host=${BBUILD_CROSS_PREFIX} \
        --build=i686 \
        || return 1

    make || return 1
    _lib_objs+=("${dir}/ext/posix/.libs/posix.a")
}


function _build_luasocket() {
    declare -r dir="$BBUILD_SOURCE_DIR"/"luasocket-$_luasocket_version"
    cd "$dir"

    info2 "Building LuaSocket"
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
