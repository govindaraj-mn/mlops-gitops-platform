from fastapi import FastAPI

app = FastAPI(title="ML Inference Service")


@app.get("/health")
def health():
    return {"status": "healthy"}


@app.post("/predict")
def predict(payload: dict):
    return {
        "prediction": "example",
        "input": payload,
    }