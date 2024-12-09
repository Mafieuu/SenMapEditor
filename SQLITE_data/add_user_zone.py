import sqlite3

def add_user(db_path, nom, paswd):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    cursor.execute("""
        INSERT INTO utilisateurs (nom, paswd)
        VALUES (?, ?);
    """, (nom, paswd))
    
    conn.commit()
    conn.close()

def add_zone(db_path, nom, utilisateur_id):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    cursor.execute("""
        INSERT INTO zones (nom, utilisateur_id)
        VALUES (?, ?);
    """, (nom, utilisateur_id))
    
    conn.commit()
    conn.close()

if __name__ == "__main__":
    db_path = "database.db"
    
    # Ajouter des utilisateurs
    add_user(db_path, "diouf_abdou221", "dakar123")
    add_user(db_path, "diome_fatou221", "passer")
    add_user(db_path, "sarr_fellwin221", "senegal123")
    
    # Ajouter des zones
    add_zone(db_path, "Sangalkam_zone1", 1)  # 1 pour user 1 ok
    add_zone(db_path, "Sangalkam_zone2", 2)      
