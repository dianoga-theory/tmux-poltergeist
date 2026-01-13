#!/usr/bin/env bash

# https://github.com/pl643/tmux-scripts/blob/main/tmux-popup-pane-manager.sh
realpath="$(realpath "$0")"

source "$(dirname "$realpath")/utils.sh"

PLUGIN_DIR="$HOME/.tmux/plugins/tmux-poltergeist"
if ! [ -d "$PLUGIN_DIR" ]; then
  mkdir -p "$PLUGIN_DIR"
fi

if ! [ -f "${PLUGIN_DIR}/.popup_lock" ]; then
  touch "${PLUGIN_DIR}/.popup_lock"
  tmux popup -E -w "$(get_tmux_option "@poltergeist_width" "50")" -h "$(get_tmux_option "@poltergeist_height" "18")" -y S -x R "$realpath"
  rm "${PLUGIN_DIR}/.popup_lock"
  exit
fi

# Create tmux poltergeist pastebuf structures if they do not exist
if ! [ -d "${PLUGIN_DIR}/pastebufs" ]; then
  mkdir -p "${PLUGIN_DIR}/pastebufs/default"
  for i in {0..9}; do
    touch "${PLUGIN_DIR}/pastebufs/default/b${i}"
  done
  ln -s "${PLUGIN_DIR}/pastebufs/default" "${PLUGIN_DIR}/pastebufs/current"
elif ! [ -d "${PLUGIN_DIR}/pastebufs/current" ]; then
  ln -s "${PLUGIN_DIR}/pastebufs/default" "${PLUGIN_DIR}/pastebufs/current"
fi

BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
LIME_YELLOW=$(tput setaf 190)
POWDER_BLUE=$(tput setaf 153)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)
BRIGHT=$(tput bold)
NORMAL=$(tput sgr0)
BLINK=$(tput blink)
REVERSE=$(tput smso)
UNDERLINE=$(tput smul)

get_color() {
  case "$1" in
    black)       echo "$BLACK" ;;
    red)         echo "$RED" ;;
    green)       echo "$GREEN" ;;
    yellow)      echo "$YELLOW" ;;
    lime_yellow) echo "$LIME_YELLOW" ;;
    powder_blue) echo "$POWDER_BLUE" ;;
    blue)        echo "$BLUE" ;;
    magenta)     echo "$MAGENTA" ;;
    cyan)        echo "$CYAN" ;;
    white)       echo "$WHITE" ;;
    *)           echo "" ;;
  esac
}

TMUX_PASTEBUF_PREVIEW_CHARS=$(get_tmux_option "@poltergeist_preview_chars" "35")
HEADLINE="$(get_color $(get_tmux_option "@poltergeist_headline_color" "red"))"
BULLET="$(get_color $(get_tmux_option "@poltergeist_bullet_color" "green"))"

HELP="
${HEADLINE}ᗣ General Keybindings${NORMAL}
  ${BULLET}[a]${NORMAL}  add from clipboard
  ${BULLET}[s]${NORMAL}  add from selection
  ${BULLET}[h]${NORMAL}  add from history
  ${BULLET}[e]${NORMAL}  edit pastebuf
  ${BULLET}[c]${NORMAL}  clear pastebuf
  ${BULLET}[w]${NORMAL}  swap pastebufs
  ${BULLET}[q]${NORMAL}  quit

${HEADLINE}ᗣ Context Keybindings${NORMAL}
  ${BULLET}[x]${NORMAL}  change context
  ${BULLET}[X]${NORMAL}  create context
  ${BULLET}[-]${NORMAL}  delete context"

default_histcmd() {
  cut -d';' -f2- ~/.zhistory | tac | awk '!x[$0]++' | tac | fzf --no-sort --tac
}

get_pastebuf_preview() {
  local bufnum="$1"
  local -r nlines="$(wc -l "${PLUGIN_DIR}/pastebufs/current/b${bufnum}" | cut -f1 -d' ')"
  local -r tmpbuf="$(cat -v "${PLUGIN_DIR}/pastebufs/current/b${bufnum}" | head -n1 | head -c"${TMUX_PASTEBUF_PREVIEW_CHARS}")"
  if [ "$nlines" -gt "1" ]; then
    echo "$tmpbuf ${RED}[$nlines lines]${NORMAL}"
  else
    echo "$tmpbuf"
  fi
}

get_cur_ctx() {
  basename "$(readlink -f "${PLUGIN_DIR}/pastebufs/current")"
}

show_menu() {
  clear
  local -r b0="$(get_pastebuf_preview 0)"
  local -r b1="$(get_pastebuf_preview 1)"
  local -r b2="$(get_pastebuf_preview 2)"
  local -r b3="$(get_pastebuf_preview 3)"
  local -r b4="$(get_pastebuf_preview 4)"
  local -r b5="$(get_pastebuf_preview 5)"
  local -r b6="$(get_pastebuf_preview 6)"
  local -r b7="$(get_pastebuf_preview 7)"
  local -r b8="$(get_pastebuf_preview 8)"
  local -r b9="$(get_pastebuf_preview 9)"

  echo -n "${HEADLINE}ᗣ tmux-poltergeist [$(get_cur_ctx)]${NORMAL}
  ${BULLET}[0]${NORMAL}  ${b0}...
  ${BULLET}[1]${NORMAL}  ${b1}...
  ${BULLET}[2]${NORMAL}  ${b2}...
  ${BULLET}[3]${NORMAL}  ${b3}...
  ${BULLET}[4]${NORMAL}  ${b4}...
  ${BULLET}[5]${NORMAL}  ${b5}...
  ${BULLET}[6]${NORMAL}  ${b6}...
  ${BULLET}[7]${NORMAL}  ${b7}...
  ${BULLET}[8]${NORMAL}  ${b8}...
  ${BULLET}[9]${NORMAL}  ${b9}...
  ${BULLET}[?]${NORMAL}  help
> "
}
  # ${BULLET}[a/s/h]${NORMAL}  add from clipboard/selection/history
       # (${tmux_pastebuf_clipboard}...)
  # ${BULLET}[e/c/x]${NORMAL}  edit/clear/swap pastebuf
show_help () {
  echo "$HELP" | less -r
}

show_menu
while : ; do
  read -srn1 c || exit
  #echo "[$c] was pressed"

  case $c in
    [0-9]) tmux send-keys "$(cat "${PLUGIN_DIR}/pastebufs/current/b${c}")"; exit ;;
    a)
      while : ; do
        show_menu
        tmux_pastebuf_clipboard="$(tmux show-buffer 2>&1 | head -n1 | head -c"${TMUX_PASTEBUF_PREVIEW_CHARS}")"
        echo -n "[a] add clip [${tmux_pastebuf_clipboard}...] to pastebuf (0-9): "
        reply=$(bash -c "read -n 1 c; echo \$c")
        if [[ "$reply" =~ [0-9] ]]; then
          tmux show-buffer > "${PLUGIN_DIR}/pastebufs/current/b${reply}"
          clear
          show_menu
          break
        fi
      done ;;
    s)
      while : ; do
        show_menu
        echo -n "[s] pastebuf (0-9): "
        reply=$(bash -c "read -n 1 c; echo \$c")
        if [[ "$reply" =~ [0-9] ]]; then
          tmux send -X copy-pipe 'read inp; echo $inp > '"${PLUGIN_DIR}/pastebufs/current/b${reply}"''
          clear
          show_menu
          break
        fi
      done ;;
    h)
      while : ; do
        show_menu
        echo -n "[h] pastebuf (0-9): "
        reply=$(bash -c "read -n 1 c; echo \$c")
        if [[ "$reply" =~ [0-9] ]]; then
          histcmd=$(get_tmux_option "@poltergeist_history_cmd")
          if [ "$histcmd" == "" ]; then
            histitem=$(default_histcmd)
          else
            histitem=$(eval "$histcmd")
          fi

          if [ -n "$histitem" ]; then
            echo -n "$histitem" > "${PLUGIN_DIR}/pastebufs/current/b${reply}"
          fi
          show_menu
          break
        fi
      done ;;
    e|v)
      while : ; do
        show_menu
        echo -n "[$c] pastebuf (0-9): "
        reply=$(bash -c "read -n 1 c; echo \$c")
        if [[ "$reply" =~ [0-9] ]]; then
          editor=$(get_tmux_option "@poltergeist_editor" "vim")
          $editor "${PLUGIN_DIR}/pastebufs/current/b${reply}"
          show_menu
          break
        fi
      done ;;
    c)
      while : ; do
        show_menu
        echo -n "[c] pastebuf (0-9): "
        reply=$(bash -c "read -n 1 c; echo \$c")
        if [[ "$reply" =~ [0-9] ]]; then
          echo "" > "${PLUGIN_DIR}/pastebufs/current/b${reply}"
          show_menu
          break
        fi
      done ;;
    w)
      show_menu
      echo -n "[x] Swap pastebufs >"
      pb1=$(bash -c "read -n 1 c; echo \$c")
      echo -n " >"
      if [[ $pb1 =~ [0-9] ]]; then
        pb2=$(bash -c "read -n 1 c; echo \$c")
        echo "$pb2"
        if [[ $pb2 =~ [0-9] ]]; then
          TMPFILE=$(mktemp "${PLUGIN_DIR}/pastebufs/current/XXXXXX")
          mv "${PLUGIN_DIR}/pastebufs/current/b${pb1}" "$TMPFILE"
          mv "${PLUGIN_DIR}/pastebufs/current/b${pb2}" "${PLUGIN_DIR}/pastebufs/current/b${pb1}"
          mv "$TMPFILE" "${PLUGIN_DIR}/pastebufs/current/b${pb2}"
          show_menu
        else
          show_menu; echo -n "Invalid pastebuf [$c]"
        fi
      else
        show_menu; echo -n "Invalid pastebuf [$c]"
      fi
      ;;
    x)
      choice="$(ls -1 ${PLUGIN_DIR}/pastebufs | grep -vx current | grep -vx $(get_cur_ctx) | fzf --prompt="Change context to: " --preview="echo -e '${GREEN}[{}]${NORMAL}'; ${PLUGIN_DIR}/scripts/print_ctx.sh {}" --preview-window=wrap)"
      # Test to handle case where fzf was cancelled
      if [ -n "$choice" ]; then
        unlink "${PLUGIN_DIR}/pastebufs/current"
        ln -s "${PLUGIN_DIR}/pastebufs/${choice}" "${PLUGIN_DIR}/pastebufs/current"
        show_menu
      fi
      ;;
    X)
      show_menu
      echo -n "[X] create new context? [y/n] "
      user_resp=$(bash -c "read -n 1 c; echo \$c")
      if [ "$user_resp" == "y" ]; then
        show_menu
        echo -n "Enter new ctx name: "
        read -r new_ctx
        show_menu
        echo -ne "Use ${GREEN}[$new_ctx]${NORMAL} as new ctx name? [y/n] "
        user_resp=$(bash -c "read -n 1 c; echo \$c")
        if [ "$user_resp" == "y" ]; then
          show_menu
          echo -ne "Create ${GREEN}[$new_ctx]${NORMAL} from an existing ctx? [y/n] "
          user_resp=$(bash -c "read -n 1 c; echo \$c")
          if [ "$user_resp" == "y" ]; then
            base="$(ls -1 "${PLUGIN_DIR}/pastebufs" | grep -vx current | fzf --prompt="base ctx: " --preview="echo -e '${GREEN}[{}]${NORMAL}'; ${PLUGIN_DIR}/scripts/print_ctx.sh {}" --preview-window=wrap)"
            show_menu
            echo -ne "Use ${GREEN}[$base]${NORMAL} as base for new ctx? [y/n] "
            user_resp=$(bash -c "read -n 1 c; echo \$c")
            if [ "$user_resp" == "y" ]; then
              cp -r "${PLUGIN_DIR}/pastebufs/${base}" "${PLUGIN_DIR}/pastebufs/${new_ctx}"
              unlink "${PLUGIN_DIR}/pastebufs/current"
              ln -s "${PLUGIN_DIR}/pastebufs/${new_ctx}" "${PLUGIN_DIR}/pastebufs/current"
              show_menu
              echo "Created and switched to context ${GREEN}[$new_ctx]${NORMAL}"
            else
              show_menu
            fi
          else
            mkdir -p "${PLUGIN_DIR}/pastebufs/${new_ctx}"
            for i in {0..9}; do
              touch "${PLUGIN_DIR}/pastebufs/${new_ctx}/b${i}"
            done
            unlink "${PLUGIN_DIR}/pastebufs/current"
            ln -s "${PLUGIN_DIR}/pastebufs/${new_ctx}" "${PLUGIN_DIR}/pastebufs/current"
            show_menu
            echo "Created and switched to context ${GREEN}[$new_ctx]${NORMAL}"
          fi
        else
          show_menu
        fi
      else
        show_menu
      fi
    ;;
    -)
      show_menu
      echo -n "[-] delete a context? [y/n] > "
      user_resp=$(bash -c "read -n 1 c; echo \$c")
      if [ "$user_resp" == "y" ]; then
        choice="$(ls -1 "${PLUGIN_DIR}/pastebufs" | grep -vx current | grep -vx "$(get_cur_ctx)" | fzf --prompt="delete ctx: " --preview="echo -e '${GREEN}[{}]${NORMAL}'; ${PLUGIN_DIR}/scripts/print_ctx.sh {}" --preview-window=wrap)"
        if [ -n "$choice" ]; then
          show_menu
          echo -ne "Delete ctx ${GREEN}[$choice]${NORMAL}? [y/n] "
          user_resp=$(bash -c "read -n 1 c; echo \$c")
          if [ "$user_resp" == "y" ]; then
            rm -rf "${PLUGIN_DIR}/pastebufs/${choice}"
            show_menu
            echo "Deleted ctx $choice"
          fi
        fi
      fi
      show_menu
      ;;
    \?) show_help ;;
    q) exit ;;
    *) show_menu; echo -n "Invalid command [$c]"; ;;
  esac
done
