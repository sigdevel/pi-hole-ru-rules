#!/bin/sh
set -eu

PIHOLE_BIN="${PIHOLE_BIN:-pihole}"
MODE="enable"

if [ "$(id -u)" -eq 0 ]; then
    SUDO_CMD=""
else
    SUDO_CMD="${SUDO_CMD:-sudo}"
fi

run_pihole() {
    if [ -n "$SUDO_CMD" ]; then
        "$SUDO_CMD" "$PIHOLE_BIN" "$@"
    else
        "$PIHOLE_BIN" "$@"
    fi
}

usage() {
    cat <<'EOF'
Usage: ./pihole-regex-east.sh [OPTION]

Options:
  -e, --enable   Add the regex rules (default)
  -d, --disable  Remove the regex rules
  -h, --help     Show this help
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        -e|--enable)
            MODE="enable"
            ;;
        -d|--disable)
            MODE="disable"
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            printf 'Unknown option: %s\n\n' "$1" >&2
            usage >&2
            exit 1
            ;;
    esac
    shift
done

regex_exists() {
    run_pihole --regex --list 2>/dev/null | grep -F -- "$1" >/dev/null 2>&1
}

add_regex() {
    comment="$1"
    regex="$2"

    if regex_exists "$regex"; then
        printf 'Already exists: %s\n' "$regex"
        return 0
    fi

    printf 'Adding: %s\n' "$regex"
    run_pihole --regex --comment "$comment" "$regex"
}

remove_regex() {
    regex="$1"

    if ! regex_exists "$regex"; then
        printf 'Already absent: %s\n' "$regex"
        return 0
    fi

    printf 'Removing: %s\n' "$regex"
    run_pihole --regex delete "$regex"
}

apply_rule() {
    comment="$1"
    regex="$2"

    case "$MODE" in
        enable)
            add_regex "$comment" "$regex"
            ;;
        disable)
            remove_regex "$regex"
            ;;
    esac
}

apply_rule "block oneme.ru family" '(^|\.)oneme\.ru$'
apply_rule "block max.ru family" '(^|\.)max\.ru$'
apply_rule "block vkuser call hosts" '^call[^.]*-[^.]*\.vkuser\.net$'
apply_rule "block okcdn videostun hosts" '^videostun[^.]*\.okcdn\.ru$'

printf 'Reloading Pi-hole DNS...\n'
run_pihole reloaddns
printf 'Done.\n'
