#!/bin/bash

function build_fn() {

    helm --kube-context ${kubecontext} repo add traefik https://traefik.github.io/traefik-helm-chart

    helm --kube-context ${kubecontext} repo update traefik
}

function install_fn() {

    helm --kube-context ${kubecontext} upgrade --install traefik traefik/traefik \
    --set additionalArguments[0]="--entryPoints.postgres.address=:5432/tcp" \
    -n traefik --create-namespace
}

function uninstall_fn() {
    helm --kube-context ${kubecontext} uninstall traefik -n traefik
}

cd $(dirname $0) && source lib/installer.sh
