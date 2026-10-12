#!/usr/bin/env bash
# Expose Grafana on http://localhost:3001 (3000 is used by Backstage).
# `kubectl port-forward` exits on the first broken stream, so restart it in a loop.
set -u
# WebSocket port-forward (default since kubectl 1.31) drops under parallel requests; use SPDY
export KUBECTL_PORT_FORWARD_WEBSOCKETS=false
while true; do
  kubectl -n monitoring port-forward svc/monitoring-grafana 3001:80
  echo "port-forward stopped, restarting in 1s (Ctrl+C twice to quit)" >&2
  sleep 1
done
