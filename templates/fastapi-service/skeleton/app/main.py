from fastapi import FastAPI

SERVICE_NAME = "${{ values.name }}"

app = FastAPI(
    title=SERVICE_NAME,
    description="${{ values.description }}",
    version="0.1.0",
)


@app.get("/")
def root() -> dict:
    return {"service": SERVICE_NAME, "message": "Hello from the Internal Developer Platform"}


@app.get("/health")
def health() -> dict:
    return {"status": "ok"}
