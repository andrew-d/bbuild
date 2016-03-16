pkgname="python"
pkgdesc="TODO"
pkgver="2.7.11"

sources=(
    "https://www.python.org/ftp/python/${pkgver}/Python-${pkgver}.tar.xz"
)
sums=(
    "962b4c45af50124ea61f11a30deb4342fc0bc21126790fa1d7f6c79809413f46"
)

library=true
binary=true

dependencies=("zlib" "openssl" "readline" "termcap" "sqlite")

# Common variables.
_builddir="$BBUILD_SOURCE_DIR/Python-$pkgver"
_destdir="$BBUILD_SOURCE_DIR/dest"


function prepare() {
    cd "$_builddir"

    if [[ "$BBUILD_TARGET_PLATFORM" = "darwin" ]]; then
        error "Don't currently support cross-compiling to Darwin"
        return 1
    fi

    cat <<EOF > config.site
ac_cv_file__dev_ptmx=no
ac_cv_file__dev_ptc=no
EOF
}


function build() {
    cd "$_builddir"

    # Needed for cross-compilation.
    export CONFIG_SITE=$(pwd)/config.site

    info2 "Building 'pgen' binary for host"
    CC= CXX= LD= AR= RANLIB= CFLAGS= CXXFLAGS= CPPFLAGS= LDFLAGS= \
    ./configure || return 1
    make Parser/pgen || return 1

    # Copy this to use in the main directory
    cp Parser/pgen "$BBUILD_SOURCE_DIR"/ || return 1

    info2 "Cleaning"
    make distclean || return 1
    _setup_modules || return 1

    # TODO: figure out why we're getting the error:
    #       checking getaddrinfo bug... yes
    # And we can then re-enable IPv6
    info2 "Configuring cross build"
    CFLAGS="${BBUILD_STATIC_FLAGS} ${CFLAGS:-}" \
    CXXFLAGS="${BBUILD_STATIC_FLAGS} ${CXXFLAGS:-}" \
    LDFLAGS="${BBUILD_STATIC_FLAGS} ${LDFLAGS:-}" \
    ./configure \
        --disable-shared \
        --disable-ipv6 \
        --host=${BBUILD_CROSS_PREFIX} \
        --build=i686 \
        || return 1

    # Edit Makefile to add the appropriate #define for sqlite3 module.
    _fix_sqlite3_define || return 1

    # Build pgen...
    info2 "Building pgen"
    make Parser/pgen || return 1

    # ... and copy our host one overtop, 'touch'ing it so it doesn't get
    # rebuilt.
    cp "$BBUILD_SOURCE_DIR"/pgen ./Parser/pgen || return 1
    touch ./Parser/pgen

    # Build Python for real
    info2 "Building Python"
    make python || return 1

    # Install the static library and all headers
    info2 "Installing library and config"
    mkdir -p "$_destdir/usr/local/bin" "$_destdir/usr/local/lib" || return 1
    make libainstall inclinstall DESTDIR="$_destdir" || return 1
}


function package() {
    cd "$_builddir"

    # Copy binary
    cp "python${BBUILD_BINARY_EXT}" "$BBUILD_OUT_DIR"/"python${BBUILD_BINARY_EXT}"
    ${STRIP} "$BBUILD_OUT_DIR"/"python${BBUILD_BINARY_EXT}"

    # Make ZIP file containing stdlib.  We exclude some common test
    # directories, to reduce the size of the output ZIP file.
    cd "$_builddir"/Lib
    zip -r "${BBUILD_OUT_DIR}"/python27.zip . \
        -x 'bsddb/test*' \
        -x 'ctypes/test*' \
        -x 'distutils/tests*' \
        -x 'email/test*' \
        -x 'idlelib/idle_test*' \
        -x 'json/tests*' \
        -x 'lib-tk/test*' \
        -x 'lib2to3/tests*' \
        -x 'sqlite3/test*' \
        -x 'test*' \
        -x 'unittest/test*' \
        || return 1

    # Add the '_sysconfigdata' module
    cd "$_builddir"/build/lib.* || return 1
    zip -u "${BBUILD_OUT_DIR}"/python27.zip \
        _sysconfigdata.py \
        || return 1
}


function setup_env() {
    echo "-I${_destdir}/usr/local/include/python2.7"                > "$depdir"/CPPFLAGS
    echo "-L${_destdir}/usr/local/lib/python2.7/config -lpython2.7" > "$depdir"/LDFLAGS
}


function _setup_modules() {
    cp Modules/Setup.dist Modules/Setup

    declare -a modules=(
        "_bisect" "_collections" "_csv" "_datetime"
        "_elementtree" "_functools" "_heapq" "_io"
        "_md5" "_posixsubprocese" "_random" "_sha"
        "_sha256" "_sha512" "_socket" "_struct"
        "_weakref" "array" "binascii" "cmath"
        "cStringIO" "cPickle" "datetime" "fcntl"
        "future_builtins" "grp" "itertools" "math"
        "mmap" "operator" "parser" "readline"
        "resource" "select" "spwd" "strop" "syslog"
        "termios" "time" "unicodedata" "zlib"
    )

    info2 "Enabling modules"
    local mod
    for mod in "${modules[@]}";
    do
        sed -i -e "s/^#${mod}/${mod}/" Modules/Setup || return 1
    done

    echo '_json _json.c' >> Modules/Setup
    echo '_multiprocessing _multiprocessing/multiprocessing.c _multiprocessing/semaphore.c _multiprocessing/socket_connection.c' >> Modules/Setup

    # Enable static linking
    sed -i '1i\
*static*' Modules/Setup || return 1

    # Set dependency paths for zlib, readline, etc.
    declare -r zlib_flags="$(cat "$BBUILD_DEPCONF_DIR"/zlib/CPPFLAGS) $(cat "$BBUILD_DEPCONF_DIR"/zlib/LDFLAGS)"
    declare -r readline_flags="$(cat "$BBUILD_DEPCONF_DIR"/readline/CPPFLAGS) $(cat "$BBUILD_DEPCONF_DIR"/readline/LDFLAGS)"
    declare -r termcap_flags="$(cat "$BBUILD_DEPCONF_DIR"/termcap/CPPFLAGS) $(cat "$BBUILD_DEPCONF_DIR"/termcap/LDFLAGS)"
    declare -r openssl_flags="$(cat "$BBUILD_DEPCONF_DIR"/openssl/CPPFLAGS) $(cat "$BBUILD_DEPCONF_DIR"/openssl/LDFLAGS)"

    info2 "Setting dependency paths"
    sed -i \
        -e "s|^zlib zlibmodule.c|zlib zlibmodule.c ${zlib_flags}|" \
        -e "s|^readline readline.c|readline readline.c ${readline_flags} ${termcap_flags}|" \
        -e "s|^.*_ssl _ssl.c.*$|_ssl _ssl.c -DUSE_SSL ${openssl_flags}|" \
        Modules/Setup \
        || return 1

    # Set up sqlite
    _setup_sqlite3 || return 1
}


function _setup_sqlite3() {
    info2 "Fixing sqlite"

    # Find the include path.
    declare -r sqlite_cppflags=$(cat "$BBUILD_DEPCONF_DIR"/sqlite/CPPFLAGS)
    declare -r sqlite_ldflags=$(cat "$BBUILD_DEPCONF_DIR"/sqlite/LDFLAGS)

    debug "sqlite_cppflags = $sqlite_cppflags"
    debug "sqlite_ldflags = $sqlite_ldflags"

    local sqlite

    # Note: for some stupid reason, the `makesetup` script that Python uses
    # assumes that any line containing an `=` is supposed to be a Makefile
    # definition.  We need to omit those.
    sqlite="_sqlite3 "
    sqlite+=$(find Modules/_sqlite/ -name '*.c' | sed 's|Modules/||g')
    sqlite+=' -DSQLITE_OMIT_LOAD_EXTENSION '
    sqlite+=" -I\$(srcdir)/Modules/_sqlite $sqlite_cppflags "
    sqlite+=" $sqlite_ldflags "

    # Remove newlines, then replace multiple spaces with a single one
    sqlite=$(echo "$sqlite" | tr '\n' ' ' | tr -s ' ')

    debug "sqlite = $sqlite"
    echo "$sqlite" >> Modules/Setup || return 1
}


function _fix_sqlite3_define() {
    info2 "Fixing sqlite3 #define"

    # As per the comment about `=`, above, we need to manually set the
    # appropriate #define in the Makefile.
    sed -i \
        -e '/$(srcdir)\/Modules\/_sqlite/ s/$/ -DMODULE_NAME=\\"sqlite3\\"/' \
        Makefile \
        || return 1
}
