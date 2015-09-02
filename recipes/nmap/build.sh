pkgname="nmap"
pkgdesc="TODO"
pkgver="6.49BETA2"

sources=(
    "https://nmap.org/dist/nmap-${pkgver}.tar.bz2"
)
sums=(
    "e2f2aaa872fec288b927ceb59500edba198d8767adbe3a83a939e7921b224b79"
)

library=false
binary=true

dependencies=("openssl" "liblua" "zlib")
if [[ "$BBUILD_TARGET_PLATFORM" != "windows" ]]; then
    dependencies=( "${dependencies[@]}" "readline" )
fi

# Common variables.
_builddir="$BBUILD_SOURCE_DIR/$pkgname-$pkgver"


function prepare() {
    cd "$_builddir"

    _openssl_version="$(cat "$BBUILD_DEPCONF_DIR"/openssl/.version)"
    _openssl_dir="$(cat "$BBUILD_DEPCONF_DIR"/openssl/.source-dir)"
    _openssl_dir="$_openssl_dir"/"openssl-${_openssl_version}"

    if [[ "$BBUILD_TARGET_PLATFORM" = "windows" ]]; then
        # Need to append `-lgdi32` to all instances of OPENSSL_LIBS
        declare -r configure_files=$(find . -name configure.ac)
        for cf in $configure_files; do
            cd "$(dirname "$cf")"

            info2 "Patching configure.ac in: $(dirname "$cf")"
            sed -i \
                -e 's|OPENSSL_LIBS="-lssl -lcrypto"|OPENSSL_LIBS="-lssl -lcrypto -lgdi32"|g' \
                configure.ac
            autoreconf -i || true
            cd "$_builddir"
        done

        # TODO: anything more?
    fi
}


function build() {
    cd "$_builddir"

    local pcapty
    case "${BBUILD_TARGET_PLATFORM}" in
        linux|android)
            pcapty="linux"
            ;;
        darwin)
            pcapty="bpf"
            ;;
        windows)
            _build_windows
            return $?
            ;;
        *)
            error "Don't know what pcap type to use for platform: ${BBUILD_TARGET_PLATFORM}"
            return 1
            ;;
    esac

    debug "_openssl_dir = ${_openssl_dir}"

    info2 "Configuring nmap"
    AR="${AR}" \
    CC="${CC} ${BBUILD_STATIC_FLAGS}" \
    CXX="${CXX} ${BBUILD_STATIC_FLAGS}" \
    CFLAGS="${BBUILD_STATIC_FLAGS} ${CFLAGS:-}" \
    CXXFLAGS="${BBUILD_STATIC_FLAGS} ${CXXFLAGS:-} -static-libstdc++" \
    RANLIB="${RANLIB}" \
    ./configure \
        --host=${BBUILD_CROSS_PREFIX} \
        --build=i686 \
        --without-ndiff \
        --without-zenmap \
        --without-nmap-update \
        --disable-universal \
        --with-pcap="${pcapty}" \
        --with-openssl="${_openssl_dir}" \
        || return 1

    # Don't build the libpcap.so file
    if [[ -e libpcap/Makefile ]]; then
        sed -i -e 's/shared\: /shared\: #/' libpcap/Makefile || return 1
    fi

    _patch_makefile_vars || return 1
    _fix_libpcre || return 1

    # Do the real build.
    info2 "Building for real"
    make || return 1
}


function package() {
    cd "$_builddir"

    declare -a files=("ncat/ncat")
    if [[ "${BBUILD_TARGET_PLATFORM}" != "windows" ]]; then
        files=( "${files[@]}" "nmap" "nping/nping" )
    fi

    local f fname
    for f in "${files[@]}"; do
        fname=$(basename "$f")
        strip_helper \
            "${f}" \
            "${BBUILD_OUT_DIR}/${fname}${BBUILD_BINARY_EXT}" \
            || return 1
    done
}


######################################################################
## Helper Functions


function _patch_makefile_vars() {
    # We need to manually patch the 'AR' and 'RANLIB' variables in all the
    # Makefiles, since they don't appear to be set properly by the configure
    # script.
    declare -r Makefiles=$(find . -name Makefile)

    info2 "Patching Makefiles"
    local mf
    for mf in $Makefiles; do
        sed -i \
            -e "s|AR\\s*=\\s*ar\$|AR = ${AR}|g" \
            -e "s|RANLIB\\s*=\\s*ranlib\$|RANLIB = ${RANLIB}|g" \
            "$mf" || return 1
    done
}


function _fix_libpcre() {
    cd "$_builddir"

    # 'Build' libpcre (which may fail, but will create the appropriate
    # Makefile).
    info2 "Doing initial dummy libpcre build"
    make pcre_build || true

    # Patch libpcre's Makefile to use the right AR.
    sed -i \
        -e "s|AR\\s*=\\s*ar\$|AR = ${AR}|g" \
        libpcre/Makefile || return 1

    return 0
}


function _build_windows() {
    warn "Building nmap on Windows is a giant pile of hacks!"
    warn "You should be aware that this may stop working at any random point, or crash randomly, etc."
    sleep 2

    info2 "Building nbase"
    cd "$_builddir/nbase"
    AR="${AR}" \
    CC="${CC} -DDISABLE_NSOCK_PCAP ${BBUILD_STATIC_FLAGS}" \
    CXX="${CXX} ${BBUILD_STATIC_FLAGS}" \
    CFLAGS="${BBUILD_STATIC_FLAGS} ${CFLAGS:-}" \
    CXXFLAGS="${BBUILD_STATIC_FLAGS} ${CXXFLAGS:-} -static-libstdc++" \
    RANLIB="${RANLIB}" \
    ./configure \
        --host=${BBUILD_CROSS_PREFIX} \
        --build=i686 \
        --disable-universal \
        --disable-ipv6 \
        --without-libpcap \
        --with-openssl="${_openssl_dir}" \
        || return 1

    sed -i \
        -e 's|#include <WINCRYPT.H>|/* #include <WINCRYPT.H> */|g' \
        -e '/#include "nbase_winconfig.h"/a #include <errno.h>' \
        nbase_winunix.h \
        || return 1

    sed -i \
        -e 's|^typedef unsigned __int.*$|/* Typedef removed */|g' \
        -e 's|^typedef signed __int.*$|/* Typedef removed */|g' \
        nbase_winconfig.h \
        || return 1

    # Append the given string at the end of the line containing 'OBJS ='
    sed -i \
        -e '/^OBJS =/ s/$/ ${LIBOBJDIR}nbase_winunix.o/' \
        Makefile \
        || return 1

    _patch_makefile_vars || return 1
    make || return 1


    info2 "Building nsock"
    cd "$_builddir/nsock/src"
    AR="${AR}" \
    CC="${CC} -DDISABLE_NSOCK_PCAP ${BBUILD_STATIC_FLAGS}" \
    CXX="${CXX} ${BBUILD_STATIC_FLAGS}" \
    CFLAGS="${BBUILD_STATIC_FLAGS} ${CFLAGS:-}" \
    CXXFLAGS="${BBUILD_STATIC_FLAGS} ${CXXFLAGS:-} -static-libstdc++" \
    RANLIB="${RANLIB}" \
    ./configure \
        --host=${BBUILD_CROSS_PREFIX} \
        --build=i686 \
        --disable-universal \
        --disable-ipv6 \
        --without-libpcap \
        --with-openssl="${_openssl_dir}" \
        || return 1

    sed -i \
        -e 's|Winsock2.h|winsock2.h|g' \
        engine_poll.c \
        netutils.c \
        nsock_internal.h \
        || return 1

    _patch_makefile_vars || return 1
    make || return 1

    info2 "Building ncat"
    cd "$_builddir/ncat"
    AR="${AR}" \
    CC="${CC} -DDISABLE_NSOCK_PCAP ${BBUILD_STATIC_FLAGS}" \
    CXX="${CXX} ${BBUILD_STATIC_FLAGS}" \
    CFLAGS="${BBUILD_STATIC_FLAGS} ${CFLAGS:-}" \
    CXXFLAGS="${BBUILD_STATIC_FLAGS} ${CXXFLAGS:-} -static-libstdc++" \
    RANLIB="${RANLIB}" \
    ./configure \
        --host=${BBUILD_CROSS_PREFIX} \
        --build=i686 \
        --disable-universal \
        --disable-ipv6 \
        --without-libpcap \
        --with-openssl="${_openssl_dir}" \
        || return 1

    sed -i \
        -e 's|WinDef.h|windef.h|g' \
        sys_wrap.h \
        || return 1

    sed -i \
        -e 's|ncat_posix.c|ncat_win.c ncat_exec_win.c|g' \
        -e 's|ncat_posix.o|ncat_win.o ncat_exec_win.o|g' \
        -e 's|-lpcap||g' \
        -e '/^OPENSSL_LIBS/ s/$/ -lws2_32/' \
        Makefile \
        || return 1

    sed -i \
        -e 's|#include <openssl/applink.c>|/* Removed include */|g' \
        ncat_ssl.c \
        || return 1

    _patch_makefile_vars || return 1
    make ncat || return 1
    return 0
}
