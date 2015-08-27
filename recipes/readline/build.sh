pkgname="readline"
pkgdesc="TODO"
pkgver="6.3"

sources=(
    "ftp://ftp.gnu.org/gnu/readline/readline-${pkgver}.tar.gz"
)
sums=(
    "56ba6071b9462f980c5a72ab0023893b65ba6debb4eeb475d7a563dc65cafd43"
)

library=true
binary=false

dependencies=()

# Common variables.
_builddir="$BBUILD_SOURCE_DIR/$pkgname-$pkgver"


function prepare() {
    cd "$_builddir"

    info2 "Removing examples in Makefile"
    sed -i 's|examples/Makefile||g' configure.ac

    info2 "Re-running autoconf"
    autoconf
}


function build() {
    cd "$_builddir"

    CFLAGS="${BBUILD_STATIC_FLAGS}" \
    CXXFLAGS="${BBUILD_STATIC_FLAGS}" \
    ./configure \
        --disable-shared \
		--enable-static \
        --host=${BBUILD_CROSS_PREFIX} \
		--build=i686 || return 1

    make || return 1
}

function setup_env() {
    echo "-L${_builddir} -lreadline" > "$depdir"/LDFLAGS

    # Note: some things will attempt to #include <readline/readline.h>, which
    # means that we need to set up a symlink so this works.
    ln -s "$_builddir" "$BBUILD_SOURCE_DIR"/readline
    echo "-I${_builddir} -I${BBUILD_SOURCE_DIR}" > "$depdir"/CPPFLAGS
}
