# ing autocompletion

# hopefully this doesn't cause too much havoc elsewhere
# but srsly, I hate how COMP_WORDS breaks on commas!
#
COMP_WORDBREAKS=${COMP_WORDBREAKS/:}
export COMP_WORDBREAKS

# This would be ideal & not require global changes, but for some reason doesn't
# want to work with a trailing comma in $cur
_ing0() {
  COMPREPLY=()
  local cur; local words
  _get_comp_words_by_ref -n : cur words
  #echo -n "{ ing completion "${words[@]:1}" -- "$cur" }"
  COMPREPLY=( $(compgen -W "$(ing completion "${words[@]:1}")" -- "$cur") ) 
  __ltrim_colon_completions "$cur"  
}

_ing() {
  COMPREPLY=()
  local cur="${COMP_WORDS[COMP_CWORD]}"
  #echo -n "{ ing completion "${COMP_WORDS[@]:1}" -- "$cur" }"
  COMPREPLY=( $(compgen -W "$(ing completion "${COMP_WORDS[@]:1}")" -- "$cur") ) 
}

complete -F _ing ing