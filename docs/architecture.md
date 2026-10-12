# Architecture

## Overview

```mermaid
flowchart LR
    Dev([Developer])

    subgraph Portal["Backstage (IDP portal)"]
        Tpl[Software Templates]
        Cat[Software Catalog]
        Plug[Plugins: K8s / ArgoCD / GH Actions / TechDocs]
    end

    subgraph GitHub["GitHub (taha-idp-lab org)"]
        SvcRepo[(Service repo<br/>code + Dockerfile + Helm chart + CI)]
        GitOpsRepo[(idp-gitops repo<br/>apps/*/values.yaml)]
        GHA[GitHub Actions<br/>lint · tests · build · Trivy]
        GHCR[(GHCR<br/>image registry)]
    end

    subgraph K8s["Kubernetes cluster (kind)"]
        Argo[ArgoCD + ApplicationSet]
        App[Service pods]
        Prom[Prometheus + Grafana]
    end

    Dev -->|1. fills the form| Tpl
    Tpl -->|2. creates repo| SvcRepo
    Tpl -->|3. opens PR| GitOpsRepo
    Tpl -->|4. registers| Cat
    SvcRepo -->|push| GHA
    GHA -->|image| GHCR
    GitOpsRepo -->|watched by| Argo
    Argo -->|deploys| App
    GHCR -->|pull| App
    App -->|/metrics| Prom
    Plug -.->|reads state| Argo
    Plug -.->|reads state| App
    Plug -.->|reads runs| GHA
    Dev -->|5. checks| Cat
```

## Golden path

```mermaid
sequenceDiagram
    actor Dev as Developer
    participant BS as Backstage
    participant GH as GitHub
    participant CI as GitHub Actions
    participant GO as GitOps repo
    participant Argo as ArgoCD
    participant K8s as Kubernetes

    Dev->>BS: Picks "FastAPI Service", enters name / team
    BS->>GH: Creates repo from skeleton
    BS->>GO: Opens PR (apps/my-service/)
    BS->>BS: Registers service in catalog
    GH->>CI: Triggers pipeline
    CI->>CI: Lint · Tests · Build · Trivy scan
    CI->>GH: Pushes image to GHCR
    Dev->>GO: Merges PR
    Argo->>GO: Detects new folder
    Argo->>K8s: Deploys service
    Dev->>BS: Checks pods, ArgoCD sync, CI, metrics
```

**Target:** under 5 minutes from click to running service.

## Key design decisions

| Decision | Why |
|---|---|
| Dedicated GitHub org | Generated repos stay isolated from personal profile |
| GitOps with ArgoCD ApplicationSet | Every `apps/<service>/` folder becomes an Application — no manual config per service |
| Helm chart lives in the service repo, values in `idp-gitops` | Service owns its packaging; platform owns environment config |
| Secrets in environment variables only | Nothing sensitive ever committed |
| Backstage reads ArgoCD through its backend proxy, with a read-only local account | The token never reaches the browser; Backstage can see deployments but never sync or delete them |
| Read-only Kubernetes ServiceAccount for Backstage (no Secrets) | Developers see their pods without cluster credentials; least privilege |
| Each service's Helm chart ships its own `ServiceMonitor` | Monitoring is self-service: no central list of Prometheus targets to maintain |
| One generic Grafana dashboard, generated from code | New services appear in the dashboard automatically; changes are reviewed in Git |
