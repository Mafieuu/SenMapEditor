import sqlite3

def add_zone(db_path, zone_name, utilisateur_id=None):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    cursor.execute("""
        INSERT INTO zones (nom, utilisateur_id)
        VALUES (?, ?);
    """, (zone_name, utilisateur_id))
    
    conn.commit()
    conn.close()

if __name__ == "__main__":
    add_zone("database.db", "Kafountine district 1",2)  
