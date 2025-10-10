drop table if exists utilisateurs cascade;

drop table if exists festivals cascade;

drop table if exists billets cascade;

drop table if exists achat_billet cascade;

drop table if exists abonnement cascade;

drop table if exists type_pass cascade;

drop table if exists bonus cascade;

drop table if exists preinscription cascade;

drop table if exists selection cascade;

drop table if exists consommation cascade;

drop table if exists recapitulatif cascade;

drop table if exists menu cascade;

drop table if exists restaurants cascade;

drop table if exists participation cascade;

drop table if exists zone cascade;

drop table if exists billet_acces cascade;

drop table if exists TEMPS cascade ;

-- Table TEMPS avec année, jour, heure et minute
CREATE TABLE  TEMPS (
    annee INTEGER NOT NULL,
    jour INTEGER NOT NULL CHECK (jour >= 1),
    heure INTEGER NOT NULL CHECK (heure >= 0 AND heure < 24),
    minute INTEGER NOT NULL CHECK (minute >= 0 AND minute < 60),
    CONSTRAINT pk_temps PRIMARY KEY (annee, jour, heure, minute)
);

CREATE TABLE utilisateurs(
    usr_login VARCHAR(255),
    usr_mdp VARCHAR(255) NOT NULL, 
    nom VARCHAR(255) NOT NULL,
    prenom VARCHAR(255) NOT NULL,
    est_etudiant BOOLEAN NOT NULL, 
    est_retraite BOOLEAN NOT NULL,
    CONSTRAINT pk_utilisateurs PRIMARY KEY(usr_login),
    CONSTRAINT uc_utilisateurs_login_mdp UNIQUE(usr_login,usr_mdp)
);


CREATE TABLE festivals(
    id_festival serial,
    date_debut_festival  TIMESTAMP NOT NULL, 
    date_fin_festival TIMESTAMP NOT NULL, 
    date_debut_preinscription TIMESTAMP NOT NULL , 
    date_fin_preinscription TIMESTAMP NOT NULL , 
    date_debut_selection TIMESTAMP NOT NULL,  
    date_fin_selection TIMESTAMP NOT NULL, 
    prix_entre FLOAT(2) NOT NULL,
    CONSTRAINT pk_festivals PRIMARY KEY (id_festival),
    --Un festival dure au moins 2 jours
    CONSTRAINT chk_festivals_2_jours_minimum CHECK (date_fin_festival >= date_debut_festival + (INTERVAL '2 DAYS')),
    -- Les préinscriptions doivent être avant le festival
    CONSTRAINT chk_festivals_preinscription_avant_festival CHECK (date_fin_preinscription <= date_debut_festival),
    CONSTRAINT chk_festivals_debut_preinscription_avant_fin CHECK (date_debut_preinscription <= date_fin_preinscription),
    -- La sélection doit être après les préinscriptions mais avant le festival
    CONSTRAINT chk_selection_apres_preinscription CHECK (date_debut_selection >= date_fin_preinscription),
    CONSTRAINT chk_fin_selection_avant_festival CHECK (date_fin_selection <= date_debut_festival),
    CONSTRAINT chk_debut_selection_avant_fin CHECK (date_debut_selection <= date_fin_selection)

);

CREATE TABLE billets(
    num_billet INT,
    id_festival INT,
    CONSTRAINT pk_billets PRIMARY KEY (num_billet,id_festival),
    CONSTRAINT fk_billets_id_festival FOREIGN KEY(id_festival) REFERENCES festivals(id_festival)
);

CREATE TABLE bonus(
    type_bonus VARCHAR(255),
    reduction_billet FLOAT(2) NOT NULL,
    crédit_bonus INT NOT NULL,
    CONSTRAINT pk_bonus PRIMARY KEY (type_bonus)
);

CREATE TABLE type_pass(
    type_bonus VARCHAR(255),
    duree INT,
    prix_achat FLOAT(2),  /* NULL ou pas NULL ? */
    CONSTRAINT pk_type_pass PRIMARY KEY(type_bonus,duree),
    CONSTRAINT fk_type_pass_type_bonus FOREIGN KEY(type_bonus) REFERENCES bonus(type_bonus),
    CONSTRAINT chk_type_pass_type_bonus CHECK (type_bonus IN ('cuillere_bronze','couteau_fer','fourchette_or')),
    CONSTRAINT chk_type_pass_duree CHECK (duree IN (1,6,12)),
    CONSTRAINT uc_type_pass_type_bonus_prix UNIQUE (type_bonus,prix_achat)
);

CREATE TABLE preinscription(
    usr_login VARCHAR(255),
    id_festival INT,
    date_preinscription TIMESTAMP NOT NULL, /* TRIGGER : date_preinscription c [id_festival.date_fin_preinscription,id_festival.date_debut_preinscription]*/
    CONSTRAINT pk_preinscription PRIMARY KEY(usr_login,id_festival),
    CONSTRAINT fk_preinscription_usr_login FOREIGN KEY (usr_login) REFERENCES utilisateurs(usr_login),
    CONSTRAINT fk_preinscription_id_festival FOREIGN KEY(id_festival) REFERENCES festivals(id_festival)
);

CREATE TABLE selection(
    usr_login VARCHAR(255),
    id_festival INT,
    periode DATE,
    CONSTRAINT pk_selection PRIMARY KEY(usr_login,id_festival,periode),
    CONSTRAINT fk_selection_usr_login FOREIGN KEY (usr_login) REFERENCES utilisateurs(usr_login),
    CONSTRAINT fk_selection_id_festival FOREIGN KEY(id_festival) REFERENCES festivals(id_festival),
    CONSTRAINT fk_selection_preselection FOREIGN KEY(usr_login,id_festival) REFERENCES preinscription(usr_login,id_festival)
);

CREATE TABLE achat_billet(  
    num_billet INT,
    id_festival INT, 
    acheteur VARCHAR(255),
    prix_payé FLOAT(2) NOT NULL, 
    credit_total FLOAT(2) NOT NULL,
    CONSTRAINT pk_achat_billet PRIMARY KEY (num_billet,id_festival,acheteur),
    CONSTRAINT fk_achat_billet_id_billet FOREIGN KEY(num_billet,id_festival) REFERENCES billets(num_billet,id_festival),
    CONSTRAINT fk_achat_billet_id_acheteur FOREIGN KEY(acheteur) REFERENCES utilisateurs(usr_login),
    CONSTRAINT uc_achat_billet_acheteur_id_festival UNIQUE (id_festival,acheteur),
    CONSTRAINT uc_achat_billet_num_billet_id_festival UNIQUE(num_billet,id_festival)

);

CREATE INDEX idx_prix_payé ON achat_billet(prix_payé); 

CREATE TABLE zone(
    num_zone INT,
    tarif_max_plat FLOAT(2) NOT NULL,
    tarif_entre_billet FLOAT(2) NOT NULL,
    CONSTRAINT pk_zone PRIMARY KEY(num_zone)
);

CREATE TABLE restaurants(
    num_zone INT, 
    nom_restaurant VARCHAR(255),
    CONSTRAINT pk_restaurant PRIMARY KEY(num_zone,nom_restaurant)
);

CREATE TABLE participation(
    id_festival INT, 
    num_zone INT, 
    nom_restaurant VARCHAR(255),
    CONSTRAINT pk_participation PRIMARY KEY(id_festival,num_zone,nom_restaurant),
    CONSTRAINT fk_participation_festival FOREIGN KEY(id_festival) REFERENCES festivals(id_festival),
    CONSTRAINT fk_participation_restaurant FOREIGN KEY(num_zone,nom_restaurant) REFERENCES restaurants(num_zone,nom_restaurant)
);


CREATE TABLE consommation(
    num_billet INT, /*id_billet*/
    id_festival INT,
    num_zone INT,   /* id_restaurant*/
    nom_restaurant VARCHAR(255),
    date_horaire TIMESTAMP,
    CONSTRAINT pk_consommation PRIMARY KEY(num_billet,id_festival,num_zone,nom_restaurant,date_horaire),
    CONSTRAINT fk_consommation_billet FOREIGN KEY(num_billet,id_festival) REFERENCES achat_billet(num_billet,id_festival),
    CONSTRAINT fk_consommation_restaurant FOREIGN KEY(num_zone,nom_restaurant) REFERENCES restaurants(num_zone,nom_restaurant),
    CONSTRAINT fk_consommation_participation FOREIGN KEY(id_festival,num_zone,nom_restaurant) REFERENCES participation(id_festival,num_zone,nom_restaurant)
);


CREATE TABLE menu(
    num_zone INT,
    nom_restaurant VARCHAR(255),
    nom_plat VARCHAR(255),
    quantite_max_quotidien INT,
    prix FLOAT(2),
    CONSTRAINT pk_menu PRIMARY KEY(num_zone,nom_restaurant,nom_plat),
    CONSTRAINT chk_menu_prix CHECK (prix> 0)
);


CREATE TABLE recapitulatif(
    num_billet INT, /*billet*/
    id_festival INT,
    date_horaire TIMESTAMP,
    num_zone INT,   /*restaurant*/ 
    nom_restaurant VARCHAR(255),
    nom_plat VARCHAR(255),  /*plat*/
    quantite INT NOT NULL,
    CONSTRAINT pk_recapitulatif PRIMARY KEY(num_billet,id_festival,date_horaire,num_zone,nom_restaurant,nom_plat),
    CONSTRAINT fk_recapitulation_consommation FOREIGN KEY(num_billet,id_festival,num_zone,nom_restaurant,date_horaire) REFERENCES consommation(num_billet,id_festival,num_zone,nom_restaurant,date_horaire),
    CONSTRAINT fk_recapitulation_plat FOREIGN KEY(num_zone,nom_restaurant,nom_plat) REFERENCES menu(num_zone,nom_restaurant,nom_plat),
    CONSTRAINT chk_recapitulatif CHECK (quantite > 0)
);



CREATE TABLE billet_acces(
    num_billet INT,
    id_festival INT,
    num_zone INT,
    CONSTRAINT pk_billet_acces PRIMARY KEY(num_billet,id_festival,num_zone),
    CONSTRAINT fk_billet_acces_id_billet FOREIGN KEY(num_billet,id_festival) REFERENCES billets(num_billet,id_festival),
    CONSTRAINT fk_billet_acces_zone FOREIGN KEy(num_zone) REFERENCES zone(num_zone)
);



CREATE TABLE abonnement(
    type_bonus VARCHAR(255),
    duree INT,
    usr_login VARCHAR(255),
    date_achat TIMESTAMP,
    CONSTRAINT pk_abonnement PRIMARY KEY(type_bonus,duree,usr_login,date_achat),
    CONSTRAINT fk_abonnement_bonus FOREIGN KEY(type_bonus,duree) REFERENCES type_pass(type_bonus,duree),
    CONSTRAINT fk_abonnement_utilisateur FOREIGN KEY(usr_login) REFERENCES utilisateurs(usr_login)
);

