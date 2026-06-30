#!/bin/bash

function build_fn() {
    helm --kube-context ${kubecontext} repo add cerbos https://download.cerbos.dev/helm-charts
    helm --kube-context ${kubecontext} repo update cerbos
}

function install_fn() {
    for deploy_dir in conf/cerbos/*/; do
        local deploy ns
        deploy=$(basename "${deploy_dir}")
        tenant_matches "${deploy}" || continue
        ns="${deploy}"

        helm --kube-context ${kubecontext} upgrade --install \
            -n "${ns}" "cerbos-${deploy}" cerbos/cerbos \
            -f "${deploy_dir}/values.yaml" \
            --create-namespace
    done
}

function uninstall_fn() {
    for deploy_dir in conf/cerbos/*/; do
        local deploy
        deploy=$(basename "${deploy_dir}")
        tenant_matches "${deploy}" || continue
        helm --kube-context ${kubecontext} uninstall "cerbos-${deploy}" -n "${deploy}" || true
    done
}

cd $(dirname $0) && source lib/helpers.sh && source lib/installer.sh
