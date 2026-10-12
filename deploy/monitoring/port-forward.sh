#!/usr/bin/env bash
# Expose Grafana on http://localhost:3001 (3000 is used by Backstage).
# `kubectl port-forward` exits on the first broken stream, so restart it in a loop.
set -u
while true; do
  kubectl -n monitoring port-forward svc/monitoring-grafana 3001:80
  echo "port-forward stopped, restarting in 1s (Ctrl+C twice to quit)" >&2
  sleep 1
done
