# Stratégie

## app mobile

Il y aura deux applications mobiles :
- Une qui utilise le raster fourni, le découpe en tuiles selon le niveau de zoom et l'affiche dans l'application. Ces tuiles occupent un espace (lord des giga octe ) conséquent et coûteux en calcul.
- Puisque dans un cas concret, les rasters et shapefiles seront à jour, ce qui permet aux agents testeurs de s'en servir pour se géolocaliser. On peut donc abandonner le raster et se servir des cartes d'OpenStreetMap. Il suffit de supprimer les bâtiments et conserver le reste, puis de le fusionner avec notre shapefile au niveau de l'application.
- D'abord, nous développons la première solution jusqu'à une première version fonctionnelle, puis nous créons une nouvelle branche sur laquelle nous ne modifions que le raster. Cette branche sera fusionnée régulièrement avec la branche principale tout en conservant les deux branches.

## Back-end

Mon ordi sera le serveur. La communication se fera avec FastAPI. Nous déléguerons à Python les tâches que Flutter_map est incapable de faire (fusion de polygones, etc.).

