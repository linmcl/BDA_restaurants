drop function if exists verifier_date_festivals() cascade; 
drop function if exists verifier_periode_preinscription() cascade; 
drop function if exists verifier_periode_selection() cascade; 
drop function if exists selections(date,int) cascade; 
drop function if exists selections_random(date,int) cascade; 

------- FESTIVALS -----------

CREATE OR REPLACE FUNCTION verifier_date_festivals()
RETURNS TRIGGER AS $$
DECLARE
    v_date_courante TIMESTAMP;
BEGIN

    -- Obtenir la date courante simulée
    v_date_courante := maintenant_temps();
    
    -- Vérifier si le festivals a bien lieu apres la date d'aujourd'hui
    IF v_date_courante > NEW.date_debut_preinscription THEN
        RAISE EXCEPTION 'Le debut du festival ne peut pas commencer avant aujourd hui';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tr_verifier_date_festivals
BEFORE INSERT OR UPDATE ON festivals
FOR EACH ROW EXECUTE FUNCTION verifier_date_festivals();


------ PREINSCRIPTION -------

CREATE OR REPLACE FUNCTION verifier_periode_preinscription()
RETURNS TRIGGER AS $$
DECLARE
    v_date_debut TIMESTAMP;
    v_date_fin TIMESTAMP;
    v_date_courante TIMESTAMP;
BEGIN
    -- Récupérer les dates de préselection pour ce festival
    SELECT date_debut_preinscription, date_fin_preinscription 
    INTO v_date_debut, v_date_fin
    FROM festivals 
    WHERE id_festival = NEW.id_festival;
    
    -- Obtenir la date courante simulée
    v_date_courante := maintenant_temps();
    
    -- Vérifier si on est dans la période de préselection
    IF v_date_courante < v_date_debut OR v_date_courante > v_date_fin THEN
        RAISE EXCEPTION 'La présélection n''est possible que du % au %', 
                        v_date_debut, v_date_fin;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tr_verifier_periode_preinscription 
BEFORE INSERT OR UPDATE ON preinscription
FOR EACH ROW EXECUTE FUNCTION verifier_periode_preinscription();


-------- SELECTION -----------

CREATE OR REPLACE FUNCTION verifier_periode_selection()
RETURNS TRIGGER AS $$
DECLARE
    v_date_debut TIMESTAMP;
    v_date_fin TIMESTAMP;
    v_date_courante TIMESTAMP;
BEGIN
    -- Récupérer les dates de sélection pour ce festival
    SELECT date_debut_selection, date_fin_selection 
    INTO v_date_debut, v_date_fin
    FROM festivals 
    WHERE id_festival = NEW.id_festival;
    
    -- Obtenir la date courante simulée
    v_date_courante := maintenant_temps();
    
    -- Vérifier si on est dans la période de sélection
    IF v_date_courante < v_date_debut OR v_date_courante > v_date_fin THEN
        RAISE EXCEPTION 'L''ajout d''une sélection n''est possible que du % au % (date actuelle : %)', 
                        v_date_debut, v_date_fin, v_date_courante;
    END IF;
    
    -- Vérifier que la période est après le debut de sélection mais avant la fin 
    IF NEW.periode < v_date_debut::DATE THEN
        RAISE EXCEPTION 'La période d''achat doit être apres le debut de la sélection (%)', v_date_debut;
    ELSIF NEW.periode >= v_date_fin::DATE THEN
        RAISE EXCEPTION 'La période d''achat doit être avant la fin de la selection (%)', v_date_fin;
    END IF;
    -- on verifie que l'utilisateur ne possède pas deja un billet
   IF EXISTS (
        SELECT 1 
        FROM achat_billet 
        WHERE acheteur = NEW.usr_login 
          AND id_festival = NEW.id_festival
    ) THEN
        RAISE EXCEPTION 'L utilisateur % possède deja un billet pour le festival %', NEW.acheteur, NEW.id_festival;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tr_verifier_periode_selection
BEFORE INSERT OR UPDATE ON selection
FOR EACH ROW EXECUTE FUNCTION verifier_periode_selection();


--------------- SELECTION -----------------

-- insert dans la table selection les personnes préinscrit pour une selection (priorité par date d'inscription)
CREATE OR REPLACE FUNCTION selections(
    p_periode_selection DATE,
    p_id_festival INT
) RETURNS VOID  AS $$
DECLARE
  record RECORD;
BEGIN

    if (select get_num_billet_libre(p_id_festival))::BOOLEAN then 
    FOR record IN
    -- selectionne les personne préinscrit qui n'ont pas deja un billet 
    SELECT usr_login FROM preinscription 
    WHERE id_festival= p_id_festival AND usr_login NOT IN 
        (SELECT acheteur FROM achat_billet
         WHERE id_festival = p_id_festival)
    -- on prend en priorité ceux inscrit en premier et limité par le nombre de ticket disponible pour le festival
    ORDER BY date_preinscription ASC
    LIMIT (SELECT COUNT(*) FROM billets WHERE id_festival =p_id_festival)
  LOOP
    INSERT INTO selection (usr_login,id_festival,periode)
    VALUES (record.usr_login,p_id_festival,p_periode_selection);
  END LOOP;
end if ; 
END;
$$ LANGUAGE plpgsql;


-- insert dans la table selection les personnes préinscrit pour une selection (priorité aleatoire)
CREATE OR REPLACE FUNCTION selections_random(
    p_periode_selection DATE,
    p_id_festival INT
) RETURNS VOID  AS $$
DECLARE
  record RECORD;
BEGIN

    if (select get_num_billet_libre(p_id_festival))::BOOLEAN then 
    FOR record IN
    -- selectionne les personne préinscrit qui n'ont pas deja un billet 
    SELECT usr_login FROM preinscription 
    WHERE id_festival= p_id_festival AND usr_login NOT IN 
        (SELECT acheteur FROM achat_billet
         WHERE id_festival = p_id_festival)
    -- on prend en priorité ceux inscrit en premier et limité par le nombre de ticket disponible pour le festival
    ORDER BY RANDOM()
    LIMIT (SELECT COUNT(*) FROM billets WHERE id_festival =p_id_festival)
  LOOP
    INSERT INTO selection (usr_login,id_festival,periode)
    VALUES (record.usr_login,p_id_festival,p_periode_selection);
  END LOOP;
end if ; 
END;
$$ LANGUAGE plpgsql;

-- ameliorer le systeme de selection des personnes lors du préinscription
-- selection par type de pass comme un chakal

CREATE OR REPLACE FUNCTION selections_par_pass(
    p_periode_selection DATE,
    p_id_festival INT
) RETURNS VOID AS $$
DECLARE
  record RECORD;
BEGIN
    IF (SELECT get_num_billet_libre(p_id_festival) > 0) THEN -- Correction boolean
        FOR record IN
            SELECT 
                p.usr_login,
                MIN(CASE tp.type_bonus
                    WHEN 'fourchette_or' THEN 1
                    WHEN 'couteau_fer' THEN 2
                    WHEN 'cuillere_bronze' THEN 3
                    ELSE 4
                END) AS priorite,
                MIN(p.date_preinscription) AS premiere_inscription -- Agrégation de la date
            FROM preinscription p
            LEFT JOIN abonnement a ON p.usr_login = a.usr_login
            LEFT JOIN type_pass tp ON a.type_bonus = tp.type_bonus AND a.duree = tp.duree
            WHERE p.id_festival = p_id_festival
                AND p.usr_login NOT IN (
                    SELECT acheteur 
                    FROM achat_billet 
                    WHERE id_festival = p_id_festival
                )
            GROUP BY p.usr_login -- Groupement unique
            ORDER BY 
                priorite ASC,
                premiere_inscription ASC -- Tri par première inscription
            LIMIT (SELECT COUNT(*) FROM billets WHERE id_festival = p_id_festival)
        LOOP
            INSERT INTO selection (usr_login, id_festival, periode)
            VALUES (record.usr_login, p_id_festival, p_periode_selection);
        END LOOP;
    END IF;
END;
$$ LANGUAGE plpgsql;