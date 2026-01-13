#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$CURRENT_DIR/scripts/utils.sh"

tmux bind-key -N "Launch tmux-poltergeist popup" "$(get_tmux_option "@poltergeist_key" "p")" run-shell "$CURRENT_DIR/scripts/popup.sh"
