drop function if exists avancer_temps(integer) cascade;
drop function if exists set_temps(integer,integer,integer,integer) cascade;
drop function if exists maintenant_temps() cascade;
drop function if exists init_temps(integer,integer,integer,integer) cascade;
drop function if exists timestamp_to_temps(timestamp) cascade;
drop function if exists set_temps_w_timestamp(timestamp) cascade;
------- TEMPS -------------

-- Fonction de contrôle pour TEMPS
CREATE OR REPLACE FUNCTION controle_temps()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        IF NEW.annee < OLD.annee THEN 
            RAISE EXCEPTION 'L''année ne peut pas reculer';
        ELSIF NEW.annee = OLD.annee AND NEW.jour < OLD.jour THEN
            RAISE EXCEPTION 'Le jour ne peut pas reculer';
        ELSIF NEW.annee = OLD.annee AND NEW.jour = OLD.jour AND NEW.heure < OLD.heure THEN
            RAISE EXCEPTION 'L''heure ne peut pas reculer';
        ELSIF NEW.annee = OLD.annee AND NEW.jour = OLD.jour AND NEW.heure = OLD.heure AND NEW.minute <= OLD.minute THEN
            RAISE EXCEPTION 'Les minutes doivent avancer';
        END IF;
    ELSIF TG_OP = 'INSERT' THEN
        IF (SELECT COUNT(*) FROM TEMPS) > 0 THEN
            RAISE EXCEPTION 'Une seule entrée de temps est autorisée';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour TEMPS
CREATE OR REPLACE TRIGGER tr_controle_temps
BEFORE INSERT OR UPDATE ON TEMPS
FOR EACH ROW EXECUTE FUNCTION controle_temps();

-- Fonction pour avancer le temps (en minutes)
CREATE OR REPLACE FUNCTION avancer_temps(
    p_minutes INTEGER DEFAULT 1
) RETURNS VOID AS $$
DECLARE
    v_annee INTEGER;
    v_jour INTEGER;
    v_heure INTEGER;
    v_minute INTEGER;
    v_total_minutes INTEGER;
BEGIN
    SELECT annee, jour, heure, minute 
    INTO v_annee, v_jour, v_heure, v_minute
    FROM TEMPS LIMIT 1;
    
    v_total_minutes := v_minute + p_minutes;
    v_minute := v_total_minutes % 60;
    v_total_minutes := v_total_minutes / 60;
    
    v_heure := v_heure + (v_total_minutes % 24);
    v_total_minutes := v_total_minutes / 24;
    
    v_jour := v_jour + v_total_minutes;
    
    UPDATE TEMPS 
    SET annee = v_annee,
        jour = v_jour,
        heure = v_heure,
        minute = v_minute;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION set_temps(
    p_annee INTEGER,
    p_jour INTEGER,
    p_heure INTEGER,
    p_minute INTEGER
) RETURNS VOID AS $$
DECLARE
BEGIN
    -- Mettre à jour
    UPDATE TEMPS 
    SET annee = p_annee,
        jour = p_jour,
        heure = p_heure,
        minute = p_minute;
END;
$$ LANGUAGE plpgsql;


-- Fonction pour obtenir le timestamp actuel 
CREATE OR REPLACE FUNCTION maintenant_temps()
RETURNS TIMESTAMP AS $$
DECLARE
    v_annee INTEGER;
    v_jour INTEGER;
    v_heure INTEGER;
    v_minute INTEGER;
BEGIN
    SELECT annee, jour, heure, minute 
    INTO v_annee, v_jour, v_heure, v_minute
    FROM TEMPS LIMIT 1;
    
    RETURN MAKE_DATE(v_annee, 1, 1) +  -- 1er janvier de l'année
           ((v_jour-1) * INTERVAL '1 day') + 
           (v_heure * INTERVAL '1 hour') + 
           (v_minute * INTERVAL '1 minute');
END;
$$ LANGUAGE plpgsql;

-- Procédure d'initialisation
CREATE OR REPLACE FUNCTION init_temps(
    p_annee INTEGER DEFAULT EXTRACT(YEAR FROM CURRENT_DATE),
    p_jour INTEGER DEFAULT 0,
    p_heure INTEGER DEFAULT 8,
    p_minute INTEGER DEFAULT 0
) RETURNS VOID AS $$
BEGIN
    DELETE FROM TEMPS;
    INSERT INTO TEMPS (annee, jour, heure, minute) 
    VALUES (p_annee, p_jour, p_heure, p_minute);
END;
$$ LANGUAGE plpgsql;
-- SELECT init_temps(2024, 10, 15, 30); 


CREATE OR REPLACE FUNCTION timestamp_to_temps(
    p_timestamp TIMESTAMP
) RETURNS TEMPS AS $$
DECLARE
    v_annee INTEGER;
    v_jour INTEGER;
    v_heure INTEGER;
    v_minute INTEGER;
    v_result TEMPS;
BEGIN
    -- Extraire les composants de la date
    v_annee := EXTRACT(YEAR FROM p_timestamp);
    
    -- Calculer le jour depuis le 1er janvier de l'année
    v_jour := EXTRACT(DOY FROM p_timestamp) - 1;
    
    -- Extraire heure et minute
    v_heure := EXTRACT(HOUR FROM p_timestamp);
    v_minute := EXTRACT(MINUTE FROM p_timestamp);
    
    -- Construire la ligne TEMPS
    v_result.annee := v_annee;
    v_result.jour := v_jour;
    v_result.heure := v_heure;
    v_result.minute := v_minute;
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION set_temps_w_timestamp(ts TIMESTAMP)
RETURNS void AS $$
DECLARE
  annee_val INTEGER;
  jour_val INTEGER;
  heure_val INTEGER;
  minute_val INTEGER;
BEGIN
  -- Extraire les composants depuis le timestamp
  annee_val := EXTRACT(YEAR FROM ts)::INTEGER;
  jour_val := EXTRACT(DOY FROM ts)::INTEGER ; -- DOY = Day Of Year
  heure_val := EXTRACT(HOUR FROM ts)::INTEGER;
  minute_val := EXTRACT(MINUTE FROM ts)::INTEGER;
  
    -- Mettre à jour
    UPDATE TEMPS 
    SET annee = annee_val,
        jour = jour_val,
        heure = heure_val,
        minute = minute_val;
END;
$$ LANGUAGE plpgsql;
