"""
translator.py
Generates English and Tamil advisory summaries without any external API.
Uses pre-built template sentences with proper Tamil agricultural terminology.
"""

from typing import Optional

# ── Tamil crop names ─────────────────────────────────────────────────────────
CROP_TAMIL = {
    "Rice":      "நெல்",
    "Groundnut": "கடலை",
    "Maize":     "மக்காச்சோளம்",
    "Millet":    "கேழ்வரகு",
    "Wheat":     "கோதுமை",
    "Sugarcane": "கரும்பு",
    "Cotton":    "பருத்தி",
    "Banana":    "வாழை",
    "Coconut":   "தேங்காய்",
}

# ── Tamil advice phrases ─────────────────────────────────────────────────────
WATER_ADVICE_TAMIL = {
    "GO":     "நீர் நிலை சாதகமாக உள்ளது. பயிர் சாகுபடி தொடங்கலாம்.",
    "MODIFY": "நீர் நிலையில் மாற்றம் தேவை. கூடுதல் நீர்ப்பாசனம் செய்யவும்.",
    "AVOID":  "தண்ணீர் போதுமான அளவு இல்லை. வேறு பயிர் தேர்வு செய்யவும்.",
}

FERTILIZER_TAMIL = (
    "ஒரு ஏக்கருக்கு யூரியா {urea} கிலோ, டி.ஏ.பி {dap} கிலோ, "
    "மியூரியேட் ஆஃப் பொட்டாஷ் {mop} கிலோ இடவும். "
    "மொத்த செலவு சுமார் ₹{cost} ஆகும்."
)

CONFIDENCE_TAMIL = {
    "high":   "மிகவும் நம்பகமான பரிந்துரை.",
    "medium": "நடுத்தர நம்பகத்தன்மை கொண்ட பரிந்துரை.",
    "low":    "குறைந்த நம்பகத்தன்மை — விவசாய வல்லுனரை அணுகவும்.",
}


def _confidence_band(score: float) -> str:
    if score >= 0.70:
        return "high"
    elif score >= 0.45:
        return "medium"
    return "low"


def generate_summary(
    top_crop: str,
    confidence: float,
    water_advice: str,
    fertilizer_plan: dict,
    alternatives: Optional[list[str]] = None,
) -> dict:
    """
    Returns {"english_summary": ..., "tamil_summary": ...}
    """
    crop_tamil = CROP_TAMIL.get(top_crop, top_crop)
    mix        = fertilizer_plan.get("fertilizer_mix", {})
    cost       = fertilizer_plan.get("cost_per_acre", 0)
    conf_pct   = round(confidence * 100, 1)
    alt_str    = ", ".join(alternatives) if alternatives else "None"
    alt_tamil  = ", ".join(CROP_TAMIL.get(a, a) for a in alternatives) if alternatives else "இல்லை"

    # ── English ───────────────────────────────────────────────────────────────
    english = (
        f"Recommended Crop: {top_crop} (Confidence: {conf_pct}%). "
        f"Based on your soil and weather inputs, {top_crop} is the most suitable crop. "
        f"Fertilizer Plan: Apply {mix.get('urea_kg', 0)} kg Urea, "
        f"{mix.get('dap_kg', 0)} kg DAP, and {mix.get('mop_kg', 0)} kg MOP per acre. "
        f"Estimated cost: ₹{cost}/acre. "
        f"Water Advisory: {water_advice}. "
        f"Alternative crops if conditions change: {alt_str}."
    )

    # ── Tamil ─────────────────────────────────────────────────────────────────
    conf_band  = _confidence_band(confidence)
    fert_tamil = FERTILIZER_TAMIL.format(
        urea=mix.get("urea_kg", 0),
        dap=mix.get("dap_kg", 0),
        mop=mix.get("mop_kg", 0),
        cost=round(cost),
    )
    water_tamil = WATER_ADVICE_TAMIL.get(water_advice, water_advice)

    tamil = (
        f"பரிந்துரைக்கப்பட்ட பயிர்: {crop_tamil} "
        f"(நம்பகத்தன்மை: {conf_pct}%). "
        f"உங்கள் மண் மற்றும் வானிலை தகவல்களின் படி, "
        f"{crop_tamil} மிகவும் ஏற்றதாக உள்ளது. "
        f"{fert_tamil} "
        f"நீர் ஆலோசனை: {water_tamil} "
        f"மாற்று பயிர்கள்: {alt_tamil}. "
        f"{CONFIDENCE_TAMIL[conf_band]}"
    )

    return {"english_summary": english, "tamil_summary": tamil}


def crop_why_tamil(crop: str) -> str:
    """Short Tamil explanation of why a crop is recommended."""
    explanations = {
        "Rice":      "மண்ணில் நைட்ரஜன் அதிகமாக உள்ளது மற்றும் மழை போதுமான அளவு உள்ளது, எனவே நெல் சாகுபடி ஏற்றது.",
        "Groundnut": "கடலைக்கு குறைந்த நைட்ரஜன் மற்றும் மிதமான மழை தேவை — இந்த நிலை ஏற்புடையது.",
        "Maize":     "மக்காச்சோளம் வளர இந்த மண் மற்றும் வெப்ப நிலை மிகவும் சாதகமாக உள்ளது.",
        "Millet":    "கேழ்வரகு வறட்சியை தாங்கும் பயிர் — குறைந்த மழை பகுதிக்கு ஏற்றது.",
        "Wheat":     "கோதுமைக்கு குளிர் வெப்பநிலை மற்றும் மிதமான மழை தேவை — இந்த நிலை சரியானது.",
        "Sugarcane": "கரும்புக்கு அதிக நீர் மற்றும் நைட்ரஜன் தேவை — மண்ணின் தரம் ஏற்புடையது.",
        "Cotton":    "பருத்திக்கு சரியான மண் pH மற்றும் வெப்ப நிலை உள்ளது.",
        "Banana":    "வாழைக்கு அதிக பொட்டாசியம் மற்றும் ஈரப்பதம் தேவை — இந்த மண் ஏற்றது.",
        "Coconut":   "தேங்காய் மரத்திற்கு கரையோர மண் மற்றும் ஈரப்பதம் ஏற்றது.",
    }
    return explanations.get(crop, f"{CROP_TAMIL.get(crop, crop)} சாகுபடிக்கு மண் மற்றும் வானிலை ஏற்றதாக உள்ளது.")
