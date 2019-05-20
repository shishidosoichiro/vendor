# source ./vendor-completion.bash
__vendor_comp_func () {
  local vendor=${COMP_WORDS[0]}
  local subcommand1=${COMP_WORDS[1]}
  local subcommand2=${COMP_WORDS[2]}
  local cur=${COMP_WORDS[COMP_CWORD]}
  local prev=${COMP_WORDS[COMP_CWORD-1]}
  if [ $COMP_CWORD = 0 ]; then
    continue;
  elif [ $COMP_CWORD = 1 ]; then
    COMPREPLY=($(compgen -W "bin env home install latest ls search uninstall versions manager root util" -- "${cur}"))
  elif [ $COMP_CWORD = 2 ]; then
    case "$subcommand1" in
      "manager")
        COMPREPLY=($(compgen -W "exec pull init" -- "${cur}"))
      ;;
      "root")
        COMPREPLY=($(compgen -W "crobber pull" -- "${cur}"))
      ;;
      "bin"|"env"|"home"|"install"|"latest"|"ls"|"search"|"uninstall"|"versions")
        apps=$($vendor ls)
        COMPREPLY=($(compgen -W "$apps" -- "${cur}"))
      ;;
    esac
  else
    case "$subcommand1" in
      "manager")
        case "$subcommand2" in
          "exec"|"pull"|"init")
            apps=$($vendor ls)
            COMPREPLY=($(compgen -W "$apps" -- "${cur}"))
          ;;
        esac
      ;;
      "root")
        case "$subcommand2" in
          "crobber"|"pull")
            apps=$($vendor ls)
            COMPREPLY=($(compgen -W "$apps" -- "${cur}"))
          ;;
        esac
      ;;
      "bin"|"env"|"home"|"install"|"latest"|"ls"|"search"|"uninstall"|"versions")
        apps=$($vendor ls)
        COMPREPLY=($(compgen -W "$apps" -- "${cur}"))
      ;;
    esac
  fi;
}
complete -F __vendor_comp_func vendor
complete -F __vendor_comp_func ./vendor
complete -F __vendor_comp_func vendor.exe
complete -F __vendor_comp_func ./vendor.exe
