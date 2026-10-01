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
