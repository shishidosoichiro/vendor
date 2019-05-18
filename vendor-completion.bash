# source ./vendor-completion.bash
__vendor_comp_func () {
  local cur=${COMP_WORDS[COMP_CWORD]}
  local prev=${COMP_WORDS[COMP_CWORD-1]}
  VENDOR=vendor
  case "$prev" in
    "vendor"|"./vendor"|"vendor.exe"|"./vendor.exe")
      COMPREPLY=($(compgen -W "bin env home install latest ls search uninstall versions manager root util" -- "${cur}"))
    ;;
    "manager")
      COMPREPLY=($(compgen -W "exec pull init" -- "${cur}"))
    ;;
    "root")
      COMPREPLY=($(compgen -W "crobber pull" -- "${cur}"))
    ;;
    "bin"|"env"|"home"|"install"|"latest"|"ls"|"search"|"uninstall"|"versions"|"exec"|"pull"|"init"|"crobber"|"pull")
      apps=$($VENDOR ls)
      COMPREPLY=($(compgen -W "$apps" -- "${cur}"))
    ;;
    *)
      echo "none of the above"
    ;;
  esac
}
complete -F __vendor_comp_func vendor
complete -F __vendor_comp_func ./vendor
complete -F __vendor_comp_func vendor.exe
complete -F __vendor_comp_func ./vendor.exe
