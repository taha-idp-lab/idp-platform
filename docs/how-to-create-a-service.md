# How to create a new service

This is the **golden path** for creating a new microservice on the Internal Developer Platform.
It takes **about 10 seconds** and requires no ticket to the platform team.

## 1. Open the template

In Backstage, go to **Create** → **FastAPI Service** → **Choose**.

<!-- screenshot: images/template-form.png -->

## 2. Fill in the form

| Field | Rules | Example |
|---|---|---|
| Service name | lowercase letters, digits, single dashes, max 40 chars | `orders-api` |
| Description | one sentence, max 120 chars | `Manages customer orders` |
| Owner team | a Group from the catalog | `team-backend` |

The name becomes the GitHub repository name and the catalog entity name, so it must be unique.

## 3. Create

Backstage runs four steps:

1. **Generate code from skeleton** — application code, tests, Dockerfile, Helm chart, CI, docs
2. **Create GitHub repository** — `taha-idp-lab/<name>` (public, branch `main`), with write access for the owner team
3. **Wait for GitHub to index the repository** — a few seconds, so the next step can read the new files
4. **Register in the catalog** — owned by your team, part of the `idp-demo` system

<!-- screenshot: images/template-run.png -->

At the end, two buttons open the new **repository** and its **catalog page**.

## 4. What you get

| Path | Purpose |
|---|---|
| `app/main.py` | FastAPI app exposing `/`, `/health` and `/metrics` |
| `tests/test_main.py` | pytest tests (passing out of the box) |
| `requirements.txt` / `requirements-dev.txt` | Pinned runtime and dev dependencies |
| `ruff.toml` | Shared lint rules |
| `Dockerfile` | Slim image, latest security updates, non-root user |
| `chart/` | Helm chart: liveness/readiness probes, resource limits, ingress |
| `.github/workflows/ci.yaml` | CI: lint, tests, build, Trivy scan, push to GHCR |
| `.github/CODEOWNERS` | Reviews automatically requested from the owner team |
| `mkdocs.yml` + `docs/` | TechDocs: overview and runbook, shown in Backstage |
| `catalog-info.yaml` | Backstage descriptor (owner, system, docs) |

From the very first push:

- the **CI** runs lint and tests, builds the image, scans it with **Trivy** and publishes it to `ghcr.io/taha-idp-lab/<name>` (tags: commit SHA and `latest`);
- the **owner team** has write access and is automatically requested as reviewer on pull requests;
- the **documentation** is available in the service's *Docs* tab in Backstage.

<!-- screenshot: images/catalog-orders-api.png -->

## 5. Start coding

```bash
git clone https://github.com/taha-idp-lab/<name>.git && cd <name>
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements-dev.txt
pytest
ruff check . && ruff format --check .
uvicorn app.main:app --reload   # http://localhost:8000/docs
```

## Troubleshooting

| Problem | Meaning | Fix |
|---|---|---|
| The form rejects the name | It doesn't match the naming rules | Use lowercase letters, digits and single dashes |
| `Repository creation failed … name already exists` | A repo with this name already exists | Pick another name, or remove the old service first |
| `Resource not accessible by integration` | The GitHub App lacks a permission | Platform team: check the App's permissions |
| `Register in the catalog` fails with `400 Bad Request` | GitHub wasn't ready to serve the new files yet | Register it manually via **Register Existing Component** with its `catalog-info.yaml` URL |
| CI fails at *Scan image with Trivy* | A fixable CRITICAL/HIGH vulnerability was found | Update the dependency, or rebuild to pick up the latest base image fixes |
| My service is missing from the Catalog | The default filter is **Owned** (only your teams' services) | Click **All** in the left panel |
| The *Docs* tab takes a while | Docs are built on first view | Wait 1–3 minutes the first time |

## Removing a service

Order matters:

1. **Backstage**: service page → ⋮ → **Unregister entity** → **Unregister Location**
   (*Delete Entity* is not enough: the entity comes back at the next catalog refresh.)
2. **GitHub**: repository → Settings → **Delete this repository**
3. **GHCR**: organization → **Packages** → the package → Package settings → **Delete this package**

Deleting the repository first leaves an orphan entity in the catalog with refresh errors.

> Tip: prefix throwaway services with `test-`.
