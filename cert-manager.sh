#!/bin/bash

function build_fn() {
    helm --kube-context ${kubecontext} repo add jetstack https://charts.jetstack.io
    helm --kube-context ${kubecontext} repo update jetstack
}

function install_fn() {
    helm --kube-context ${kubecontext} upgrade --install \
    cert-manager jetstack/cert-manager \
    --set crds.enabled=true \
    -n cert-manager \
    --create-namespace
    cat <<-EOF | kubectl --context ${kubecontext} -n cert-manager apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
    name: selfsigned-root-issuer
spec:
    selfSigned: {}
EOF
}

function uninstall_fn() {
    kubectl --context ${kubecontext} -n cert-manager delete ClusterIssuer selfsigned-root-issuer
    helm --kube-context ${kubecontext} uninstall cert-manager -n cert-manager
}

cd $(dirname $0) && source lib/installer.sh
