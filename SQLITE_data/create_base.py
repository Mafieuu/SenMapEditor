import sqlite3

# Connexion à la base de données SQLite (ou création si elle n'existe pas)
conn = sqlite3.connect('database.db')
cursor = conn.cursor()

# Création de la table zones
cursor.execute('''
CREATE TABLE zones (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nom TEXT NOT NULL
)
''')

# Création de la table polygones
cursor.execute('''
CREATE TABLE polygones (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    zone_id INTEGER NOT NULL,
    type_pol TEXT,
    statut TEXT,
    nombre_habitants INTEGER,
    geom TEXT,
    FOREIGN KEY (zone_id) REFERENCES zones (id) ON DELETE CASCADE
)
''')

# Création de la table utilisateurs
cursor.execute('''
CREATE TABLE utilisateurs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nom TEXT NOT NULL,
    paswd TEXT ,
    zone_id INTEGER,
    FOREIGN KEY (zone_id) REFERENCES zones (id) ON DELETE SET NULL
)
''')

# Création de la table creations
cursor.execute('''
CREATE TABLE creations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    polygone_id INTEGER UNIQUE,
    zone_id INTEGER,
    utilisateur_id INTEGER,
    geom TEXT,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (polygone_id) REFERENCES polygones (id) ON DELETE CASCADE,
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs (id) ON DELETE SET NULL
)
''')

# Création de la table suppressions
cursor.execute('''
CREATE TABLE suppressions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    polygone_id INTEGER,
    zone_id INTEGER,
    utilisateur_id INTEGER,
    date_suppression TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs (id) ON DELETE SET NULL
)
''')

# Création de la table modifications
cursor.execute('''
CREATE TABLE modifications (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    polygone_id INTEGER,
    zone_id INTEGER,
    utilisateur_id INTEGER,
    nouvelle_geom TEXT,
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (polygone_id) REFERENCES polygones (id) ON DELETE CASCADE,
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs (id) ON DELETE SET NULL
)
''')

# Création de la table fusions
cursor.execute('''
CREATE TABLE fusions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    polygone_id_resultant INTEGER,
    zone_id INTEGER,
    utilisateur_id INTEGER,
    polygones_fusionnes TEXT,
    nouvelle_geom TEXT,
    date_fusion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (polygone_id_resultant) REFERENCES polygones (id) ON DELETE CASCADE,
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs (id) ON DELETE SET NULL
)
''')

# Création de la table divisions
cursor.execute('''
CREATE TABLE divisions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    polygone_id_original INTEGER,
    zone_id INTEGER,
    utilisateur_id INTEGER,
    nouvelle_geometries TEXT,
    date_division TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (polygone_id_original) REFERENCES polygones (id) ON DELETE SET NULL,
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs (id) ON DELETE SET NULL
)
''')

# Création de la table questionnaire
cursor.execute('''
CREATE TABLE questionnaire (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    polygone_id INTEGER NOT NULL,
    question1 TEXT NOT NULL,
    question2 TEXT NOT NULL,
    question3 TEXT NOT NULL,
    question4 TEXT NOT NULL,
    question5 TEXT NOT NULL,
    question6 TEXT NOT NULL,
    question7 TEXT NOT NULL,
    question8 TEXT NOT NULL,
    question9 TEXT NOT NULL,
    question10 TEXT NOT NULL,
    FOREIGN KEY (polygone_id) REFERENCES polygones (id) ON DELETE CASCADE
)
''')

# Sauvegarde des modifications et fermeture de la connexion
conn.commit()
conn.close()
