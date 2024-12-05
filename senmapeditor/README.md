# senmapeditor
## super important
Attention au sysyeme de projection utilise
## remarque
Pour les plugins de flutter map dispo dans flutter_map_plugin de github, il se peut que des problemes subvienne du au fait que le fichier local.properties n'existe pas(elle est ignore ) le probleme est souleve par gladle .
Solution :cree ce fichier et ajouter le chemin vers suivant (a adapter)
Le ndk compatible au projet flutter_map_pluggin est actuellement la version 25.1.8937393 , il faut la telecharger 
dans android studio puis cree le fichier local.properties partout ou elle est ignore et y ecrire pour mon cas 
ndk.dir=C:\Users\HP\AppData\Local\Android\sdk\ndk\25.1.8937393

