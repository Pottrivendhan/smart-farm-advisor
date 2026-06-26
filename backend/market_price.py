"""
market_price.py
Random Forest Regression model for crop market price prediction.
Trained on synthetic Tamil Nadu mandi price data.
"""

import numpy as np
import pandas as pd
import pickle
import os
from typing import Optional

BASE_DIR   = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(BASE_DIR, "..", "models", "price_model.pkl")

# ── Synthetic price baselines (INR / quintal) ─────────────────────────────────
PRICE_BASE = {
    "Rice":      2100, "Groundnut": 5500, "Maize":  1800,
    "Millet":    2200, "Wheat":     2200, "Sugarcane": 300,
    "Cotton":    6500, "Banana":    1200, "Coconut": 2800,
}

# ── Seasonal multipliers (month 1-12) ────────────────────────────────────────
SEASONAL = [0.97, 0.95, 0.96, 1.00, 1.03, 1.05,
            1.07, 1.05, 1.02, 0.99, 0.97, 0.98]

CROP_INDEX  = {c: i for i, c in enumerate(PRICE_BASE.keys())}
DISTRICTS   = [
    "Ariyalur","Chengalpattu","Chennai","Coimbatore","Cuddalore",
    "Dharmapuri","Dindigul","Erode","Kallakurichi","Kancheepuram",
    "Karur","Krishnagiri","Madurai","Mayiladuthurai","Nagapattinam",
    "Namakkal","Nilgiris","Perambalur","Pudukkottai","Ramanathapuram",
    "Ranipet","Salem","Sivagangai","Tenkasi","Thanjavur","Theni",
    "Thoothukudi","Tiruchirappalli","Tirunelveli","Tirupathur",
    "Tiruppur","Tiruvallur","Tiruvannamalai","Tiruvarur",
    "Vellore","Viluppuram","Virudhunagar",
]
DIST_INDEX  = {d: i for i, d in enumerate(DISTRICTS)}


def _generate_training_data(n: int = 3000):
    rows = []
    rng  = np.random.default_rng(42)
    for _ in range(n):
        crop     = rng.choice(list(PRICE_BASE.keys()))
        district = rng.choice(DISTRICTS)
        month    = int(rng.integers(1, 13))
        base     = PRICE_BASE[crop]
        seasonal = SEASONAL[month - 1]
        noise    = rng.normal(0, base * 0.05)
        price    = base * seasonal + noise
        rows.append([CROP_INDEX[crop], DIST_INDEX[district], month, price])
    return np.array(rows)


def _train_price_model():
    from sklearn.ensemble import RandomForestRegressor
    data = _generate_training_data()
    X, y = data[:, :3], data[:, 3]
    model = RandomForestRegressor(n_estimators=100, random_state=42, n_jobs=-1)
    model.fit(X, y)
    os.makedirs(os.path.dirname(MODEL_PATH), exist_ok=True)
    with open(MODEL_PATH, "wb") as f:
        pickle.dump(model, f)
    return model


def _load_price_model():
    if os.path.exists(MODEL_PATH):
        with open(MODEL_PATH, "rb") as f:
            return pickle.load(f)
    return _train_price_model()


_price_model: Optional[object] = None


def predict_price(crop: str, district: str, month: int) -> dict:
    global _price_model
    if _price_model is None:
        _price_model = _load_price_model()

    ci = CROP_INDEX.get(crop, 0)
    di = DIST_INDEX.get(district, 0)
    X  = np.array([[ci, di, month]])
    predicted = float(_price_model.predict(X)[0])

    # Predict next 6 months for trend
    trend = []
    for m in range(month, month + 6):
        m_mod = ((m - 1) % 12) + 1
        px    = float(_price_model.predict(np.array([[ci, di, m_mod]]))[0])
        trend.append({"month": m_mod, "price": round(px, 2)})

    # Recommendation
    next_prices = [t["price"] for t in trend[1:4]]
    avg_future  = sum(next_prices) / len(next_prices)
    if avg_future > predicted * 1.05:
        recommendation = "HOLD"
        reason = f"Price expected to rise ~{((avg_future/predicted)-1)*100:.1f}% in next 3 months."
    elif avg_future < predicted * 0.95:
        recommendation = "SELL_NOW"
        reason = f"Price may drop ~{((1-avg_future/predicted))*100:.1f}% — sell now for best return."
    else:
        recommendation = "FLEXIBLE"
        reason = "Market is stable. Either sell now or hold 1–2 months."

    return {
        "crop":            crop,
        "district":        district,
        "month":           month,
        "predicted_price": round(predicted, 2),
        "unit":            "INR / quintal",
        "recommendation":  recommendation,
        "reason":          reason,
        "trend":           trend,
    }
