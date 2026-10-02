from fastapi import FastAPI
from prometheus_fastapi_instrumentator import Instrumentator

SERVICE_NAME = "${{ values.name }}"

app = FastAPI(
    title=SERVICE_NAME,
    description="${{ values.description }}",
    version="0.1.0",
)

# Exposes Prometheus metrics (request count, latency, ...) on GET /metrics
Instrumentator().instrument(app).expose(app, include_in_schema=False)


@app.get("/")
def root() -> dict:
    return {"service": SERVICE_NAME, "message": "Hello from the Internal Developer Platform"}


@app.get("/health")
def health() -> dict:
    return {"status": "ok"}
