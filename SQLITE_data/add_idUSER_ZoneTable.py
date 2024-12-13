import sqlite3

def update_utilisateur_id_in_zones(db_path):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Récupérer les utilisateurs et leurs zones associées
    cursor.execute("SELECT id, zone_id FROM utilisateurs")
    utilisateurs = cursor.fetchall()
    
    # Mettre à jour la colonne utilisateur_id dans la table zones 
    # bug :si plusieurs users ont meme zone seul l'id du dernier est pris en compte
    for utilisateur in utilisateurs:
        utilisateur_id, zone_id = utilisateur
        cursor.execute("""
            UPDATE zones
            SET utilisateur_id = ?
            WHERE id = ?;
        """, (utilisateur_id, zone_id))
    
    conn.commit()
    conn.close()

if __name__ == "__main__":
    update_utilisateur_id_in_zones("database.db")
