import sqlite3

def add_column_utilisateur_id(db_path):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Ajouter la colonne utilisateur_id à la table zones
    cursor.execute("""
        ALTER TABLE zones
        ADD COLUMN utilisateur_id INTEGER;
    """)
    
    conn.commit()
    conn.close()

if __name__ == "__main__":
    add_column_utilisateur_id("database.db")
