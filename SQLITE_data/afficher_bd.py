import sqlite3

def display_data(db_path="database.db"):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Afficher les utilisateurs
    cursor.execute("SELECT * FROM utilisateurs;")
    utilisateurs = cursor.fetchall()
    print("Utilisateurs:")
    for utilisateur in utilisateurs:
        print(utilisateur)
        print("*****************************************************************")

    # Afficher les zones
    cursor.execute("SELECT * FROM zones;")
    zones = cursor.fetchall()
    print("\nZones:")
    for zone in zones:
        print(zone)
        print("*****************************************************************")

    # Afficher les polygones
    cursor.execute("SELECT * FROM polygones;")
    polygones = cursor.fetchall()
    print("\nPolygones:")
    for polygone in polygones:
        print(polygone)
        print("*****************************************************************")

    conn.close()

if __name__ == "__main__":
    display_data()
