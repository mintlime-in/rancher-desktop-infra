#!/bin/bash

function build_fn() {
    helm --kube-context ${kubecontext} repo add minio https://operator.min.io/
}

function install_fn() {
    helm --kube-context ${kubecontext} upgrade --install \
    --namespace minio \
    --create-namespace \
    minio-operator minio/operator \
    --set operator.replicaCount=1

    helm --kube-context ${kubecontext} upgrade --install -n minio minio minio/tenant -f conf/minio.yaml
    
}

function uninstall_fn() {
    helm --kube-context ${kubecontext} uninstall minio-operator -n minio
}

cd $(dirname $0)  && source lib/installer.sh
