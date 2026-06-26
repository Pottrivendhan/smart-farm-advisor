"""
fertilizer.py
Budget-aware fertilizer mix calculator.
Returns urea / DAP / MOP quantities and cost per acre.
"""

from typing import Optional

# ── Fertilizer nutrient content (%) ─────────────────────────────────────────
UREA_N  = 0.46   # 46 % N
DAP_N   = 0.18   # 18 % N
DAP_P   = 0.46   # 46 % P
MOP_K   = 0.60   # 60 % K

# ── Prices (INR / kg) ────────────────────────────────────────────────────────
PRICE = {"urea": 6.0, "dap": 27.0, "mop": 17.0}   # approximate MRP

# ── Crop-specific NPK targets (kg / acre) ────────────────────────────────────
NPK_TARGETS: dict[str, dict[str, float]] = {
    "Rice":      {"N": 80,  "P": 40,  "K": 40},
    "Groundnut": {"N": 25,  "P": 50,  "K": 30},
    "Maize":     {"N": 70,  "P": 35,  "K": 35},
    "Millet":    {"N": 20,  "P": 20,  "K": 20},
    "Wheat":     {"N": 60,  "P": 45,  "K": 30},
    "Sugarcane": {"N": 120, "P": 60,  "K": 80},
    "Cotton":    {"N": 60,  "P": 30,  "K": 30},
    "Banana":    {"N": 100, "P": 75,  "K": 100},
    "Coconut":   {"N": 50,  "P": 40,  "K": 80},
}

DEFAULT_NPK = {"N": 60, "P": 30, "K": 30}


def get_fertilizer_plan(
    crop: str,
    budget_cap: Optional[float] = None,
    acres: float = 1.0,
) -> dict:
    """
    Compute fertilizer quantities and cost for `acres` of `crop`.
    If budget_cap (INR) is given, scale down proportionally to fit.
    """
    target = NPK_TARGETS.get(crop, DEFAULT_NPK).copy()

    # Scale to acreage
    target = {k: v * acres for k, v in target.items()}

    # ── Calculate raw kg needed ───────────────────────────────────────────────
    # Strategy: DAP first (covers both N & P), then residual N from urea, K from MOP
    dap_kg  = target["P"] / DAP_P                  # kg DAP to supply all P
    n_from_dap = dap_kg * DAP_N                    # N already supplied by DAP
    residual_n = max(0.0, target["N"] - n_from_dap)
    urea_kg = residual_n / UREA_N                  # kg urea for remaining N
    mop_kg  = target["K"] / MOP_K                  # kg MOP to supply all K

    # ── Cost calculation ─────────────────────────────────────────────────────
    cost = urea_kg * PRICE["urea"] + dap_kg * PRICE["dap"] + mop_kg * PRICE["mop"]

    # ── Budget constraint ────────────────────────────────────────────────────
    note = None
    if budget_cap and cost > budget_cap:
        scale  = budget_cap / cost
        urea_kg *= scale
        dap_kg  *= scale
        mop_kg  *= scale
        cost    = budget_cap
        note = (
            f"Quantities scaled to ₹{budget_cap:.0f} budget "
            f"({scale * 100:.0f}% of recommended dose). "
            "Consider split application to maximise efficiency."
        )

    per_acre_npk = NPK_TARGETS.get(crop, DEFAULT_NPK)

    return {
        "crop":          crop,
        "acres":         acres,
        "npk_target":    per_acre_npk,
        "fertilizer_mix": {
            "urea_kg": round(urea_kg, 2),
            "dap_kg":  round(dap_kg,  2),
            "mop_kg":  round(mop_kg,  2),
        },
        "cost_per_acre": round(cost / acres, 2),
        "total_cost":    round(cost, 2),
        "note":          note,
    }
