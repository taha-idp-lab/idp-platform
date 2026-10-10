# Engineering Journal

## 2026-09-30 — Week 0 + start of Week 1
- WSL2 environment: `.wslconfig` (8 GB RAM, `networkingMode=mirrored` to fix network timeouts to the npm registry).
- Docker Desktop: disabled Resource Saver (otherwise the Docker CLI in WSL stops responding).
- `create-app` failed: `@yarnpkg/core@4.9.2` (published 2026-09-24) depends on a `got` patch file that doesn't exist.
  Workaround: `resolutions` → `@yarnpkg/core: 4.9.1`. Remove once a fixed version is released.
- ✅ Backstage running locally (http://localhost:3000, guest auth).

## 2026-10-01 — Phase 1: GitHub sign-in
- GitHub OAuth App (org `taha-idp-lab`), callback `http://localhost:7007/api/auth/github/handler/frame`.
- Backend: `plugin-auth-backend-module-github-provider`. Frontend (new frontend system): `SignInPageBlueprint` module.
- Resolver `usernameMatchingUserEntityName` → `User` entity in `catalog/org.yaml` (+ `platform-team` group).
- Secrets in `backstage/.env` (git-ignored), loaded by `yarn dev`.
- Gotchas: module installed but not registered in `index.ts`; typo in env var name; Yarn 4 scripts don't run in bash (`set` unknown) → wrap with `bash -c`.

## 2026-10-01 — Phase 1: PostgreSQL
- Replaced in-memory SQLite with PostgreSQL 17 (Docker Compose, named volume, healthcheck), host port 5433.
- Credentials in `.env`; `yarn dev` starts the DB (`docker compose up -d --wait`) before Backstage.
- Verified: 13 `backstage_plugin_*` databases created (one per plugin).
- Gotchas:
  - `database:` mis-indented in `app-config.yaml` → Backstage silently fell back to in-memory SQLite (no error!).
  - A Windows PostgreSQL already listens on 5432 and is reachable from WSL in mirrored mode → container moved to 5433.
  - After `wsl --shutdown`, Docker Desktop's WSL integration timed out (0x8007274c). Fix: quit Docker Desktop → `wsl --shutdown` → open Ubuntu → restart Docker Desktop.

## 2026-10-01 — Phase 1: GitHub integration
- GitHub App `idpbackstagetaha` created with `backstage-cli create-github-app taha-idp-lab`, installed on the org (all repos).
- Config: `apps: - $include: <credentials file>` (file git-ignored).
- `allowedInstallationOwners` lives inside the credentials file: `$include` can't have sibling keys.
- Why an App over a PAT: dedicated identity, scoped to one org, short-lived tokens, not tied to a person.
- Verified by registering `idp-platform` in the catalog via its `catalog-info.yaml` (owner `group:platform-team`).

## ✅ Phase 1 closed
Backstage runs locally with GitHub sign-in, PostgreSQL persistence, secrets in env/ignored files, and a GitHub App integration.

## 2026-10-01 — Phase 2, step 1: catalog structure
- Added `team-backend` group (future owner of generated services) and `idp-demo` System (`catalog/systems.yaml`).
- `idp-platform` and `idp-gitops` are both `partOf` `idp-demo`, owned by `platform-team`.
- Note: `User`/`Group` need explicit `rules: allow` on a catalog location; `System` is allowed by default.
- Note: Catalog Graph page needs a root entity (`rootEntityRefs[]=...`), otherwise it renders empty.

## 2026-10-02 — Phase 2, step 2: FastAPI skeleton
- `templates/fastapi-service/skeleton/`: FastAPI app (`/`, `/health`), pytest tests, pinned deps (prod vs dev), non-root Dockerfile, `catalog-info.yaml` (owner + `system: idp-demo`), README.
- Placeholders: `${{ values.name }}`, `${{ values.description }}`, `${{ values.owner }}`.
- Tested locally by rendering placeholders with `sed`: 2 tests passed, `/docs` OK.
- Note: `httpx2` instead of `httpx` for FastAPI's TestClient (httpx is deprecated there).

## 2026-10-02 — Phase 2, steps 3–4: first template run 🎉
- `templates/fastapi-service/template.yaml`: form (name with regex, description, OwnerPicker on Groups) → `fetch:template` → `publish:github` → `catalog:register`.
- `publish:github` defaults are private repo + branch protection, which fails on a free GitHub org → set `repoVisibility: public`, `protectDefaultBranch: false` (to revisit in Phase 6).
- First run failed: `Resource not accessible by integration` → GitHub App needed **Administration: Read & write**; new permissions must be accepted on the org installation, then restart Backstage (cached app token).
- ✅ `orders-api` created in `taha-idp-lab`, registered in the catalog (owner `team-backend`, system `idp-demo`), cloned and `pytest` → 2 passed.
- ⏱️ Time from form submission to registered repo: **under 10 seconds**.

## 2026-10-02 — Phase 2, step 5: robustness
- Form validation: regex `^[a-z0-9]+(-[a-z0-9]+)*$` + `maxLength: 40` reject uppercase, `_`, leading/trailing/double dashes. Valid for GitHub repo, Backstage entity and future K8s namespace names.
- Re-running with an existing name: fails at `publish:github` ("name already exists"), `register` skipped, existing repo untouched.
- Scaffolder runs steps in order and stops at the first failure, but does NOT roll back previous steps → cleanup procedure needed.
- Cleanup procedure (tested with `test-cleanup`): 1) Backstage: entity ⋮ → Unregister entity → **Unregister Location**; 2) GitHub: delete the repo. Order matters (otherwise orphan entity with refresh errors).
- Convention: prefix throwaway services with `test-`.

## ✅ Phase 2 closed — v1
Deliverable reached: one click in Backstage creates a repository from the FastAPI skeleton and registers it in the catalog (owner team + `idp-demo` system), in about 10 seconds.
- Docs: `docs/how-to-create-a-service.md` (developer golden path, troubleshooting, cleanup).
- Pending: screenshots (placeholders left as HTML comments).
- Next (Phase 3): production-ready skeleton — CI (lint, tests, build, Trivy, push to GHCR), Helm chart, `/metrics`, TechDocs, CODEOWNERS.

## 2026-10-02 — Phase 3, steps 1–2: metrics, lint, CI
- Skeleton: `/metrics` (prometheus-fastapi-instrumentator), `ruff.toml` (E, F, I, B, UP), 3 tests.
- CI (`.github/workflows/ci.yaml`): lint + tests → build → Trivy (CRITICAL/HIGH, ignore-unfixed) → push to GHCR on `main` only. Actions pinned by commit SHA; least-privilege permissions (`packages: write` only on the build job).
- `${{ }}` conflict with Backstage templating → `copyWithoutTemplating: [.github/workflows/*]` in `fetch:template`.
- GitHub App needed **Workflows: Read & write** to push workflow files.
- 🛡️ First run of `test-ci` was BLOCKED by Trivy: CVE-2026-103111 (HIGH) in `libpcre2` from the Debian base image (fix available, base image not rebuilt yet). Fix: `apt-get upgrade` in the Dockerfile. Trade-off: less reproducible builds, but security fixes applied at build time.
- ✅ `test-ci`: CI green, image published to `ghcr.io/taha-idp-lab/test-ci`.

## 2026-10-05 — Phase 3, step 3: Helm chart
- `skeleton/chart/`: Deployment (liveness/readiness on `/health`, requests/limits, non-root UID 1000, no privilege escalation, drop ALL caps), Service (80 → 8000), Ingress (disabled by default).
- Labels in `_helpers.tpl`; selector labels kept minimal (immutable after first deploy); `backstage.io/kubernetes-id` on all objects for the Phase 5 Kubernetes plugin.
- Backstage renders `Chart.yaml`/`values.yaml`; `chart/templates/*` added to `copyWithoutTemplating` (Helm `{{ }}`).
- Dockerfile: explicit `--uid 1000` to match `runAsUser`.
- Validated with `helm lint` + `helm template` (no cluster needed).

## 2026-10-05 — Phase 3, steps 4–5: TechDocs, CODEOWNERS
- TechDocs: `mkdocs.yml` + `docs/index.md` + `docs/runbook.md` in the skeleton, `backstage.io/techdocs-ref: dir:.` annotation. Built on demand by Backstage (generator `runIn: docker`).
- CODEOWNERS: `* @taha-idp-lab/${{ values.owner | parseEntityRef | pick('name') }}`.
- GitHub teams `platform-team` / `team-backend` created with the same names as the Backstage Groups.
- `publish:github` → `collaborators: [{ team: <owner>, access: push }]` (write access is required for CODEOWNERS to be valid). Failures here are only logged as warnings ("Skipping push access…"), not errors.
- GitHub App: + Organization **Members: Read-only**.
- Ownership is declared once (form) and enforced everywhere: catalog, repo permissions, review requests.

## ✅ Phase 3 closed
Every generated service now ships with: lint + tests, CI (build, Trivy scan, push to GHCR), Helm chart (probes, limits, non-root), `/metrics`, TechDocs + runbook, CODEOWNERS.
Next (Phase 4): kind cluster + ArgoCD + ApplicationSet → form-to-running-pod without manual steps.

## 2026-10-05 — Phase 4, steps 3–4: ApplicationSet + first GitOps deployment 🎉
- `idp-gitops/bootstrap/applicationset-dev.yaml`: Git directory generator on `apps/*` → one Application `<service>-dev` per folder, namespace = service name (`CreateNamespace=true`), automated sync with `prune` + `selfHeal`.
- Multi-source: Helm chart from the service repo (`chart/`), values from `idp-gitops` (`$values/apps/<service>/values-dev.yaml`).
- Only manual `kubectl apply` of the project: the ApplicationSet itself (bootstrap).
- `idp-gitops` made public so ArgoCD can read it (production alternative: org-wide repo credential template).
- ✅ `test-docs` deployed by merging a PR that adds `apps/test-docs/values-dev.yaml` (image tag = commit SHA, not `latest`, for traceability and rollback). App Synced + Healthy, pod 1/1 Ready.

## 2026-10-10 — Phase 4, step 5: template opens the GitOps PR 🎉
- Template split into two workspaces: `service/` → `publish:github`, `gitops/` (from `gitops-skeleton/`) → `publish:github:pull-request` into `idp-gitops` at `apps/<name>/`.
- Initial `values-dev.yaml` uses `tag: latest` + `pullPolicy: Always`: the image doesn't exist yet when the template runs (first CI ~3 min).
- GitHub App: + Pull requests: Read & write.
- `teamReviewers` failed: "Reviews may only be requested from collaborators" → platform-team had no access to idp-gitops. Fix: team access (Maintain) + CODEOWNERS on idp-gitops. The PR was still created (the action only logs reviewer errors).
- ✅ `test-gitops`: form → repo + CI + catalog + deployment PR → merge → ArgoCD → pod Running. The ApplicationSet now manages 2 apps.
