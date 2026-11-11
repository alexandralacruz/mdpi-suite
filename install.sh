#!/usr/bin/env bash
# =============================================================================
# MDPI Review Suite — Multi-agent installer (Linux / macOS)
# =============================================================================
#
# Compatible with: pi-coding-agent · Claude Code · OpenAI Codex CLI
#
# Local usage (cloned repo):
#   ./install.sh                  # Interactive mode (menu)
#   ./install.sh --all            # Install all skills (pi)
#   ./install.sh <skill-name>     # Install a specific skill
#   ./install.sh --uninstall <skill-name>  # Uninstall a skill
#   ./install.sh --uninstall --all         # Uninstall all
#   ./install.sh --list           # List available skills
#   ./install.sh --status         # Show installation status
#   ./install.sh --help           # Show help
#
# Multi-agent:
#   ./install.sh --all --agent claude
#   ./install.sh --all --agent codex
#   ./install.sh --all --agent all
#
# Remote usage (one-liner from any machine). No git required — if git is not
# available, the repo is downloaded as a ZIP automatically:
#   curl -sSL https://raw.githubusercontent.com/alexandralacruz/mdpi-suite/main/install.sh | bash
#   curl -sSL https://raw... | bash -s -- --all --agent codex
#   curl -sSL https://raw... | bash -s -- --all --agent all
# =============================================================================

set -euo pipefail

# ─── Remote bootstrap: if no local SKILL.md, download the repo ──────────────

_is_local_repo() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-}")" 2>/dev/null && pwd)" || return 1
    local skill_count
    skill_count=$(find "$script_dir" -maxdepth 2 -name SKILL.md -type f 2>/dev/null | wc -l)
    [ "$skill_count" -gt 0 ]
}

if ! _is_local_repo; then
    # Remote execution (curl | bash): download the repo automatically.
    # No git required — if unavailable, downloads the ZIP from GitHub.
    REPO_URL="${REPO_URL:-https://github.com/alexandralacruz/mdpi-suite.git}"
    ZIP_URL="${ZIP_URL:-https://codeload.github.com/alexandralacruz/mdpi-suite/zip/refs/heads/main}"
    TMP_DIR="$(mktemp -d /tmp/mdpi-suite.XXXXXX)"
    trap 'rm -rf "$TMP_DIR"' EXIT

    SUITE_DIR=""

    # ── Option 1: git clone (if git is available) ──────────────────────────
    if command -v git &>/dev/null; then
        echo "→ Downloading MDPI Review Suite (git)..."
        if git clone --depth 1 "$REPO_URL" "$TMP_DIR/repo" >/dev/null 2>&1 \
            && [ -f "$TMP_DIR/repo/install.sh" ]; then
            SUITE_DIR="$TMP_DIR/repo"
        else
            echo "⚠ git clone failed. Trying direct ZIP download..." >&2
            rm -rf "$TMP_DIR/repo"
        fi
    else
        echo "→ git not detected. Using direct ZIP download (no git)..."
    fi

    # ── Option 2: ZIP download from GitHub (no git required) ───────────────
    if [ -z "$SUITE_DIR" ]; then
        ZIP_FILE="$TMP_DIR/suite.zip"
        SRC_DIR="$TMP_DIR/src"
        mkdir -p "$SRC_DIR"

        echo "→ Downloading MDPI Review Suite (ZIP)..."
        if command -v curl &>/dev/null; then
            curl -sSL -o "$ZIP_FILE" "$ZIP_URL"
        elif command -v wget &>/dev/null; then
            wget -q -O "$ZIP_FILE" "$ZIP_URL"
        elif command -v python3 &>/dev/null; then
            python3 -c "import urllib.request; urllib.request.urlretrieve('$ZIP_URL', '$ZIP_FILE')"
        else
            echo "Error: no curl, wget, or python3 available to download the ZIP." >&2
            echo "Download manually:" >&2
            echo "  https://github.com/alexandralacruz/mdpi-suite/archive/refs/heads/main.zip" >&2
            exit 1
        fi

        echo "→ Extracting ZIP..."
        if command -v unzip &>/dev/null; then
            unzip -q "$ZIP_FILE" -d "$SRC_DIR"
        elif command -v python3 &>/dev/null; then
            python3 -m zipfile -e "$ZIP_FILE" "$SRC_DIR"
        elif command -v tar &>/dev/null; then
            tar -xf "$ZIP_FILE" -C "$SRC_DIR" 2>/dev/null || {
                echo "Error: could not extract the ZIP with tar." >&2
                exit 1
            }
        else
            echo "Error: no unzip, python3, or tar found. Extract the ZIP manually:" >&2
            echo "  https://github.com/alexandralacruz/mdpi-suite/archive/refs/heads/main.zip" >&2
            exit 1
        fi

        # The ZIP extracts into a folder named "mdpi-suite-main"
        SUITE_DIR="$SRC_DIR/mdpi-suite-main"
        if [ ! -f "$SUITE_DIR/install.sh" ]; then
            local_found="$(find "$SRC_DIR" -name install.sh -type f -print -quit 2>/dev/null)"
            if [ -n "$local_found" ]; then
                SUITE_DIR="$(dirname "$local_found")"
            fi
        fi
        if [ -z "$SUITE_DIR" ] || [ ! -f "$SUITE_DIR/install.sh" ]; then
            echo "Error: install.sh not found in the downloaded ZIP." >&2
            exit 1
        fi
    fi

    cd "$SUITE_DIR"
    # No exec: compatible with Windows (Git Bash) where execvp may fail
    "$SUITE_DIR/install.sh" "$@"
    exit $?
fi

# ─── Configuration ───────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST_DIR="${PI_SKILLS_DIR:-$HOME/.pi/agent/skills}"

# Paths per agent
AGENT_SKILLS_DIRS=(
    "pi:$HOME/.pi/agent/skills"
    "claude:$HOME/.claude/skills"
    "codex:$HOME/.codex/skills"
)

# ─── Colors ─────────────────────────────────────────────────────────────────

if [ -t 1 ] && command -v tput >/dev/null 2>&1; then
    BOLD=$(tput bold); RED=$(tput setaf 1); GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3); BLUE=$(tput setaf 4); CYAN=$(tput setaf 6)
    RESET=$(tput sgr0)
else
    BOLD=""; RED=""; GREEN=""; YELLOW=""; BLUE=""; CYAN=""; RESET=""
fi

# ─── Available skills (directories containing SKILL.md) ──────────────────────

get_available_skills() {
    local skills=()
    for dir in "$SCRIPT_DIR"/*/; do
        [ -d "$dir" ] || continue
        local name; name=$(basename "$dir")
        [[ "$name" == .* || "$name" == scripts || "$name" == node_modules ]] && continue
        [ -f "$dir/SKILL.md" ] || continue
        skills+=("$name")
    done
    printf '%s\n' "${skills[@]}" | sort
}

get_skill_description() {
    local skill_dir="$SCRIPT_DIR/$1"
    [ -f "$skill_dir/SKILL.md" ] || { echo "(no description)"; return; }
    sed -n '/^---$/,/^---$/p' "$skill_dir/SKILL.md" \
        | grep '^description:' \
        | sed 's/^description:[[:space:]]*//' \
        | head -c 120
    echo
}

# ─── Installation functions ──────────────────────────────────────────────────

install_skill() {
    local skill_name="$1"
    local src="$SCRIPT_DIR/$skill_name"
    local dst="$DEST_DIR/$skill_name"

    if [ ! -d "$src" ] || [ ! -f "$src/SKILL.md" ]; then
        echo "  ${RED}✖${RESET} ${BOLD}$skill_name${RESET} — not a valid skill (missing SKILL.md)"
        return 1
    fi

    if [ -d "$dst" ]; then
        echo "  ${YELLOW}⚠${RESET}  ${BOLD}$skill_name${RESET} already installed at ${CYAN}$dst${RESET}"
        return 0
    fi

    mkdir -p "$DEST_DIR"
    cp -r "$src" "$dst"
    echo "  ${GREEN}✔${RESET} ${BOLD}$skill_name${RESET} installed → ${CYAN}$dst${RESET}"
    return 0
}

uninstall_skill() {
    local skill_name="$1"
    local dst="$DEST_DIR/$skill_name"

    if [ ! -d "$dst" ]; then
        echo "  ${YELLOW}○${RESET} ${BOLD}$skill_name${RESET} — not installed"
        return 1
    fi

    rm -rf "$dst"
    echo "  ${GREEN}✔${RESET} ${BOLD}$skill_name${RESET} uninstalled"
    return 0
}

is_installed() {
    [ -d "$DEST_DIR/$1" ] && [ -f "$DEST_DIR/$1/SKILL.md" ]
}

# ─── Commands ────────────────────────────────────────────────────────────────

cmd_list() {
    echo
    echo "${BOLD}${BLUE}MDPI Review Suite${RESET} — Available skills"
    echo "${BLUE}────────────────────────────────────────${RESET}"
    echo
    printf "  ${BOLD}%-28s %s${RESET}\n" "SKILL" "DESCRIPTION"
    printf "  %-28s %s\n" "─────" "──────────"
    while IFS= read -r skill; do
        local desc; desc=$(get_skill_description "$skill")
        local status=""
        is_installed "$skill" && status=" ${GREEN}[installed]${RESET}"
        printf "  ${CYAN}%-28s${RESET} %s%s\n" "$skill" "${desc:0:85}" "$status"
    done < <(get_available_skills)
    echo
    echo "  ${BOLD}Total:${RESET} $(get_available_skills | wc -l) skills"
    echo
    echo "  Destination: ${CYAN}$DEST_DIR${RESET}"
    echo
    echo "  ${BOLD}Commands:${RESET}"
    echo "    ./install.sh --all          Install all"
    echo "    ./install.sh <name>         Install one"
    echo "    ./install.sh                Interactive mode"
    echo
}

cmd_status() {
    echo
    echo "${BOLD}${BLUE}Installation status${RESET}"
    echo "${BLUE}───────────────────${RESET}"
    echo
    local installed=0 total=0
    while IFS= read -r skill; do
        total=$((total + 1))
        if is_installed "$skill"; then
            installed=$((installed + 1))
            echo "  ${GREEN}✔${RESET} ${BOLD}$skill${RESET}"
        else
            echo "  ${RED}✖${RESET} ${BOLD}$skill${RESET}"
        fi
    done < <(get_available_skills)
    echo
    echo "  ${BOLD}$installed/$total${RESET} skills installed"
    echo "  Destination: ${CYAN}$DEST_DIR${RESET}"
    echo
}

cmd_install_all() {
    local agent="${1:-}"

    if [ -n "$agent" ] && [ "$agent" != "all" ]; then
        local agent_dir; agent_dir=$(get_agent_dir "$agent")
        if [ -z "$agent_dir" ]; then
            echo "${RED}Error:${RESET} Agent '${BOLD}$agent${RESET}' not recognized."
            echo "Valid agents: pi, claude, codex, all"
            exit 1
        fi
        DEST_DIR="$agent_dir"
    fi

    if [ "$agent" = "all" ]; then
        cmd_install_all_agents
        return
    fi

    echo
    echo "${BOLD}${BLUE}Installing MDPI Review Suite (all skills)${RESET}"
    echo "${BLUE}─────────────────────────────────────────${RESET}"
    echo
    echo "  Destination: ${CYAN}$DEST_DIR${RESET}"
    [ -n "$agent" ] && echo "  Agent:       ${CYAN}$agent${RESET}"
    echo

    local count=0 errors=0
    while IFS= read -r skill; do
        if install_skill "$skill"; then
            count=$((count + 1))
        else
            errors=$((errors + 1))
        fi
    done < <(get_available_skills)

    echo
    echo "  ${BOLD}Result:${RESET} ${GREEN}$count installed${RESET}$([ $errors -gt 0 ] && echo ", ${RED}$errors errors${RESET}")"
    echo
    case "${agent:-pi}" in
        pi)     echo "  ${BOLD}Note:${RESET} Restart pi or use ${CYAN}/skill:<name>${RESET} to load the skills." ;;
        claude) echo "  ${BOLD}Note:${RESET} In Claude Code use ${CYAN}/skill:<name>${RESET} to invoke." ;;
        codex)  echo "  ${BOLD}Note:${RESET} In Codex use ${CYAN}/skill:<name>${RESET} to invoke." ;;
    esac
    echo
}

cmd_install_all_agents() {
    echo
    echo "${BOLD}${BLUE}Installing into all detected agents${RESET}"
    echo "${BLUE}──────────────────────────────────${RESET}"
    echo

    local detected
    mapfile -t detected < <(detect_agents)

    if [ ${#detected[@]} -eq 0 ]; then
        echo "  ${YELLOW}No agents detected. Installing into pi by default.${RESET}"
        DEST_DIR="$HOME/.pi/agent/skills" cmd_install_all "pi"
        return
    fi

    for agent in "${detected[@]}"; do
        echo "  ${BOLD}→ Installing for ${CYAN}$agent${RESET} ..."
        local agent_dir; agent_dir=$(get_agent_dir "$agent")
        DEST_DIR="$agent_dir" cmd_install_all "$agent"
        echo
    done

    echo "  ${GREEN}✔${RESET} Multi-agent installation complete."
    echo
}

cmd_uninstall_all() {
    echo
    echo "${BOLD}${RED}Uninstalling all MDPI Review Suite skills${RESET}"
    echo "${RED}───────────────────────────────────────────${RESET}"
    echo
    echo "  Destination: ${CYAN}$DEST_DIR${RESET}"
    echo

    local count=0 errors=0
    while IFS= read -r skill; do
        if uninstall_skill "$skill"; then
            count=$((count + 1))
        else
            errors=$((errors + 1))
        fi
    done < <(get_available_skills)

    echo
    echo "  ${BOLD}Result:${RESET} ${GREEN}$count uninstalled${RESET}$([ $errors -gt 0 ] && echo ", ${RED}$errors not found${RESET}")"
    echo
}

cmd_install_one() {
    local skill="$1"

    local match; match=$(get_available_skills | grep -i "^$skill" || true)
    if [ -z "$match" ]; then
        match=$(get_available_skills | grep -i "$skill" || true)
    fi

    local matches; matches=$(echo "$match" | wc -l)
    if [ "$matches" -eq 0 ]; then
        echo "${RED}Error:${RESET} Skill '${BOLD}$skill${RESET}' not found."
        echo "Use ${CYAN}./install.sh --list${RESET} to see available skills."
        exit 1
    elif [ "$matches" -gt 1 ]; then
        echo "${YELLOW}Multiple skills match '${BOLD}$skill${RESET}':${RESET}"
        echo "$match" | while read -r m; do echo "  - $m"; done
        echo "Be more specific."
        exit 1
    fi

    skill="$match"
    echo
    echo "${BOLD}${BLUE}Installing skill:${RESET} ${CYAN}$skill${RESET}"
    echo

    if install_skill "$skill"; then
        echo
        echo "  ${GREEN}✔${RESET} Done. Use ${CYAN}/skill:$skill${RESET} in pi."
    fi
    echo
}

cmd_uninstall_one() {
    local skill="$1"
    local match; match=$(get_available_skills | grep -i "^$skill" || true)
    if [ -z "$match" ]; then
        match=$(get_available_skills | grep -i "$skill" || true)
    fi
    local matches; matches=$(echo "$match" | wc -l)
    if [ "$matches" -eq 0 ]; then
        echo "${RED}Error:${RESET} Skill '${BOLD}$skill${RESET}' not found."
        exit 1
    elif [ "$matches" -gt 1 ]; then
        echo "${YELLOW}Multiple skills match:${RESET}"
        echo "$match"
        exit 1
    fi
    skill="$match"
    echo
    echo "${BOLD}${RED}Uninstalling skill:${RESET} ${CYAN}$skill${RESET}"
    echo
    uninstall_skill "$skill"
    echo
}

# ─── Agent detection ────────────────────────────────────────────────────────

detect_agents() {
    local detected=()
    for entry in "${AGENT_SKILLS_DIRS[@]}"; do
        local agent="${entry%%:*}"
        local dir="${entry#*:}"
        case "$agent" in
            pi)     command -v pi &>/dev/null || [ -d "$HOME/.pi" ] && detected+=("pi") ;;
            claude) command -v claude &>/dev/null || [ -d "$HOME/.claude" ] && detected+=("claude") ;;
            codex)  command -v codex &>/dev/null || [ -d "$HOME/.codex" ] && detected+=("codex") ;;
        esac
    done
    printf '%s\n' "${detected[@]}"
}

get_agent_dir() {
    local agent="$1"
    # pi uses DEST_DIR to respect the PI_SKILLS_DIR variable
    if [ "$agent" = "pi" ]; then
        echo "$DEST_DIR"
        return 0
    fi
    for entry in "${AGENT_SKILLS_DIRS[@]}"; do
        [[ "${entry%%:*}" == "$agent" ]] && echo "${entry#*:}" && return 0
    done
    echo ""
    return 1
}

# ─── Interactive mode ────────────────────────────────────────────────────────

interactive_menu() {
    local detected
    mapfile -t detected < <(detect_agents)

    echo
    echo "${BOLD}${BLUE}╔══════════════════════════════════════════════╗${RESET}"
    echo "${BOLD}${BLUE}║        MDPI Review Suite Installer           ║${RESET}"
    echo "${BOLD}${BLUE}║     pi · Claude Code · Codex compatible      ║${RESET}"
    echo "${BOLD}${BLUE}╚══════════════════════════════════════════════╝${RESET}"
    echo
    echo "  Destination: ${CYAN}$DEST_DIR${RESET}"
    if [ ${#detected[@]} -gt 0 ]; then
        echo "  Detected agents: ${GREEN}${detected[*]}${RESET}"
    fi
    echo

    local skills=()
    while IFS= read -r s; do skills+=("$s"); done < <(get_available_skills)

    echo "  ${BOLD}Available skills:${RESET}"
    echo
    for i in "${!skills[@]}"; do
        local num=$((i + 1))
        local status=""
        is_installed "${skills[$i]}" && status=" ${GREEN}[installed]${RESET}" || status=" ${YELLOW}[not installed]${RESET}"
        printf "  ${CYAN}%2d)${RESET} %-28s %s\n" "$num" "${skills[$i]}" "$status"
    done

    echo
    echo "  ${BOLD}Options:${RESET}"
    echo "  ${CYAN} a${RESET}) Install ${BOLD}all${RESET}"
    echo "  ${CYAN} 1-$(echo "${#skills[@]}")${RESET}) Install an individual skill"
    echo "  ${CYAN} s${RESET}) Show status"
    echo "  ${CYAN} q${RESET}) Quit"
    echo

    read -r -p "  ${BOLD}Choose an option:${RESET} " choice
    echo

    case "$choice" in
        [aA])
            cmd_install_all
            ;;
        [sS])
            cmd_status
            interactive_menu
            ;;
        [qQ])
            echo "  Goodbye!"
            echo
            exit 0
            ;;
        *)
            if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] 2>/dev/null \
                && [ "$choice" -le "${#skills[@]}" ]; then
                local skill="${skills[$((choice - 1))]}"
                if is_installed "$skill"; then
                    echo "  ${YELLOW}$skill${RESET} is already installed."
                    read -r -p "  ${BOLD}Reinstall? (y/N):${RESET} " reinstall
                    if [[ "$reinstall" =~ ^[yY] ]]; then
                        rm -rf "$DEST_DIR/$skill"
                        install_skill "$skill"
                    fi
                else
                    install_skill "$skill"
                fi
                echo
                read -r -p "  ${BOLD}Press Enter to continue...${RESET}"
                interactive_menu
            else
                echo "  ${RED}Invalid option.${RESET}"
                echo
                interactive_menu
            fi
            ;;
    esac
}

# ─── Help ─────────────────────────────────────────────────────────────────────

cmd_help() {
    echo
    echo "${BOLD}MDPI Review Suite — Installer (multi-agent)${RESET}"
    echo
    echo "  ${BOLD}USAGE:${RESET}"
    echo "    ./install.sh                          Interactive mode (menu)"
    echo "    ./install.sh --all                    Install all skills (pi)"
    echo "    ./install.sh --all --agent claude     Install all for Claude Code"
    echo "    ./install.sh --all --agent codex      Install all for Codex CLI"
    echo "    ./install.sh --all --agent all        Install into all agents"
    echo "    ./install.sh <skill-name>             Install one skill"
    echo "    ./install.sh --uninstall <name>       Uninstall a skill"
    echo "    ./install.sh --uninstall --all        Uninstall all"
    echo "    ./install.sh --list                   List available skills"
    echo "    ./install.sh --status                 Show installation status"
    echo "    ./install.sh --help                   This help"
    echo
    echo "  ${BOLD}SUPPORTED AGENTS:${RESET}"
    echo "    pi       → ~/.pi/agent/skills/       (pi-coding-agent)"
    echo "    claude   → ~/.claude/skills/         (Claude Code / Anthropic)"
    echo "    codex    → ~/.codex/skills/          (OpenAI Codex CLI)"
    echo "    all      → Install into all detected agents"
    echo
    echo "  ${BOLD}ENVIRONMENT VARIABLES:${RESET}"
    echo "    PI_SKILLS_DIR      Destination directory (default: ~/.pi/agent/skills/)"
    echo
    echo "  ${BOLD}EXAMPLES:${RESET}"
    echo "    ./install.sh --all"
    echo "    ./install.sh --all --agent claude"
    echo "    ./install.sh --all --agent all"
    echo "    ./install.sh reviewer-mdpi-journal"
    echo "    ./install.sh --uninstall reviewer-mdpi-perspective"
    echo "    PI_SKILLS_DIR=.pi/skills ./install.sh --all"
    echo
}

# ─── Entrypoint ───────────────────────────────────────────────────────────────

main() {
    local agent=""
    local args=()
    while [ $# -gt 0 ]; do
        case "$1" in
            --agent)
                agent="$2"
                shift 2
                ;;
            --agent=*)
                agent="${1#*=}"
                shift
                ;;
            *)
                args+=("$1")
                shift
                ;;
        esac
    done
    set -- "${args[@]}"

    if [ $# -eq 0 ]; then
        interactive_menu
        exit 0
    fi

    case "${1:-}" in
        --help|-h|help)
            cmd_help
            ;;
        --list|-l|list)
            cmd_list
            ;;
        --status|-s|status)
            cmd_status
            ;;
        --all|-a)
            cmd_install_all "$agent"
            ;;
        --uninstall|-u)
            shift
            if [ $# -eq 0 ]; then
                echo "${RED}Error:${RESET} Specify a skill or --all to uninstall."
                echo "  ./install.sh --uninstall <skill-name>"
                echo "  ./install.sh --uninstall --all"
                exit 1
            fi
            if [ "${1:-}" = "--all" ] || [ "${1:-}" = "-a" ]; then
                cmd_uninstall_all
            else
                cmd_uninstall_one "$1"
            fi
            ;;
        *)
            cmd_install_one "$1"
            ;;
    esac
}

main "$@"
