import geopandas as gpd
import re  # Pour recuperer le nom du fichier a partir du chemin

def shapefile_to_geojson(chemin_shp, out_folder=r"../data_out"):
    """
    Convertit un fichier Shapefile (.shp) en fichier GeoJSON.

    parametre:
    chemin_shp (str): chemin fichier .shp
    out_folder (str):  dossier out

    """
    # return un objet Match, methode .groupe(0) pour recup le texte complet
    name_shp = re.search(r'([^/\\]+)(?=\.shp)', chemin_shp)
    # conversion
    fil_converti = gpd.read_file(chemin_shp)
    output_file = f"{out_folder}/{name_shp.group(0)}.geojson"
    fil_converti.to_file(output_file, driver="GeoJSON")

shapefile_to_geojson(r"C:\Users\HP\Desktop\temp\HACKATON\Sen_Map_Editor\back_end\data_in\proj_SANGALKAM.shp")