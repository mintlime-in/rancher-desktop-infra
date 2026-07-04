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

    # CRs below go through the operator's mutating webhooks, so wait for the
    # operator pod (and its Service endpoints) to be ready before applying them,
    # otherwise kubectl apply intermittently fails with
    # "no endpoints available for service stackgres-operator".
    kubectl --context ${kubecontext} -n stackgres rollout status deployment/stackgres-operator --timeout=180s

    for ns_dir in conf/stackgres/*/; do
        local ns
        ns="$(basename "${ns_dir}")"
        tenant_matches "${ns}" || continue
        # Namespace is created here (not embedded in the tenant manifest) so that
        # uninstall_fn's "kubectl delete -f" never deletes the namespace itself —
        # it's shared with other components (e.g. minio, cerbos) for this tenant.
        kubectl --context ${kubecontext} create namespace "${ns}" --dry-run=client -o yaml | kubectl --context ${kubecontext} apply -f -
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
