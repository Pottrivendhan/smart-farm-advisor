"""
database.py
SQLite-based local storage for farmer profiles and recommendation history.
"""

import sqlite3
import json
import os
from datetime import datetime
from typing import Optional

DB_PATH = os.path.join(os.path.dirname(__file__), "..", "models", "farm_data.db")


def get_conn() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH, check_same_thread=False)
    conn.row_factory = sqlite3.Row
    return conn


def init_db():
    """Create tables if they don't exist."""
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    conn = get_conn()
    c = conn.cursor()

    c.executescript("""
    CREATE TABLE IF NOT EXISTS farmers (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        name        TEXT NOT NULL,
        phone       TEXT,
        district    TEXT,
        village     TEXT,
        acres       REAL DEFAULT 1.0,
        created_at  TEXT DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS recommendations (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        farmer_id       INTEGER,
        district        TEXT,
        N REAL, P REAL, K REAL, pH REAL,
        temperature REAL, humidity REAL, rainfall REAL,
        best_crop       TEXT,
        confidence      REAL,
        fertilizer_json TEXT,
        water_advice    TEXT,
        summary_en      TEXT,
        summary_ta      TEXT,
        created_at      TEXT DEFAULT (datetime('now')),
        FOREIGN KEY (farmer_id) REFERENCES farmers(id)
    );

    CREATE TABLE IF NOT EXISTS disease_logs (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        farmer_id   INTEGER,
        disease     TEXT,
        confidence  REAL,
        crop        TEXT,
        created_at  TEXT DEFAULT (datetime('now')),
        FOREIGN KEY (farmer_id) REFERENCES farmers(id)
    );

    CREATE TABLE IF NOT EXISTS market_queries (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        farmer_id   INTEGER,
        crop        TEXT,
        district    TEXT,
        month       INTEGER,
        predicted_price REAL,
        recommendation  TEXT,
        created_at  TEXT DEFAULT (datetime('now')),
        FOREIGN KEY (farmer_id) REFERENCES farmers(id)
    );
    """)
    conn.commit()
    conn.close()


# ── Farmer CRUD ───────────────────────────────────────────────────────────────

def create_farmer(name: str, phone: str = "", district: str = "",
                  village: str = "", acres: float = 1.0) -> int:
    conn = get_conn()
    cur  = conn.execute(
        "INSERT INTO farmers (name, phone, district, village, acres) VALUES (?,?,?,?,?)",
        (name, phone, district, village, acres)
    )
    farmer_id = cur.lastrowid
    conn.commit(); conn.close()
    return farmer_id


def get_farmer(farmer_id: int) -> Optional[dict]:
    conn = get_conn()
    row  = conn.execute("SELECT * FROM farmers WHERE id=?", (farmer_id,)).fetchone()
    conn.close()
    return dict(row) if row else None


def list_farmers() -> list[dict]:
    conn = get_conn()
    rows = conn.execute("SELECT * FROM farmers ORDER BY created_at DESC").fetchall()
    conn.close()
    return [dict(r) for r in rows]


# ── Recommendation history ────────────────────────────────────────────────────

def save_recommendation(farmer_id: int, inputs: dict, result: dict,
                        fertilizer: dict, water: dict, summary: dict) -> int:
    conn = get_conn()
    cur  = conn.execute("""
        INSERT INTO recommendations
          (farmer_id, district, N, P, K, pH, temperature, humidity, rainfall,
           best_crop, confidence, fertilizer_json, water_advice, summary_en, summary_ta)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
    """, (
        farmer_id,
        inputs.get("district", ""),
        inputs["N"], inputs["P"], inputs["K"], inputs["pH"],
        inputs["temperature"], inputs["humidity"], inputs["rainfall"],
        result["best_crop"], result["confidence"],
        json.dumps(fertilizer), water["advice"],
        summary.get("english_summary", ""),
        summary.get("tamil_summary", ""),
    ))
    rid = cur.lastrowid
    conn.commit(); conn.close()
    return rid


def get_history(farmer_id: int, limit: int = 20) -> list[dict]:
    conn = get_conn()
    rows = conn.execute(
        "SELECT * FROM recommendations WHERE farmer_id=? ORDER BY created_at DESC LIMIT ?",
        (farmer_id, limit)
    ).fetchall()
    conn.close()
    return [dict(r) for r in rows]


def save_disease_log(farmer_id: int, disease: str, confidence: float, crop: str = ""):
    conn = get_conn()
    conn.execute(
        "INSERT INTO disease_logs (farmer_id, disease, confidence, crop) VALUES (?,?,?,?)",
        (farmer_id, disease, confidence, crop)
    )
    conn.commit(); conn.close()


def save_market_query(farmer_id: int, crop: str, district: str,
                      month: int, price: float, recommendation: str):
    conn = get_conn()
    conn.execute("""
        INSERT INTO market_queries (farmer_id, crop, district, month, predicted_price, recommendation)
        VALUES (?,?,?,?,?,?)
    """, (farmer_id, crop, district, month, price, recommendation))
    conn.commit(); conn.close()


# Auto-init on import
init_db()
