pkgname="procps"
pkgdesc="TODO"
pkgver="3.3.11"

sources=(
    "${pkgname}-${pkgver}.tar.gz::https://gitlab.com/procps-ng/procps/repository/archive.tar.gz?ref=v${pkgver}"
)
sums=(
    "69e421cb07d5dfd38100b4b68714e9cb05d4fe58a7c5145c7b672d1ff08ca58b"
)

library=true
binary=true

dependencies=("ncurses")

# Common variables.
_builddir="$BBUILD_SOURCE_DIR/${pkgname}-$pkgver"
_destdir="$BBUILD_SOURCE_DIR/dest"

_programs=( \
    "free" \
    "pgrep" \
    "pkill" \
    "pmap" \
    "pwdx" \
    "tload" \
    "uptime" \
    "vmstat" \
    "w" \
)


function prepare() {
    # Need to rename the unpacked directory
    mv "$BBUILD_SOURCE_DIR"/procps-v${pkgver}-* "$_builddir" || return 1
    cd "$_builddir" || return 1
}


function build() {
    cd "$_builddir"

    info2 "Reconfiguring"
    autoreconf -i || return 1

    info2 "Configuring"

    ac_cv_func_malloc_0_nonnull=yes \
    ac_cv_func_realloc_0_nonnull=yes \
    CC="${CC} ${BBUILD_STATIC_FLAGS}" \
    LD="${LD:-} ${BBUILD_STATIC_FLAGS}" \
    ./configure \
        --host=${BBUILD_CROSS_PREFIX} \
        --build=i686 \
        --disable-shared \
        --disable-dependency-tracking \
        --prefix="${BBUILD_SOURCE_DIR}/dest" \
        PKG_CONFIG=/bin/true \
        || return 1

    info2 "Building library"
    make proc/libprocps.la || return 1
    rm proc/libprocps.la proc/.libs/*
    make proc/libprocps.la LDFLAGS=-all-static || return 1

    info2 "Building programs"
    make ps/pscommand "${_programs[@]}" || return 1
    rm ps/pscommand
    for prog in "${_programs[@]}"; do
        rm "$prog"
    done

    make ps/pscommand "${_programs[@]}" LDFLAGS=-all-static || return 1
}


function package() {
    cd "$_builddir"

    for prog in "${_programs[@]}"; do
        cp "$prog" "$BBUILD_OUT_DIR/$prog"
        "${STRIP}" "$BBUILD_OUT_DIR/$prog"
    done

    cp ps/pscommand "$BBUILD_OUT_DIR/ps"
    "${STRIP}" "$BBUILD_OUT_DIR/ps"
}


function setup_env() {
    cd "$_builddir"

    # Install into our destination directory
    mkdir -p "$_destdir" || return 1
    make install-libLTLIBRARIES install-proc_libprocps_la_includeHEADERS || return 1

    # Set the install flags
    echo "-I${_destdir}/include"      > "$depdir"/CPPFLAGS
    echo "-L${_destdir}/lib -lprocps" > "$depdir"/LDFLAGS
}
