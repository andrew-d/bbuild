pkgname="xxd"
pkgdesc="TODO"
pkgver="1.10"

sources=(
    "xxd.c"
)
sums=(
    "ab00e6b3f0e1a9bfb3b35d069742899cf245a35f85960cd39938ce690e706526"
)

library=false
binary=true

dependencies=()


function build() {
    cd "$BBUILD_SOURCE_DIR"

    ${CC} \
        ${BBUILD_STATIC_FLAGS} \
        -O3 \
        -DUNIX \
        -o xxd \
        xxd.c \
        || return 1
}


function package() {
cd "$BBUILD_SOURCE_DIR"

    cp xxd "$BBUILD_OUT_DIR"/xxd
    ${STRIP} "$BBUILD_OUT_DIR"/xxd
}
