#!/usr/bin/env bash
# Creates a single-node kind cluster (control plane runs as static pods in kube-system).
set -euo pipefail
cd "$(dirname "$0")/.."

for bin in docker kind kubectl helm; do
  command -v "$bin" >/dev/null || { echo "Missing dependency: $bin"; exit 1; }
done

if kind get clusters | grep -qx devops; then
  echo "Cluster 'devops' already exists. To apply port mappings run: kind delete cluster --name devops"
else
  kind create cluster --config kind/kind-config.yaml --wait 120s
fi
kubectl cluster-info --context kind-devops
kubectl get nodes -o wide
