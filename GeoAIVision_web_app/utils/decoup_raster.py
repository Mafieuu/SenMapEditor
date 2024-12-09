
import os
import rasterio
import geopandas as gpd
import numpy as np
from rasterio.features import rasterize
from rasterio.transform import from_origin
from rasterio.windows import Window

def create_directory_structure(base_path):
    """
    Crée la structure de dossiers nécessaire pour le traitement des données.

    Args:
        base_path (str): Chemin de base où créer les dossiers
    """
    os.makedirs(os.path.join(base_path, 'raster'), exist_ok=True)
    os.makedirs(os.path.join(base_path, 'mask'), exist_ok=True)

def extract_raster_info(raster_path):
    """
    Extrait les informations de base du raster.

    Args:
        raster_path (str): Chemin vers le fichier raster

    Returns:
        dict: Informations du raster
    """
    with rasterio.open(raster_path) as src:
        return {
            'width': src.width,
            'height': src.height,
            'profile': src.profile.copy()
        }

def cut_raster(raster_path, output_base_path, window_size=256, overlap=0):
    """
    Découpe un raster en sous-rasters de taille spécifiée tout en préservant leur géolocalisation.

    Args:
        raster_path (str): Chemin vers le fichier raster
        output_base_path (str): Chemin de base pour les fichiers de sortie
        window_size (int, optional): Taille de la fenêtre de découpage. Défaut à 256.
        overlap (int, optional): Chevauchement entre les sous-rasters. Défaut à 50.
    """
    # Extraire le nom de base du raster
    base_raster_name = os.path.splitext(os.path.basename(raster_path))[0]

    # Ouvrir le raster 
    with rasterio.open(raster_path) as src_raster:
        # Copier le profil du raster original
        raster_profile = src_raster.profile.copy()

        # Générer les fenêtres de découpage
        for y in range(0, src_raster.height, window_size - overlap):
            for x in range(0, src_raster.width, window_size - overlap):
                # Ajuster la fenêtre aux dimensions du raster
                window_width = window_size
                window_height = window_size

                # Ajuster les coordonnées si on dépasse les bords du raster
                if window_size > src_raster.width - x:
                    x = src_raster.width - window_size
                if window_size > src_raster.height - y:
                    y = src_raster.height - window_size

                # Créer une fenêtre de lecture
                window = Window(x, y, window_width, window_height)

                # Calculer les nouvelles coordonnées géographiques pour le sous-raster
                transform = src_raster.window_transform(window)

                # Lire les données du raster
                raster_data = src_raster.read(window=window)

                # Préparer les profils pour les sous-rasters
                sub_raster_profile = raster_profile.copy()

                # Mettre à jour les profils avec les nouvelles dimensions et transformation
                sub_raster_profile.update({
                    'height': window_height,
                    'width': window_width,
                    'transform': transform,
                    'count': src_raster.count,
                    'dtype': src_raster.dtypes[0]
                })

                # Générer le nom de fichier pour ce sous-raster
                sub_raster_name = f"{base_raster_name}_{x}_{y}.tif"

                # Chemins complets de sortie
                raster_output_path = os.path.join(output_base_path, sub_raster_name)

                # Créer le répertoire de sortie s'il n'existe pas
                os.makedirs(os.path.dirname(raster_output_path), exist_ok=True)

                # Écrire les sous-rasters avec leur géoréférencement correct
                with rasterio.open(raster_output_path, 'w', **sub_raster_profile) as dst_raster:
                    dst_raster.write(raster_data)

