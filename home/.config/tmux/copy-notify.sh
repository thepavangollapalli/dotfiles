#!/bin/sh
# Copy stdin to the macOS clipboard and briefly show how much was copied at
# the right of the status bar.
tmp=$(mktemp) || exit 1
trap 'rm -f "$tmp"' EXIT
cat >"$tmp"
pbcopy <"$tmp"
chars=$(LC_ALL=en_US.UTF-8 wc -m <"$tmp" | tr -d ' ')
[ "$chars" = 1 ] && unit=char || unit=chars
notice="Copied $chars $unit to the clipboard"
tmux set -g @copy_notice "$notice" \; refresh-client -S
# Clear the notice later unless a newer copy has replaced it.
(sleep 1.5
 [ "$(tmux show -gv @copy_notice)" = "$notice" ] && tmux set -gu @copy_notice \; refresh-client -S
) >/dev/null 2>&1 &
