#!/bin/sh
# Keep scrolling a tmux copy-mode pane while a mouse drag holds the selection
# cursor within two rows of its top or bottom edge, where the mouse can reach.
# tmux itself scrolls there only when the mouse moves.
pane="$1"
[ -n "$pane" ] || exit 1

if [ "$(tmux display -p -t "$pane" '#{?@drag_scrolling,1,0}')" = 1 ]; then
  exit 0
fi
tmux set -p -t "$pane" @drag_scrolling 1
trap 'tmux set -pu -t "$pane" @drag_scrolling 2>/dev/null' EXIT

while :; do
  state="$(tmux display -p -t "$pane" \
    '#{?@drag_scrolling,1,0} #{pane_in_mode} #{copy_cursor_y} #{pane_height}')" || exit 0
  set -- $state
  [ "$1" = 1 ] && [ "$2" = 1 ] && [ -n "$3" ] || exit 0
  if [ "$3" -le 1 ]; then
    tmux send-keys -X -N 2 -t "$pane" cursor-up
  elif [ "$3" -ge $(($4 - 2)) ]; then
    tmux send-keys -X -N 2 -t "$pane" cursor-down
  fi
  sleep 0.03
done
