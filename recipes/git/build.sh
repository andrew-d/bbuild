pkgname="git"
pkgdesc="TODO"
pkgver="2.6.0-rc1"

sources=(
    "git-${pkgver}.tar.gz::https://github.com/git/git/archive/v${pkgver}.tar.gz"
)
sums=(
    "40cdf38f8ad1f7b8d416c3d57b0ca82dd382f89b06de6cc8e18df1023162f967"
)

library=false
binary=true

dependencies=("zlib")

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

    make || return 1

    mkdir -p "$_destdir" || return 1
    make install DESTDIR="$_destdir" || return 1
}


function package() {
    cd "$_destdir"

    # These are binaries
    for f in git git-receive-pack git-shell git-upload-archive git-upload-pack; do
        strip_helper \
            "usr/bin/${f}${BBUILD_BINARY_EXT}" \
            "$BBUILD_OUT_DIR"/ \
            || return 1
    done

    # These are scripts (perl or shell)
    for f in git-cvsserver gitk; do
        cp "usr/bin/$f" "$BBUILD_OUT_DIR/" || return 1
    done
}
