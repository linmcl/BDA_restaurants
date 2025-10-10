# Scénario 

## creation_festivals.sql 

Ce fichier SQL sert à simuler l'ajout d'un nouveau festival dans la base de données ainsi que l'ensemble du processus lié aux préinscriptions, sélections et achats de billets.


## creation_consommation.sql
Ce fichier SQL permet de tester la création de consommations pendant un festival, la gestion concurrente des achats de plats par les participants, ainsi que le calcul du chiffre d'affaires des restaurants et du festival. Il vérifie également les règles métiers liées aux soldes et aux limitations de consommation.

## creation_transaction.sql 
Ce fichier SQL sert a tester les transactions. Celui-ci possède la meme base que creation_festivals.sql avec un exemple d'achat de billet qui est une action pouvant etre critique a l'aide des commandes SQL begin,commit,rollback.
Les transactions sont mis en commentaire et doivent etre éxécuté a part dans 2 terminals après que le fichier soit exécuté.


## creation_ticket_recapitulatif.sql 
Ce fichier SQL sert a montrer un exemple d'utilisation d'une transaction avec rollback pour la gestion des erreurs lors de la creation d'un ticket de consommation lors de l'ajout d'un plat dans la consommation.

# Exécution 
lancer la commande 
    
     \i creation_festivals.sql
    
(resp. creation_consommation.sql) a partir du dossier ETUDES.
 
Les requetes sql sont à éxécuter dans l'ordre. 

# Gestion d'erreur

Certaines requêtes présentes dans ce script sont volontairement conçues pour générer des erreurs.
Ces erreurs permettent de vérifier que les triggers et contraintes métier sont correctement appliqués par la base de données (par exemple, interdiction de consommer en dehors d'un festival, contrôle d'accès aux zones, solde insuffisant, dépassement du nombre maximum de plats, etc.). Celle-ci sont par défault mis en commentaire.

# Remarque

le fichier insert_data.sql doit etre exécuté avant l'ajout des triggers pour des raisons pratiques. Les copies sont supposé correcte et servent de base pour les démonstration de requete nécessitant beaucoups de données.