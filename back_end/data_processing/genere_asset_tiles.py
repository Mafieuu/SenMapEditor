import os
from pathlib import Path

def generate_tiles_txt(tiles_directory, output_file='tiles.txt'):
    """
    Génère un fichier texte répertoriant tous les dossiers contenant des images

    :param tiles_directory: Chemin du dossier racine contenant les tuiles
    :param output_file: Nom du fichier de sortie (défaut: tiles.txt)
    """

    tiles_dir = Path(tiles_directory)

    if not tiles_dir.exists():
        raise FileNotFoundError(f"Le répertoire '{tiles_directory}' n'existe pas.")

    image_paths = []

    for root, _, files in os.walk(tiles_directory):
        image_files = [f for f in files if f.lower().endswith(('.png', '.jpg', '.jpeg', '.gif', '.webp'))]
        if image_files:
            relative_path = Path(root).relative_to(tiles_dir)
            image_paths.extend(relative_path / img for img in image_files)

    image_paths.sort()

    try:
        with open(output_file, 'w', encoding='utf-8') as f:
            for path in image_paths:
                f.write(f"{path}\n")
        print(f"Fichier texte généré : {output_file}")
    except OSError as e:
        print(f"Erreur lors de l'écriture du fichier : {e}")

if __name__ == '__main__':
    tiles_dir = r"C:\Users\HP\Desktop\temp\HACKATON\teste\raster\visualisation\assets\tiles"
    generate_tiles_txt(tiles_dir)