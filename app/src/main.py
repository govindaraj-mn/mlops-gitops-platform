from fastapi import FastAPI
from prometheus_client import Counter, generate_latest, CONTENT_TYPE_LATEST
from fastapi.responses import Response

app = FastAPI(title="ML Inference Service")

REQUEST_COUNT = Counter(
    "ml_inference_requests_total",
    "Total number of requests received by the inference service",
)


@app.get("/health")
def health():
    return {"status": "healthy", "version": "phase-2-e2e-test"}


@app.post("/predict")
def predict(payload: dict):
    REQUEST_COUNT.inc()

    return {
        "prediction": "example",
        "input": payload,
    }


@app.get("/metrics")
def metrics():
    return Response(
        generate_latest(),
        media_type=CONTENT_TYPE_LATEST,
    )