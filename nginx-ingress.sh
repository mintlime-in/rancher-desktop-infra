#!/bin/bash

function install_fn() {

    helm --kube-context ${kubecontext} upgrade --install ingress-nginx ingress-nginx \
    --repo https://kubernetes.github.io/ingress-nginx \
    --set controller.extraArgs.enable-ssl-passthrough="" \
    -n ingress-nginx --create-namespace

}

function uninstall_fn() {
    helm --kube-context ${kubecontext} uninstall ingress-nginx -n ingress-nginx
}

cd $(dirname $0) && source lib/installer.sh
