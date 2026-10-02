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

1. **Generate code from skeleton** — FastAPI app, tests, Dockerfile, `catalog-info.yaml`
2. **Create GitHub repository** — `taha-idp-lab/<name>` (public, branch `main`)
3. **Wait for GitHub to index the repository** — a few seconds, so the next step can read the new files
4. **Register in the catalog** — owned by your team, part of the `idp-demo` system

<!-- screenshot: images/template-run.png -->

At the end, two buttons open the new **repository** and its **catalog page**.

## 4. What you get

```
<name>/
├── app/main.py          # FastAPI app with / and /health
├── tests/test_main.py   # pytest tests (passing)
├── requirements.txt     # pinned runtime dependencies
├── requirements-dev.txt # + test dependencies
├── Dockerfile           # slim image, non-root user
├── catalog-info.yaml    # Backstage descriptor (owner, system)
└── README.md
```

<!-- screenshot: images/catalog-orders-api.png -->

Start coding:

```bash
git clone https://github.com/taha-idp-lab/<name>.git && cd <name>
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements-dev.txt
pytest
uvicorn app.main:app --reload   # http://localhost:8000/docs
```

## Troubleshooting

| Problem | Meaning | Fix |
|---|---|---|
| The form rejects the name | It doesn't match the naming rules | Use lowercase letters, digits and single dashes |
| `Repository creation failed … name already exists` | A repo with this name already exists | Pick another name, or remove the old service first |
| `Resource not accessible by integration` | The GitHub App lacks a permission | Platform team: check the App's **Administration** permission |
| `Register in the catalog` fails with `400 Bad Request` | GitHub wasn't ready to serve the new files yet | The repo exists: register it manually via **Register Existing Component** with its `catalog-info.yaml` URL |
| My service is missing from the Catalog | The default filter is **Owned** (only your teams' services) | Click **All** in the left panel |

## Removing a service

Order matters:

1. **Backstage**: service page → ⋮ → **Unregister entity** → **Unregister Location**
   (*Delete Entity* is not enough: the entity comes back at the next catalog refresh.)
2. **GitHub**: repository → Settings → **Delete this repository**

Deleting the repository first leaves an orphan entity in the catalog with refresh errors.

> Tip: prefix throwaway services with `test-`.
