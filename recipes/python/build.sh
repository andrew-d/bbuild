pkgname="python"
pkgdesc="TODO"
pkgver="2.7.10"

sources=(
    "https://www.python.org/ftp/python/${pkgver}/Python-${pkgver}.tar.xz"
)
sums=(
    "1cd3730781b91caf0fa1c4d472dc29274186480161a150294c42ce9b5c5effc0"
)

library=false
binary=true

dependencies=("zlib" "openssl" "readline" "termcap")

# Common variables.
_builddir="$BBUILD_SOURCE_DIR/Python-$pkgver"


function prepare() {
    cd "$_builddir"

    if [[ "$BBUILD_TARGET_PLATFORM" = "darwin" ]]; then
        error "Don't currently support cross-compiling to Darwin"
        return 1
    fi

    _setup_modules || return 1

    cat <<EOF > config.site
ac_cv_file__dev_ptmx=no
ac_cv_file__dev_ptc=no
EOF
}


function build() {
    cd "$_builddir"

    # Needed for cross-compilation.
    export CONFIG_SITE=$(pwd)/config.site

    info2 "Building Python for host"
    CC= CXX= LD= AR= RANLIB= CFLAGS= CPPFLAGS= LDFLAGS= \
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
    info2 "Doing cross build"
    CFLAGS="${BBUILD_STATIC_FLAGS} ${CFLAGS:-}" \
    CXXFLAGS="${BBUILD_STATIC_FLAGS} ${CXXFLAGS:-}" \
    LDFLAGS="${BBUILD_STATIC_FLAGS} ${LDFLAGS:-}" \
    ./configure \
        --disable-shared \
        --disable-ipv6 \
        --host=${BBUILD_CROSS_PREFIX} \
        --build=i686 \
        || return 1

    # Build pgen...
    make Parser/pgen || return 1

    # ... and copy our host one overtop, 'touch'ing it so it doesn't get
    # rebuilt.
    cp "$BBUILD_SOURCE_DIR"/pgen ./Parser/pgen || return 1
    touch ./Parser/pgen

    # Build Python for real
    make python || return 1
}


function package() {
    cd "$_builddir"

    # Copy binary
    cp "python${BBUILD_BINARY_EXT}" "$BBUILD_OUT_DIR"/"python${BBUILD_BINARY_EXT}"
    ${STRIP} "$BBUILD_OUT_DIR"/"python${BBUILD_BINARY_EXT}"

    # Make ZIP file containing stdlib.  We exclude some common test
    # directories, to reduce the size of the output ZIP file.
    cd Lib
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
        -x 'unittest/test*'
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

    sed -i \
        -e "s|^zlib zlibmodule.c|zlib zlibmodule.c ${zlib_flags}|" \
        -e "s|^readline readline.c|readline readline.c ${readline_flags} ${termcap_flags}|" \
        -e "s|^.*_ssl _ssl.c.*$|_ssl _ssl.c -DUSE_SSL ${openssl_flags}|" \
        Modules/Setup \
        || return 1
}
