# Running the platform locally

Everything runs on one laptop: WSL2 (Ubuntu) + Docker Desktop + a `kind` cluster.

## Daily start-up

After a reboot, start things in this order.

**0. Docker and the cluster**

Start Docker Desktop and wait for *Engine running*. Then:

```bash
docker ps --format '{{.Names}}' | grep -q idp-control-plane || docker start idp-control-plane
kubectl get pods -A | grep -vE 'Running|Completed'   # only the header line should remain
```

**1. ArgoCD** — terminal 1 (keep it open)

```bash
~/projects/idp-platform/deploy/argocd/port-forward.sh       # http://localhost:8081
```

**2. Grafana** — terminal 2 (keep it open)

```bash
~/projects/idp-platform/deploy/monitoring/port-forward.sh   # http://localhost:3001
```

**3. Backstage** — terminal 3 (keep it open)

```bash
cd ~/projects/idp-platform/backstage && yarn dev            # http://localhost:3000
```

`yarn dev` starts PostgreSQL (Docker Compose), loads `.env` and starts Backstage.
The ArgoCD port-forward must be running, otherwise the ArgoCD cards show an error.

## URLs

| Tool | URL | Login |
|---|---|---|
| Backstage | http://localhost:3000 | GitHub |
| ArgoCD | http://localhost:8081 | `admin` (password set at install) |
| Grafana | http://localhost:3001 | `admin` / `kubectl -n monitoring get secret grafana-admin -o jsonpath='{.data.admin-password}' \| base64 -d` |

## Secrets (never committed)

| Secret | Where | Used by |
|---|---|---|
| `backstage/.env` | `AUTH_GITHUB_*`, `POSTGRES_*`, `K8S_*`, `ARGOCD_AUTH_TOKEN` | Backstage |
| `backstage/github-app-*-credentials.yaml` | GitHub App private key | Backstage templates (repo creation, PRs) |
| `~/.idp/kind-registry-config.json` | Classic PAT `read:packages` (expires after 90 days) | kind node, to pull images from GHCR |
| Secret `monitoring/grafana-admin` | In the cluster | Grafana admin login |
| Org secret `GITOPS_APP_PRIVATE_KEY` + variable `GITOPS_APP_CLIENT_ID` | GitHub organization | CI job *Deploy to dev* |

## Cluster add-ons (installed once)

| Component | How | Config |
|---|---|---|
| kind cluster | `kind create cluster --config deploy/kind/cluster.yaml` | `deploy/kind/` |
| GHCR pull credentials | `deploy/kind/registry-auth.sh` | re-run when the PAT expires |
| ArgoCD | Helm `argo/argo-cd` | `deploy/argocd/values.yaml` + `idp-gitops/bootstrap/` |
| Backstage read-only access | `kubectl apply -f deploy/backstage/k8s-rbac.yaml` | ServiceAccount `backstage-reader` |
| Prometheus + Grafana | Helm `prometheus-community/kube-prometheus-stack` | `deploy/monitoring/values.yaml` |
| FastAPI dashboard | `python3 deploy/monitoring/dashboards/generate.py && kubectl apply -f deploy/monitoring/dashboards/fastapi-services.yaml` | dashboard as code |

## Troubleshooting

| Problem | Cause | Fix |
|---|---|---|
| A change in `.env` or `app-config.yaml` has no effect | An old Backstage process still holds port 7007 | `ss -ltnp \| grep 7007`, kill that PID, then `yarn dev` |
| `address already in use` when starting a port-forward | A port-forward is already running | `pgrep -af port-forward` — keep the looping one, kill the others |
| Grafana "Failed to fetch" / ArgoCD cards in error | The port-forward is down | Check terminals 1 and 2; the scripts restart automatically |
| Pods in `ImagePullBackOff` with `401 Unauthorized` | The GHCR PAT expired | Create a new classic PAT (`read:packages`), then `deploy/kind/registry-auth.sh` |
| `kubectl` cannot reach the cluster | Docker was restarted and the kind node is stopped | `docker start idp-control-plane`, wait 1 minute |
| Docker commands hang in WSL | Docker Desktop WSL integration lost | Quit Docker Desktop → `wsl --shutdown` → open Ubuntu → start Docker Desktop |

> Port-forwards are a local-only workaround. Next step (Phase 6): an Ingress controller on the
> ports already mapped by kind (8080/8443), so ArgoCD and Grafana get stable URLs.
