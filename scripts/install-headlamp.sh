#!/usr/bin/env bash
# Deploys Headlamp (web GUI for cluster resources) and prints a login token. Idempotent.
set -euo pipefail

helm repo add headlamp https://kubernetes-sigs.github.io/headlamp/ >/dev/null 2>&1 || true
helm repo update >/dev/null
helm upgrade --install headlamp headlamp/headlamp -n kube-system --wait

kubectl -n kube-system create serviceaccount headlamp-admin --dry-run=client -o yaml | kubectl apply -f -
# Demo only: cluster-admin. In production use a scoped read-only ClusterRole.
kubectl create clusterrolebinding headlamp-admin-user \
  --clusterrole=cluster-admin --serviceaccount=kube-system:headlamp-admin \
  --dry-run=client -o yaml | kubectl apply -f -

echo; echo "=== LOGIN TOKEN ==="
kubectl -n kube-system create token headlamp-admin --duration=8h
echo; echo "Starting port-forward: http://localhost:8081  (Ctrl+C to stop)"
kubectl -n kube-system port-forward svc/headlamp 8081:80
