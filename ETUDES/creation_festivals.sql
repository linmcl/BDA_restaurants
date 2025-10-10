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
\! echo "\033[33mCréation d'un nouveau festival:  \033[0m \n-- préselection : 01/06/2025 - 15/06/2025\n-- selection : 16/06/2025 - 30/06/2025\n-- ouverture : 01/07/2025 - 10/07/2025  "

INSERT INTO festivals(id_festival,date_debut_festival,date_fin_festival,date_debut_preinscription,date_fin_preinscription,date_debut_selection,date_fin_selection,prix_entre)
VALUES(3,'2025-07-01 10:00:00','2025-07-10 23:59:59','2025-06-01 00:00:00','2025-06-15 23:59:59','2025-06-16 00:00:00','2025-06-30 23:59:59',25.50) ; 
INSERT INTO billets (num_billet,id_festival)
VALUES (1,3),(2,3);
\prompt '\033[36mAppuyez sur Entrée pour continuer...\033[0m' dummy_var

-- exemple avec de mauvaise date : 
\! echo "\033[31mERREUR\033[0m : exemple de création de festivals avec de mauvaise date" 
INSERT INTO festivals(id_festival,date_debut_festival,date_fin_festival,date_debut_preinscription,date_fin_preinscription,date_debut_selection,date_fin_selection,prix_entre)
VALUES(5,'2025-07-01 10:00:00','2025-07-10 23:59:59','2023-06-01 00:00:00','2025-06-15 23:59:59','2025-06-16 00:00:00','2025-06-30 23:59:59',25.50) ; 
\prompt '\033[36mAppuyez sur Entrée pour continuer...\033[0m' dummy_var


DEALLOCATE preinscription_festival;
PREPARE preinscription_festival(text,int) AS 
    INSERT INTO preinscription(usr_login, id_festival, date_preinscription) 
    VALUES ($1,$2,maintenant_temps());


-- si on laisse cette ligne erreur car ce n'est pas encore la période de préselection 
\! echo "\n\033[31mERREUR\033[0m :ce n'est pas encore le debut de la période de préselection"
EXECUTE preinscription_festival('lucie.blanc',3) ; 
\prompt '\033[36mAppuyez sur Entrée pour continuer...\033[0m' dummy_var


/* insertion correcte */
\! echo "\n\033[32mSUCCÈS\033[0m : insertion correcte de 4 preselection\n"
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

\! echo "\n\033[33mListe des personnes ajouté a la préselection du festival 3\033[0m"
select * from preinscription  where id_festival =3;
\prompt '\033[36mAppuyez sur Entrée pour continuer...\033[0m' dummy_var


-- erreur car ce n'est pas la période de sélection  du festival 3
\! echo "\n\033[31mERREUR\033[0m : les sélection ne peuvent se faire seulement lors de la période de sélection"
select selections('2025-06-17',3);
\prompt '\033[36mAppuyez sur Entrée pour continuer...\033[0m' dummy_var



-- selection correcte
\! echo "\n\033[32mSUCCÈS\033[0m : selection correcte"
select set_temps_w_timestamp('2025/6/17 00:00:01');
select maintenant_temps();
select selections('2025-06-18',3);
\! echo "\033[33mPersonnes sélectionées pour pouvoir acheter leur billet le 2025-06-18:\033[0m"
select * from selection where id_festival  = 3; 
\prompt '\033[36mAppuyez sur Entrée pour continuer...\033[0m' dummy_var

-- erreur car lucie.blanc n'achete pas le jour de sa sélection 
\! echo "\n\033[31mERREUR\033[0m : car lucie.blanc n'achete pas le jour de sa sélection"
call achat_billet('lucie.blanc',3,30000,true,true,false);
select * from achat_billet where id_festival =3; 
\prompt '\033[36mAppuyez sur Entrée pour continuer...\033[0m' dummy_var


-- lucie achete son billet car elle est bien sélectionné 
\! echo "\033[32mSUCCÈS\033[0m : lucie achete son billet car elle est bien sélectionner \n"
select set_temps_w_timestamp('2025/6/18 12:00:00');
select maintenant_temps() ; 
call achat_billet('lucie.blanc',3,3000,true,false,true);
\! echo "\n \033[32mSUCCÈS\033[0m : lucie a réussi a acheter son billet"
select * from achat_billet  where id_festival =3;
\prompt '\033[36mAppuyez sur Entrée pour continuer...\033[0m' dummy_var

-- on refait une selection
\! echo "\033[33m--\033[0m on refait une selection\n"
select set_temps_w_timestamp('2025/6/19 00:00:01');
select maintenant_temps();
select selections('2025-06-20',3);
\! echo "\n \033[33mDe nouvelle personnes sont sélectionné pour acheter un billet le 2025-06-20  \033[0m "
select * from selection  where id_festival = 3; 
/* remarque ici lucie.leblanc ne peut pas etre reselectioné car a deja achater son billet */
/* remarque marc.henry n'a pas acheter son billet lors de la premiere selection il peut donc etre resélectionné  */
\! echo "\033[33mREMARQUE 1 : \033[0mici lucie.leblanc ne peut pas etre reselectioné car a deja achater son billet"
\! echo  "\033[33mREMARQUE 2 : \033[0mmarc.henry n'a pas acheter son billet lors de la premiere selection il peut donc etre resélectionné  "
\prompt '\033[36mAppuyez sur Entrée pour continuer...\033[0m' dummy_var
-- marc.henry tente d'acheter son billet 
\! echo  "\n\033[33mmarc.henry tente d'acheter son billet  \033[0m "
select set_temps_w_timestamp('2025/6/20 12:00:00');
select maintenant_temps() ; 
call achat_billet('marc.henry',3,10000,false,true,true);
select * from achat_billet  where id_festival =3;
\prompt '\033[36mAppuyez sur Entrée pour continuer...\033[0m' dummy_var

-- on refait une sélection -> plus de billet dispo ? 
\! echo "\033[33mOn refait une sélection -> plus de billet dispo ?\033[0m\n"
select set_temps_w_timestamp('2025/6/20 15:00:01');
select maintenant_temps();
select selections_random('2025-06-21',3);

select * from selection  where id_festival = 3; 
\! echo  "\n\033[34mEND  \033[0m "

