"""
predictor.py
Loads the trained Random Forest model and provides crop predictions
with confidence scores, feature importance, and alternative suggestions.
"""

import os
import pickle
import numpy as np

BASE_DIR   = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(BASE_DIR, "..", "models", "model.pkl")
ENC_PATH   = os.path.join(BASE_DIR, "..", "models", "label_encoder.pkl")
FEAT_PATH  = os.path.join(BASE_DIR, "..", "models", "feature_names.pkl")

# ── Plain-language crop descriptions ─────────────────────────────────────────
CROP_REASONS = {
    "Rice":      "High N content and adequate rainfall make paddy cultivation ideal.",
    "Groundnut": "Moderate phosphorus and low rainfall suit groundnut well.",
    "Maize":     "Balanced NPK and warm temperature favour maize growth.",
    "Millet":    "Drought-tolerant crop suited to low-rainfall, well-drained soils.",
    "Wheat":     "Cooler temperature and moderate moisture favour wheat yield.",
    "Sugarcane": "High N, K, and moisture availability suit sugarcane.",
    "Cotton":    "Neutral pH and warm, dry conditions are ideal for cotton.",
    "Banana":    "High K content and humidity suit banana plantation.",
    "Coconut":   "Coastal-type soil moisture and K levels suit coconut palm.",
}

# ── Low-rainfall alternative map ─────────────────────────────────────────────
LOW_RAIN_ALTERNATIVES = {
    "Rice":      ["Millet", "Groundnut"],
    "Sugarcane": ["Maize", "Cotton"],
    "Banana":    ["Coconut", "Maize"],
    "Maize":     ["Millet", "Groundnut"],
    "Wheat":     ["Millet", "Groundnut"],
    "Cotton":    ["Millet", "Groundnut"],
    "Groundnut": ["Millet"],
    "Coconut":   ["Millet", "Groundnut"],
    "Millet":    ["Millet"],  # already drought-tolerant
}


def _load():
    with open(MODEL_PATH, "rb") as f:
        clf = pickle.load(f)
    with open(ENC_PATH, "rb") as f:
        le = pickle.load(f)
    with open(FEAT_PATH, "rb") as f:
        features = pickle.load(f)
    return clf, le, features


_clf, _le, _features = _load()
_importances = _clf.feature_importances_


def predict(
    N: float, P: float, K: float,
    pH: float, temperature: float,
    humidity: float, rainfall: float,
) -> dict:
    """
    Returns prediction dict with top-3 crops, confidence, features, explanation.
    """
    x = np.array([[N, P, K, pH, temperature, humidity, rainfall]])
    proba = _clf.predict_proba(x)[0]

    # Top-3 crops by probability
    top3_idx  = np.argsort(proba)[::-1][:3]
    top3_crops = [
        {"crop": _le.classes_[i], "confidence": round(float(proba[i]), 4)}
        for i in top3_idx
    ]

    best_crop = top3_crops[0]["crop"]
    best_conf = top3_crops[0]["confidence"]

    # Top-3 feature importances
    feat_imp = sorted(
        zip(_features, _importances),
        key=lambda x: -x[1]
    )[:3]
    top_factors = [
        {"feature": f, "importance": round(float(v), 4)}
        for f, v in feat_imp
    ]

    # Explanation text
    explanation = (
        f"{CROP_REASONS.get(best_crop, 'Soil and weather conditions align well.')} "
        f"The model is {best_conf * 100:.1f}% confident. "
        f"Key drivers: {', '.join(f['feature'] for f in top_factors)}."
    )

    # Rainfall-drop alternatives
    alternatives = LOW_RAIN_ALTERNATIVES.get(best_crop, ["Millet", "Groundnut"])

    return {
        "top_crops":    top3_crops,
        "best_crop":    best_crop,
        "confidence":   best_conf,
        "top_factors":  top_factors,
        "alternatives": alternatives,
        "explanation":  explanation,
    }


def why_crop(crop: str) -> str:
    return CROP_REASONS.get(crop, "Soil and climate conditions are suitable for this crop.")
