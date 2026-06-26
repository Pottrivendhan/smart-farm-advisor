"""
report_generator.py — PDF advisory report (fpdf2, latin-1 safe)
"""
import os, io, re
from datetime import datetime
from fpdf import FPDF

REPORTS_DIR = os.path.join(os.path.dirname(__file__), "..", "reports")


def _s(text, limit: int = 400) -> str:
    """Sanitize text to latin-1 safe characters."""
    text = str(text)[:limit]
    replacements = {
        '\u2013': '-', '\u2014': '--', '\u2018': "'", '\u2019': "'",
        '\u201c': '"', '\u201d': '"', '\u2026': '...', '\u20b9': 'Rs',
        '\u00b0': ' deg', '\u00d7': 'x',
    }
    for src, dst in replacements.items():
        text = text.replace(src, dst)
    return text.encode('latin-1', 'replace').decode('latin-1')


class FarmReport(FPDF):
    def header(self):
        self.set_fill_color(27, 67, 50)
        self.rect(0, 0, 210, 18, "F")
        self.set_font("Helvetica", "B", 12)
        self.set_text_color(255, 255, 255)
        self.set_xy(10, 2)
        self.cell(190, 14, "AI Smart Farm Advisor  |  Tamil Nadu", align="L")
        self.ln(20)
        self.set_text_color(0, 0, 0)

    def footer(self):
        self.set_y(-12)
        self.set_font("Helvetica", "I", 8)
        self.set_text_color(120, 120, 120)
        self.cell(0, 10, f"Page {self.page_no()} | {datetime.now().strftime('%d %b %Y %H:%M')}", align="C")

    def sec(self, title: str):
        self.set_fill_color(82, 183, 136)
        self.set_text_color(255, 255, 255)
        self.set_font("Helvetica", "B", 10)
        self.set_x(10)
        self.cell(190, 8, f"  {_s(title)}", fill=True, new_x="LMARGIN", new_y="NEXT")
        self.set_text_color(0, 0, 0)
        self.ln(2)

    def row(self, key: str, val: str, shade: bool = False):
        KEY_W, VAL_W, H = 48, 132, 6
        fill_color = (240, 247, 243) if shade else (255, 255, 255)
        self.set_fill_color(*fill_color)
        y0 = self.get_y()
        self.set_x(10)
        self.set_font("Helvetica", "B", 9)
        self.multi_cell(KEY_W, H, _s(key) + ":", fill=shade, align="L",
                        new_x="RIGHT", new_y="TOP")
        y_key_end = self.get_y()
        self.set_xy(10 + KEY_W, y0)
        self.set_font("Helvetica", "", 9)
        self.multi_cell(VAL_W, H, _s(val, 400), fill=shade, align="L",
                        new_x="LMARGIN", new_y="NEXT")
        y_val_end = self.get_y()
        self.set_y(max(y_key_end, y_val_end))

    def badge(self, text: str, bg: tuple):
        self.set_fill_color(*bg)
        self.set_text_color(255, 255, 255)
        self.set_font("Helvetica", "B", 10)
        self.set_x(10)
        self.cell(40, 8, _s(text), fill=True, align="C", new_x="LMARGIN", new_y="NEXT")
        self.set_text_color(0, 0, 0)
        self.ln(4)


def generate_pdf_report(
    farmer_name, district, soil, weather,
    crop_result, fertilizer_result, water_result, summary,
    disease_result=None,
) -> bytes:
    os.makedirs(REPORTS_DIR, exist_ok=True)
    pdf = FarmReport(orientation="P", unit="mm", format="A4")
    pdf.set_auto_page_break(auto=True, margin=15)
    pdf.set_margins(10, 10, 10)
    pdf.add_page()

    # Farmer
    pdf.sec("Farmer Information")
    pdf.row("Name", farmer_name, shade=True)
    pdf.row("District", district)
    pdf.row("Date", datetime.now().strftime("%d %b %Y"), shade=True)
    pdf.ln(3)

    # Soil
    pdf.sec("Soil Parameters")
    for i, (k, v) in enumerate(soil.items()):
        pdf.row(str(k), str(v), shade=bool(i % 2))
    pdf.ln(3)

    # Weather
    pdf.sec("Weather Conditions")
    for i, (k, v) in enumerate(weather.items()):
        pdf.row(str(k), str(v), shade=bool(i % 2))
    pdf.ln(3)

    # Crop
    pdf.sec("Crop Recommendation")
    pdf.row("Recommended", str(crop_result.get("best_crop", "")), shade=True)
    pdf.row("Confidence",  f"{crop_result.get('confidence', 0)*100:.1f}%")
    pdf.row("Explanation", str(crop_result.get("explanation", ""))[:300], shade=True)
    alts = ", ".join(str(a) for a in crop_result.get("alternatives", []))
    pdf.row("Alternatives", alts)
    pdf.ln(3)

    # Fertilizer
    pdf.sec("Fertilizer Plan (per acre)")
    mix = fertilizer_result.get("fertilizer_mix", {})
    pdf.row("Urea", f"{mix.get('urea_kg', 0)} kg", shade=True)
    pdf.row("DAP",  f"{mix.get('dap_kg', 0)} kg")
    pdf.row("MOP",  f"{mix.get('mop_kg', 0)} kg", shade=True)
    cost = fertilizer_result.get('cost_per_acre', 0)
    pdf.row("Cost", f"Rs {cost} / acre")
    if fertilizer_result.get("note"):
        pdf.row("Note", str(fertilizer_result["note"])[:250], shade=True)
    pdf.ln(3)

    # Water
    pdf.sec("Water / Irrigation Advisory")
    adv = water_result.get("advice", "GO")
    colors = {"GO": (45, 106, 79), "MODIFY": (200, 120, 0), "AVOID": (166, 0, 0)}
    pdf.badge(adv, colors.get(adv, (80, 80, 80)))
    pdf.row("Reason", str(water_result.get("reason", ""))[:300])
    pdf.ln(3)

    # Disease
    if disease_result:
        pdf.sec("Plant Disease Analysis")
        pdf.row("Disease",    str(disease_result.get("disease", "")), shade=True)
        pdf.row("Confidence", f"{disease_result.get('confidence', 0)*100:.1f}%")
        pdf.row("Severity",   str(disease_result.get("severity", "")), shade=True)
        pdf.row("Treatment",  str(disease_result.get("treatment", ""))[:250])
        pdf.row("Prevention", str(disease_result.get("prevention", ""))[:250], shade=True)
        pdf.ln(3)

    # Summary
    pdf.sec("Advisory Summary")
    pdf.set_font("Helvetica", "", 9)
    pdf.set_x(10)
    en = _s(str(summary.get("english_summary", "")), 600)
    pdf.multi_cell(190, 6, en)

    buf = io.BytesIO()
    pdf.output(buf)
    return buf.getvalue()
