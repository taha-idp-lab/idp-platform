# ${{ values.name }}

${{ values.description }}

**Owner:** `${{ values.owner }}` · **System:** `idp-demo`

## Endpoints

| Method | Path | Description |
|---|---|---|
| GET | `/` | Service name and greeting |
| GET | `/health` | Health check (used by Kubernetes probes) |
| GET | `/metrics` | Prometheus metrics |
| GET | `/docs` | Interactive API docs (Swagger UI) |

## Local development

```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements-dev.txt
uvicorn app.main:app --reload    # http://localhost:8000/docs
pytest
ruff check . && ruff format --check .
```

## CI/CD

Every push runs the **CI** workflow (`.github/workflows/ci.yaml`):

1. Lint (`ruff`) and tests (`pytest`)
2. Docker image build
3. Security scan with **Trivy** — the pipeline fails on fixable CRITICAL/HIGH vulnerabilities
4. Push to `ghcr.io/taha-idp-lab/${{ values.name }}` (branch `main` only), tagged with the commit SHA and `latest`

## Deployment

The Helm chart lives in `chart/`. Environment-specific values live in the
[`idp-gitops`](https://github.com/taha-idp-lab/idp-gitops) repository.
