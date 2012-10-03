# ing autocompletion

_ing_builtins=(list help generate setup implicit base)

_ing_is_builtin() {
  for e in ${_ing_builtins[@]}; do [[ "$e" == "$1" ]] && return 0; done; return 1;
}

_ing() {
  COMPREPLY=()
  local word="${COMP_WORDS[COMP_CWORD]}"

  COMPREPLY=( $(compgen -W "$(ing completion ${COMP_WORDS[@]})" -- "$word") )  
}

complete -F _ing ing