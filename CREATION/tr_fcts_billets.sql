drop function if exists verifier_achat_billet() cascade ; 
drop function if exists calculer_prix_billet_entree(varchar,int) cascade; 
drop function if exists calculer_prix_zone_entree(boolean,boolean,boolean) cascade;
drop function if exists calculer_prix_billet(varchar,int,int,boolean,boolean,boolean) cascade;
drop function if exists get_num_billet_libre(int) cascade;
drop function if exists peut_acheter_billet(varchar,int) cascade;
-- drop function if exists achat_billet(varchar,int,int,boolean,boolean,boolean) cascade;
drop PROCEDURE if exists achat_billet(varchar,int,int,boolean,boolean,boolean) cascade;

-------- BILLET ------------

CREATE OR REPLACE FUNCTION verifier_achat_billet()
RETURNS TRIGGER AS $$
BEGIN

    -- on verifie que l'acheteur a bien fait la selection avant d'acheter son billet 
    IF NOT EXISTS (
        SELECT 1 
        FROM selection 
        WHERE usr_login = NEW.acheteur
          AND id_festival = NEW.id_festival
    ) THEN
        RAISE EXCEPTION 'Aucune sélection trouvée pour l’utilisateur % au festival %', NEW.acheteur, NEW.id_festival;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tr_verifier_achat_billet
BEFORE INSERT OR UPDATE ON achat_billet
FOR EACH ROW EXECUTE FUNCTION verifier_achat_billet();

-- calcul le prix d'entré du billet (sans les credits)
CREATE OR REPLACE FUNCTION calculer_prix_billet_entree(
    p_usr_login VARCHAR(255),
    p_id_festival INT
) RETURNS FLOAT AS $$
DECLARE
    prix_base FLOAT;
    reduction FLOAT := 0;
    est_étudiant BOOLEAN;
    est_retraité BOOLEAN;
BEGIN
    -- Récupérer le prix de base du festival
    SELECT prix_entre INTO prix_base FROM festivals WHERE id_festival = p_id_festival;
        IF prix_base is null then return 30 ; end if ; 

    -- Vérifier les abonnements bonus
    SELECT COALESCE(MAX(b.reduction_billet), 0.0) INTO reduction
    FROM abonnement a
    JOIN type_pass tp ON a.type_bonus = tp.type_bonus AND a.duree = tp.duree
    JOIN bonus b ON tp.type_bonus = b.type_bonus
    WHERE a.usr_login = p_usr_login
    AND a.date_achat < maintenant_temps() 
    AND a.date_achat + (tp.duree * INTERVAL '1 month') > maintenant_temps();

    /* a changer ici dire que seul le dernier prend effet ou alors dire que seul le max prend effet */

    -- Vérifier le statut de l'utilisateur
    SELECT est_etudiant, est_retraite INTO est_étudiant, est_retraité 
    FROM utilisateurs WHERE usr_login = p_usr_login;
    
    -- Appliquer les réductions de statut
    IF est_étudiant THEN reduction := reduction + 0.10; -- 20% de réduction
    ELSIF est_retraité THEN reduction := reduction + 0.5; -- 30% de réduction
    END IF;
    
    RETURN prix_base * (1-reduction);
END;
$$ LANGUAGE plpgsql;


-- calcul le prix d'entré du billet (sans les credits)
CREATE OR REPLACE FUNCTION calculer_prix_zone_entree(
    p_acces_zone1 BOOLEAN,
    p_acces_zone2 BOOLEAN,
    p_acces_zone3 BOOLEAN
) RETURNS FLOAT AS $$
DECLARE
    prix FLOAT:=0 ;

BEGIN
    IF p_acces_zone1 AND p_acces_zone2 AND p_acces_zone3 THEN RETURN 45.50;
    END IF; 
    IF p_acces_zone1 THEN prix:=prix +10.99 ; 
    END IF; 
    IF p_acces_zone2 THEN prix:= prix + 20.99;
    END IF;
    IF p_acces_zone3 THEN prix:= prix+ 30.50; 
    END IF;

    RETURN prix ;
END;
$$ LANGUAGE plpgsql;

------------------------- ACHAT D'UN BILLET ----------------------

-- calcul le prix d'entré du billet (avec credits et zone) 
CREATE OR REPLACE FUNCTION calculer_prix_billet(
    p_usr_login VARCHAR(255),
    p_id_festival INT,
    p_credit_achete INT,
    p_acces_zone1 BOOLEAN,
    p_acces_zone2 BOOLEAN,
    p_acces_zone3 BOOLEAN
) RETURNS FLOAT AS $$
DECLARE
    reduction FLOAT := 0;
BEGIN
   
    IF p_credit_achete < 0 THEN 
        RAISE EXCEPTION 'Le nombre de crédit acheté ne peut pas etre négatif ';
    END IF;
    RETURN calculer_prix_billet_entree(p_usr_login,p_id_festival) + (p_credit_achete*0.80) 
    + calculer_prix_zone_entree(p_acces_zone1,p_acces_zone2,p_acces_zone3);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_num_billet_libre(
    p_id_festival INT
) RETURNS INT AS $$
DECLARE 
    v_num_billet_dispo INT ;
BEGIN
    
        SELECT num_billet 
        INTO v_num_billet_dispo 
        FROM billets AS b 
        WHERE id_festival = p_id_festival AND 
        num_billet NOT IN(
            SELECT num_billet FROM achat_billet AS ab 
            WHERE ab.id_festival = p_id_festival
        )
        LIMIT 1 
   ;
    IF FOUND THEN   
        RETURN v_num_billet_dispo;
    END IF; 
    RAISE EXCEPTION 'Il n y a plus de billet disponible pour le festival %', p_id_festival;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION peut_acheter_billet(
    p_usr_login VARCHAR(255),
    p_id_festival INT
) RETURNS BOOLEAN AS $$
DECLARE
    v_periode_selection DATE;
    v_date_actuelle TIMESTAMP;
    v_est_dans_periode BOOLEAN;
    v_a_deja_achete BOOLEAN;
BEGIN
    -- 1. Récupérer la période de sélection de l'utilisateur
    SELECT periode INTO v_periode_selection
    FROM selection
    WHERE usr_login = p_usr_login
    AND id_festival = p_id_festival
    ORDER BY periode DESC
    LIMIT 1;
    
    IF v_periode_selection IS NULL THEN
        RAISE NOTICE 'L''utilisateur % n''a pas de période de sélection pour ce festival', p_usr_login;
        RETURN FALSE;
    END IF;
    
    -- 2. Obtenir le temps actuel simulé
    v_date_actuelle := maintenant_temps();
        
    -- 3. Vérifier si on est dans la période d'achat
    v_est_dans_periode := ((v_date_actuelle::date) = v_periode_selection);
    IF not v_est_dans_periode THEN 
    raise notice 'la date actuelle % n''est pas egale a la période % ', (v_date_actuelle::date) , v_periode_selection;
    end if; 
    -- 4. Retourner le résultat
    RETURN v_est_dans_periode;

END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE PROCEDURE achat_billet(
    p_usr_login VARCHAR(255),
    p_id_festival INT,
    p_credit_achete INT,
    p_acces_zone1 BOOLEAN,
    p_acces_zone2 BOOLEAN,
    p_acces_zone3 BOOLEAN
)LANGUAGE plpgsql AS $$ 
DECLARE 
    v_num_billet INT;
    v_prix_payé FLOAT;
BEGIN 
    
    IF NOT peut_acheter_billet(p_usr_login,p_id_festival)
    THEN RAISE EXCEPTION 'Impossible d acheter un billet pour % pour le festival %', p_usr_login,p_id_festival ; 
    END IF;

    LOCK TABLE achat_billet IN ACCESS EXCLUSIVE MODE;

    v_num_billet = get_num_billet_libre(p_id_festival); 
    v_prix_payé = calculer_prix_billet(p_usr_login,p_id_festival,p_credit_achete,p_acces_zone1,p_acces_zone2,p_acces_zone3);

    INSERT INTO achat_billet(num_billet,id_festival,acheteur,prix_payé,credit_total) 
    VALUES (v_num_billet,p_id_festival,p_usr_login,v_prix_payé,p_credit_achete);

    IF p_acces_zone1 THEN 
    INSERT INTO billet_acces(num_billet,id_festival,num_zone)
    VALUES(v_num_billet,p_id_festival,1);
    END IF; 

    IF p_acces_zone2 THEN 
    INSERT INTO billet_acces(num_billet,id_festival,num_zone)
    VALUES(v_num_billet,p_id_festival,2);
    END IF; 

    IF p_acces_zone3 THEN 
    INSERT INTO billet_acces(num_billet,id_festival,num_zone)
    VALUES(v_num_billet,p_id_festival,3);
    END IF; 
    
END; 
$$ ;



-- rajouter trigger peu pas ajouter de nouveau billet si le festival a déja commencer
-- erreur creer un billet alors que le festival est fini
CREATE OR REPLACE FUNCTION verifier_billet_festival()
RETURNS TRIGGER AS $$
DECLARE
    v_festival_debut TIMESTAMP;
    v_festival_fin TIMESTAMP;
    v_maintenant TIMESTAMP;
BEGIN
    -- Récupérer les dates du festival
    SELECT date_debut_festival, date_fin_festival 
    INTO v_festival_debut, v_festival_fin
    FROM festivals 
    WHERE id_festival = NEW.id_festival;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Festival % inexistant', NEW.id_festival;
    END IF;

    -- Obtenir la date courante simulée
    v_maintenant := maintenant_temps();

    -- Vérifier si le festival a déjà commencé ou est terminé
    IF v_maintenant >= v_festival_debut THEN
        IF v_maintenant <= v_festival_fin THEN
            RAISE EXCEPTION 'Création billet impossible : le festival % a déjà commencé depuis le %', 
                          NEW.id_festival, v_festival_debut;
        ELSE
            RAISE EXCEPTION 'Création billet impossible : le festival % est terminé depuis le %', 
                          NEW.id_festival, v_festival_fin;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Création du déclencheur
CREATE TRIGGER tr_verifier_billet_festival
BEFORE INSERT ON billets
FOR EACH ROW EXECUTE FUNCTION verifier_billet_festival();
