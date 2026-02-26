#!/usr/bin/env bash
# install.sh — Install git hooks from obtuse-hubris
# Part of obtuse-hubris — preventing AI agents from destroying your repos.
#
# Usage:
#   ./hooks/install.sh              Install hooks to current repo's .git/hooks/
#   ./hooks/install.sh --global     Install as global git hooks (all repos)
#   ./hooks/install.sh --uninstall  Remove hooks from current repo
#   ./hooks/install.sh --global --uninstall  Remove global hooks

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# Resolve the directory where this script lives (i.e., the hooks source dir)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

HOOKS=("pre-push" "pre-commit" "post-checkout")
GLOBAL=0
UNINSTALL=0

# --- Parse arguments ---

for arg in "$@"; do
    case "$arg" in
        --global|-g)
            GLOBAL=1
            ;;
        --uninstall|--remove)
            UNINSTALL=1
            ;;
        --help|-h)
            echo "Usage: $0 [--global] [--uninstall]"
            echo ""
            echo "  --global      Install/uninstall as global git hooks (affects all repos)"
            echo "  --uninstall   Remove previously installed hooks"
            echo "  --help        Show this help"
            exit 0
            ;;
        *)
            echo "Unknown argument: $arg"
            echo "Run '$0 --help' for usage."
            exit 1
            ;;
    esac
done

# --- Determine target directory ---

if [[ "$GLOBAL" -eq 1 ]]; then
    # Global hooks directory
    GLOBAL_HOOKS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/git/hooks"
    TARGET_DIR="$GLOBAL_HOOKS_DIR"
else
    # Local repo hooks
    GIT_DIR="$(git rev-parse --git-dir 2>/dev/null || true)"
    if [[ -z "$GIT_DIR" ]]; then
        echo -e "${RED}Error: Not inside a git repository.${RESET}"
        echo "  Run this from inside a git repo, or use --global to install globally."
        exit 1
    fi
    TARGET_DIR="${GIT_DIR}/hooks"
fi

# --- Uninstall ---

if [[ "$UNINSTALL" -eq 1 ]]; then
    echo -e "${BOLD}Uninstalling hooks from: ${TARGET_DIR}${RESET}"
    echo ""

    removed=0
    for hook in "${HOOKS[@]}"; do
        target="${TARGET_DIR}/${hook}"
        if [[ -f "$target" ]]; then
            # Only remove if it's one of ours (check for the signature comment)
            if grep -q "obtuse-hubris" "$target" 2>/dev/null; then
                rm "$target"
                echo -e "  ${RED}Removed${RESET}: ${hook}"
                removed=$((removed + 1))
            else
                echo -e "  ${YELLOW}Skipped${RESET}: ${hook} (not ours — does not contain obtuse-hubris signature)"
            fi
        else
            echo -e "  ${DIM}Not found${RESET}: ${hook}"
        fi
    done

    if [[ "$GLOBAL" -eq 1 ]]; then
        current_hooks_path=$(git config --global core.hooksPath 2>/dev/null || echo "")
        if [[ "$current_hooks_path" == "$TARGET_DIR" ]]; then
            git config --global --unset core.hooksPath
            echo ""
            echo -e "  ${RED}Removed${RESET}: core.hooksPath global config"
        fi
    fi

    echo ""
    echo -e "${GREEN}Uninstalled ${removed} hook(s).${RESET}"
    exit 0
fi

# --- Install ---

echo ""
echo -e "${BOLD}Installing git hooks from obtuse-hubris${RESET}"
echo -e "${DIM}Source: ${SCRIPT_DIR}${RESET}"
echo -e "${DIM}Target: ${TARGET_DIR}${RESET}"
echo ""

# Create target directory if needed
mkdir -p "$TARGET_DIR"

installed=0
skipped=0

for hook in "${HOOKS[@]}"; do
    source="${SCRIPT_DIR}/${hook}"
    target="${TARGET_DIR}/${hook}"

    if [[ ! -f "$source" ]]; then
        echo -e "  ${RED}Missing source${RESET}: ${source}"
        continue
    fi

    # Check for existing hooks that aren't ours
    if [[ -f "$target" ]]; then
        if ! grep -q "obtuse-hubris" "$target" 2>/dev/null; then
            echo -e "  ${YELLOW}CONFLICT${RESET}: ${hook}"
            echo "    An existing hook is already installed that is not from this project."
            echo "    Existing hook: ${target}"
            echo ""
            echo "    Options:"
            echo "      1. Back up and replace: mv '${target}' '${target}.bak'"
            echo "      2. Merge manually: combine both hooks into one script"
            echo "      3. Chain hooks: rename existing to ${hook}.local and call it from ours"
            echo ""
            skipped=$((skipped + 1))
            continue
        fi
    fi

    cp "$source" "$target"
    chmod +x "$target"
    installed=$((installed + 1))

    case "$hook" in
        pre-push)
            echo -e "  ${GREEN}Installed${RESET}: ${BOLD}pre-push${RESET}"
            echo "    Blocks force-push attempts (--force, -f, --force-with-lease)"
            echo "    Detects non-fast-forward pushes and remote branch deletions"
            echo "    Override: I_KNOW_WHAT_FORCE_PUSH_DOES=1 git push --force"
            echo ""
            ;;
        pre-commit)
            echo -e "  ${GREEN}Installed${RESET}: ${BOLD}pre-commit${RESET}"
            echo "    Detects git-filter-repo artifacts (.git/filter-repo/)"
            echo "    Warns if history-rewriting tools are installed"
            echo "    Checks for filter-branch refs/original/ directory"
            echo "    Flags suspicious git identity override variables"
            echo ""
            ;;
        post-checkout)
            echo -e "  ${GREEN}Installed${RESET}: ${BOLD}post-checkout${RESET}"
            echo "    Detects filter-repo and filter-branch artifacts"
            echo "    Warns about missing or orphaned remote tracking"
            echo "    Checks for significant local/remote divergence"
            echo "    Monitors reflog for excessive 'git reset' operations"
            echo ""
            ;;
    esac
done

# Set global hooks path if --global
if [[ "$GLOBAL" -eq 1 && "$installed" -gt 0 ]]; then
    git config --global core.hooksPath "$TARGET_DIR"
    echo -e "${GREEN}Set core.hooksPath=${TARGET_DIR}${RESET}"
    echo ""
    echo -e "${YELLOW}Note: Global hooks override per-repo hooks.${RESET}"
    echo "  Per-repo .git/hooks/ will be ignored while core.hooksPath is set."
    echo "  To restore per-repo hooks: git config --global --unset core.hooksPath"
fi

# --- Summary ---

echo ""
if [[ "$installed" -gt 0 ]]; then
    echo -e "${GREEN}${BOLD}Installed ${installed} hook(s).${RESET}"
fi
if [[ "$skipped" -gt 0 ]]; then
    echo -e "${YELLOW}Skipped ${skipped} hook(s) due to conflicts (see above).${RESET}"
fi

if [[ "$installed" -eq 0 && "$skipped" -eq 0 ]]; then
    echo -e "${YELLOW}No hooks were installed.${RESET}"
fi

echo ""
echo -e "${DIM}These hooks protect against the destructive actions documented in${RESET}"
echo -e "${DIM}the obtuse-hubris: https://github.com/CIRWEL/obtuse-hubris${RESET}"
echo ""
