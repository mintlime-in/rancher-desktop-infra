#!/bin/bash

function build_fn() {
    gitClone "https://github.com/ongres/stackgres"
}

function install_fn() {
    helm --kube-context ${kubecontext} upgrade --install --create-namespace \
    --namespace stackgres \
    stackgres-operator -f conf/helm/stackgres.yaml \
    --create-namespace \
    https://stackgres.io/downloads/stackgres-k8s/stackgres/latest/helm/stackgres-operator.tgz

    kubectl --context ${kubecontext} apply -f conf/stackgres.yaml
}

function uninstall_fn() {
    helm --kube-context ${kubecontext} uninstall stackgres-operator -n stackgres
    kubectl --context ${kubecontext} delete -f conf/stackgres.yaml
}

cd $(dirname $0) && source lib/helpers.sh && source lib/installer.sh
