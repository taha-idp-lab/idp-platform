# Internal Developer Platform (IDP) with Backstage

> A self-service developer platform: create, deploy and observe a new microservice **in under 5 minutes**, following organization best practices (CI/CD, security, GitOps, observability).

🚧 **Status:** work in progress — see [`JOURNAL.md`](JOURNAL.md) for progress.

## ✅ What works today (v1)

A developer fills a form in Backstage and gets, **in about 10 seconds**, a new GitHub repository with a working FastAPI service, registered in the catalog with its owner team.

<!-- screenshot: docs/images/template-run.png -->

➡️ Developer guide: [How to create a new service](docs/how-to-create-a-service.md)

## The problem

Creating a new service usually means copy-pasting an old repo, rewriting a CI pipeline, writing Helm charts, and opening a ticket to the DevOps team — then waiting days. Every team does it differently, there is no service inventory, and security scanning is inconsistent.

## The solution

A **golden path**, packaged as a product:

1. A developer fills a form in **Backstage**.
2. A new repo is generated from a template (code, Dockerfile, Helm chart, CI with Trivy scan).
3. A PR declares the service in the **GitOps** repo.
4. **ArgoCD** deploys it to **Kubernetes** automatically.
5. CI status, deployments, pods, metrics and docs are visible on one page in Backstage.

## Stack

Backstage · GitHub Actions · GHCR · ArgoCD (ApplicationSet) · Helm · Kubernetes (kind) · Prometheus / Grafana · Trivy

## Architecture

See [`docs/architecture.md`](docs/architecture.md).

## Repositories

| Repo | Role |
|---|---|
| `idp-platform` (this repo) | Backstage portal, software templates, catalog entities |
| [`idp-gitops`](https://github.com/taha-idp-lab/idp-gitops) | Desired state of the cluster (ArgoCD ApplicationSet + per-service values) |

## Roadmap

- [x] **Phase 0** — Environment, repos, architecture
- [x] **Phase 1** — Backstage running with GitHub auth and PostgreSQL
- [x] **Phase 2 (v1)** — Catalog + first template: one click creates a repo
- [ ] **Phase 3** — Production-ready skeleton (CI, Trivy, Helm, `/metrics`, TechDocs)
- [ ] **Phase 4 (v2)** — GitOps: form → service running in the cluster
- [ ] **Phase 5 (v3)** — Visibility: Kubernetes, ArgoCD, GitHub Actions plugins + Grafana
- [ ] **Phase 6** — Second template, demo scenarios, final docs

## Run locally

```bash
cd backstage
yarn install
yarn start   # http://localhost:3000
```

---

*Built by [Taha Ibourk-El-Idrissi](https://github.com/tahaelidrissi) — Software & Networks engineering student at INPT.*
