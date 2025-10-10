\i ../CREATION/create_table.sql
\cd ../CREATION 
\i insert_data.sql 
\i create_trigger.sql 
\cd ../ETUDES

-- initialisation du temps a  01/05/2025 00:00:00 

\! echo "\033[33mInitialisation du temps a  01/05/2025 00:00:00\033[0m "
SELECT init_temps(2025, 121, 00, 00); 
SELECT maintenant_temps();
\prompt '\033[36mAppuyez sur Entrée pour continuer...\033[0m' dummy_var
--creation d'un nouveau festival:
-- préselection : 01/06/2025 - 15/06/2025 
-- selection : 16/06/2025 - 30/06/2025 
-- ouverture : 01/07/2025 - 10/07/2025  
\! echo "\033[33mCréation d'un nouveau festival:  \033[0m \n-- préselection : 01/06/2025 - 15/06/2025\n-- selection : 16/06/2025 - 30/06/2025\n-- ouverture : 01/07/2025 - 10/07/2025 "

INSERT INTO festivals(id_festival,date_debut_festival,date_fin_festival,date_debut_preinscription,date_fin_preinscription,date_debut_selection,date_fin_selection,prix_entre)
VALUES(3,'2025-07-01 10:00:00','2025-07-10 23:59:59','2025-06-01 00:00:00','2025-06-15 23:59:59','2025-06-16 00:00:00','2025-06-30 23:59:59',25.50) ; 
INSERT INTO billets (num_billet,id_festival)
VALUES (1,3),(2,3),(3,3);


DEALLOCATE preinscription_festival;
PREPARE preinscription_festival(text,int) AS 
    INSERT INTO preinscription(usr_login, id_festival, date_preinscription) 
    VALUES ($1,$2,maintenant_temps());

\prompt '\033[36mAppuyez sur Entrée pour continuer...\033[0m' dummy_var
/* insertion correcte */
\! echo "\n\033[32mSUCCÈS\033[0m : Insertion correcte de 6 préselection\n"
SELECT set_temps(2025,153,10,0);
select maintenant_temps();

EXECUTE preinscription_festival('lucie.blanc',3) ; 


SELECT set_temps(2025,153,12,0);
select maintenant_temps();

EXECUTE preinscription_festival('marc.henry',3) ; 

SELECT set_temps(2025,153,12,10);
select maintenant_temps();

EXECUTE preinscription_festival('hugo.roux',3) ; 
EXECUTE preinscription_festival('sophie.berger',3);
EXECUTE preinscription_festival('quentin.leclerc',3);
EXECUTE preinscription_festival('francois.leroy',3);

\! echo "\n\033[33mListe des personnes ajouté a la préselection du festival 3\033[0m"
\! echo "\033[33mPersonnes sélectionnées pour pouvoir acheter leur billet le 2025-06-18:\033[0m"
SELECT 
    s.*,
    COALESCE(
        (SELECT tp.type_bonus 
         FROM abonnement a
         JOIN type_pass tp ON a.type_bonus = tp.type_bonus AND a.duree = tp.duree
         WHERE a.usr_login = s.usr_login
         ORDER BY 
             CASE tp.type_bonus
                 WHEN 'fourchette_or' THEN 1
                 WHEN 'couteau_fer' THEN 2
                 WHEN 'cuillere_bronze' THEN 3
                 ELSE 4
             END ASC
         LIMIT 1),
        'Aucun pass'
    ) AS type_pass
FROM preinscription s
WHERE s.id_festival = 3;

\prompt '\033[36mAppuyez sur Entrée pour continuer...\033[0m' dummy_var

\! echo "\n\033[32mSUCCÈS\033[0m: Selection correcte"
select set_temps_w_timestamp('2025/6/17 00:00:01');
select maintenant_temps();
select selections_par_pass('2025-06-18',3);
\! echo "\033[33mPersonnes sélectionnées pour pouvoir acheter leur billet le 2025-06-18:\033[0m"
SELECT 
    s.*,
    COALESCE(
        (SELECT tp.type_bonus 
         FROM abonnement a
         JOIN type_pass tp ON a.type_bonus = tp.type_bonus AND a.duree = tp.duree
         WHERE a.usr_login = s.usr_login
         ORDER BY 
             CASE tp.type_bonus
                 WHEN 'fourchette_or' THEN 1
                 WHEN 'couteau_fer' THEN 2
                 WHEN 'cuillere_bronze' THEN 3
                 ELSE 4
             END ASC
         LIMIT 1),
        'Aucun pass'
    ) AS type_pass
FROM selection s
WHERE s.id_festival = 3;

\prompt '\033[36mAppuyez sur Entrée pour continuer...\033[0m' dummy_var

------------------------ ÉTAPE 1 : Quentin et francois achètent leurs billets ------------------------

\! echo "\n\033[33mQuentin.leroy et francois.leroy achètent leurs billets\033[0m"

-- Avance le temps au 18/06/2025 12:00 (période d'achat valide)
SELECT set_temps_w_timestamp('2025-06-18 12:00:00');
SELECT maintenant_temps(); -- Affiche 2025-06-18 12:00:00

-- Quentin.leroy achète son billet (pass OR)
call achat_billet('quentin.leclerc', 3, 3000, true, false, true);

-- Hugo.roux achète son billet (pass BRONZE)
call achat_billet('francois.leroy', 3, 2500, false, false, true);

\! echo "\n\033[33mBillets après achat de Quentin et francois\033[0m"
SELECT * FROM achat_billet WHERE id_festival = 3;
\prompt '\033[36mAppuyez sur Entrée pour continuer...\033[0m' dummy_var 

------------------------ ÉTAPE 2 : hugo.roux tente d'acheter ------------------------

\! echo "\n\033[31mERREUR\033[0m : hugo.roux tente d'acheter sans être sélectionnée"
call achat_billet('hugo.roux', 3, 2000, false, false, false); 
\prompt '\033[36mAppuyez sur Entrée pour continuer...\033[0m' dummy_var
-- Résultat: ERREUR: L'utilisateur hugo.roux n'est pas sélectionné pour cette période

------------------------ ÉTAPE 3 : Lucie.blanc tente trop tard ------------------------

\! echo "\n\033[31mERREUR\033[0m :Lucie.blanc tente d'acheter après la période"
SELECT set_temps_w_timestamp('2025-06-19 09:00:00'); -- Période expirée
call achat_billet('lucie.blanc', 3, 3500, true, false, false); 
-- Résultat: ERREUR: Date invalide : 2025-06-19 09:00:00 hors période de sélection
\prompt '\033[36mAppuyez sur Entrée pour continuer...\033[0m' dummy_var
------------------------ ÉTAPE 4 : Nouvelle sélection ------------------------

\! echo "\n\033[33mNouvelle sélection le 20/06 \033[0m"
SELECT set_temps_w_timestamp('2025-06-20 00:00:01');
select selections_par_pass('2025-06-20',3);

\! echo "\n\033[33mNouvelle liste de sélection \033[0m"
SELECT
    s.*,
    COALESCE(a.type_bonus, 'Aucun pass') AS type_pass
FROM selection s
LEFT JOIN abonnement a ON s.usr_login = a.usr_login
WHERE s.id_festival = 3
order by s.periode asc ;
\prompt '\033[36mAppuyez sur Entrée pour continuer...\033[0m' dummy_var
------------------------ ÉTAPE 5 : Lucie.blanc achète ------------------------

\! echo "\n\033[33mLucie.blanc achète son billet \033[0m"
SELECT set_temps_w_timestamp('2025-06-20 14:30:00');
call achat_billet('lucie.blanc', 3, 4000, true, true, false);

\! echo "\n\033[33mBillets après achat de Lucie \033[0m"
SELECT * FROM achat_billet WHERE id_festival = 3;
\prompt '\033[36mAppuyez sur Entrée pour continuer...\033[0m' dummy_var
------------------------ ÉTAPE 6 : hugo.roux retente ------------------------

\! echo "\n\033[31mERREUR\033[0m : hugo.roux tente à nouveau mais il n'y a plus de billets"
call achat_billet('hugo.roux', 3, 2000, false, false, true);
-- Résultat: ERREUR: Plus de billets disponibles pour le festival 3

\! echo "\n\033[33mÉtat final des billets \033[0m"
SELECT * FROM billets WHERE id_festival = 3;
SELECT * FROM achat_billet WHERE id_festival = 3;
\! echo  "\n\033[34mEND  \033[0m "
