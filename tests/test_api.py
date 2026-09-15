import sys
from urllib import response

sys.path.insert(0, "app")

from fastapi.testclient import TestClient
from src.main import app


client = TestClient(app)


def test_health():
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json()["status"] == "healthy"
    assert response.json()["version"] == "phase-2-e2e-test"


def test_predict():
    payload = {"feature": "test"}

    response = client.post("/predict", json=payload)

    assert response.status_code == 200
    assert response.json()["prediction"] == "example"
    assert response.json()["input"] == payload


def test_metrics():
    response = client.get("/metrics")

    assert response.status_code == 200
    assert "ml_inference_requests_total" in response.text