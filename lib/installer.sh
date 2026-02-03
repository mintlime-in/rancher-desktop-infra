#!/bin/bash

function usage() {
  cat <<-EOF
  Usage: bash $0 -c <kubecontext> [-i/-u] [-h]
    options:
      -c  kube-context
      -b  build
      -i  install
      -u  uninstall
      -h  help
EOF
}

scriptName=$(basename $0 | cut -d"." -f1)

install=0
uninstall=0
while getopts ":ic:buh" opt; do
  case ${opt} in
    c)
      export kubecontext=${OPTARG}
    ;;
    i)
      install=1
    ;;
    b)
      build=1
    ;;
    u)
      uninstall=1
    ;;
    h)
      usage
      exit 0
    ;;
  esac
done

[[ ${kubecontext} == "" ]] && usage && exit 1

echo "kubecontext: ${kubecontext}"

[[ "${build}" -eq 1 ]] && {
  echo "Building ${scriptName}"
  build_fn
}

[[ "${install}" -eq 1 ]] && {
  echo -n "Installing ${scriptName} in '${kubecontext}' cluster. Proceed[Y/n]?:"
  read -n 1 prompt
  echo
  prompt=$(echo $prompt | tr '[a-z]' '[A-Z]')
  [[ $prompt == "" ]] && prompt="Y"
  [[ $prompt == "Y" ]] && install_fn
}

[[ "${uninstall}" -eq 1 ]] && {
  echo -n "Uninstalling ${scriptName} in '${kubecontext}' cluster. Proceed[Y/n]?:"
  read -n 1 prompt
  echo
  prompt=$(echo $prompt | tr '[a-z]' '[A-Z]')
  [[ $prompt == "" ]] && prompt="Y"
  [[ $prompt == "Y" ]] && uninstall_fn
}
