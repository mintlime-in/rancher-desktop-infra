#!/bin/bash

function build_fn() {
    helm --kube-context ${kubecontext} repo add stackgres https://stackgres.io/downloads/stackgres-k8s/stackgres/helm/
    helm --kube-context ${kubecontext} repo update stackgres
}

function install_fn() {
    helm --kube-context ${kubecontext} upgrade --install \
    --create-namespace -n stackgres \
    --force-conflicts \
    stackgres-operator stackgres/stackgres-operator \
    --set-string adminui.service.type=ClusterIP

    for ns_dir in conf/stackgres/*/; do
        tenant_matches "$(basename "${ns_dir}")" || continue
        kubectl --context ${kubecontext} apply -f "${ns_dir}"
    done
}

function uninstall_fn() {
    for ns_dir in conf/stackgres/*/; do
        tenant_matches "$(basename "${ns_dir}")" || continue
        kubectl --context ${kubecontext} delete -f "${ns_dir}"
    done
    
    helm --kube-context ${kubecontext} uninstall stackgres-operator -n stackgres
}

cd $(dirname $0) && source lib/helpers.sh && source lib/installer.sh
