import logging
from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from pydantic import BaseModel
from typing import List, Dict, Optional, Any
from services.ocr_service import extract_lab_data_from_image
from services.ml_service import ml_engine
from services import statistics_service

# Logging setup
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("woundify-ai")

app = FastAPI(
    title="Woundify AI Engine",
    description="Microbiology OCR, Bacterial Pattern Recognition, and Statistical Analysis APIs",
    version="1.0.0"
)

# Request Models
class PredictionRequest(BaseModel):
    gram_stain: str  # GRAM_POSITIVE or GRAM_NEGATIVE
    shape: str       # COCCUS or BACILLUS
    imvic_indole: str  # POSITIVE or NEGATIVE
    imvic_methyl_red: str  # POSITIVE or NEGATIVE
    imvic_voges_proskauer: str  # POSITIVE or NEGATIVE
    imvic_citrate: str  # POSITIVE or NEGATIVE
    patient_age: int
    diabetes_type: str  # TYPE_1, TYPE_2, etc.
    hba1c: Optional[float] = None
    macconkey: str = "NON_LACTOSE_FERMENTER"  # LACTOSE_FERMENTER or NON_LACTOSE_FERMENTER
    colony_texture: Optional[str] = None
    colony_size: Optional[str] = None
    no_significant_growth: bool = False
    h2s: str = "NEGATIVE"  # POSITIVE or NEGATIVE
    motil: str = "NEGATIVE"  # POSITIVE or NEGATIVE
    urease: str = "NEGATIVE"  # POSITIVE or NEGATIVE
    emb: int = 0  # 0=Colorless, 1=Merah Muda, 2=Hijau Metalik (green sheen)
    tsi: int = 3  # 0=Acid/Acid+Gas, 1=Acid/Acid no gas, 2=Acid/Alkali+H2S, 3=Alkali/Alkali
    nas: str = "NEGATIVE"  # POSITIVE (tumbuh baik) or NEGATIVE (tidak tumbuh)

class StatisticsDescriptiveRequest(BaseModel):
    data: List[float]

class StatisticsNormalityRequest(BaseModel):
    data: List[float]

class StatisticsCorrelationRequest(BaseModel):
    x: List[float]
    y: List[float]

class StatisticsLinearRegressionRequest(BaseModel):
    x: List[float]
    y: List[float]

class StatisticsLogisticRegressionRequest(BaseModel):
    X: List[List[float]]
    y: List[int]

class StatisticsTTestRequest(BaseModel):
    group1: List[float]
    group2: List[float]
    paired: bool = False

class StatisticsReliabilityRequest(BaseModel):
    matrix: List[List[float]]  # dimensions: [respondents, items]

class StatisticsValidityRequest(BaseModel):
    matrix: List[List[float]]  # dimensions: [respondents, items]

@app.get("/")
def read_root():
    return {
        "app": "Woundify AI Engine",
        "status": "healthy",
        "version": "1.0.0"
    }

# ----------------- OCR ENDPOINT -----------------
@app.post("/api/ocr")
async def perform_ocr(file: UploadFile = File(...)):
    try:
        content = await file.read()
        logger.info(f"Received OCR request for file: {file.filename}")
        parsed_data = extract_lab_data_from_image(content, file.filename)
        return parsed_data
    except Exception as e:
        logger.error(f"OCR execution failed: {str(e)}")
        raise HTTPException(status_code=500, detail=f"OCR error: {str(e)}")

# ----------------- PREDICTION ENDPOINT -----------------
@app.post("/api/predict")
def predict_bacterial_wound_profile(req: PredictionRequest):
    try:
        # If the culture showed no significant growth, don't force a classification
        # into one of the 7 trained pathogen classes — that was producing false positives
        # on healed wounds / normal skin flora swabs.
        if req.no_significant_growth:
            return {
                "predicted_bacteria": "Tidak ada pertumbuhan bermakna (No Significant Growth)",
                "confidence_score": 1.0,
                "differential_diagnosis": [],
                "prediction_reasoning": ["Tidak ditemukan koloni bakteri pada media kultur"],
                "low_confidence": False,
                "infection_risk_level": "LOW",
                "chronic_risk_level": "LOW",
                "complication_risk_level": "LOW",
                "antibiotic_resistance": {
                    "resistant_drugs": [],
                    "susceptible_drugs": []
                },
                "recommendations": "Tidak ditemukan pertumbuhan bakteri bermakna. Kemungkinan flora normal kulit atau luka sudah dalam fase penyembuhan. Tetap lakukan evaluasi klinis bila ada tanda infeksi (nyeri, kemerahan, nanah).",
                "disclaimer": "Alat bantu keputusan klinis, bukan diagnosis. Konfirmasi dengan kultur laboratorium."
            }

        # 1. Bacterial identification using RandomForest, with differential + reasoning
        prediction = ml_engine.predict_bacteria(
            req.gram_stain,
            req.shape,
            req.imvic_indole,
            req.imvic_methyl_red,
            req.imvic_voges_proskauer,
            req.imvic_citrate,
            req.h2s,
            req.motil,
            req.urease,
            req.macconkey,
            req.emb,
            req.tsi,
            req.nas
        )
        predicted_bacteria = prediction["predicted_bacteria"]
        confidence = prediction["confidence"]

        # 2. Risk levels inference
        risks = ml_engine.predict_risks(
            predicted_bacteria,
            req.patient_age,
            req.diabetes_type,
            req.hba1c
        )

        # 3. Resistance profile
        resistance = ml_engine.predict_antibiotic_resistance(predicted_bacteria)

        return {
            "predicted_bacteria": predicted_bacteria,
            "confidence_score": confidence,
            "differential_diagnosis": prediction["differential"],
            "prediction_reasoning": prediction["reasoning"],
            "low_confidence": prediction["low_confidence"],
            "infection_risk_level": risks["infection_risk"],
            "chronic_risk_level": risks["chronic_risk"],
            "complication_risk_level": risks["complication_risk"],
            "antibiotic_resistance": {
                "resistant_drugs": resistance["resistant"],
                "susceptible_drugs": resistance["susceptible"]
            },
            "recommendations": resistance["recommendation"],
            "disclaimer": "Alat bantu keputusan klinis, bukan diagnosis. Konfirmasi dengan kultur laboratorium."
        }
    except Exception as e:
        logger.error(f"Prediction failed: {str(e)}")
        raise HTTPException(status_code=500, detail=f"ML Prediction error: {str(e)}")

# ----------------- AI PERFORMANCE EVALUATION -----------------
@app.get("/api/ai/evaluation")
def evaluate_ai_model():
    try:
        return ml_engine.evaluate_model_performance()
    except Exception as e:
        logger.error(f"Model evaluation failed: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Evaluation error: {str(e)}")

# ----------------- STATISTICAL ANALYSIS ENDPOINTS -----------------
@app.post("/api/statistics/descriptive")
def descriptive_stats(req: StatisticsDescriptiveRequest):
    return statistics_service.calculate_descriptive_stats(req.data)

@app.post("/api/statistics/normality")
def normality_test(req: StatisticsNormalityRequest):
    res = statistics_service.calculate_normality_shapiro(req.data)
    if "error" in res:
        raise HTTPException(status_code=400, detail=res["error"])
    return res

@app.post("/api/statistics/correlation")
def correlation_test(req: StatisticsCorrelationRequest):
    res = statistics_service.calculate_pearson_correlation(req.x, req.y)
    if "error" in res:
        raise HTTPException(status_code=400, detail=res["error"])
    return res

@app.post("/api/statistics/regression-linear")
def linear_regression(req: StatisticsLinearRegressionRequest):
    res = statistics_service.calculate_linear_regression(req.x, req.y)
    if "error" in res:
        raise HTTPException(status_code=400, detail=res["error"])
    return res

@app.post("/api/statistics/regression-logistic")
def logistic_regression(req: StatisticsLogisticRegressionRequest):
    res = statistics_service.calculate_logistic_regression(req.X, req.y)
    if "error" in res:
        raise HTTPException(status_code=400, detail=res["error"])
    return res

@app.post("/api/statistics/t-test")
def t_test(req: StatisticsTTestRequest):
    res = statistics_service.calculate_t_test(req.group1, req.group2, req.paired)
    if "error" in res:
        raise HTTPException(status_code=400, detail=res["error"])
    return res

@app.post("/api/statistics/reliability")
def reliability_test(req: StatisticsReliabilityRequest):
    res = statistics_service.calculate_cronbach_alpha(req.matrix)
    if "error" in res:
        raise HTTPException(status_code=400, detail=res["error"])
    return res

@app.post("/api/statistics/validity")
def validity_test(req: StatisticsValidityRequest):
    res = statistics_service.calculate_pearson_validity(req.matrix)
    if "error" in res:
        raise HTTPException(status_code=400, detail=res["error"])
    return res

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
