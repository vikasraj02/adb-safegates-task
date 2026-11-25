#!/usr/bin/env bash
# Build image, load it into kind, deploy/roll out. Usage: ./scripts/deploy.sh [tag]
set -euo pipefail
cd "$(dirname "$0")/.."
TAG="${1:-local}"
IMAGE="hello-python:${TAG}"

docker build --build-arg APP_VERSION="$TAG" -t "$IMAGE" .
kind load docker-image "$IMAGE" --name devops

kubectl apply -f k8s/
kubectl -n hello set image deployment/hello-python app="$IMAGE"
kubectl -n hello rollout status deployment/hello-python --timeout=120s
echo "Deployed $IMAGE -> http://localhost:8080"
