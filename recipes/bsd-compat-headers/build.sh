pkgname="bsd-compat-headers"
pkgdesc="TODO"
pkgver="0.1"

sources=(
    "sys-cdefs.h"
    "sys-queue.h"
    "sys-tree.h"
)

sums=(
    "30bb6d7e0e0b61fcd95d830c376c829a614bce4683c1b97e06c201ec2c6e839a"
    "3659cd137c320991a78413dd370a92fd18e0a8bc36d017d554f08677a37d7d5a"
    "e1e498a79bf160a5766fa560f2b07b206fe89fe21a62600c77d72e00a6992f92"
)

library=true
binary=false

dependencies=()


function build() {
    cd "$BBUILD_SOURCE_DIR"

    mkdir -p include/sys || return 1
    for f in cdefs queue tree; do
        cp "sys-${f}.h" include/sys/"${f}.h" || return 1
    done

    return 0
}


function setup_env() {
    echo "-I${BBUILD_SOURCE_DIR}/include" > "$depdir"/CPPFLAGS
}
