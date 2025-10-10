\i creation_festivals.sql

\! echo "insertion des restaurant qui participe au festival"
INSERT INTO participation (id_festival,num_zone,nom_restaurant)
VALUES (3,3,'La Petite Cour'),
       (3,2,'Curry House'),
       (3,1,'Sushi Yumi');
select * from participation where id_festival = 3 ; 

-- creation d'une consommation correcte 
\! echo "\n-- creation d'une consommation correcte pour le billet 1 (lucie.blanc)"
call creer_consommation(1,3,3,'La Petite Cour','2025/07/01 12:30:00');
\! echo "\n-- creation d'une consommation pour le billet 2 (marc.henry)"
call creer_consommation(2,3,3,'La Petite Cour','2025/07/01 12:30:00');
call creer_consommation(2,3,2,'Curry House','2025/07/04 15:43:00');


-- le premier passe tandis que le deuxieme non car le nombre max / j a été atteint 
call ajoute_plat_consommation(1,3,'2025/07/01 12:30:00',3,'La Petite Cour','Menu spécial',2);

-- ajout d'autre plat pour billet 1,3
\! echo "On ajoute d'autre plats pour le billet 1 (lucie.blanc)"
call ajoute_plat_consommation(1,3,'2025/07/01 12:30:00',3,'La Petite Cour','Soufflé Grand Marnier',2);
call ajoute_plat_consommation(1,3,'2025/07/01 12:30:00',3,'La Petite Cour','Saint-Jacques poêlées',2);
call ajoute_plat_consommation(1,3,'2025/07/01 12:30:00',3,'La Petite Cour','Café gourmand',1);
call ajoute_plat_consommation(1,3,'2025/07/01 12:30:00',3,'La Petite Cour','Menu Dégustation',1);

\! echo "On ajoute d'autre plats pour le billet 2 (marc.henry)"
call ajoute_plat_consommation(2,3, '2025/07/04 15:43:00',2,'Curry House','Lamb rogan josh',2);
call ajoute_plat_consommation(2,3, '2025/07/04 15:43:00',2,'Curry House','Garlic naan',4);
call ajoute_plat_consommation(2,3, '2025/07/04 15:43:00',2,'Curry House','Samosas',10);
call ajoute_plat_consommation(2,3, '2025/07/04 15:43:00',2,'Curry House','Mango lassi',2);

\! echo "\n\033[35m CREATION TICKET DE CONSOMMATION\033[0\n"
\prompt '\033[36mAppuyez sur Entrée pour continuer...\033[0m' dummy_var


-- Pour des raisons économique le festival n'autorise pas les remboursements
-- donc on interdit la suppression de ligne dans la table récapitulatif 
\! echo '\n\033[33mPour des raisons économique le festival n autorise pas les remboursements donc on interdit la suppression de tuple dans récapitulatif\033[0m\n' 
delete from recapitulatif  where nom_plat ='samosas';
\prompt '\033[36mAppuyez sur Entrée pour continuer...\033[0m' dummy_var

\! echo '\n\033[33mSi un restaurant fait une erreur de manipulation et introduit une consommation erroné, il utilise les transactions pour corriger \033[0m'
\prompt '\033[36mAppuyez sur Entrée pour continuer...\033[0m' dummy_var

BEGIN;
\! echo "\n\033[33mOn commence a creer un ticket de consommation \033[0m"
call creer_consommation(2,3,2,'Curry House','2025/07/04 20:10:00');
select * from consommation where num_billet=2 and id_festival = 3 and date_horaire= '2025/07/04 20:10:00';
\prompt '\033[36mAppuyez sur Entrée pour continuer...\033[0m' dummy_var

\! echo "\n\033[33mOn rajoute des plats\033[0m"
call ajoute_plat_consommation(2,3, '2025/07/04 20:10:00',2,'Curry House','Lamb rogan josh',2);
SAVEPOINT ajout_1;
call ajoute_plat_consommation(2,3, '2025/07/04 20:10:00',2,'Curry House','Garlic naan',4);
SAVEPOINT ajout_2;
select * from recapitulatif where num_billet=2 and id_festival = 3 and date_horaire= '2025/07/04 20:10:00';
\prompt '\033[36mAppuyez sur Entrée pour continuer...\033[0m' dummy_var

\! echo "\n\033[33mOn met par erreur 50 samosas au client !!!!\033[0m"
call ajoute_plat_consommation(2,3,'2025/07/04 20:10:00',2,'Curry House','Samosas',50);
select * from recapitulatif where num_billet=2 and id_festival = 3 and date_horaire= '2025/07/04 20:10:00';
\prompt '\033[36mAppuyez sur Entrée pour continuer...\033[0m' dummy_var

ROLLBACk TO ajout_2;
\prompt '\033[36mAppuyez sur Entrée pour continuer...\033[0m' dummy_var

select * from recapitulatif where num_billet=2 and id_festival = 3 and date_horaire= '2025/07/04 20:10:00';
\prompt '\033[36mAppuyez sur Entrée pour continuer...\033[0m' dummy_var
call ajoute_plat_consommation(2,3,'2025/07/04 20:10:00',2,'Curry House','Samosas',3);
select * from recapitulatif where num_billet=2 and id_festival = 3 and date_horaire= '2025/07/04 20:10:00';
COMMIT; 

