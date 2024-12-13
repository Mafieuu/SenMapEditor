import sqlite3

def add_user(db_path, user_name, password, zone_id):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Ajouter l'utilisateur avec la zone_id
    cursor.execute("""
        INSERT INTO utilisateurs (nom, paswd, zone_id)
        VALUES (?, ?, ?);
    """, (user_name, password, zone_id))
    
    conn.commit()
    conn.close()

if __name__ == "__main__":
    add_user("database.db", "diome_fatou", "passer123", 3)
