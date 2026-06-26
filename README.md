# 🌾 Smart Farm Advisor v2.0 — Tamil Nadu

AI-powered farming assistant for Tamil Nadu smallholder farmers.
**Flutter Android App + FastAPI Backend + ML Models**

---

## 🚀 What's New in v2.0

| Feature | Status |
|---|---|
| Flutter Android App (11 screens) | ✅ |
| Voice Input (Tamil + English) | ✅ |
| Live Weather Auto-fetch (OpenWeatherMap) | ✅ |
| Plant Disease Detection (CNN + fallback) | ✅ |
| Market Price Prediction (6-month trend) | ✅ |
| PDF Report + WhatsApp Share | ✅ |
| SQLite Farmer Profiles + History | ✅ |
| All 38 Tamil Nadu Districts | ✅ |
| Tamil + English UI Toggle | ✅ |
| Offline AI Mode | ✅ |

---

## 📁 Project Structure

```
smart_farm/
├── backend/
│   ├── main.py                # FastAPI app (12 endpoints)
│   ├── predictor.py           # Crop ML model
│   ├── fertilizer.py          # Fertilizer optimizer
│   ├── water_check.py         # Irrigation rules
│   ├── translator.py          # English + Tamil summaries
│   ├── market_price.py        # Price prediction (Random Forest)
│   ├── disease_detection.py   # Leaf disease classifier
│   ├── weather_service.py     # OWM + seasonal fallback
│   ├── report_generator.py    # PDF generation (fpdf2)
│   ├── database.py            # SQLite farmer DB
│   └── train_model.py         # Model training
├── flutter_app/
│   ├── lib/
│   │   ├── main.dart          # App entry + routing
│   │   ├── models/models.dart # All data models
│   │   ├── services/api_service.dart
│   │   ├── providers/app_provider.dart
│   │   ├── utils/constants.dart
│   │   ├── widgets/common_widgets.dart
│   │   └── screens/
│   │       ├── splash_login_screen.dart
│   │       ├── home_screen.dart
│   │       ├── soil_input_screen.dart
│   │       ├── crop_result_screen.dart
│   │       ├── disease_screen.dart
│   │       ├── market_screen.dart
│   │       └── reports_settings_screen.dart
│   ├── assets/translations/en.json
│   ├── assets/translations/ta.json
│   └── pubspec.yaml
├── data/crop_data.csv
├── models/                    # Trained .pkl files
├── requirements.txt
└── README.md
```

---

## ⚙️ Backend Setup

```bash
cd smart_farm
python -m venv .venv
source .venv/bin/activate      # Windows: .venv\Scripts\activate
pip install -r requirements.txt

# Train the crop model (already done, models/ folder included)
python backend/train_model.py

# Start the API
uvicorn backend.main:app --reload --host 0.0.0.0 --port 8000
```

API docs: http://localhost:8000/docs

### Optional: Live weather
```bash
export OWM_API_KEY=your_openweathermap_key
```
Without a key, seasonal averages are used automatically.

---

## 📱 Flutter App Setup

### Prerequisites
- Flutter SDK 3.19+
- Android Studio / VS Code
- Android Emulator or physical device

```bash
cd smart_farm/flutter_app
flutter pub get
flutter run
```

### For physical device (same WiFi as backend):
Edit `lib/utils/constants.dart`:
```dart
const String kBaseUrl = 'http://YOUR_PC_IP:8000';
```

---

## 🔌 API Endpoints

| Method | Endpoint | Description |
|---|---|---|
| GET | `/` | Health check |
| GET | `/districts` | All 38 TN districts |
| POST | `/full_advisory` | Crop + fertilizer + water in one call |
| POST | `/predict_crop` | Crop prediction |
| POST | `/fertilizer_plan` | Fertilizer optimizer |
| POST | `/water_check` | Irrigation advisory |
| POST | `/market_price` | Price prediction + 6-month trend |
| POST | `/detect_disease` | Leaf image disease detection |
| GET | `/weather/{district}` | Live or seasonal weather |
| POST | `/generate_report` | PDF report (bytes) |
| POST | `/farmer` | Create farmer profile |
| GET | `/history/{id}` | Recommendation history |

---

## 📱 App Screens

1. **Splash** — Logo animation + auto-login check
2. **Login** — Farmer profile creation
3. **Home Dashboard** — 6 feature tiles
4. **Soil Input** — Sliders + voice input + auto-weather
5. **Crop Results** — 4 tabs: Crop / Fertilizer / Water / Summary
6. **Disease Detection** — Camera / gallery upload + results
7. **Market Price** — Price prediction + 6-month line chart
8. **Reports** — PDF download + WhatsApp share + history
9. **Settings** — Language toggle + profile + API status

---

## 🌟 Hackathon Highlights for Judges

1. **End-to-end AI pipeline** — soil → crop → fertilizer → water → PDF
2. **Truly offline** — ML runs on backend, cached locally
3. **Voice input in Tamil** — farmers can speak district name, field values
4. **Auto weather** — no manual weather entry needed
5. **Disease detection** — point camera at leaf, get diagnosis + treatment
6. **Market intelligence** — 6-month price trend with SELL/HOLD signal
7. **PDF + WhatsApp** — farmer can share report instantly
8. **SQLite history** — every recommendation saved with timestamps
9. **Tamil UI** — full toggle, proper agricultural terminology
10. **All 38 districts** — complete Tamil Nadu coverage

---

## 🔮 Future Roadmap

- [ ] Real CNN model trained on PlantVillage dataset
- [ ] Government scheme eligibility checker
- [ ] Satellite NDVI crop health via Google Earth Engine
- [ ] SMS advisory for feature phones (Twilio)
- [ ] Crop insurance calculator
- [ ] Multi-crop comparison mode

---

*Built for hackathon · Tamil Nadu farmer empowerment · 2024*
