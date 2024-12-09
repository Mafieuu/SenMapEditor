import sqlite3
import json
from datetime import datetime

#----------------------------------  Création de la base SQLite
def create_database(db_path="database.db"):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

# ------------------------------------ Creation des tables
    cursor.execute("""
        CREATE TABLE utilisateurs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nom TEXT NOT NULL,
            paswd TEXT UNIQUE NOT NULL
        );
    """)

    cursor.execute("""
        CREATE TABLE zones (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nom TEXT NOT NULL,
            utilisateur_id INTEGER,
            FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs (id) ON DELETE SET NULL
        );
    """)

    cursor.execute("""
        CREATE TABLE polygones (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            zone_id INTEGER NOT NULL,
            geom TEXT NOT NULL, -- Géométrie en GeoJSON
            FOREIGN KEY (zone_id) REFERENCES zones (id) ON DELETE CASCADE
        );
    """)

    cursor.execute("""
        CREATE TABLE creations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            polygone_id INTEGER UNIQUE,
            zone_id INTEGER,
            utilisateur_id INTEGER,
            geom TEXT NOT NULL, -- Géométrie en GeoJSON
            date_creation TEXT DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (polygone_id) REFERENCES polygones (id) ON DELETE CASCADE,
            FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs (id) ON DELETE SET NULL
        );
    """)

    cursor.execute("""
        CREATE TABLE suppressions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            polygone_id INTEGER,
            zone_id INTEGER,
            utilisateur_id INTEGER,
            date_suppression TEXT DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs (id) ON DELETE SET NULL
        );
    """)

    cursor.execute("""
        CREATE TABLE modifications (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            polygone_id INTEGER,
            zone_id INTEGER,
            utilisateur_id INTEGER,
            nouvelle_geom TEXT NOT NULL, -- Nouvelle géométrie en GeoJSON
            date_modification TEXT DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (polygone_id) REFERENCES polygones (id) ON DELETE CASCADE,
            FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs (id) ON DELETE SET NULL
        );
    """)

    cursor.execute("""
        CREATE TABLE fusions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            polygone_id_resultant INTEGER,
            zone_id INTEGER,
            utilisateur_id INTEGER,
            polygones_fusionnes TEXT, -- IDs des polygones fusionnés en JSON
            nouvelle_geom TEXT NOT NULL, -- Géométrie résultante en GeoJSON
            date_fusion TEXT DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (polygone_id_resultant) REFERENCES polygones (id) ON DELETE CASCADE,
            FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs (id) ON DELETE SET NULL
        );
    """)

    cursor.execute("""
        CREATE TABLE divisions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            polygone_id_original INTEGER,
            zone_id INTEGER,
            utilisateur_id INTEGER,
            nouvelle_geometries TEXT, -- Liste des nouvelles géométries en JSON
            date_division TEXT DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (polygone_id_original) REFERENCES polygones (id) ON DELETE SET NULL,
            FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs (id) ON DELETE SET NULL
        );
    """)

    conn.commit()
    conn.close()


# ----------------- creation
create_database()

