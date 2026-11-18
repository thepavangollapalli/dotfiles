#!/bin/sh
# Copy stdin to the macOS clipboard and briefly report how much was copied.
# Usage: copy-notify.sh CLIENT_NAME
client=$1
tmp=$(mktemp) || exit 1
trap 'rm -f "$tmp"' EXIT
cat >"$tmp"
pbcopy <"$tmp"
chars=$(LC_ALL=en_US.UTF-8 wc -m <"$tmp" | tr -d ' ')
[ "$chars" = 1 ] && unit=char || unit=chars
tmux display-message -c "$client" -d 1500 "Copied $chars $unit to the clipboard"
