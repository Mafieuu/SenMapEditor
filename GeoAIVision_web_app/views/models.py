import streamlit as st 
import rasterio
import numpy as np
import matplotlib.pyplot as plt
import boto3
from io import BytesIO
import plotly.express as px
import plotly.graph_objects as go
import tempfile
import os 
from utils.create_shapefile import predict_masks, merge_masks_to_shapefile, streamlit_visualisation
from utils.decoup_raster import create_directory_structure, extract_raster_info, cut_raster



# Titre de l'application
st.title("Chargeur et Visualisateur de Raster")

# Méthode de chargement
# source = st.radio("Sélectionnez la source du raster", 
#                   ["Ordinateur local", "AWS S3"])

# Variables pour stocker le raster
# raster_data = None
# raster_metadata = None

# Chargement depuis l'ordinateur local
""" if source == "Ordinateur local":
    uploaded_file = st.file_uploader("Choisissez un fichier raster", 
                                     type=['tif', 'tiff', 'img'])
    
    if uploaded_file is not None:
        try:
            # Ouvrir le fichier raster
            with rasterio.open(uploaded_file) as src:
                raster_data = src.read()
                raster_metadata = src.meta
            
            st.success("Raster chargé avec succès !")
        
        except Exception as e:
            st.error(f"Erreur de chargement : {e}")

# Chargement depuis AWS S3
elif source == "AWS S3":
    # Champs de configuration AWS
    st.sidebar.header("Configuration AWS S3")
    aws_access_key = st.sidebar.text_input("AWS Access Key ID", type="password")
    aws_secret_key = st.sidebar.text_input("AWS Secret Access Key", type="password")
    bucket_name = st.sidebar.text_input("Nom du Bucket")
    object_key = st.sidebar.text_input("Chemin du fichier raster")
    
    if st.sidebar.button("Charger depuis S3"):
        try:
            # Création du client S3
            s3 = boto3.client(
                's3', 
                aws_access_key_id=aws_access_key, 
                aws_secret_access_key=aws_secret_key
            )
            
            # Téléchargement du fichier
            obj = s3.get_object(Bucket=bucket_name, Key=object_key)
            raster_bytes = obj['Body'].read()
            
            # Ouverture du raster en mémoire
            with rasterio.open(BytesIO(raster_bytes)) as src:
                raster_data = src.read()
                raster_metadata = src.meta
            
            st.success("Raster S3 chargé avec succès !")
        
        except Exception as e:
            st.error(f"Erreur de chargement S3 : {e}")
 """
# Visualisation interactive du raster
""" if raster_data is not None:
    st.header("Visualisation du Raster")
    
    # Sélection de la bande à afficher si multi-bandes
    if raster_data.ndim == 3 and raster_data.shape[0] > 1:
        band_number = st.slider("Sélectionner la bande", 
                                1, raster_data.shape[0], 1)
        image_to_display = raster_data[band_number-1]
    else:
        # Gestion des rasters mono-bande
        image_to_display = raster_data[0] if raster_data.ndim > 2 else raster_data

    # Affichage d'information sur le nombre de bandes
    st.info(f"Dimensions du raster : {raster_data.shape}")
    
    # Options d'affichage
    display_option = st.selectbox(
        "Mode d'affichage", 
        ["Image interactive", "Heatmap interactive", "Histogramme interactif"]
    )
    
    # Conteneur pour l'affichage
    display_container = st.container()
    
    # Affichage selon l'option choisie
    if display_option == "Image interactive":
        # Création d'un graphique Plotly interactif
        fig = px.imshow(image_to_display, 
                        color_continuous_scale='viridis', 
                        title="Raster Interactif")
        fig.update_layout(
            height=600,
            width=800,
            coloraxis_colorbar=dict(title="Valeur")
        )
        display_container.plotly_chart(fig, use_container_width=True)
    
    elif display_option == "Heatmap interactive":
        # Création d'une heatmap interactive
        fig = go.Figure(data=go.Heatmap(
            z=image_to_display,
            colorscale='Viridis'
        ))
        fig.update_layout(
            title="Heatmap du Raster",
            height=600,
            width=800
        )
        display_container.plotly_chart(fig, use_container_width=True)
    
    elif display_option == "Histogramme interactif":
        # Histogramme interactif des valeurs de pixel
        fig = px.histogram(
            x=image_to_display.ravel(), 
            title="Distribution des valeurs de pixel",
            labels={'x': 'Valeurs de pixel', 'y': 'Fréquence'}
        )
        fig.update_layout(
            height=600,
            width=800
        )
        display_container.plotly_chart(fig, use_container_width=True)
    
    # Statistiques descriptives
    st.subheader("Statistiques du Raster")
    col1, col2, col3 = st.columns(3)
    
    with col1:
        st.metric("Min", f"{np.min(image_to_display):.2f}")
    with col2:
        st.metric("Max", f"{np.max(image_to_display):.2f}")
    with col3:
        st.metric("Moyenne", f"{np.mean(image_to_display):.2f}")

    
    # Affichage des métadonnées
    if raster_metadata:
        st.subheader("Métadonnées du Raster")
        metadata_dict = dict(raster_metadata)
        st.json(metadata_dict) """


# Style et personnalisation
# st.markdown("""
# <style>
# .stContainer {
#     border: 1px solid #e0e0e0;
#     border-radius: 5px;
#     padding: 10px;
#     margin-bottom: 10px;
# }
# </style>
# """, unsafe_allow_html=True)
###################################################

# Bouton de téléchargement du raster
uploaded_file = st.file_uploader(
    "Choisissez un fichier raster", 
    type=['tif', 'tiff']
)


if uploaded_file is not None:
    # Sauvegarde temporaire du fichier
    temp_dir = tempfile.mkdtemp()
    input_path = os.path.join(temp_dir, uploaded_file.name)
    original_folder = os.path.dirname(uploaded_file.name)
    
    with open(input_path, 'wb') as f:
        f.write(uploaded_file.getbuffer())
    
    # Chemins de modèle et étapes de traitement
    model_path = os.path.join(original_folder,'GeoAIVision_trained_model.h5')
    raster_path = original_folder
    output_base_path = os.path.join(original_folder, 'raster')
    sub_rasters = output_base_path
    mask_paths = os.path.join(original_folder, 'mask')
    output_shapefile = os.path.join(original_folder, 'shap')

    
    # Étapes de traitement
    sub_rasters = cut_raster(raster_path, output_base_path, window_size=256, overlap=0)
    mask_paths = predict_masks(sub_rasters, model_path)
    
    # Génération du shapefile
    output_shapefile = os.path.splitext(input_path)[0] + '.shp'
    shapefile_path = merge_masks_to_shapefile(mask_paths, output_shapefile)
    
    # Visualisation
    streamlit_visualisation(input_path, shapefile_path)