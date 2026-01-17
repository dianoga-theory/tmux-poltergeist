# tmux-poltergeist

<img src="../assets/poltergeist.png?raw=true" width="500">

Are you sick of typing the same thing over and over into your terminal? Do you ever wish you had a helpful pair of ghost hands to do your job?

tmux-poltergeist is a clipboard-like tool for pasting repetitive text. You can save text or commands in one of 10 paste buffers for quick injection into the terminal. So whether you want to input gnarly shell commands or just `cat /proc/kallsyms`, poltergeist is here to get the job done.

<img src="../assets/poltergeist.gif?raw=true" width="500">

# Commands

The following commands can be used for managing paste buffers.

| Key | Description |
| --- | ----------- |
|  a  | add from tmux paste buffer |
|  s  | add from current tmux selection |
|  h  | add from shell history |
|  o  | add from other pastebuf |
|  e  | edit pastebuf with text editor |
|  c  | clear pastebuf |
|  w  | swap pastebufs |
|  q  | exit popup |

# Contexts

Need more than 10 things in your clipboard? tmux-poltergeist supports switching between contexts, each of which is a separate set of 10 paste buffers.

The following commands are used for managing contexts:

| Key | Description |
| --- | ----------- |
| x   | Switch to an existing context |
| X   | Create a new context |
| -   | Delete a context |

# Installation

After installing the [tmux plugin manager](https://github.com/tmux-plugins/tpm), you can add tmux-poltergeist to the list of plugins in your `~/.tmux.conf`.

```
set -g @plugin 'dianoga-theory/tmux-poltergeist'
```

The default keybinding for launching tmux-poltergeist is `<prefix-key> p`. You can change the keybinding by setting `@poltergeist_key` (see below).

# Configuration

tmux-poltergeist can be configured with the following variables. The following settings are the defaults.

```
set -g @poltergeist_key "p"
set -g @poltergeist_width "50"
set -g @poltergeist_height "18"
set -g @poltergeist_preview_chars "35"
set -g @poltergeist_headline_color "red"
set -g @poltergeist_bullet_color "green"
set -g @poltergeist_history_cmd "cut -d';' -f2- ~/.zhistory | tac | awk '!x[$0]++' | tac | fzf --no-sort --tac"
set -g @poltergeist_editor "vim"
```

# Related Projects

laktak created a similar tmux plugin for executing repetitive commands called [tome](https://github.com/laktak/tome). Compared to tmux-poltergeist, it has more scripting features, but potentially requires more keystrokes to execute commands.
