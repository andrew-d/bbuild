pkgname="git"
pkgdesc="TODO"
pkgver="2.6.0-rc2"

sources=(
    "git-${pkgver}.tar.gz::https://github.com/git/git/archive/v${pkgver}.tar.gz"
)
sums=(
    "b9c837193bc74af386051087845b634db871d15fdeb0cb190512ee3ad6a7ce1d"
)

library=false
binary=true

dependencies=("zlib" "curl" "expat")

# Common variables.
_builddir="$BBUILD_SOURCE_DIR/$pkgname-$pkgver"
_destdir="${BBUILD_SOURCE_DIR}/dest"


function prepare() {
    cd "$_builddir"

    # This prevents an irritating warning
    sed -i \
        -e 's|#include <sys/poll.h>|#include <poll.h>|g' \
        git-compat-util.h \
        || return 1
}


function build() {
    cd "$_builddir"

    make configure || return 1

    # Remove '-lfoo' flags from LDFLAGS and store in LIBS.
    declare -a myLIBS=()
    declare -a myLDFLAGS=()
    declare -a ldArr=(${LDFLAGS:-})

    for flag in "${ldArr[@]}"; do
        if [[ $flag == -l* ]]; then
            myLIBS+=("$flag")
        else
            myLDFLAGS+=("$flag")
        fi
    done

    export LDFLAGS="${myLDFLAGS[*]}"
    export LIBS="${myLIBS[*]}"

    debug "new LDFLAGS: ${LDFLAGS}"
    debug "new LIBS: ${LIBS}"

    # We need to explicitly provide two values for the configure script, since
    # it attempts to run a program otherwise, which doesn't work when cross-
    # compiling.
    CC="${CC} ${BBUILD_STATIC_FLAGS}" \
    CFLAGS="${CFLAGS:-} ${BBUILD_STATIC_FLAGS}" \
    LDFLAGS="${LDFLAGS:-} ${BBUILD_STATIC_FLAGS}" \
    ./configure \
        --host=${BBUILD_CROSS_PREFIX} \
        --build=i686 \
        --prefix=/usr \
        ac_cv_fread_reads_directories=no \
        ac_cv_snprintf_returns_bogus=no \
        || return 1

    make \
        EXTLIBS="${LIBS}" \
        || return 1

    mkdir -p "$_destdir" || return 1
    make install DESTDIR="$_destdir" || return 1
}


function package() {
    cd "$_destdir"

    # Things in ${prefix}/bin
    for f in usr/bin/*; do
        _maybe_strip "$f" "$BBUILD_OUT_DIR"/ || return 1
    done

    # Everything in our libexec directory
    mkdir -p "$BBUILD_OUT_DIR/exec-path" || return 1
    for f in usr/libexec/git-core/*; do
        # Skip mergetools
        if [[ $f == *mergetools ]]; then
            continue
        fi

        _maybe_strip "$f" "$BBUILD_OUT_DIR/exec-path/" || return 1
    done

    # Copy the mergetools directory
    cp -r usr/libexec/git-core/mergetools "$BBUILD_OUT_DIR/exec-path/" || return 1
}


function _maybe_strip() {
    declare -r src="$1"
    declare -r dst="$2"

    # `-s` is true if the file exists and is larger than 0 bytes.
    if [[ ! -s "$src" ]]; then
        error "File does not exist: $src"
        return 1
    fi

    declare -r info=$(file "$src" 2>&1)
    if [[ $info == *"statically linked"* ]]; then
        strip_helper "$src" "$dst" || return 1
    else
        cp "$src" "$dst" || return 1
    fi

    return 0
}
