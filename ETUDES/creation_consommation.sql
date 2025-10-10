\i creation_festivals.sql

\! echo "\n\033[35mScenario Consommation\n\033[0m"

\! echo "\033[33mInitialisation du temps a  01/05/2025 00:00:00\033[0m "
INSERT INTO participation (id_festival,num_zone,nom_restaurant)
VALUES (3,3,'La Petite Cour'),
       (3,2,'Curry House'),
       (3,1,'Sushi Yumi');
select * from participation where id_festival = 3 ; 

\prompt '\033[36mAppuyez sur Entrée pour continuer...\033[0m' dummy_var

-- creation de consommation incorrecte 
\! echo "\033[31mERREUR\033[0m : creation de consommation avec erreurs\n"
\! echo "\n\033[31m#1\033[0m :  billet inexistant" 
call creer_consommation(3,3,3,'La Petite Cour','2025/07/01 12:30:00');
\prompt '\033[36mAppuyez sur Entrée pour continuer...\033[0m' dummy_var

\! echo "\n\033[31m#2\033[0m : hors festival" 
call creer_consommation(1,3,3,'La Petite Cour','2025/08/01 12:30:00');
\prompt '\033[36mAppuyez sur Entrée pour continuer...\033[0m' dummy_var

\! echo "\n\033[31m#3\033[0m : accès zone non autorisé"
call creer_consommation(1,3,2,'Curry House','2025/07/01 19:30:00');
\prompt '\033[36mAppuyez sur Entrée pour continuer...\033[0m' dummy_var


-- creation d'une consommation correcte 
\! echo "\n\033[33mCreation d'une consommation correcte pour le billet 1 (lucie.blanc)\033[0m"
call creer_consommation(1,3,3,'La Petite Cour','2025/07/01 12:30:00');
\! echo "\n\033[33mCreation d'une consommation pour le billet 2 (marc.henry)\033[0m"
call creer_consommation(2,3,3,'La Petite Cour','2025/07/01 12:30:00');
call creer_consommation(2,3,2,'Curry House','2025/07/04 15:43:00');

select * from consommation where id_festival =3;
\prompt '\033[36mAppuyez sur Entrée pour continuer...\033[0m' dummy_var

-- exemple de concurrence : 
-- le premier passe tandis que le deuxieme non car le nombre max / j a été atteint 
\! echo "\033[33mExemple de concurrence : le premier passe tandis que le deuxieme non car le nombre max/j a été atteint\033[0m"
call ajoute_plat_consommation(1,3,'2025/07/01 12:30:00',3,'La Petite Cour','Menu spécial',2);

call ajoute_plat_consommation(2,3,'2025/07/01 12:30:00',3,'La Petite Cour','Menu spécial',2);
select * from recapitulatif where id_festival=3;
\prompt '\033[36mAppuyez sur Entrée pour continuer...\033[0m' dummy_var

-- ajout d'autre plat pour billet 1,3
\! echo "\033[33mOn ajoute d'autre plats pour le billet 1 (lucie.blanc)\033[0m"
call ajoute_plat_consommation(1,3,'2025/07/01 12:30:00',3,'La Petite Cour','Soufflé Grand Marnier',2);
call ajoute_plat_consommation(1,3,'2025/07/01 12:30:00',3,'La Petite Cour','Saint-Jacques poêlées',2);
call ajoute_plat_consommation(1,3,'2025/07/01 12:30:00',3,'La Petite Cour','Café gourmand',1);
call ajoute_plat_consommation(1,3,'2025/07/01 12:30:00',3,'La Petite Cour','Menu Dégustation',1);
select * from recapitulatif where num_billet=1 and id_festival = 3 and date_horaire= '2025/07/01 12:30:00';

\prompt '\033[36mAppuyez sur Entrée pour continuer...\033[0m' dummy_var

\! echo "\033[33mOn ajoute d'autre plats pour le billet 2 (marc.henry)\033[0m"
call ajoute_plat_consommation(2,3, '2025/07/04 15:43:00',2,'Curry House','Lamb rogan josh',2);
call ajoute_plat_consommation(2,3, '2025/07/04 15:43:00',2,'Curry House','Garlic naan',4);
call ajoute_plat_consommation(2,3, '2025/07/04 15:43:00',2,'Curry House','Samosas',10);
call ajoute_plat_consommation(2,3, '2025/07/04 15:43:00',2,'Curry House','Mango lassi',2);
select * from recapitulatif where num_billet=2 and id_festival = 3 and date_horaire= '2025/07/04 15:43:00';
\prompt '\033[36mAppuyez sur Entrée pour continuer...\033[0m' dummy_var


-- exemple d'ajoute de plat incorrecte : 
\! echo "\033[31mERREUR\033[0m : ajout de plat incorrecte :"
\! echo  "\n\033[31m#1\033[0m solde insuffisant"
call ajoute_plat_consommation(1,3,'2025/07/01 12:30:00',3,'La Petite Cour','Vin au verre',100);
\prompt '\033[36mAppuyez sur Entrée pour continuer...\033[0m' dummy_var


-- ajout d'un plat au menu avec erreur 
\! echo "\n\033[31mERREUR\033[0m : ajout d'un plat au menu avec"
\! echo  "\033[31m#1\033[0m nombre de plat max atteint" 
call ajoute_plat_menu(3,'La Petite Cour','Sauce du Chef',100,10.0);

\prompt '\033[36mAppuyez sur Entrée pour continuer...\033[0m' dummy_var

\! echo "\n\033[31m#2\033[0m ne respecte pas le prix max de sa zone "
call ajoute_plat_menu(1,'Factory','Milkshake',100,300);
\prompt '\033[36mAppuyez sur Entrée pour continuer...\033[0m' dummy_var


\! echo "\n\033[33mCalcul du chiffre d'affaire de chaque restaurants pour chaque festival\033[0m \n"
select * from calcul_chiffre_affaires();


DEALLOCATE calcul_chiffre_affaires_festival ; 
PREPARE calcul_chiffre_affaires_festival(int) AS 
    SELECT * FROM calcul_chiffre_affaires(p_id_festival => $1);  

DEALLOCATE calcul_chiffre_affaires_restaurant;
PREPARE calcul_chiffre_affaires_restaurant(int,VARCHAR) AS 
    SELECT * FROM calcul_chiffre_affaires(p_num_zone => $1,p_nom_restaurant => $2);
\prompt '\033[36mAppuyez sur Entrée pour continuer...\033[0m' dummy_var
\! echo "\n\033[33mChiffre d'affaire global de chaque restaurants pour le festival 3\033[0m" 
EXECUTE calcul_chiffre_affaires_festival(3);
\prompt '\033[36mAppuyez sur Entrée pour continuer...\033[0m' dummy_var

\! echo "\n\033[33mChiffre d'affaire global du restaurant 'La Petite Cour' de la zone 3\033[0m" 
EXECUTE calcul_chiffre_affaires_restaurant(3,'La Petite Cour');

\prompt '\033[36mAppuyez sur Entrée pour continuer...\033[0m' dummy_var

\! echo "\n\033[33mClassement globaux des restaurants de la zone 3 \033[0m"
select * from classement_restaurants(p_num_zone => 3);
\prompt '\033[36mAppuyez sur Entrée pour continuer...\033[0m' dummy_var

\! echo "\n\033[33mExplain d'une requete utilisant l'index secondaire sur prix_payé\033[0m"
select * from achat_billet where prix_payé >100 and prix_payé <500 ;
explain select * from achat_billet where prix_payé >100 and prix_payé <500 ;
\! echo  "\n\033[34mEND  \033[0m "

