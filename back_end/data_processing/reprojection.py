#
# Pas de reprojection = perdre deux jours complet de sa vie
#
import geopandas as gpd

# Charger le fichier shapefile
file_path = r'C:\Users\HP\Desktop\temp\HACKATON\Sen_Map_Editor\back_end\data_in\SANGALKAM.shp'
output_path = r'C:\Users\HP\Desktop\temp\HACKATON\Sen_Map_Editor\back_end\data_in\proj_SANGALKAM.shp'

try:
    gdf = gpd.read_file(file_path)
    
    # Vérifier si un système de coordonnées est défini
    if gdf.crs is None:
        raise ValueError("Le fichier shapefile n'a pas de système de coordonnées défini.")
    
    # Reprojection vers WGS84
    gdf_reprojected = gdf.to_crs(epsg=4326)
    
    # Sauvegarder le shapefile reprojeté
    gdf_reprojected.to_file(output_path)
    print(f"Fichier reprojeté sauvegardé avec succès : {output_path}")
    
except Exception as e:
    print(f"Erreur : {e}")
