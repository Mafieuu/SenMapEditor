import sqlite3
import json

def insert_polygone(db_path, zone_id, geojson_path):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    with open(geojson_path, 'r') as file:
        geojson_data = json.load(file)
        for feature in geojson_data['features']:
            geom = json.dumps(feature['geometry'])  # Convertir la géométrie en texte JSON
            cursor.execute("""
                INSERT INTO polygones (zone_id, geom)
                VALUES (?, ?);
            """, (zone_id, geom))
    
    conn.commit()
    conn.close()

if __name__ == "__main__":
    insert_polygone("database.db", 2, r"C:\Users\HP\Desktop\temp\HACKATON\Sen_Map_Editor\senmapeditor\assets\geojson\SANGALKAM.geojson")
