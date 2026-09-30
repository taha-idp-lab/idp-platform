# Engineering Journal

## 2026-09-30 — Week 0 + start of Week 1
- WSL2 environment: `.wslconfig` (8 GB RAM, `networkingMode=mirrored` to fix network timeouts to the npm registry).
- Docker Desktop: disabled Resource Saver (otherwise the Docker CLI in WSL stops responding).
- `create-app` failed: `@yarnpkg/core@4.9.2` (published 2026-09-24) depends on a `got` patch file that doesn't exist.
  Workaround: `resolutions` → `@yarnpkg/core: 4.9.1`. Remove once a fixed version is released.
- ✅ Backstage running locally (http://localhost:3000, guest auth).
