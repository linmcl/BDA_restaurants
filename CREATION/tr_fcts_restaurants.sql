DROP FUNCTION if exists afficher_historique_commande(integer,integer) cascade;
drop PROCEDURE if exists creer_consommation(int,int,int,text,TIMESTAMP) cascade ;
drop PROCEDURE if exists ajoute_plat_consommation(int,int,TIMESTAMP,int,VARCHAR,VARCHAR,int) cascade ; 
drop PROCEDURE if exists ajoute_plat_menu(int,VARCHAR(255),VARCHAR(255),int,FLOAT(2)) cascade ; 
drop function if exists compter_nb_plat_acheter(date,VARCHAR,VARCHAR) cascade ;
drop function if exists compter_solde_restante(int,int) cascade ;
drop function if exists a_acces_zone(int,int,int) cascade ;
drop function if exists verif_stock_plat() cascade ;
drop function if exists verif_billet_valide() cascade ;
drop function if exists verif_zone_valide()  cascade ; 
drop function if exists verif_solde_suffisant() cascade ; 
drop function if exists afficher_historique_commande(int,int) cascade ;
drop function if exists verif_nb_plats() cascade ;
drop function if exists verif_prix_plat_zone() cascade ;
drop function if exists interdit_delete() cascade ;
DROP FUNCTION if exists calcul_chiffre_affaires(TIMESTAMP,TIMESTAMP,INT,INT,VARCHAR(255)) cascade ;
drop function if exists classement_restaurants(TIMESTAMP,TIMESTAMP,INT) cascade;



-- fonction : ajoute une consommation 
CREATE OR REPLACE PROCEDURE creer_consommation(
    p_num_billet INT,
    p_id_festival INT,
    p_num_zone INT, 
    p_nom_restaurant TEXT,
    p_date_horaire TIMESTAMP
)LANGUAGE plpgsql AS $$ 
BEGIN 

    INSERT INTO consommation(num_billet,id_festival,num_zone,nom_restaurant,date_horaire) 
    VALUES (p_num_billet,p_id_festival,p_num_zone,p_nom_restaurant,p_date_horaire);

END; 
$$; 

-- fonction : ajoute un plat dans le récapitulatif de consommation 
CREATE OR REPLACE PROCEDURE ajoute_plat_consommation(
    p_num_billet INT,
    p_id_festival INT,
    p_date_horaire TIMESTAMP,
    p_num_zone INT, 
    p_nom_restaurant VARCHAR(255),
    p_nom_plat VARCHAR(255),
    p_quantite INT
)LANGUAGE plpgsql AS $$ 
BEGIN 
    INSERT INTO recapitulatif(num_billet,id_festival,date_horaire,num_zone,nom_restaurant,nom_plat,quantite)
    VALUES (p_num_billet,p_id_festival,p_date_horaire,p_num_zone,p_nom_restaurant,p_nom_plat,p_quantite);
END; 
$$; 


-- fonction : ajoute un plat dans le menu d'un restaurant 
CREATE OR REPLACE PROCEDURE ajoute_plat_menu (
    p_num_zone INT, 
    p_nom_restaurant VARCHAR(255),
    p_nom_plat VARCHAR(255),
    p_quantite_max_quotidien INT,
    p_prix FLOAT(2)
)LANGUAGE plpgsql AS $$ 
BEGIN 
    INSERT INTO menu(num_zone,nom_restaurant,nom_plat,quantite_max_quotidien,prix)
    VALUES (p_num_zone,p_nom_restaurant,p_nom_plat,p_quantite_max_quotidien,p_prix);
END; 
$$; 






-- fonction qui compte le nombre d'un plat un jour donnée
CREATE OR REPLACE FUNCTION compter_nb_plat_acheter(
    p_date DATE, p_nom_restaurant VARCHAR(255), p_nom_plat VARCHAR(255)
)
RETURNS INT AS $$
DECLARE
    v_nb_plat_acheter INT;
BEGIN
    SELECT SUM(quantite)
    INTO v_nb_plat_acheter
    FROM recapitulatif
    WHERE DATE(date_horaire) = p_date 
    AND nom_restaurant = p_nom_restaurant
    AND nom_plat = p_nom_plat;
    
    RETURN v_nb_plat_acheter;
END;
$$ LANGUAGE plpgsql;

-- fonction qui renvoie le solde restant dans le billet 
CREATE OR REPLACE FUNCTION compter_solde_restante(
    p_num_billet INT,
    p_id_festival INT
)
RETURNS FLOAT AS $$
DECLARE 
 v_credit_utilise FLOAT(2):=0;
 v_prix_plat FLOAT(2);
 v_credit_total FLOAT(2);
 ligne RECORD;
BEGIN
    SELECT credit_total INTO v_credit_total
    FROM achat_billet
    WHERE id_festival =p_id_festival AND num_billet=p_num_billet;

    FOR ligne IN
    SELECT *
    FROM recapitulatif
    WHERE num_billet = p_num_billet AND id_festival = p_id_festival
  LOOP
    SELECT prix INTO v_prix_plat FROM menu 
    WHERE ligne.nom_plat = nom_plat AND  nom_restaurant=ligne.nom_restaurant;

    v_credit_utilise := v_credit_utilise + (ligne.quantite * v_prix_plat);
  END LOOP;
  RETURN COALESCE(v_credit_total- v_credit_utilise,0);

END;
$$ LANGUAGE plpgsql;
--select compter_solde_restante(1,3);


-- fonction qui renvoie true si un billet à acces la zone donnée en parametre 
CREATE OR REPLACE FUNCTION a_acces_zone(
    p_zone INT,
    p_num_billet INT,
    p_id_festival INT
)
RETURNS BOOLEAN AS $$
BEGIN
   PERFORM 1 FROM billet_acces WHERE num_zone = p_zone AND num_billet = p_num_billet AND p_id_festival = id_festival;
   IF FOUND THEN RETURN true;
   ELSE  RETURN false; 
   END IF;
END;
$$ LANGUAGE plpgsql;
--select a_acces_zone(3,1,3);

-------- CONSOMMATION ---------

/*trigger : ne peut pas ajouter a recap un plat si il a deja été commander son nombre de fois max /j*/
CREATE OR REPLACE FUNCTION verif_stock_plat()
RETURNS TRIGGER AS $$
DECLARE
    v_nb_plat_max INT;
    v_nb_plat_commander INT;
BEGIN
    v_nb_plat_commander = compter_nb_plat_acheter((NEW.date_horaire::DATE),NEW.nom_restaurant,NEW.nom_plat);
    v_nb_plat_max = (
        SELECT quantite_max_quotidien 
        FROM menu 
        WHERE num_zone = NEW.num_zone 
        AND nom_restaurant = NEW.nom_restaurant 
        AND nom_plat = NEW.nom_plat
    );
    -- RAISE notice '%  % ',v_nb_plat_max, v_nb_plat_commander;
    IF (v_nb_plat_commander) > v_nb_plat_max THEN
    RAISE EXCEPTION 'Le plat % a atteint son stock maximum, nombre de plat restant : % (quantité souhaitée : %) ', NEW.nom_plat, ( v_nb_plat_max-v_nb_plat_commander+NEW.quantite), (NEW.quantite);
    END IF;

    RETURN NULL;
END;    
$$ LANGUAGE plpgsql; 

CREATE OR REPLACE TRIGGER tr_verifier_stock_plat
AFTER INSERT OR UPDATE ON recapitulatif
FOR EACH ROW EXECUTE FUNCTION verif_stock_plat();

/*trigger : il faut avoir un ticket valide pour le festival auquel on mange */
CREATE OR REPLACE FUNCTION verif_billet_valide()
RETURNS TRIGGER AS $$
DECLARE
    festival_dates RECORD;
BEGIN
    -- 1. Vérifier l'existence du billet pour le festival
    IF NOT EXISTS (
        SELECT 1 
        FROM billets 
        WHERE num_billet = NEW.num_billet
        AND id_festival = NEW.id_festival
    ) THEN
        RAISE EXCEPTION 'Billet invalide : Le billet % n''existe pas pour le festival %', 
            NEW.num_billet, NEW.id_festival;
    END IF;

    -- 2. Vérifier les dates du festival
    SELECT date_debut_festival, date_fin_festival
    INTO festival_dates
    FROM festivals
    WHERE id_festival = NEW.id_festival;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Festival % introuvable', NEW.id_festival;
    END IF;

    -- 3. Vérifier que la consommation est pendant le festival
    IF NEW.date_horaire NOT BETWEEN festival_dates.date_debut_festival 
                             AND festival_dates.date_fin_festival THEN
        RAISE EXCEPTION 
            'Date invalide : % hors période du festival (% à %)',
            NEW.date_horaire,
            festival_dates.date_debut_festival,
            festival_dates.date_fin_festival;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tr_verif_billet_valide
BEFORE INSERT OR UPDATE ON consommation
FOR EACH ROW EXECUTE FUNCTION verif_billet_valide();



/*trigger : verifie que la consommation se fait dans une zone autorisé */
CREATE OR REPLACE FUNCTION verif_zone_valide()
RETURNS TRIGGER AS $$
DECLARE
BEGIN
    IF NOT a_acces_zone(NEW.num_zone,NEW.num_billet,NEW.id_festival) THEN 
    raise EXCEPTION 'Le billet %,% n''a pas accès a la zone %',NEW.num_billet,NEW.id_festival,NEW.num_zone;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tr_verif_zone_valide
BEFORE INSERT OR UPDATE ON consommation
FOR EACH ROW EXECUTE FUNCTION verif_zone_valide();

/*trigger : verifie que la personne ai suffisament de credit pour ajouter ce plat a son recap */
CREATE OR REPLACE FUNCTION verif_solde_suffisant()
RETURNS TRIGGER AS $$
DECLARE
v_prix_plat FLOAT(2);
BEGIN
    -- recupere le prix du plat commandé
    SELECT prix INTO v_prix_plat FROM menu 
    WHERE NEW.nom_plat = nom_plat AND  nom_restaurant=NEW.nom_restaurant;

    -- si la somme apres ajout est négatif alors l'opération est refusé
    IF (compter_solde_restante(NEW.num_billet,NEW.id_festival)-(NEW.quantite * v_prix_plat)) <0 THEN 
    raise EXCEPTION 'solde insuffisant; solde actuelle : % , solde si ajout : % ',compter_solde_restante(NEW.num_billet,NEW.id_festival),(compter_solde_restante(NEW.num_billet,NEW.id_festival)-(NEW.quantite * v_prix_plat));
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tr_verif_solde_suffisant
BEFORE INSERT OR UPDATE ON recapitulatif
FOR EACH ROW EXECUTE FUNCTION verif_solde_suffisant();



/* function : afficher l'historique d'un bon de commande recap */
CREATE OR REPLACE FUNCTION afficher_historique_commande(
    p_num_billet INT,
    p_id_festival INT
)
RETURNS TABLE (
    date_commande DATE,
    restaurant VARCHAR(255),
    plat VARCHAR(255),
    quantite INT,
    prix_unitaire NUMERIC,
    sous_total NUMERIC,
    total_commande NUMERIC
) AS $$
BEGIN
    -- Vérifier si le bon de commande existe
    IF NOT EXISTS (
        SELECT 1 
        FROM recapitulatif 
        WHERE num_billet = p_num_billet 
        AND id_festival = p_id_festival
    ) THEN
        RAISE EXCEPTION 'Bon de commande % introuvable pour le festival %', 
            p_num_billet, p_id_festival;
    END IF;

    -- Retourner les détails
    RETURN QUERY
    SELECT 
        r.date_horaire::DATE as date_commande,
        r.nom_restaurant as restaurant,
        r.nom_plat as plat,
        r.quantite as quantite,
        m.prix::NUMERIC as prix_unitaire,
        (r.quantite * m.prix)::NUMERIC(10,2) as sous_total,
        (SELECT SUM(r2.quantite * m2.prix) 
         FROM recapitulatif r2
         JOIN menu m2 ON r2.num_zone = m2.num_zone
             AND r2.nom_restaurant = m2.nom_restaurant
             AND r2.nom_plat = m2.nom_plat
         WHERE r2.num_billet = p_num_billet
             AND r2.id_festival = p_id_festival AND r2.date_horaire::DATE = r.date_horaire::DATE
        )::NUMERIC(10,2) as total_commande

    FROM recapitulatif r
    JOIN menu m ON r.num_zone = m.num_zone
        AND r.nom_restaurant = m.nom_restaurant
        AND r.nom_plat = m.nom_plat
    WHERE r.num_billet = p_num_billet
        AND r.id_festival = p_id_festival;

END;
$$ LANGUAGE plpgsql;
--select * from afficher_historique_commande(1002,1);


/*3 un un menu ne peut pas avoir plus que 10 plat dans son menu */
CREATE OR REPLACE FUNCTION verif_nb_plats()
RETURNS TRIGGER AS $$
DECLARE
    nb_plats_actuels INT;
BEGIN
    -- Compter le nombre de plats existants pour ce restaurant
    SELECT COUNT(*) INTO nb_plats_actuels
    FROM menu
    WHERE num_zone = NEW.num_zone
      AND nom_restaurant = NEW.nom_restaurant;

    -- Vérifier si l'ajout/mise à jour dépasse la limite
    IF (TG_OP = 'INSERT' AND nb_plats_actuels >= 10) THEN
        RAISE EXCEPTION 'Menu complet (max 10 plats). Plats actuels: %', nb_plats_actuels;
    ELSIF (TG_OP = 'UPDATE' AND OLD.num_zone = NEW.num_zone 
           AND OLD.nom_restaurant = NEW.nom_restaurant 
           AND nb_plats_actuels >= 10) THEN
        RAISE EXCEPTION 'Menu complet (max 10 plats)';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tr_verifier_nb_plats
BEFORE INSERT OR UPDATE ON menu
FOR EACH ROW EXECUTE FUNCTION verif_nb_plats();


/* trigger : un plat ne peut pas coûter plus chere que le prix maximal fixé par la zone où elle se situe*/
CREATE OR REPLACE FUNCTION verif_prix_plat_zone()
RETURNS TRIGGER AS $$
DECLARE 
    v_tarif_max FLOAT(2);
BEGIN

 SELECT tarif_max_plat INTO v_tarif_max 
        FROM zone 
        WHERE num_zone = NEW.num_zone;

    IF NEW.prix > v_tarif_max
    THEN
        RAISE EXCEPTION 'Le plat %(%$/u) est trop cher pour la zone % ( %$/u max)', NEW.nom_plat,NEW.prix, NEW.num_zone,v_tarif_max;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tr_verifier_prix_plat_zone
BEFORE INSERT OR UPDATE ON menu
FOR EACH ROW EXECUTE FUNCTION verif_prix_plat_zone();

CREATE OR REPLACE FUNCTION interdit_delete()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'Suppression interdite sur cette table !';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_interdit_delete
BEFORE DELETE ON recapitulatif
FOR EACH STATEMENT
EXECUTE FUNCTION interdit_delete();


/* fct : calcule le chiffre d'affaire  */
CREATE OR REPLACE FUNCTION calcul_chiffre_affaires(
    p_date_debut TIMESTAMP DEFAULT NULL,
    p_date_fin TIMESTAMP DEFAULT NULL,
    p_id_festival INT DEFAULT NULL,
    p_num_zone INT DEFAULT NULL,
    p_nom_restaurant VARCHAR(255) DEFAULT NULL  
)
RETURNS TABLE (
    id_festival INT,
    num_zone INT,
    nom_restaurant VARCHAR(255),
    nombre_plat_vendu NUMERIC(10,2),
    chiffre_affaires NUMERIC(10,2)
)
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(f.id_festival,-1),
        rst.num_zone,
        rst.nom_restaurant,
        COALESCE(SUM(r.quantite)::NUMERIC(10,2),0),
        COALESCE(SUM(r.quantite * m.prix)::NUMERIC(10,2),0) AS total
     FROM festivals as f CROSS JOIN restaurants as rst 
        LEFT JOIN recapitulatif r ON r.id_festival = f.id_festival and r.num_zone = rst.num_zone and r.nom_restaurant=rst.nom_restaurant 
        LEFT JOIN menu m ON m.num_zone =  rst.num_zone and  m.nom_restaurant = rst.nom_restaurant and m.nom_plat = r.nom_plat 
    WHERE 
        (p_date_debut IS NULL OR r.date_horaire >= p_date_debut)
        AND (p_date_fin IS NULL OR r.date_horaire <= p_date_fin)
        AND (p_num_zone IS NULL OR rst.num_zone = p_num_zone)
        AND (p_nom_restaurant IS NULL OR rst.nom_restaurant = p_nom_restaurant)
        AND (p_id_festival IS NULL OR f.id_festival = p_id_festival)

    GROUP BY rst.num_zone, f.id_festival, rst.nom_restaurant 
    ORDER BY total desc,rst.nom_restaurant,rst.num_zone,f.id_festival;

END;
$$ LANGUAGE plpgsql;


/* classement des meilleurs restaurant en terme de chiffre d'affaire (window)*/
CREATE OR REPLACE FUNCTION classement_restaurants(
    p_date_debut TIMESTAMP DEFAULT NULL,
    p_date_fin TIMESTAMP DEFAULT NULL,
    p_num_zone INT DEFAULT NULL
)
RETURNS TABLE (
    position_rank BIGINT,
    num_zone INT,
    nom_restaurant VARCHAR(255),
    chiffre_affaires NUMERIC(10,2),
    part_marche NUMERIC(5,2)
)
AS $$
BEGIN
    RETURN QUERY
    WITH ca_restaurants AS (
        SELECT
            rst.num_zone,
            rst.nom_restaurant,
            COALESCE(SUM(r.quantite * m.prix)::NUMERIC(10,2),0) AS ca,
            COALESCE(SUM(SUM(r.quantite * m.prix)) OVER () ,0) AS ca_total
        FROM recapitulatif r
        JOIN menu m ON r.num_zone = m.num_zone
            AND r.nom_restaurant = m.nom_restaurant
            AND r.nom_plat = m.nom_plat
        right join restaurants rst on rst.num_zone = r.num_zone and rst.nom_restaurant= r.nom_restaurant 
        WHERE 
            (p_date_debut IS NULL OR r.date_horaire >= p_date_debut)
            AND (p_date_fin IS NULL OR r.date_horaire <= p_date_fin)
            AND (p_num_zone IS NULL OR rst.num_zone = p_num_zone)
        GROUP BY rst.num_zone, rst.nom_restaurant
    )
    SELECT
        RANK() OVER (ORDER BY ca DESC) AS classement,
        ca_restaurants.num_zone,
        ca_restaurants.nom_restaurant,
        ca_restaurants.ca,
        (ca * 100 / ca_total)::NUMERIC(5,2) AS part_marche
    FROM ca_restaurants
    ORDER BY classement;
END;
$$ LANGUAGE plpgsql;
