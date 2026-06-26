"""
water_check.py
Rule-based water / irrigation advisory for Tamil Nadu crops.
"""

from dataclasses import dataclass
from typing import Literal

Advice = Literal["GO", "MODIFY", "AVOID"]


@dataclass
class WaterRule:
    min_rain: float   # mm / month threshold
    max_rain: float
    ideal_humidity: float  # %
    note_low: str
    note_high: str
    note_ok: str


RULES: dict[str, WaterRule] = {
    "Rice": WaterRule(
        min_rain=150, max_rain=300,
        ideal_humidity=80,
        note_low="Rice needs >150 mm/month. Supplement with canal or borewell irrigation every 3–5 days.",
        note_high="Excess rainfall can cause lodging. Ensure proper field drainage channels.",
        note_ok="Rainfall is adequate for paddy cultivation. Maintain 5 cm standing water.",
    ),
    "Groundnut": WaterRule(
        min_rain=40, max_rain=120,
        ideal_humidity=60,
        note_low="Groundnut needs at least 40 mm. Apply one or two protective irrigations at pod-fill stage.",
        note_high="Waterlogging causes pod rot. Raise beds and ensure drainage.",
        note_ok="Moisture conditions are suitable. Irrigate at 21-day intervals if no rain.",
    ),
    "Maize": WaterRule(
        min_rain=50, max_rain=150,
        ideal_humidity=65,
        note_low="Maize is sensitive at tasselling. Apply irrigation if >2-week dry spell.",
        note_high="Excess water causes nitrogen leaching. Delay sowing until rainfall moderates.",
        note_ok="Conditions are favourable. Irrigate at knee-high and tasselling stages.",
    ),
    "Millet": WaterRule(
        min_rain=20, max_rain=80,
        ideal_humidity=50,
        note_low="Millet is drought-tolerant. Even 20 mm suffices at emergence.",
        note_high="Millet susceptible to downy mildew in wet conditions. Avoid waterlogging.",
        note_ok="Ideal dry conditions for millet. One pre-sowing irrigation is sufficient.",
    ),
    "Wheat": WaterRule(
        min_rain=30, max_rain=100,
        ideal_humidity=55,
        note_low="Apply critical irrigations at crown-root initiation and grain-filling.",
        note_high="Excessive rain causes rust diseases. Avoid wheat if monsoon is very heavy.",
        note_ok="Moisture levels are suited for wheat. Apply 5–6 irrigations across the season.",
    ),
    "Sugarcane": WaterRule(
        min_rain=120, max_rain=250,
        ideal_humidity=75,
        note_low="Sugarcane needs continuous moisture. Drip irrigation is strongly recommended.",
        note_high="Waterlogging stunts cane growth. Install subsurface drainage.",
        note_ok="Good moisture availability. Use drip/furrow irrigation for uniform supply.",
    ),
    "Cotton": WaterRule(
        min_rain=40, max_rain=100,
        ideal_humidity=55,
        note_low="Cotton needs irrigation at boll formation. Avoid moisture stress after 60 days.",
        note_high="Boll shedding occurs in waterlogged soil. Ridge planting is essential.",
        note_ok="Conditions are favourable. Irrigate at 15-day intervals during boll development.",
    ),
    "Banana": WaterRule(
        min_rain=80, max_rain=180,
        ideal_humidity=78,
        note_low="Banana has high water demand. Drip irrigation at 30–40 L/plant/day.",
        note_high="Ensure free drainage to prevent root rot (Fusarium).",
        note_ok="Good moisture. Maintain even water supply from shooting to harvest.",
    ),
    "Coconut": WaterRule(
        min_rain=100, max_rain=200,
        ideal_humidity=80,
        note_low="Basin irrigation at 200 L/tree every 4–7 days during summer months.",
        note_high="Coconut tolerates moderate flooding but roots should not stay submerged.",
        note_ok="Rainfall is sufficient. Supplement with drip in dry spells.",
    ),
}

DEFAULT_RULE = WaterRule(
    min_rain=50, max_rain=150, ideal_humidity=65,
    note_low="Rainfall is below optimal. Supplemental irrigation is advised.",
    note_high="High rainfall may cause waterlogging. Ensure good field drainage.",
    note_ok="Moisture conditions appear suitable for cultivation.",
)


def check_water(crop: str, rainfall: float, humidity: float) -> dict:
    """
    Returns a water advisory dict with keys: advice, reason, irrigation_tip.
    """
    rule = RULES.get(crop, DEFAULT_RULE)

    if rainfall < rule.min_rain:
        if rainfall < rule.min_rain * 0.5:
            advice = "AVOID"
            reason = (
                f"Rainfall ({rainfall:.0f} mm) is critically low "
                f"(need ≥{rule.min_rain} mm). {rule.note_low}"
            )
        else:
            advice = "MODIFY"
            reason = (
                f"Rainfall ({rainfall:.0f} mm) is below the {rule.min_rain} mm threshold. "
                f"{rule.note_low}"
            )
    elif rainfall > rule.max_rain:
        advice = "MODIFY"
        reason = (
            f"Rainfall ({rainfall:.0f} mm) exceeds the safe maximum of {rule.max_rain} mm. "
            f"{rule.note_high}"
        )
    else:
        advice = "GO"
        reason = (
            f"Rainfall ({rainfall:.0f} mm) is within the ideal {rule.min_rain}–{rule.max_rain} mm range. "
            f"{rule.note_ok}"
        )

    # Humidity modifier
    humidity_note = ""
    if humidity > 90:
        humidity_note = " High humidity (>90%) increases disease risk — monitor for fungal issues."
    elif humidity < 40:
        humidity_note = " Very low humidity (<40%) may increase evapotranspiration; irrigate more frequently."

    return {
        "crop":    crop,
        "advice":  advice,
        "reason":  reason + humidity_note,
        "rainfall_range": f"{rule.min_rain}–{rule.max_rain} mm",
    }
