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

    for tenant_dir in conf/minio/*/; do
        tenant=$(basename "${tenant_dir}")
        helm --kube-context ${kubecontext} upgrade --install \
            -n "${tenant}" "${tenant}-minio" minio/tenant \
            -f "${tenant_dir}/values.yaml" \
            --create-namespace
        create_user_fn "${tenant}"
    done
}

function create_user_fn() {
    local tenant=$1
    local ns="${tenant}"
    local tenant_dir="conf/minio/${tenant}"
    local endpoint="https://minio.${ns}.svc.cluster.local"

    local access_key secret_key
    access_key=$(yq e '.tenant.configSecret.accessKey' "${tenant_dir}/values.yaml")
    secret_key=$(yq e '.tenant.configSecret.secretKey' "${tenant_dir}/values.yaml")

    # Build init script — MC_INSECURE=true is set in the Job env so no --insecure flags needed
    local init_script
    local q_access_key q_secret_key
    q_access_key=$(printf '%q' "${access_key}")
    q_secret_key=$(printf '%q' "${secret_key}")
    init_script="#!/bin/sh\n"
    init_script+="until mc alias set myminio ${endpoint} ${q_access_key} ${q_secret_key} 2>/dev/null; do echo 'waiting for minio...'; sleep 3; done\n"
    init_script+="until mc ready myminio 2>/dev/null; do echo 'waiting for minio ready...'; sleep 3; done\n"

    for f in "${tenant_dir}/buckets/"*.json; do
        [[ -f "$f" ]] || continue
        local bucket
        bucket=$(basename "$f" .json)
        init_script+="mc mb --ignore-existing myminio/${bucket} || true\n"
        init_script+="mc anonymous set-json /buckets/$(basename "$f") myminio/${bucket} || true\n"
    done

    for f in "${tenant_dir}/policies/"*.json; do
        [[ -f "$f" ]] || continue
        local policy_name
        policy_name=$(basename "$f" .json)
        init_script+="mc admin policy create myminio ${policy_name} /policies/$(basename "$f") || true\n"
    done

    # yq v4 syntax: iterate users by index to pair name+password and name+policies
    local user_count
    user_count=$(yq e '.users | length' "${tenant_dir}/users.yaml")
    for ((i=0; i<user_count; i++)); do
        local name password q_password
        name=$(yq e ".users[$i].name" "${tenant_dir}/users.yaml")
        password=$(yq e ".users[$i].password" "${tenant_dir}/users.yaml")
        q_password=$(printf '%q' "${password}")
        init_script+="mc admin user add myminio ${name} ${q_password} || true\n"

        local policy_count
        policy_count=$(yq e ".users[$i].policies | length" "${tenant_dir}/users.yaml")
        for ((j=0; j<policy_count; j++)); do
            local policy
            policy=$(yq e ".users[$i].policies[$j]" "${tenant_dir}/users.yaml")
            init_script+="mc admin policy attach myminio ${policy} --user ${name} || true\n"
        done
    done

    init_script+="echo 'MinIO init complete for ${tenant}!'\n"

    kubectl --context ${kubecontext} -n ${ns} create configmap ${tenant}-minio-init-script \
        --from-literal=init.sh="$(printf "${init_script}")" \
        --dry-run=client -o yaml | kubectl --context ${kubecontext} apply -f -

    kubectl --context ${kubecontext} -n ${ns} create configmap ${tenant}-minio-policies \
        --from-file="${tenant_dir}/policies/" \
        --dry-run=client -o yaml | kubectl --context ${kubecontext} apply -f -

    kubectl --context ${kubecontext} -n ${ns} create configmap ${tenant}-minio-buckets \
        --from-file="${tenant_dir}/buckets/" \
        --dry-run=client -o yaml | kubectl --context ${kubecontext} apply -f -

    # Persist each user's credentials as a K8s secret so other services (e.g. Cerbos) can reference them
    for ((i=0; i<user_count; i++)); do
        local uname upassword
        uname=$(yq e ".users[$i].name" "${tenant_dir}/users.yaml")
        upassword=$(yq e ".users[$i].password" "${tenant_dir}/users.yaml")
        kubectl --context ${kubecontext} -n ${ns} create secret generic "${tenant}-${uname}" \
            --from-literal=accessKey="${uname}" \
            --from-literal=secretKey="${upassword}" \
            --dry-run=client -o yaml | kubectl --context ${kubecontext} apply -f -
    done

    kubectl --context ${kubecontext} -n ${ns} delete job ${tenant}-minio-init --ignore-not-found

    kubectl --context ${kubecontext} apply -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: ${tenant}-minio-init
  namespace: ${ns}
spec:
  template:
    spec:
      restartPolicy: OnFailure
      containers:
      - name: mc
        image: minio/mc:latest
        command: ["/bin/sh", "/scripts/init.sh"]
        env:
        - name: MC_INSECURE
          value: "true"
        volumeMounts:
        - name: init-script
          mountPath: /scripts
        - name: policies
          mountPath: /policies
        - name: buckets
          mountPath: /buckets
      volumes:
      - name: init-script
        configMap:
          name: ${tenant}-minio-init-script
          defaultMode: 0755
      - name: policies
        configMap:
          name: ${tenant}-minio-policies
      - name: buckets
        configMap:
          name: ${tenant}-minio-buckets
EOF
}

function uninstall_fn() {
    helm --kube-context ${kubecontext} uninstall minio-operator -n minio
}

cd $(dirname $0) && source lib/helpers.sh && source lib/installer.sh
