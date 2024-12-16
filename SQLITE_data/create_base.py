# Création de la base de données en coherence avec l'app mobile
import sqlite3

def create_database(db_path):
    # Connexion à la base de données SQLite (ou création si elle n'existe pas)
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Création de la table zones
    cursor.execute('''
    CREATE TABLE zones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        utilisateur_id INTEGER
    )
    ''')

    # Création de la table utilisateurs avec zone_id
    cursor.execute('''
    CREATE TABLE utilisateurs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        paswd TEXT,
        zone_id INTEGER,
        FOREIGN KEY (zone_id) REFERENCES zones (id) ON DELETE SET NULL
    )
    ''')

    # Création de la table polygones avec geom
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

    # Création de la table action_log
    cursor.execute('''
    CREATE TABLE action_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        polygone_id INTEGER NOT NULL,
        zone_id INTEGER NOT NULL,
        utilisateur_id INTEGER NOT NULL,
        action TEXT NOT NULL,
        details TEXT,
        date_action TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (polygone_id) REFERENCES polygones (id) ON DELETE CASCADE,
        FOREIGN KEY (zone_id) REFERENCES zones (id) ON DELETE CASCADE,
        FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs (id) ON DELETE CASCADE
    )
    ''')
    

    # Création de la table questionnaire
    cursor.execute('''
        CREATE TABLE questionnaire (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            polygone_id INTEGER NOT NULL,
            land_use_type TEXT,
            is_occupied INTEGER,
            household_count INTEGER,
            building_type TEXT,
            roof_material TEXT,
            has_electricity INTEGER,
            has_water_access INTEGER,
            ownership_status TEXT,
            additional_comments TEXT,
            FOREIGN KEY (polygone_id) REFERENCES polygones (id) ON DELETE CASCADE
        )
        ''')

    # Sauvegarde des modifications et fermeture de la connexion
    conn.commit()
    conn.close()
if __name__=="__main__":
    create_database(r"C:\Users\HP\Desktop\temp\HACKATON\Sen_Map_Editor\SQLITE_data\database.db")
