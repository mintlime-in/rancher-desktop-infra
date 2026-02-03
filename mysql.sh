#!/bin/bash

function install_fn() {
  kubectl --context ${kubecontext} apply -f conf/mysql.yaml
}

function uninstall_fn() {
    kubectl --context ${kubecontext} delete -f conf/mysql.yaml
}

cd $(dirname $0) && source lib/installer.sh
