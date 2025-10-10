\i ../CREATION/create_table.sql
\cd ../CREATION 
\i insert_data.sql 
\i create_trigger.sql 
\cd ../ETUDES

-- initialisation du temps a  01/05/2025 00:00:00 

\echo "initialisation du temps a  01/05/2025 00:00:00"
SELECT init_temps(2025, 121, 00, 00); 
SELECT maintenant_temps();

--creation d'un nouveau festival:
-- préinscription : 01/06/2025 - 15/06/2025 
-- selection : 16/06/2025 - 30/06/2025 
-- ouverture : 01/07/2025 - 10/07/2025  
\! echo "creation d'un nouveau festival:\n-- préinscription : 01/06/2025 - 15/06/2025\n-- selection : 16/06/2025 - 30/06/2025\n-- ouverture : 01/07/2025 - 10/07/2025 "

INSERT INTO festivals(id_festival,date_debut_festival,date_fin_festival,date_debut_preinscription,date_fin_preinscription,date_debut_selection,date_fin_selection,prix_entre)
VALUES(3,'2025-07-01 10:00:00','2025-07-10 23:59:59','2025-06-01 00:00:00','2025-06-15 23:59:59','2025-06-16 00:00:00','2025-06-30 23:59:59',25.50) ; 
INSERT INTO billets (num_billet,id_festival)
VALUES (1,3),(2,3),(3,3);

DEALLOCATE preinscription_festival;
PREPARE preinscription_festival(text,int) AS 
    INSERT INTO preinscription(usr_login, id_festival, date_preinscription) 
    VALUES ($1,$2,maintenant_temps());



/* insertion correcte */
\! echo "\ninsertion correcte de 4 préinscription\n"
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
\! echo "\nliste des personnes ajouté a la préinscription du festival 3"
select * from preinscription  where id_festival =3;


-- selection correcte
\! echo "\n-- selection correcte"
select set_temps_w_timestamp('2025/6/17 00:00:01');
select maintenant_temps();
select selections('2025-06-18',3);
\! echo "personnes sélectionées pour pouvoir acheter leur billet le 2025-06-18:"
select * from selection where id_festival  = 3; 



-- lucie achete son billet car elle est bien sélectionné 
\! echo "-- lucie achete son billet car elle est bien sélectionner \n"
select set_temps_w_timestamp('2025/6/18 12:00:00');
select maintenant_temps() ; 
call achat_billet('lucie.blanc',3,3000,true,false,true);
\! echo "\n lucie a réussi a acheter son billet"
select * from achat_billet  where id_festival =3;

-- on refait une selection
\! echo "-- on refait une selection\n"
select set_temps_w_timestamp('2025/6/19 00:00:01');
select maintenant_temps();
select selections('2025-06-20',3);
\! echo "\nde nouvelle personnes sont sélectionné pour acheter un billet le 2025-06-20"
select * from selection  where id_festival = 3; 
/* remarque ici lucie.leblanc ne peut pas etre reselectioné car a deja achater son billet */
/* remarque marc.henry n'a pas acheter son billet lors de la premiere selection il peut donc etre resélectionné  */

\! echo "REMARQUE 1 : ici lucie.leblanc ne peut pas etre reselectioné car a deja achater son billet\nREMARQUE 2 : marc.henry n'a pas acheter son billet lors de la premiere selection il peut donc etre resélectionné  "

select set_temps_w_timestamp('2025/6/20 12:00:00');
select maintenant_temps() ; 
select * from achat_billet  where id_festival  = 3 ; 

/*

\! echo "transaction pour marc.henry qui souhaite acheter son bilet "
begin ; 
call achat_billet('marc.henry',3,10000,false,true,true);
rollback ; 
commit;

\! echo "transaction pour hugo.roux qui souhaite aussi acheter son billet "

begin ; 
call achat_billet('hugo.roux',3,10000,false,true,true);
commit; 

*/