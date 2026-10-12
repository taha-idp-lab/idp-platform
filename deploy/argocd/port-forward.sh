#!/usr/bin/env bash
# Expose the ArgoCD API/UI on http://localhost:8081 for local use (UI + Backstage plugin).
# `kubectl port-forward` exits on the first broken stream, so restart it in a loop.
set -u
while true; do
  kubectl port-forward svc/argocd-server -n argocd 8081:80
  echo "port-forward stopped, restarting in 1s (Ctrl+C twice to quit)" >&2
  sleep 1
done
