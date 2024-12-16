import json
from shapely.geometry import shape
import sqlite3

def remplir_polygone(db_path, zone_id, geojson_path, utilisateur_id):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
   
    with open(geojson_path, 'r', encoding='utf-8') as file:
        geojson_data = json.load(file)
        for feature in geojson_data['features']:
            # Align with Dart Polygone model properties
            type_pol = feature['properties'].get('type_pol', None)
            
            # Convert GeoJSON to WKT
            geom_shapely = shape(feature['geometry'])
            wkt_geom = geom_shapely.wkt
           
            # Insert the polygon
            cursor.execute("""
                INSERT INTO polygones (zone_id, type_pol, geom)
                VALUES (?, ?, ?);
            """, (zone_id, type_pol, wkt_geom))
           
            polygone_id = cursor.lastrowid
           
            # Log the action
            cursor.execute("""
                INSERT INTO action_log
                (polygone_id, zone_id, utilisateur_id, action, details)
                VALUES (?, ?, ?, ?, ?);
            """, (
                polygone_id,
                zone_id,
                utilisateur_id,
                'CREATE',
                'Imported from GeoJSON ' # ajouter ici le non du fichier geojson comme fait dans back-end/
            ))
   
    conn.commit()
    conn.close()

if __name__ == "__main__":
    DB_PATH = "database.db"
    
    # Remplir avec les données GeoJSON
    ZONE_ID = 2
    UTILISATEUR_ID = 2
    GEOJSON_PATH = r"data.geojson"
    
    remplir_polygone(DB_PATH, ZONE_ID, GEOJSON_PATH, UTILISATEUR_ID)

