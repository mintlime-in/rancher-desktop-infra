#!/bin/bash

function install_fn() {
  kubectl --context ${kubecontext} apply -f conf/keycloak.yaml
}

function uninstall_fn() {
    kubectl --context ${kubecontext} delete -f conf/keycloak.yaml
}

cd $(dirname $0) && source lib/installer.sh
