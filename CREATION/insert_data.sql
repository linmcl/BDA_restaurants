-- Tables de base
\copy utilisateurs FROM './csv/utilisateurs.csv' DELIMITER ',' CSV HEADER;

-- Tables festivals et billets
\copy festivals FROM './csv/festivals.csv' DELIMITER ',' CSV HEADER;
\copy billets FROM './csv/billets.csv' DELIMITER ',' CSV HEADER;
\copy achat_billet FROM './csv/achat_billet.csv' DELIMITER ',' CSV HEADER;

-- Système de pass
\copy bonus FROM './csv/bonus.csv' DELIMITER ',' CSV HEADER;
\copy type_pass FROM './csv/type_pass.csv' DELIMITER ',' CSV HEADER;
\copy abonnement FROM './csv/abonnement.csv' DELIMITER ',' CSV HEADER;

-- Préinscriptions et sélections
\copy preinscription FROM './csv/preinscription.csv' DELIMITER ',' CSV HEADER;
\copy selection FROM './csv/selection.csv' DELIMITER ',' CSV HEADER;

-- Système de zones et restaurants
\copy zone FROM './csv/zone.csv' DELIMITER ',' CSV HEADER;
\copy restaurants FROM './csv/restaurants.csv' DELIMITER ',' CSV HEADER;
\copy participation FROM './csv/participation.csv' DELIMITER ',' CSV HEADER;

-- Menus et consommations
\copy menu FROM './csv/menu.csv' DELIMITER ',' CSV HEADER;
\copy consommation FROM './csv/consommation.csv' DELIMITER ',' CSV HEADER;
\copy recapitulatif FROM './csv/recapitulatif.csv' DELIMITER ',' CSV HEADER;

-- Accès aux zones
\copy billet_acces FROM './csv/billet_acces.csv' DELIMITER ',' CSV HEADER;