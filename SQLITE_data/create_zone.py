import sqlite3

def add_zone(db_path, zone_name):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    cursor.execute("""
        INSERT INTO zones (nom)
        VALUES (?);
    """, (zone_name,))
    
    conn.commit()
    conn.close()

if __name__ == "__main__":
    add_zone("database.db", "kafountine")
