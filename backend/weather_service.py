"""
weather_service.py
Fetches live weather data from OpenWeatherMap.
Falls back to Tamil Nadu seasonal averages when offline or no API key.
"""

import os
import json
import requests
from typing import Optional
from datetime import datetime

OWM_API_KEY = os.getenv("OWM_API_KEY", "")   # Set in environment for live data

# ── District → lat/lon mapping (Tamil Nadu) ──────────────────────────────────
DISTRICT_COORDS = {
    "Ariyalur":       (11.14, 79.08), "Chengalpattu":   (12.69, 79.98),
    "Chennai":        (13.08, 80.27), "Coimbatore":     (11.00, 76.96),
    "Cuddalore":      (11.75, 79.77), "Dharmapuri":     (12.12, 78.16),
    "Dindigul":       (10.36, 77.97), "Erode":          (11.34, 77.72),
    "Kallakurichi":   (11.74, 78.96), "Kancheepuram":   (12.83, 79.70),
    "Karur":          (10.96, 78.08), "Krishnagiri":    (12.52, 78.21),
    "Madurai":        (9.92,  78.12), "Mayiladuthurai": (11.10, 79.65),
    "Nagapattinam":   (10.76, 79.84), "Namakkal":       (11.22, 78.17),
    "Nilgiris":       (11.41, 76.73), "Perambalur":     (11.23, 78.88),
    "Pudukkottai":    (10.38, 78.82), "Ramanathapuram": (9.37,  78.83),
    "Ranipet":        (12.93, 79.33), "Salem":          (11.65, 78.16),
    "Sivagangai":     (9.84,  78.48), "Tenkasi":        (8.96,  77.31),
    "Thanjavur":      (10.79, 79.14), "Theni":          (10.01, 77.48),
    "Thoothukudi":    (8.76,  78.13), "Tiruchirappalli":(10.79, 78.70),
    "Tirunelveli":    (8.73,  77.70), "Tirupathur":     (12.49, 78.57),
    "Tiruppur":       (11.10, 77.34), "Tiruvallur":     (13.14, 79.91),
    "Tiruvannamalai": (12.23, 79.07), "Tiruvarur":      (10.77, 79.63),
    "Vellore":        (12.92, 79.13), "Viluppuram":     (11.94, 79.49),
    "Virudhunagar":   (9.58,  77.95),
}

# ── Seasonal fallback data (month → avg temp/humidity/rainfall for TN) ───────
TN_SEASONAL = {
    1:  {"temperature": 24.0, "humidity": 72, "rainfall": 30},
    2:  {"temperature": 26.0, "humidity": 68, "rainfall": 15},
    3:  {"temperature": 29.0, "humidity": 65, "rainfall": 12},
    4:  {"temperature": 32.0, "humidity": 68, "rainfall": 20},
    5:  {"temperature": 34.0, "humidity": 70, "rainfall": 35},
    6:  {"temperature": 33.0, "humidity": 75, "rainfall": 55},
    7:  {"temperature": 31.0, "humidity": 78, "rainfall": 90},
    8:  {"temperature": 30.0, "humidity": 80, "rainfall": 110},
    9:  {"temperature": 29.0, "humidity": 82, "rainfall": 130},
    10: {"temperature": 28.0, "humidity": 84, "rainfall": 200},
    11: {"temperature": 26.0, "humidity": 80, "rainfall": 150},
    12: {"temperature": 24.5, "humidity": 75, "rainfall": 60},
}


def get_weather(district: str) -> dict:
    """
    Returns weather dict with temperature, humidity, rainfall.
    Uses OWM live data if API key is set, otherwise seasonal fallback.
    """
    coords = DISTRICT_COORDS.get(district)
    month  = datetime.now().month

    if OWM_API_KEY and coords:
        try:
            lat, lon = coords
            url = (
                f"https://api.openweathermap.org/data/2.5/weather"
                f"?lat={lat}&lon={lon}&appid={OWM_API_KEY}&units=metric&lang=en"
            )
            r = requests.get(url, timeout=5)
            if r.status_code == 200:
                d = r.json()
                rain_1h = d.get("rain", {}).get("1h", 0)
                return {
                    "temperature": round(d["main"]["temp"], 1),
                    "humidity":    d["main"]["humidity"],
                    "rainfall":    round(rain_1h * 24 * 30, 1),  # estimate monthly
                    "source":      "live",
                    "description": d["weather"][0]["description"].capitalize(),
                }
        except Exception:
            pass

    # Fallback
    seasonal = TN_SEASONAL.get(month, TN_SEASONAL[6]).copy()
    seasonal["source"]      = "seasonal_average"
    seasonal["description"] = f"Estimated seasonal average for {district} in month {month}"
    return seasonal
