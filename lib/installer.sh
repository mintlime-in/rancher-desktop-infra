#!/bin/bash

function usage() {
  cat <<-EOF
  Usage: bash $0 [-i/-u] [-t <filter>] [-l] [-h]
    options:
      -b          build
      -i          install
      -u          uninstall
      -t <filter> deploy only the matching tenant/component (e.g. -t srmvcas)
      -l          list available tenants/components
      -h          help
EOF
}

scriptName=$(basename $0 | cut -d"." -f1)
export kubecontext="rancher-desktop"
export tenant_filter=""

# Returns 0 if the given tenant should be deployed, 1 if filtered out.
# Usage: tenant_matches <tenant> && deploy...
function tenant_matches() {
  [[ -z "${tenant_filter}" ]] && return 0
  [[ ",${tenant_filter}," == *",${1},"* ]] && return 0
  return 1
}

install=0
uninstall=0
list=0
while getopts ":ibut:lh" opt; do
  case ${opt} in
    i)
      install=1
    ;;
    b)
      build=1
    ;;
    u)
      uninstall=1
    ;;
    t)
      tenant_filter="${OPTARG}"
    ;;
    l)
      list=1
    ;;
    h)
      usage
      exit 0
    ;;
  esac
done

echo "kubecontext: ${kubecontext}"

[[ "${list}" -eq 1 ]] && {
  declare -f list_fn > /dev/null && list_fn || \
    { echo "Available ${scriptName} tenants:"; ls -1 "conf/${scriptName}/"; }
  exit 0
}

[[ "${build}" -eq 1 ]] && {
  echo "Building ${scriptName}"
  build_fn
}

[[ "${install}" -eq 1 ]] && install_fn

[[ "${uninstall}" -eq 1 ]] && uninstall_fn
