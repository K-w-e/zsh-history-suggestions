# Source from ~/.zshrc, after configuring history and key bindings.
[[ -o interactive ]] || return 0

() {
  emulate -L zsh
  zmodload zsh/parameter || return 1
  autoload -Uz add-zle-hook-widget

  typeset -ga _zhs_events _zhs_matches
  typeset -gA _zhs_hidden
  typeset -g _zhs_query='' _zhs_message=''
  typeset -g _zhs_hidden_file=${XDG_STATE_HOME:-$HOME/.local/state}/zsh-history-suggestions/hidden
  typeset -gi _zhs_selected=1 _zhs_loaded=0

  _zhs_load_hidden() {
    local entry
    _zhs_hidden=()
    [[ -f $_zhs_hidden_file && -r $_zhs_hidden_file ]] || return 0
    # Read quoted entries as data, never as shell code.
    while IFS= read -r entry; do
      [[ -n $entry ]] && _zhs_hidden[$entry]=1
    done < "$_zhs_hidden_file"
    return 0
  }

  _zhs_update_matches() {
    emulate -L zsh
    [[ $BUFFER == "$_zhs_query" ]] && return 0

    _zhs_query=$BUFFER
    _zhs_matches=()
    _zhs_selected=1
    [[ -n ${BUFFER//[[:space:]]/} ]] || return 0

    if (( ! _zhs_loaded )); then
      _zhs_events=( ${(Onk)history} )
      _zhs_load_hidden
      _zhs_loaded=1
    fi

    local event entry encoded
    local -A seen
    for event in "${_zhs_events[@]}"; do
      entry=${history[$event]}
      [[ -n $entry && $entry == *"$_zhs_query"* ]] || continue
      encoded=${(qqqq)entry}
      [[ -n ${seen[$encoded]} || -n ${_zhs_hidden[$encoded]} ]] && continue
      seen[$encoded]=1
      _zhs_matches+=( "$entry" )
      (( ${#_zhs_matches} == 5 )) && break
    done
    return 0
  }

  _zhs_clear() {
    if [[ -n $_zhs_message ]]; then
      _zhs_message=''
      zle -M ''
    fi
    return 0
  }

  _zhs_has_matches() {
    [[ $CONTEXT == start && $KEYMAP != (vicmd|isearch) ]] &&
      (( ! ISEARCHMATCH_ACTIVE && COLUMNS >= 8 )) || return 1
    _zhs_update_matches
    (( ${#_zhs_matches} > 0 ))
  }

  _zhs_redraw() {
    emulate -L zsh
    if ! _zhs_has_matches; then
      _zhs_clear
      return 0
    fi

    local entry shown marker message=''
    local -i i=0 width=$(( COLUMNS - 4 ))
    for entry in "${_zhs_matches[@]}"; do
      (( ++i ))
      marker='  '
      (( i == _zhs_selected )) && marker='> '
      shown=${(V)entry}
      if (( ${(m)#shown} > width )); then
        shown="${(mr:$(( width - 3 )):)shown}..."
      fi
      [[ -z $message ]] || message+=$'\n'
      message+="$marker$shown"
    done
    if [[ $message != "$_zhs_message" ]]; then
      _zhs_message=$message
      zle -M "$message"
    fi
    return 0
  }

  _zhs_finish() {
    # ZLE erases the menu on exit. Calling zle -M here can cause the next
    # prompt to be skipped if the executed command clears the screen.
    _zhs_message=''
    _zhs_events=()
    _zhs_matches=()
    _zhs_query=''
    _zhs_loaded=0
  }

  _zhs_hide() {
    emulate -L zsh
    _zhs_has_matches || return 0
    local entry=${_zhs_matches[_zhs_selected]}
    local encoded=${(qqqq)entry}
    local -i selected=$_zhs_selected
    if ! (
      umask 077
      command mkdir -p -- "${_zhs_hidden_file:h}" &&
        print -r -- "$encoded" >> "$_zhs_hidden_file"
    ) 2>/dev/null; then
      zle -R 'Impossibile salvare il suggerimento da nascondere.'
      return 1
    fi
    _zhs_hidden[$encoded]=1
    _zhs_query=''
    _zhs_update_matches
    local -i count=${#_zhs_matches}
    (( count > 0 )) && _zhs_selected=$(( selected < count ? selected : count ))
    return 0
  }

  _zhs_choose() {
    emulate -L zsh
    if ! _zhs_has_matches; then
      # When there are no suggestions, keep the standard editing behavior.
      case $WIDGET in
        zhs-next) zle down-line-or-history -w ;;
        zhs-prev) zle up-line-or-history -w ;;
        zhs-insert) zle expand-or-complete -w ;;
      esac
      return $?
    fi
    local -i count=${#_zhs_matches}
    case $WIDGET in
      zhs-next) _zhs_selected=$(( _zhs_selected % count + 1 )) ;;
      zhs-prev) _zhs_selected=$(( (_zhs_selected + count - 2) % count + 1 )) ;;
      zhs-insert)
        BUFFER=${_zhs_matches[_zhs_selected]}
        CURSOR=${#BUFFER}
        _zhs_query=$BUFFER
        _zhs_matches=()
        ;;
    esac
    return 0
  }

  add-zle-hook-widget line-pre-redraw _zhs_redraw
  add-zle-hook-widget line-finish _zhs_finish
  zle -N zhs-next _zhs_choose
  zle -N zhs-prev _zhs_choose
  zle -N zhs-insert _zhs_choose
  zle -N zhs-hide _zhs_hide

  local map
  for map in emacs viins; do
    bindkey -M "$map" '^[[B' zhs-next
    bindkey -M "$map" '^[OB' zhs-next
    bindkey -M "$map" '^[[A' zhs-prev
    bindkey -M "$map" '^[OA' zhs-prev
    bindkey -M "$map" '^I' zhs-insert
    bindkey -M "$map" '^X^D' zhs-hide
  done
}
