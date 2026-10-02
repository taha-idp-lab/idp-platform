from fastapi.testclient import TestClient

from app.main import SERVICE_NAME, app

client = TestClient(app)


def test_root_returns_service_name():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json()["service"] == SERVICE_NAME


def test_health_is_ok():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_metrics_are_exposed():
    client.get("/")  # generate at least one request
    response = client.get("/metrics")
    assert response.status_code == 200
    assert "http_requests_total" in response.text
