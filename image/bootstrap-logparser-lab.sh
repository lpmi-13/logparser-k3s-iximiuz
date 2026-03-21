#!/bin/bash
set -euo pipefail

KUBECONFIG_PATH="${KUBECONFIG:-/home/laborant/.kube/config}"
CRD_PATH="/opt/logparser-lab-operator/lab.learning.io_logparserlabs.yaml"
LOGS_DIR="/var/lib/logparser-lab/logs"

export KUBECONFIG="${KUBECONFIG_PATH}"

for _ in $(seq 1 90); do
  if kubectl get --raw=/readyz >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

kubectl get --raw=/readyz >/dev/null 2>&1 || {
  echo "k3s API did not become ready in time"
  exit 1
}

mkdir -p "${LOGS_DIR}"

kubectl apply -f "${CRD_PATH}"
kubectl wait --for=condition=Established --timeout=60s \
  crd/logparserlabs.lab.learning.io
