import os
import rasterio
import geopandas as gpd
import numpy as np
#import tensorflow as tf
from keras.models import load_model
from rasterio.windows import Window
from shapely.geometry import Polygon
import streamlit as st
import matplotlib.pyplot as plt
import tempfile

def predict_masks(sub_rasters, model_path):
    """
    Applique le modèle de machine learning à chaque sous-raster.
    
    Args:
        sub_rasters (list): Chemins des sous-rasters
        model_path (str): Chemin du modèle .h5
    
    Returns:
        list: Chemins des masks générés
    """
    # Chargement du modèle
    #model = tf.keras.models.load_model(model_path)
    model = load_model(model_path)
    
    # Dossier de sauvegarde des masks
    mask_dir = os.path.join(
        os.path.dirname(sub_rasters[0]), 
        '..', 
        'mask'
    )
    os.makedirs(mask_dir, exist_ok=True)
    
    # Liste des chemins de masks
    mask_paths = []
    
    for raster_path in sub_rasters:
        # Ouverture du sous-raster
        with rasterio.open(raster_path) as src:
            raster_data = src.read()
            profile = src.profile
            
            # Prétraitement (à ajuster selon votre modèle)
            input_data = raster_data.transpose(1, 2, 0)
            input_data = np.expand_dims(input_data, axis=0)
            
            # Prédiction
            prediction = model.predict(input_data)
            mask = (prediction[0, :, :, 0] > 0.5).astype(np.uint8)
            
            # Chemin de sauvegarde du mask
            mask_path = os.path.join(
                mask_dir, 
                f'mask_{os.path.basename(raster_path)}'
            )
            
            # Sauvegarde du mask
            profile.update({
                'count': 1,
                'dtype': 'uint8'
            })
            
            with rasterio.open(mask_path, 'w', **profile) as dst:
                dst.write(mask.reshape(1, mask.shape[0], mask.shape[1]))
            
            mask_paths.append(mask_path)
    
    return mask_paths

def merge_masks_to_shapefile(mask_paths, output_path):
    """
    Fusionne les masks en un shapefile unique.
    
    Args:
        mask_paths (list): Chemins des fichiers mask
        output_path (str): Chemin de sortie du shapefile
    
    Returns:
        str: Chemin du shapefile généré
    """
    # Liste pour stocker les polygones
    polygons = []
    
    for mask_path in mask_paths:
        with rasterio.open(mask_path) as src:
            mask = src.read(1)
            transform = src.transform
            
            # Création des polygones à partir des régions de mask
            for geom, val in rasterio.features.shapes(mask, transform=transform):
                if val == 1:
                    polygons.append(Polygon(geom['coordinates'][0]))
    
    # Création du GeoDataFrame
    gdf = gpd.GeoDataFrame(geometry=polygons)
    gdf.crs = src.crs
    
    # Sauvegarde du shapefile
    gdf.to_file(output_path)
    
    return output_path

def streamlit_visualisation(raster_path, shapefile_path):
    """
    Visualisation interactive Streamlit du raster et du shapefile.
    
    Args:
        raster_path (str): Chemin du raster original
        shapefile_path (str): Chemin du shapefile généré
    """
    st.title('Détection de Maisons')
    
    # Chargement du raster
    with rasterio.open(raster_path) as src:
        raster_data = src.read()
        extent = rasterio.transform.array_bounds(
            src.height, src.width, src.transform
        )
    
    # Chargement du shapefile
    gdf = gpd.read_file(shapefile_path)
    
    # Affichage
    fig, ax = plt.subplots(figsize=(15, 10))
    ax.imshow(
        raster_data.transpose(1, 2, 0), 
        extent=extent, 
        aspect='auto'
    )
    gdf.plot(ax=ax, facecolor='none', edgecolor='red')
    
    st.pyplot(fig)


    