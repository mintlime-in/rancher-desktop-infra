#!/bin/bash

function build_fn() {
    helm --kube-context ${kubecontext} repo add grafana https://grafana.github.io/helm-charts
    helm --kube-context ${kubecontext} repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm --kube-context ${kubecontext} repo update prometheus-community grafana
}

function install_fn() {
    helm --kube-context ${kubecontext} upgrade --install \
    prometheus prometheus-community/kube-prometheus-stack \
    -n monitoring \
    --create-namespace \
    -f conf/helm/prometheus-stack.yaml
}

function uninstall_fn() {
    helm --kube-context ${kubecontext} uninstall prometheus -n monitoring
}

cd $(dirname $0) && source lib/installer.sh
