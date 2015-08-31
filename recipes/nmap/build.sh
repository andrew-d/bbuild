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

dependencies=("openssl" "liblua" "zlib" "readline")

# Common variables.
_builddir="$BBUILD_SOURCE_DIR/$pkgname-$pkgver"


function build() {
    cd "$_builddir"

    local pcapty
    case "${BBUILD_TARGET_PLATFORM}" in
        linux|android)
            pcapty=linux
            ;;
        darwin)
            pcapty=bpf
            ;;
        *)
            error "Don't know what pcap type to use for platform: ${BBUILD_TARGET_PLATFORM}"
            return 1
            ;;
    esac

    local openssl_dir openssl_version
    openssl_version="$(cat "$BBUILD_DEPCONF_DIR"/openssl/.version)"
    openssl_dir="$(cat "$BBUILD_DEPCONF_DIR"/openssl/.source-dir)"
    openssl_dir="$openssl_dir"/"openssl-${openssl_version}"

    debug "openssl_dir = ${openssl_dir}"

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
        --with-openssl="${openssl_dir}" \
        || return 1

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

    # Don't build the libpcap.so file
    if [[ -e libpcap/Makefile ]]; then
        sed -i -e 's/shared\: /shared\: #/' libpcap/Makefile || return 1
    fi

    # 'Build' libpcre (which may fail, but will create the appropriate
    # Makefile).
    info2 "Doing initial dummy libpcre build"
    make pcre_build || true

    # Patch libpcre's Makefile to use the right AR.
    sed -i \
        -e "s|AR\\s*=\\s*ar\$|AR = ${AR}|g" \
        libpcre/Makefile || return 1

    # Do the real build.
    info2 "Building for real"
    make || return 1
}


function package() {
    cd "$_builddir"

    local f fname
    for f in nmap ncat/ncat nping/nping; do
        fname=$(basename "$f")
        cp "${f}${BBUILD_BINARY_EXT}" "$BBUILD_OUT_DIR"/"${fname}${BBUILD_BINARY_EXT}"
        ${STRIP} "$BBUILD_OUT_DIR"/"${fname}${BBUILD_BINARY_EXT}"
    done
}
