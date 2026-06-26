"""
main.py  –  Smart Farm Advisor API v2.0
Run: uvicorn backend.main:app --reload --port 8000
"""
from __future__ import annotations
import json, os
from typing import Optional
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import Response
from pydantic import BaseModel, Field

from backend.predictor        import predict, why_crop
from backend.fertilizer       import get_fertilizer_plan
from backend.water_check      import check_water
from backend.translator       import generate_summary
from backend.market_price     import predict_price
from backend.disease_detection import detect_disease
from backend.weather_service  import get_weather, DISTRICT_COORDS
from backend.report_generator import generate_pdf_report
from backend.database         import (
    create_farmer, get_farmer, list_farmers,
    save_recommendation, get_history,
    save_disease_log, save_market_query
)

# ── Cache ─────────────────────────────────────────────────────────────────────
CACHE_PATH = os.path.join(os.path.dirname(__file__), "..", "models", "cache.json")

def _load_cache():
    if os.path.exists(CACHE_PATH):
        try:
            with open(CACHE_PATH) as f: return json.load(f)
        except: pass
    return {}

def _save_cache(c):
    with open(CACHE_PATH, "w") as f: json.dump(c, f, ensure_ascii=False, indent=2)

_cache = _load_cache()

# ── App ───────────────────────────────────────────────────────────────────────
app = FastAPI(
    title="Smart Farm Advisor API",
    description="AI-powered Tamil Nadu farming assistant — v2.0",
    version="2.0.0",
)
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

# ── Schemas ───────────────────────────────────────────────────────────────────
class SoilWeatherInput(BaseModel):
    N: float = Field(..., ge=0, le=200)
    P: float = Field(..., ge=0, le=200)
    K: float = Field(..., ge=0, le=200)
    pH: float = Field(..., ge=3.5, le=9.5)
    temperature: float = Field(..., ge=5, le=50)
    humidity: float = Field(..., ge=5, le=100)
    rainfall: float = Field(..., ge=0, le=500)
    district: Optional[str] = None
    soil_type: Optional[str] = None
    farmer_id: Optional[int] = None

class FertilizerInput(BaseModel):
    crop: str
    budget_cap: Optional[float] = None
    acres: float = 1.0

class WaterInput(BaseModel):
    crop: str
    rainfall: float
    humidity: float

class SummaryInput(BaseModel):
    top_crop: str
    confidence: float
    water_advice: str
    fertilizer_plan: dict
    alternatives: Optional[list[str]] = None

class MarketInput(BaseModel):
    crop: str
    district: str
    month: int = Field(..., ge=1, le=12)
    farmer_id: Optional[int] = None

class FarmerCreate(BaseModel):
    name: str
    phone: str = ""
    district: str = ""
    village: str = ""
    acres: float = 1.0

class ReportInput(BaseModel):
    farmer_name: str
    district: str
    soil: dict
    weather: dict
    crop_result: dict
    fertilizer_result: dict
    water_result: dict
    summary: dict
    disease_result: Optional[dict] = None

# ── Root ──────────────────────────────────────────────────────────────────────
@app.get("/")
def root():
    return {"message": "Smart Farm Advisor API v2.0 🌾", "docs": "/docs"}

@app.get("/districts")
def districts():
    return {"districts": sorted(DISTRICT_COORDS.keys())}

# ── Crop Prediction ───────────────────────────────────────────────────────────
@app.post("/predict_crop")
def predict_crop(inp: SoilWeatherInput):
    key = f"{inp.N}_{inp.P}_{inp.K}_{inp.pH}_{inp.temperature}_{inp.humidity}_{inp.rainfall}"
    if key in _cache:
        return {**_cache[key], "cached": True}
    result = predict(N=inp.N, P=inp.P, K=inp.K, pH=inp.pH,
                     temperature=inp.temperature, humidity=inp.humidity, rainfall=inp.rainfall)
    _cache[key] = result
    _save_cache(_cache)
    return {**result, "cached": False}

# ── Fertilizer ────────────────────────────────────────────────────────────────
@app.post("/fertilizer_plan")
def fertilizer_plan(inp: FertilizerInput):
    return get_fertilizer_plan(crop=inp.crop, budget_cap=inp.budget_cap, acres=inp.acres)

# ── Water ─────────────────────────────────────────────────────────────────────
@app.post("/water_check")
def water_check(inp: WaterInput):
    return check_water(crop=inp.crop, rainfall=inp.rainfall, humidity=inp.humidity)

# ── Why crop ─────────────────────────────────────────────────────────────────
@app.get("/why/{crop}")
def why(crop: str):
    return {"crop": crop, "reason": why_crop(crop)}

# ── Summary ───────────────────────────────────────────────────────────────────
@app.post("/generate_summary")
def summary(inp: SummaryInput):
    return generate_summary(top_crop=inp.top_crop, confidence=inp.confidence,
                            water_advice=inp.water_advice, fertilizer_plan=inp.fertilizer_plan,
                            alternatives=inp.alternatives)

# ── Weather ───────────────────────────────────────────────────────────────────
@app.get("/weather/{district}")
def weather(district: str):
    return get_weather(district)

# ── Market Price ──────────────────────────────────────────────────────────────
@app.post("/market_price")
def market_price(inp: MarketInput):
    result = predict_price(crop=inp.crop, district=inp.district, month=inp.month)
    if inp.farmer_id:
        save_market_query(inp.farmer_id, inp.crop, inp.district,
                          inp.month, result["predicted_price"], result["recommendation"])
    return result

# ── Disease Detection ─────────────────────────────────────────────────────────
@app.post("/detect_disease")
async def detect(
    farmer_id: Optional[int] = None,
    file: UploadFile = File(...)
):
    print("Content-Type:", file.content_type)
    print("Filename:", file.filename)

    if not file.filename.lower().endswith((".jpg", ".jpeg", ".png")):
        raise HTTPException(
            status_code=400,
            detail="Please upload JPG or PNG image."
        )

    data = await file.read()
    result = detect_disease(data)

    if farmer_id and "error" not in result:
        save_disease_log(
            farmer_id,
            result["disease"],
            result["confidence"],
        )

    return result

# ── Full Advisory (single call for Flutter) ───────────────────────────────────
@app.post("/full_advisory")
def full_advisory(inp: SoilWeatherInput):
    """One-shot endpoint: crop + fertilizer + water + summary."""
    crop_r  = predict(N=inp.N, P=inp.P, K=inp.K, pH=inp.pH,
                      temperature=inp.temperature, humidity=inp.humidity, rainfall=inp.rainfall)
    best    = crop_r["best_crop"]
    fert_r  = get_fertilizer_plan(crop=best)
    water_r = check_water(crop=best, rainfall=inp.rainfall, humidity=inp.humidity)
    summ_r  = generate_summary(top_crop=best, confidence=crop_r["confidence"],
                               water_advice=water_r["advice"], fertilizer_plan=fert_r,
                               alternatives=crop_r["alternatives"])
    if inp.farmer_id:
        inputs = inp.model_dump()
        save_recommendation(inp.farmer_id, inputs, crop_r, fert_r, water_r, summ_r)

    return {"crop": crop_r, "fertilizer": fert_r, "water": water_r, "summary": summ_r}

# ── PDF Report ────────────────────────────────────────────────────────────────
@app.post("/generate_report")
def generate_report(inp: ReportInput):
    pdf_bytes = generate_pdf_report(
        farmer_name=inp.farmer_name, district=inp.district,
        soil=inp.soil, weather=inp.weather,
        crop_result=inp.crop_result, fertilizer_result=inp.fertilizer_result,
        water_result=inp.water_result, summary=inp.summary,
        disease_result=inp.disease_result,
    )
    return Response(content=pdf_bytes, media_type="application/pdf",
                    headers={"Content-Disposition": "attachment; filename=farm_report.pdf"})

# ── Farmer Management ─────────────────────────────────────────────────────────
@app.post("/farmer")
def create(inp: FarmerCreate):
    fid = create_farmer(inp.name, inp.phone, inp.district, inp.village, inp.acres)
    return {"farmer_id": fid, "message": "Farmer created"}

@app.get("/farmer/{farmer_id}")
def get_one(farmer_id: int):
    f = get_farmer(farmer_id)
    if not f: raise HTTPException(404, "Farmer not found")
    return f

@app.get("/farmers")
def all_farmers():
    return list_farmers()

@app.get("/history/{farmer_id}")
def history(farmer_id: int, limit: int = 20):
    return get_history(farmer_id, limit)

@app.get("/cache/clear")
def clear_cache():
    global _cache
    _cache = {}
    _save_cache(_cache)
    return {"message": "Cache cleared"}
