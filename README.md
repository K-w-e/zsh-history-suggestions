# zsh-history-suggestions

Inline history suggestion menu for Zsh with zero external dependencies.

As you type, up to five distinct matching commands from your Zsh history are displayed below the prompt, ordered from most recent to oldest. Matching is a literal substring search anywhere in the command (for example, typing `git` matches both `git status` and `sudo git status`).

## Features

- **Zero dependencies**: uses Zsh's built-in `zsh/parameter` module and ZLE widgets.
- **Substring matching**: searches anywhere in historical commands, deduplicated and ordered by recency.
- **Non-intrusive fallback**: when no suggestions are shown, arrow keys and `Tab` retain their standard Zsh behavior.
- **Persistent hide list**: hide noisy or sensitive commands from future suggestions without deleting them from your Zsh history.
- **Terminal-aware truncation**: truncates long commands to fit the current terminal width (`COLUMNS`) and disables itself in `vicmd`, `isearch`, or very narrow terminals.

## Installation

Add the following line near the bottom of `~/.zshrc`, after your history settings and keybindings:

```zsh
source /path/to/zsh-history-suggestions/history-suggestions.zsh
```

Open a new shell or run `source ~/.zshrc`.

If your Zsh history is not yet configured for persistence, add these settings **before** the `source` line:

```zsh
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
```

## Keybindings

| Key | Action |
|---|---|
| `Up` / `Down` | Move selection through the displayed suggestions (`>` marks the active item) |
| `Tab` | Insert the selected suggestion (or the first one) into the command line without executing it |
| `Ctrl-X` then `Ctrl-D` | Hide the selected suggestion across future sessions without removing it from Zsh history |

## Hidden Suggestions

Hidden entries are stored in:

```text
${XDG_STATE_HOME:-$HOME/.local/state}/zsh-history-suggestions/hidden
```

The file is created with `077` umask (owner-only permissions) and read strictly as data. To restore all hidden suggestions, delete that file.
