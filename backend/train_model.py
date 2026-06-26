"""
train_model.py
Trains a Random Forest classifier on the crop dataset.
Run: python train_model.py
"""

import os
import pickle
import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from sklearn.metrics import accuracy_score, confusion_matrix, classification_report

# ── Paths ────────────────────────────────────────────────────────────────────
BASE_DIR   = os.path.dirname(os.path.abspath(__file__))
DATA_PATH  = os.path.join(BASE_DIR, "..", "data", "crop_data.csv")
MODEL_DIR  = os.path.join(BASE_DIR, "..", "models")
MODEL_PATH = os.path.join(MODEL_DIR, "model.pkl")
ENC_PATH   = os.path.join(MODEL_DIR, "label_encoder.pkl")
FEAT_PATH  = os.path.join(MODEL_DIR, "feature_names.pkl")

FEATURES = ["N", "P", "K", "pH", "temperature", "humidity", "rainfall"]


def train():
    os.makedirs(MODEL_DIR, exist_ok=True)

    # ── Load data ────────────────────────────────────────────────────────────
    df = pd.read_csv(DATA_PATH)
    print(f"📂  Loaded {len(df)} rows from {DATA_PATH}")

    X = df[FEATURES].values
    le = LabelEncoder()
    y = le.fit_transform(df["crop_label"].values)

    # ── Train / test split ───────────────────────────────────────────────────
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.20, random_state=42, stratify=y
    )

    # ── Train Random Forest ──────────────────────────────────────────────────
    clf = RandomForestClassifier(
        n_estimators=200,
        max_depth=None,
        min_samples_split=2,
        random_state=42,
        n_jobs=-1,
    )
    clf.fit(X_train, y_train)

    # ── Evaluate ─────────────────────────────────────────────────────────────
    y_pred = clf.predict(X_test)
    acc    = accuracy_score(y_test, y_pred)

    print(f"\n✅  Accuracy : {acc * 100:.2f}%\n")
    print("Confusion Matrix:")
    print(confusion_matrix(y_test, y_pred))
    print("\nClassification Report:")
    print(classification_report(y_test, y_pred, target_names=le.classes_))

    # ── Feature importance ───────────────────────────────────────────────────
    importances = clf.feature_importances_
    print("\nFeature Importances:")
    for feat, imp in sorted(zip(FEATURES, importances), key=lambda x: -x[1]):
        print(f"  {feat:15s}: {imp:.4f}")

    # ── Save artefacts ───────────────────────────────────────────────────────
    with open(MODEL_PATH, "wb") as f:
        pickle.dump(clf, f)
    with open(ENC_PATH, "wb") as f:
        pickle.dump(le, f)
    with open(FEAT_PATH, "wb") as f:
        pickle.dump(FEATURES, f)

    print(f"\n💾  Model      → {MODEL_PATH}")
    print(f"💾  Encoder    → {ENC_PATH}")
    print(f"💾  Features   → {FEAT_PATH}")
    return acc


if __name__ == "__main__":
    train()
