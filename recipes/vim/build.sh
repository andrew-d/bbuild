pkgname="vim"
pkgdesc="TODO"
pkgver="7.4.1579"

sources=(
    "vim-${pkgver}.tar.gz::https://github.com/vim/vim/archive/v${pkgver}.tar.gz"
)
sums=(
    "ff346656a0484da0da1603d60c52b46d94e2bb1441799cb936f1725880df3913"
)

library=false
binary=true

dependencies=("ncurses" "liblua" "python")

# Common variables.
_builddir="$BBUILD_SOURCE_DIR/$pkgname-$pkgver"
_destdir="$BBUILD_SOURCE_DIR/dest"


function build() {
    cd "$_builddir"

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
    #export LIBS="${myLIBS[*]}"

    # We can't run programs on cross-compilation. Manually specify values here.
    declare -a config_args=(" ")
    case "${BBUILD_TARGET_PLATFORM}" in
        linux|android)
            config_args+=("vim_cv_getcwd_broken=no")
            config_args+=("vim_cv_memmove_handles_overlap=yes")
            config_args+=("vim_cv_stat_ignores_slash=no")
            config_args+=("vim_cv_terminfo=yes")
            config_args+=("vim_cv_toupper_broken=no")
            config_args+=("vim_cv_tty_group=world")
            ;;
        *)
            error "Cannot currently configure Vim for this platform"
            return 1
            ;;
    esac

    declare -r lua_prefix="$(cat "$BBUILD_DEPCONF_DIR"/liblua/.source-dir)/dest"
    declare -r python_cfg="$(cat "$BBUILD_DEPCONF_DIR"/python/.source-dir)/dest/usr/local/lib/python2.7/config"

    CFLAGS="${CFLAGS:-} ${BBUILD_STATIC_FLAGS}" \
    CPPFLAGS="${CPPFLAGS}" \
    LDFLAGS="${LDFLAGS:-} ${BBUILD_STATIC_FLAGS}" \
    LUA_PREFIX="$lua_prefix" \
    ./configure \
        --with-compiledby='bbuild' \
        --with-x=no \
        --with-tlib=ncurses \
        --with-features=huge \
        --enable-cscope \
        --enable-multibyte \
        --disable-gui \
        --disable-netbeans \
        --disable-rubyinterp \
        --disable-python3interp \
        --enable-pythoninterp \
        --with-python-config-dir="$python_cfg" \
        --enable-luainterp \
        --host=${BBUILD_CROSS_PREFIX} \
        --build=i686 \
        ${config_args[*]} \
        || return 1

    make PYTHON_LIBS="${myLIBS[*]}" || return 1

    mkdir -p "$_destdir" || return 1
    make -C src installruntime DESTDIR="$_destdir" || return 1
}


function package() {
    cd "$_builddir"

    strip_helper \
        "src/vim${BBUILD_BINARY_EXT}" \
        "$BBUILD_OUT_DIR"/ \
        || return 1

    # Copy the runtime
    # Note: the `*` is deliberate - we want to copy the directory in the
    # folder, without knowing its name.
    mkdir -p "$BBUILD_OUT_DIR/runtime" || return 1
    cp -r \
        "$_destdir"/usr/local/share/vim/vim*/* \
        "$BBUILD_OUT_DIR/runtime/" \
        || return 1
}
