"""
dataset_generator.py
Generates a realistic synthetic agricultural dataset for Tamil Nadu crops.
Run: python dataset_generator.py
"""

import numpy as np
import pandas as pd
import os

np.random.seed(42)

# ── Crop-specific realistic ranges ──────────────────────────────────────────
# Each entry: (N_mean, N_std, P_mean, P_std, K_mean, K_std,
#              pH_mean, pH_std, temp_mean, temp_std,
#              humidity_mean, humidity_std, rainfall_mean, rainfall_std, n_samples)
CROP_PROFILES = {
    "Rice": dict(
        N=(80, 15), P=(40, 10), K=(40, 10),
        pH=(6.0, 0.4), temp=(25, 2), humidity=(82, 5), rainfall=(200, 40),
        n=150
    ),
    "Groundnut": dict(
        N=(25, 8), P=(50, 10), K=(30, 8),
        pH=(6.2, 0.4), temp=(28, 3), humidity=(60, 8), rainfall=(60, 20),
        n=120
    ),
    "Maize": dict(
        N=(70, 15), P=(35, 10), K=(35, 10),
        pH=(6.5, 0.4), temp=(26, 3), humidity=(65, 8), rainfall=(80, 25),
        n=120
    ),
    "Millet": dict(
        N=(20, 8), P=(20, 6), K=(20, 6),
        pH=(6.8, 0.5), temp=(30, 3), humidity=(50, 10), rainfall=(35, 15),
        n=120
    ),
    "Wheat": dict(
        N=(60, 12), P=(45, 10), K=(30, 8),
        pH=(6.5, 0.4), temp=(21, 3), humidity=(55, 8), rainfall=(55, 20),
        n=100
    ),
    "Sugarcane": dict(
        N=(120, 20), P=(60, 12), K=(80, 15),
        pH=(6.5, 0.4), temp=(28, 3), humidity=(75, 8), rainfall=(175, 40),
        n=120
    ),
    "Cotton": dict(
        N=(60, 12), P=(30, 8), K=(30, 8),
        pH=(7.0, 0.4), temp=(30, 3), humidity=(55, 8), rainfall=(65, 20),
        n=100
    ),
    "Banana": dict(
        N=(100, 20), P=(75, 15), K=(100, 20),
        pH=(6.5, 0.4), temp=(28, 3), humidity=(78, 8), rainfall=(120, 30),
        n=100
    ),
    "Coconut": dict(
        N=(50, 12), P=(40, 10), K=(80, 15),
        pH=(6.0, 0.4), temp=(27, 2), humidity=(80, 6), rainfall=(150, 35),
        n=100
    ),
}


def sample_crop(crop_name: str, profile: dict) -> pd.DataFrame:
    n = profile["n"]

    def sample(mean_std): 
        return np.random.normal(mean_std[0], mean_std[1], n).clip(0)

    df = pd.DataFrame({
        "N":           sample(profile["N"]).round(1),
        "P":           sample(profile["P"]).round(1),
        "K":           sample(profile["K"]).round(1),
        "pH":          np.random.normal(profile["pH"][0], profile["pH"][1], n).clip(4.5, 8.5).round(2),
        "temperature": sample(profile["temp"]).round(1),
        "humidity":    np.random.normal(profile["humidity"][0], profile["humidity"][1], n).clip(20, 100).round(1),
        "rainfall":    sample(profile["rainfall"]).round(1),
        "crop_label":  crop_name,
    })
    return df


def generate_dataset(output_path: str = "crop_data.csv"):
    frames = [sample_crop(name, prof) for name, prof in CROP_PROFILES.items()]
    df = pd.concat(frames, ignore_index=True).sample(frac=1, random_state=42)
    df.to_csv(output_path, index=False)
    print(f"✅  Dataset saved → {output_path}  ({len(df)} rows)")
    print(df["crop_label"].value_counts().to_string())
    return df


if __name__ == "__main__":
    out = os.path.join(os.path.dirname(__file__), "crop_data.csv")
    generate_dataset(out)
