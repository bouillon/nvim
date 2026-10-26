#!/bin/bash
# Neovim bootstrap for a fresh Linux box: deploy this config into ~/.config/nvim
# and install every LSP server / tool the config uses, so `nvim` just works.
#
# How to install (recommended, one pass, no questions):
#   su -                                           # root password
#   cd /home/vav/configs_apps/nvim && ./init.sh vav
# If everything system-wide is already there, run it as yourself: ./init.sh —
# su then asks the root password only if something is missing.
#
# Languages served (see ~/.config/nvim/init.vim): Python (pyright + ruff),
# TypeScript & JavaScript (ts_ls + eslint_d + prettier), Rust (rust-analyzer),
# YAML (yaml-language-server), Go (gopls), CSS/SCSS (stylelint-lsp).
#
# Install channels: apt for what Debian/Ubuntu ship (node, go, rust, ripgrep,
# build tools, ruff), npm -g (/usr/local) for the Node language servers,
# `go install` into the user's ~/go/bin for gopls, linked as
# /usr/local/bin/gopls. Idempotent — re-run any time; present tools are skipped.
#
# Details — both ways set up the nvim of ONE user (USER):
#   ./init.sh            as that user; the system steps (apt, npm -g, the
#                        /usr/local/bin link) are collected and run by ONE
#                        `su root -c` — the root password is asked once, and
#                        only when something is missing.
#   ./init.sh USER       as root (also `sudo ./init.sh`, USER defaults to
#                        $SUDO_USER): system steps run directly, the user's
#                        steps via `su - USER`, so files belong to USER.
# No sudo: as a user the system steps ask the root password once (su); as
# root give the user name. The final check runs as USER (= what USER's nvim sees).
set -u

have(){ command -v "$1" >/dev/null 2>&1; }
log(){ printf '\n\033[1;36m== %s\033[0m\n' "$*"; }
warn(){ printf '\033[1;33mWARN: %s\033[0m\n' "$*" >&2; }
die(){ printf '\033[1;31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }
usage(){ sed -n '2,/^set -u/p' "$0" | sed '$d; s/^# \{0,1\}//'; }

case "${1:-}" in -h|--help) usage; exit 0 ;; esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ "$(id -u)" -eq 0 ]; then
    IS_ROOT=1
    TARGET="${1:-${SUDO_USER:-}}"
    [ -n "$TARGET" ] && [ "$TARGET" != root ] \
        || die "as root, name the user whose nvim you set up: ./init.sh USER (see -h)"
    id "$TARGET" >/dev/null 2>&1 || die "no such user: $TARGET"
    TARGET_HOME="$(getent passwd "$TARGET" | cut -d: -f6)"
else
    IS_ROOT=0
    TARGET="$(id -un)"
    [ -z "${1:-}" ] || [ "$1" = "$TARGET" ] || die "as $TARGET you can only set up yourself; for $1 run as root: ./init.sh $1"
    TARGET_HOME="$HOME"
fi

# Run a command string as USER (login env when we are root).
as_user(){ if [ "$IS_ROOT" -eq 1 ]; then su - "$TARGET" -c "$1"; else bash -c "$1"; fi; }
user_which(){ as_user "command -v $1" 2>/dev/null; }
user_have(){ user_which "$1" >/dev/null; }

# System steps are collected in ROOT_CMDS and run in one go (step 5).
ROOT_CMDS=()
as_root(){ ROOT_CMDS+=("$(printf '%q ' "$@")"); }

echo "=== Neovim config + language servers setup for $TARGET ($TARGET_HOME) ==="
if [ "$IS_ROOT" -eq 1 ]; then echo "Running as root for user $TARGET: system steps directly, user steps via su - $TARGET"
else echo "Running as $TARGET; system steps via su (root password) if needed"; fi

# --- 1. Deploy the config (git worktree tracks ~/.config/nvim) ---------------
log "Deploying config"
as_user "
git -C '$SCRIPT_DIR' config core.worktree '../../../' 2>/dev/null || true
if [ -d '$SCRIPT_DIR/.config/nvim' ]; then
    echo 'Moving .config/nvim to ~/.config/nvim...'
    mkdir -p ~/.config/nvim
    mv '$SCRIPT_DIR/.config/nvim/'* ~/.config/nvim/
    rmdir '$SCRIPT_DIR/.config/nvim' '$SCRIPT_DIR/.config' 2>/dev/null || true
fi
if [ -d '$SCRIPT_DIR/.local' ]; then
    echo 'Moving .local to ~/.local...'
    mkdir -p ~/.local
    mv '$SCRIPT_DIR/.local/'* ~/.local/
    rmdir '$SCRIPT_DIR/.local' 2>/dev/null || true
fi"

# --- 2. System packages via apt (only what is missing) -----------------------
# nodejs/npm (Node LSPs), golang-go (gopls), rustc/cargo/rust-analyzer (Rust),
# ripgrep (Telescope live-grep), build-essential (telescope-fzf-native `make`),
# ruff (Python), neovim itself, curl/git.
need=()
if have apt-get; then
    log "apt packages"
    declare -A APT_FOR=(
        [neovim]=nvim [git]=git [curl]=curl [build-essential]=make
        [ripgrep]=rg [nodejs]=node [npm]=npm [golang-go]=go
        [rust-analyzer]=rust-analyzer [cargo]=cargo [ruff]=ruff
    )
    for pkg in "${!APT_FOR[@]}"; do user_have "${APT_FOR[$pkg]}" || need+=("$pkg"); done
    # rust-analyzer needs the std source (rust-src); it's a Recommends, which
    # --no-install-recommends skips, so request it explicitly.
    [ -d /usr/lib/rustlib/src/rust/library ] || need+=(rust-src)
    if [ "${#need[@]}" -gt 0 ]; then
        echo "missing: ${need[*]}"
        as_root apt-get update -qq
        as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${need[@]}"
    else
        echo "all apt tools already present"
    fi
else
    warn "no apt-get — install node, go, rust, ripgrep, ruff, neovim by hand"
fi
apt_brings(){ [[ " ${need[*]-} " == *" $1 "* ]]; }

# --- 3. Node language servers via npm -g (not packaged in apt) ----------------
# npm may itself come from the apt step above (same root run, after it)
if have npm || apt_brings npm; then
    log "npm -g language servers"
    # bin-name -> npm package(s)
    declare -A NPM_FOR=(
        [pyright-langserver]="pyright"
        [yaml-language-server]="yaml-language-server"
        [stylelint-lsp]="stylelint stylelint-lsp"
        [eslint_d]="eslint_d"
        [prettier]="prettier"
    )
    for bin in "${!NPM_FOR[@]}"; do
        if user_have "$bin"; then echo "ok: $bin"; else
            echo "missing: ${NPM_FOR[$bin]}"
            as_root npm install -g ${NPM_FOR[$bin]}
        fi
    done
    # TypeScript + JS: typescript-language-server wraps the CLASSIC tsserver, which
    # lives only in typescript 5.x — `typescript` latest is the 7.x native port and
    # ships no lib/tsserver.js, so pin @5. Verify the file, not just the bin.
    TSLIB="$(npm root -g 2>/dev/null)/typescript/lib/tsserver.js"
    if user_have typescript-language-server && [ -f "$TSLIB" ]; then echo "ok: typescript-language-server"; else
        echo "missing: typescript@5 typescript-language-server"
        as_root npm install -g 'typescript@5' typescript-language-server
    fi
else
    warn "no npm — Python(pyright)/TS/JS/YAML/CSS servers will be missing"
fi

# --- 4. Go: gopls (go install as USER; apt's version lags) -------------------
# "ok" = gopls runnable from USER's PATH — the same test as the self-check and
# nvim (cmd = { 'gopls', ... }). A stale link to another user's private home
# (e.g. /root/go/bin) is not runnable, so the link is replaced (system step).
NEED_GOPLS=0
GOBIN_DIR="$TARGET_HOME/go/bin"
if user_have gopls; then
    log "Go: gopls"; echo "ok: gopls"
elif user_have go || apt_brings golang-go; then
    log "Go: gopls"
    NEED_GOPLS=1
    echo "missing: link /usr/local/bin/gopls -> $GOBIN_DIR/gopls"
    as_root ln -sfn "$GOBIN_DIR/gopls" /usr/local/bin/gopls
else
    warn "no go — gopls will be missing"
fi

# --- 5. System steps: as root directly, as a user one su (one password) ------
if [ "${#ROOT_CMDS[@]}" -gt 0 ]; then
    ROOT_SCRIPT="set -e"
    for c in "${ROOT_CMDS[@]}"; do ROOT_SCRIPT="$ROOT_SCRIPT; $c"; done
    if [ "$IS_ROOT" -eq 1 ]; then
        log "System steps"
        printf '  %s\n' "${ROOT_CMDS[@]}"
        bash -c "$ROOT_SCRIPT" || die "system steps failed: $ROOT_SCRIPT"
    else
        log "System steps (su asks for the root password once)"
        printf '  %s\n' "${ROOT_CMDS[@]}"
        have su || die "su not found. In a root shell run: $ROOT_SCRIPT — then re-run ./init.sh"
        su root -c "$ROOT_SCRIPT" \
            || die "system steps failed. In a root shell run: $ROOT_SCRIPT — then re-run ./init.sh"
    fi
fi
if [ "$NEED_GOPLS" -eq 1 ] && ! as_user "[ -x '$GOBIN_DIR/gopls' ]"; then
    echo "installing: gopls (as $TARGET, into $GOBIN_DIR)"
    as_user "GOBIN='$GOBIN_DIR' go install golang.org/x/tools/gopls@latest" || die "go install gopls failed"
fi

# --- 6. Plugins: vim-plug + :PlugInstall (as USER) ---------------------------
log "Neovim plugins"
as_user '
PLUG="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/autoload/plug.vim"
[ -f "$PLUG" ] || curl -fsSL --create-dirs -o "$PLUG" \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim || echo "WARN: vim-plug download failed" >&2
if command -v nvim >/dev/null 2>&1; then
    nvim --headless "+PlugInstall --sync" +qa 2>/dev/null || echo "WARN: PlugInstall reported issues" >&2
fi'

# --- 7. Self-check as USER: every server the config enables -------------------
log "Check as $TARGET (one binary per language server)"
fail=0
check(){ local p; if p="$(user_which "$1")"; then printf '  \033[1;32mOK\033[0m   %-14s %s\n' "$2" "$p";
         else printf '  \033[1;31mMISS\033[0m %-14s (%s)\n' "$2" "$1"; fail=1; fi; }
check pyright-langserver           "python/pyright"
check ruff                         "python/ruff"
check typescript-language-server   "ts+js/ts_ls"
if [ -f "$(npm root -g 2>/dev/null)/typescript/lib/tsserver.js" ]; then
    printf '  \033[1;32mOK\033[0m   %-14s %s\n' "ts/tsserver" "typescript 5.x (classic tsserver)"
else printf '  \033[1;31mMISS\033[0m %-14s (need typescript@5, not the 7.x native port)\n' "ts/tsserver"; fail=1; fi
check eslint_d                     "js/eslint_d"
check rust-analyzer                "rust"
if [ -d /usr/lib/rustlib/src/rust/library ]; then
    printf '  \033[1;32mOK\033[0m   %-14s %s\n' "rust/std-src" "/usr/lib/rustlib/src/rust/library"
else printf '  \033[1;31mMISS\033[0m %-14s (rust-analyzer needs rust-src for std)\n' "rust/std-src"; fail=1; fi
check yaml-language-server         "yaml"
check gopls                        "go"
check stylelint-lsp                "css"
check rg                           "telescope grep"
echo
if [ "$fail" -eq 0 ]; then
    echo -e "\033[1;32mAll language servers present for $TARGET. Open nvim — LSP works.\033[0m"
else
    echo -e "\033[1;33mSome servers missing (see MISS above). Re-run after fixing, or install by hand.\033[0m"
fi
exit "$fail"
