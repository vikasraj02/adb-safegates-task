# Junior DevOps Assignment – Kubernetes, Docker, CI/CD

Hello World Python web app, built as a hardened distroless image, deployed to a single-node **kind** cluster, visualised with **Headlamp**, and built/deployed by **GitHub Actions**.

```
├── app/app.py                  # Hello World web server (stdlib only)
├── Dockerfile                  # distroless, non-root
├── k8s/                        # Namespace, Deployment, Service
├── kind/kind-config.yaml       # single-node cluster + host port mapping
├── scripts/                    # setup-cluster.sh, install-headlamp.sh, deploy.sh
├── .github/workflows/ci.yml    # build, test, scan, deploy
└── docs/screenshots/           # Headlamp log screenshots
```

## 1. Prerequisites (Ubuntu / WSL2)
Docker, [kind](https://kind.sigs.k8s.io/), kubectl, helm, git. Verify:
```bash
docker version && kind version && kubectl version --client && helm version
```
On WSL2, enable Docker Desktop's WSL integration (or install Docker Engine in WSL).

## 2. Build the cluster
```bash
git clone <your-repo-url> && cd <repo>
./scripts/setup-cluster.sh
```
If a `devops` cluster already exists, recreate it so the port mapping applies:
`kind delete cluster --name devops && ./scripts/setup-cluster.sh`

Check: `kubectl get pods -n kube-system` shows `kube-apiserver-*`, `kube-controller-manager-*`, `etcd-*`, `kube-scheduler-*`.

## 3. Deploy the GUI (Headlamp)
```bash
./scripts/install-headlamp.sh      # prints a token, then port-forwards to :8081
```
Open http://localhost:8081, paste the token. Then:
**Workloads → Pods → namespace `kube-system` → `kube-apiserver-devops-control-plane` → Logs** and screenshot it. Repeat for `kube-controller-manager-devops-control-plane`. Save to `docs/screenshots/`.

## 4. Deploy the app
```bash
./scripts/deploy.sh                # builds image, loads into kind, applies manifests
```
Open http://localhost:8080 → "Hello, World!" plus the serving pod name (refresh to see the 2 replicas).

## 5. CI/CD pipeline (`.github/workflows/ci.yml`)
| Job | Runs on | Steps |
|---|---|---|
| `build` | GitHub-hosted | build image → smoke test (`/healthz` + page) → Trivy scan (fails on fixable HIGH/CRITICAL) |
| `deploy` | **self-hosted** (your WSL box), only on push to `main` | `scripts/deploy.sh <git-sha>` → load into kind → rolling update |

### Register the self-hosted runner
GitHub-hosted runners cannot reach a cluster on your laptop, so deploy runs on your machine.
Repo → **Settings → Actions → Runners → New self-hosted runner → Linux x64**, run the shown commands inside WSL, then:
```bash
./run.sh      # keep running; runner user needs access to docker, kind, kubectl
```
Test: change the text in `app/app.py`, `git push` to `main`, watch Actions, refresh http://localhost:8080 (the version shown is the commit SHA).
Without a runner, the `build` job still runs; `deploy` waits for a runner. Use `./scripts/deploy.sh` manually.

## 6. Design decisions (the "why")
- **kind, not k3s:** k3s embeds the control plane in one process, so there are no `kube-apiserver`/`kube-controller-manager` pods to show logs for. kind (kubeadm inside a container) runs them as static pods.
- **Headlamp:** lightweight, in-cluster web UI with a pod log viewer; the task forbids kubectl for visualisation.
- **Python stdlib server:** zero dependencies means no pip supply chain and a minimal image. Production apps would use gunicorn/uvicorn.
- **Distroless `:nonroot`:** no shell or package manager (smaller attack surface, fewer CVEs); runs as UID 65532. Debug with the `:debug-nonroot` tag locally only.
- **Least privilege in Kubernetes:** `runAsNonRoot`, `readOnlyRootFilesystem`, drop ALL capabilities, no privilege escalation, `seccomp: RuntimeDefault`, no service-account token mounted, CPU/memory limits.
- **Port 8080:** unprivileged port, so no capability needed to bind.
- **NodePort + kind `extraPortMappings`:** simplest way to reach the app from the host without an ingress controller.
- **`kind load` instead of a registry:** no registry or credentials needed for a local demo. A real setup would push to GHCR/ACR and pull from there.
- **Workflow `permissions: contents: read`:** least privilege for the `GITHUB_TOKEN`.
- **Headlamp `cluster-admin`:** demo shortcut. Production would bind a read-only ClusterRole.

## 7. Cleanup
```bash
kind delete cluster --name devops
```
