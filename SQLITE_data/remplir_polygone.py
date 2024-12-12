import sqlite3
import json

def remplir_polygone(db_path, zone_id, geojson_path):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    with open(geojson_path, 'r') as file:
        geojson_data = json.load(file)
        for feature in geojson_data['features']:
            type_pol = feature['properties'].get('type_pol', None)
            geom = json.dumps(feature['geometry'])  # Convertir la géométrie en texte JSON
            
            cursor.execute("""
                INSERT INTO polygones (zone_id, type_pol, geom)
                VALUES (?, ?, ?);
            """, (zone_id, type_pol, geom))
    
    conn.commit()
    conn.close()

if __name__ == "__main__":
    remplir_polygone("database.db", 1, r"C:\Users\HP\Desktop\temp\HACKATON\Sen_Map_Editor\senmapeditor\assets\geojson\SANGALKAM.geojson")
