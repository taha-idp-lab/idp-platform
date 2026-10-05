#!/usr/bin/env bash
# Gives every kind node read access to GHCR, so pods can pull private images
# of the taha-idp-lab organization without per-namespace imagePullSecrets.
# Credentials file (NOT in git): ~/.idp/kind-registry-config.json
set -euo pipefail
CONFIG="${HOME}/.idp/kind-registry-config.json"
[ -f "$CONFIG" ] || { echo "Missing $CONFIG" >&2; exit 1; }
for node in $(kind get nodes --name idp); do
  docker cp "$CONFIG" "${node}:/var/lib/kubelet/config.json"
  docker exec "$node" systemctl restart kubelet.service
  echo "✓ registry credentials installed on ${node}"
done
