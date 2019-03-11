# source ./vendor-completion.bash
__vendor_comp_func () {
  local cur=${COMP_WORDS[COMP_CWORD]}
  local prev=${COMP_WORDS[COMP_CWORD-1]}

  if [ "$prev" = "vendor" -o "$prev" = "./vendor" -o "$prev" = "vendor.exe" -o "$prev" = "./vendor.exe" ]; then
    COMPREPLY=($(compgen -W "bin env home install ls search uninstall versions manager root util" -- "${cur}"))
  elif [ "$prev" = "manager" ]; then
    COMPREPLY=($(compgen -W "exec pull init" -- "${cur}"))
  elif [ "$prev" = "root" ]; then
    COMPREPLY=($(compgen -W "crobber pull" -- "${cur}"))
  fi
}
complete -F __vendor_comp_func vendor
complete -F __vendor_comp_func ./vendor
complete -F __vendor_comp_func vendor.exe
complete -F __vendor_comp_func ./vendor.exe
