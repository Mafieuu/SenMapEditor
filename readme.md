
# Application Flutter de Gestion des Polygones

## Description
Cette application Flutter permet d'afficher et de modifier des polygones à partir d'un fichier GeoJSON de Sangalkam. Elle inclut un système d'authentification basé sur un fichier JSON local.

## Fonctionnalités
- Affichage du fichier GeoJSON de Sangalkam.
- Modification des polygones (création, fusion, suppression).
- Système d'authentification (inscription et connexion).
- Enregistrement des informations utilisateur dans un fichier JSON.


## Utilisation
1. Lancez l'application :
   ```bash
   flutter run
   ```
2. À l'ouverture de l'application, l'utilisateur peut s'inscrire ou se connecter.
   - **Inscription** : Fournir prénom, nom, pseudonyme, mot de passe et choisir une zone parmi une liste de zones. Les informations sont enregistrées dans un fichier JSON.
   - **Connexion** : Saisir le pseudonyme et le mot de passe pour vérifier les informations dans le fichier JSON.

3. Si la connexion est réussie :
   - Vérifiez localement si le fichier GeoJSON correspondant à la localité de l'utilisateur est présent.
     - Si oui, affichez le fichier et appliquez les modifications, créations et fusions.
     - Si non, proposez de télécharger le fichier depuis AWS. Envoyez le pseudonyme et le mot de passe pour vérification. Si les informations correspondent, téléchargez le fichier GeoJSON.

## TODO
- [ ] Implémenter la fonctionnalité de mise à jour de la base de données via un bouton de mise à jour.
- [ ] Ajouter la gestion des erreurs et des messages d'erreur pour les tentatives de connexion échouées.
- [ ] Optimiser le processus de téléchargement et de vérification des fichiers GeoJSON depuis AWS.
- [ ] Améliorer l'interface utilisateur pour une meilleure expérience utilisateur.
- [ ] Ajouter des tests unitaires et d'intégration pour assurer la fiabilité de l'application.
## Note important 
Dans la branche debug il y'a une version de l'application qui utulise des tuiles et une autre qui implemente un interface user
cependant ma config de java m'empeche de compiler ces applications (qui n'ont pas d'erreur selon le compilateur)

