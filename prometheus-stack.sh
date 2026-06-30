#!/bin/bash

function build_fn() {
    helm --kube-context ${kubecontext} repo add grafana https://grafana.github.io/helm-charts
    helm --kube-context ${kubecontext} repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm --kube-context ${kubecontext} repo update prometheus-community grafana
}

function install_fn() {
cat >/tmp/prometheus-stack.yaml <<EOF
grafana:
  adminPassword: coe@2024
  ingress:
    enabled: true
    hosts:
      - grafana.localhost
    tls:
      - hosts:
          - grafana.localhost
        secretName: grafana-tls
    annotations:
      cert-manager.io/cluster-issuer: lets-encrypt
  sidecar:
    datasources:
      env:
        SKIP_TLS_VERIFY: "true"
    dashboards:
      annotations:
        grafana_folder: "kubernetes"
      defaultFolderName: "General"
      folderAnnotation: "grafana_folder"
      provider:
        foldersFromFilesStructure: true
      env:
        SKIP_TLS_VERIFY: "true"
EOF
    helm --kube-context ${kubecontext} upgrade --install \
    prometheus prometheus-community/kube-prometheus-stack \
    -n monitoring \
    --create-namespace \
    -f /tmp/prometheus-stack.yaml
}

function uninstall_fn() {
    helm --kube-context ${kubecontext} uninstall prometheus -n monitoring
}

cd $(dirname $0) && source lib/installer.sh
