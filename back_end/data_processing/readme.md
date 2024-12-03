# Data Processing

Ce dossier contient des fonctions pour le traitement des données géospatiales.

## Fonction : `shapefile_to_geojson`

Convertit un fichier Shapefile (.shp) en fichier GeoJSON (.geojson).

### Paramètres
- **`chemin_shp` (str)** : Chemin complet du fichier Shapefile.
- **`out_folder` (str)** : Dossier où enregistrer le fichier GeoJSON (par défaut `../daya_out`).

### Cas pratique
#### Important
Les shapesfiles doivent etre reprojete avec reprojection.py avant la conversion en geojson

```python
from data_processing import shapefile_to_geojson

shapefile_to_geojson("chemin/vers/mon_fichier.shp", out_folder="chemin/vers/dossier_de_sortie")
```
## installation de gdal  sous windows
telecharger OSGeo4W,lors de l'installation optez pour gdal.
aller dans OSGeo4W Shell puis taper gdalinfo --version 
alternative : ajouter le dossier bin de OSGeo4W Shell dans la variable d'environement.
## Conversion de .tif vers .png
Dans un terminal saisir la commande 
gdal_translate my_raster.tif output_file.png
## Le plugin QTiles de Qgis
Gdal converti bien le raster en png mais le fichier est bien trop lourd et grand pour etre charge et affiche sur smartphone.
solution installer le pluggin QTiles de Qgis.
Elle permet de decomposer mon .tuif en tuile selon le niveau de zoom
https://makina-corpus.com/sig-cartographie/sig-mettre-en-place-des-tuiles-vectorielles
https://blog.jawg.io/pourquoi-utiliser-des-tuiles-vectorielles-plutot-que-des-tuiles-raster-dans-vos-cartes-interactives/
## Gestion des sources extrnes par flutter
Pour demander a flutter de charger mon tuile dans ses asserts,flutter n'est pas assez intelligent pour trouver les fichiers.
Il va falloir modifier le fichier pubspec.yaml et ajouter autant de ligne pour chaque dossier contenant directement les images.
du coup ce travail sera delegue a python, le principe est que par defaut on charge un raster et un shapefil puis on prend les autres
dans AWS, la il y aura plus de sossier asset.
## abandon tuiles classiques au profil des MBtiles
Le tuiles classiques generent des tas de dossiers et c'est galere a afficher.
alternative :MBtiles (ideal pour base de donnee)
doc : https://naturagis.fr/qgis/images-fichier-mbtiles-avec-qgis/
**
https://github.com/josxha/flutter_map_plugins/tree/main/flutter_map_mbtiles

permet de lire les fichiers mbtiles dans flutter
**


