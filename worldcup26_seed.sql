-- ============================================================
-- worldcup26.db — FIFA World Cup 2026 Database
-- SQLite seed file
-- Created: 2026-06-15 | Germán Ontiveros
-- Source: FIFA official squad lists (confirmed 2026-06-02)
-- ============================================================
-- Run: sqlite3 worldcup26.db < worldcup26_seed.sql
-- Or paste into DBeaver and execute.
-- ============================================================

PRAGMA foreign_keys = ON;

-- ============================================================
-- TABLE: teams
-- ============================================================
DROP TABLE IF EXISTS broadcasts;
DROP TABLE IF EXISTS goalkeeper_stats;
DROP TABLE IF EXISTS player_stats;
DROP TABLE IF EXISTS players;
DROP TABLE IF EXISTS matches;
DROP TABLE IF EXISTS teams;

CREATE TABLE teams (
    team_id         TEXT PRIMARY KEY,    -- 3-letter FIFA code
    country         TEXT NOT NULL,
    confederation   TEXT NOT NULL,       -- UEFA / CONMEBOL / AFC / CAF / CONCACAF / OFC
    group_name      TEXT NOT NULL,       -- 'A' through 'L'
    fifa_ranking    INTEGER,
    coach           TEXT,
    host            INTEGER DEFAULT 0,   -- 1 if co-host (MEX, USA, CAN)
    appearances     INTEGER,             -- previous WC tournaments excluding WC26; 0 = first-timer
    best_finish     TEXT,                -- NULL for first-timers
    market_value_m  REAL,                -- total squad market value, EUR millions
    base_camp       TEXT                 -- base camp city, State/Province (Wikipedia, 2026-06-17)
);

-- ============================================================
-- TABLE: players
-- ============================================================
CREATE TABLE players (
    player_id       INTEGER PRIMARY KEY AUTOINCREMENT,
    fbref_id        TEXT,                  -- FBref player id (stable join key)
    team_id         TEXT NOT NULL REFERENCES teams(team_id),
    name            TEXT NOT NULL,
    position        TEXT,                  -- FBref roster pos (GK/DF/MF/FW; combos e.g. 'FW,MF')
    shirt_number    INTEGER,
    footed          TEXT,                  -- pending: player page
    birthday        TEXT,                  -- 'YYYY-MM-DD'
    birthplace      TEXT,
    height_cm       INTEGER,               -- pending: player page
    weight_kg       INTEGER,               -- pending: player page
    league          TEXT,                  -- pending: player page
    club            TEXT,
    matches_played  INTEGER,               -- career NT (excl WC26); pending
    matches_started INTEGER,               -- pending
    minutes_played  INTEGER,               -- pending
    goals           INTEGER,               -- pending
    assists         INTEGER,               -- pending
    pk              INTEGER,               -- pending
    pk_att          INTEGER,               -- pending
    shots           INTEGER,               -- pending
    shots_on_target INTEGER,               -- pending
    yellow_cards    INTEGER,               -- pending
    red_cards       INTEGER                -- pending
);

-- ============================================================
-- TABLE: matches
-- ============================================================
-- ============================================================
-- TABLE: stadiums  (16 WC26 venues; capacity = FIFA-published)
-- ============================================================
CREATE TABLE stadiums (
    stadium_id      INTEGER PRIMARY KEY,
    name            TEXT NOT NULL,        -- canonical venue name (= matches.stadium)
    city            TEXT NOT NULL,
    state           TEXT,                 -- state / province
    country         TEXT NOT NULL,        -- USA / Mexico / Canada
    capacity        INTEGER,              -- FIFA-published WC26 capacity
    timezone        TEXT,                 -- IANA tz, e.g. America/Chicago
    elevation_m     INTEGER,              -- approx. metres above sea level
    surface_native  TEXT,                 -- permanent surface: Grass / Artificial turf
    surface_wc      TEXT,                 -- WC26 playing surface (always Grass)
    roof            TEXT                  -- Open / Retractable / Fixed canopy / Partial / Canopy
);

CREATE TABLE matches (
    match_id        INTEGER PRIMARY KEY AUTOINCREMENT,
    fifa_match_no   INTEGER UNIQUE,           -- FIFA official match number (1–104)
    team_home       TEXT REFERENCES teams(team_id),  -- NULL for unresolved knockout fixtures
    team_away       TEXT REFERENCES teams(team_id),
    goals_home      INTEGER,                  -- NULL = not yet played
    goals_away      INTEGER,                  -- NULL = not yet played
    pk_home         INTEGER,                  -- penalty shoot-out goals; NULL unless knockout + goals tied after 120'
    pk_away         INTEGER,                  -- penalty shoot-out goals; NULL unless knockout + goals tied after 120'
    corners_home    INTEGER,                  -- dynamic; from FBref match page
    corners_away    INTEGER,                  -- dynamic; from FBref match page
    possession_home REAL,                     -- possession % without sign e.g. 40.0; dynamic; from FBref
    possession_away REAL,                     -- possession % without sign e.g. 60.0; dynamic; from FBref
    stage           TEXT NOT NULL,            -- 'group' / 'r32' / 'r16' / 'qf' / 'sf' / 'third_place' / 'final'
    group_name      TEXT NOT NULL,            -- 'A'–'L' for group stage; 'knock-out' for knockout stage
    match_date      TEXT,                     -- ISO 'YYYY-MM-DD'; knockout rounds pending
    match_time      TEXT,                     -- local time 'HH:MM'; from FBref; pending population
    stadium         TEXT,                     -- knockout rounds pending
    city            TEXT,                     -- knockout rounds pending
    stadium_id      INTEGER REFERENCES stadiums(stadium_id),  -- FK -> stadiums; NULL until venue assigned
    attendance      INTEGER,                  -- dynamic; from FBref match page
    referee         TEXT,                     -- dynamic; from FBref match page
    fbref_match_id  TEXT                      -- FBref match hex (e.g. 'a2c54ed9'); pipeline join key
);

-- ============================================================
-- TABLE: player_stats
-- ============================================================
CREATE TABLE player_stats (
    stat_id        INTEGER PRIMARY KEY AUTOINCREMENT,               -- Unique ID
    player_id      INTEGER NOT NULL REFERENCES players(player_id),  -- JOIN with players table
    match_id       INTEGER NOT NULL REFERENCES matches(match_id),   -- JOIN with matches table
    minutes_played INTEGER DEFAULT 0,                               -- FBref Min
    goals          INTEGER DEFAULT 0,                               -- FBref Gls
    assists        INTEGER DEFAULT 0,                               -- FBref Ast
    pk_made        INTEGER DEFAULT 0,                               -- FBref PK - Penalty Kicks Made
    pk_att         INTEGER DEFAULT 0,                               -- FBref PKatt - Penalty Kicks Attempted
    shots          INTEGER DEFAULT 0,                               -- FBref Sh
    shots_on_goal  INTEGER DEFAULT 0,                               -- FBref SoT
    yellow_cards   INTEGER DEFAULT 0,                               -- FBref CrdY
    red_cards      INTEGER DEFAULT 0,                               -- FBref CrdR
    fouls          INTEGER DEFAULT 0,                               -- FBref Fls
    fouls_drawn    INTEGER DEFAULT 0,                               -- FBref Fld
    offsides       INTEGER DEFAULT 0,                               -- FBref Off
    crosses        INTEGER DEFAULT 0,                               -- FBref Crs
    tackles_won    INTEGER DEFAULT 0,                               -- FBref TklW
    interceptions  INTEGER DEFAULT 0,                               -- FBref Int
    own_goals      INTEGER DEFAULT 0,                               -- FBref OG
    pk_won         INTEGER DEFAULT 0,                               -- FBref PKwon
    pk_conceded    INTEGER DEFAULT 0,                               -- FBref PKcon
    UNIQUE (player_id, match_id)
);

-- ============================================================
-- TABLE: goalkeeper_stats
-- ============================================================
CREATE TABLE goalkeeper_stats (
    stat_id                 INTEGER PRIMARY KEY AUTOINCREMENT,               -- Unique ID
    player_id               INTEGER NOT NULL REFERENCES players(player_id),  -- JOIN with players table
    match_id                INTEGER NOT NULL REFERENCES matches(match_id),   -- JOIN with matches table
    minutes_played          INTEGER DEFAULT 0,                               -- FBref Min
    shots_on_target_against INTEGER DEFAULT 0,                               -- FBref SoTA
    goals_against           INTEGER DEFAULT 0,                               -- FBref GA
    saves                   INTEGER DEFAULT 0,                               -- FBref Saves
    UNIQUE (player_id, match_id)
);

-- ============================================================
-- SEED: teams (all 48 — real groups, confederations, rankings)
-- FIFA rankings: April 1, 2026 official update
-- ============================================================

INSERT INTO teams (team_id, country, confederation, group_name, fifa_ranking, coach, host, appearances, best_finish) VALUES
-- GROUP A
('MEX', 'Mexico', 'CONCACAF', 'A', 16, 'Javier Aguirre', 1, 17, 'Quarterfinals'),
('RSA', 'South Africa', 'CAF', 'A', 67, 'Hugo Broos', 0, 3, 'Group stage'),
('KOR', 'South Korea', 'AFC', 'A', 22, 'Hong Myung-bo', 0, 11, 'Fourth place'),
('CZE', 'Czechia', 'UEFA', 'A', 38, 'Miroslav Koubek', 0, 1, 'Group stage'),

-- GROUP B
('CAN', 'Canada', 'CONCACAF', 'B', 48, 'Jesse Marsch', 1, 2, 'Group stage'),
('BIH', 'Bosnia & Herz.', 'UEFA', 'B', 63, 'Sergej Barbarez', 0, 1, 'Group stage'),
('QAT', 'Qatar', 'AFC', 'B', 58, 'Markus Babbel', 0, 1, 'Group stage'),
('SUI', 'Switzerland', 'UEFA', 'B', 19, 'Murat Yakin', 0, 12, 'Quarterfinals'),

-- GROUP C
('BRA', 'Brazil', 'CONMEBOL', 'C', 6, 'Dorival Junior', 0, 22, 'Champion'),
('MAR', 'Morocco', 'CAF', 'C', 14, 'Walid Regragui', 0, 6, 'Fourth place'),
('HAI', 'Haiti', 'CONCACAF', 'C', 92, 'Marc Collat', 0, 1, 'Group stage'),
('SCO', 'Scotland', 'UEFA', 'C', 39, 'Steve Clarke', 0, 8, 'Group stage'),

-- GROUP D
('USA', 'United States', 'CONCACAF', 'D', 11, 'Mauricio Pochettino', 1, 11, 'Third place'),
('PAR', 'Paraguay', 'CONMEBOL', 'D', 53, 'Gustavo Alfaro', 0, 8, 'Quarterfinals'),
('AUS', 'Australia', 'AFC', 'D', 23, 'Tony Popovic', 0, 6, 'Round of 16'),
('TUR', 'Türkiye', 'UEFA', 'D', 26, 'Vincenzo Montella', 0, 2, 'Third place'),

-- GROUP E
('GER', 'Germany', 'UEFA', 'E', 12, 'Julian Nagelsmann', 0, 20, 'Champion'),
('CUW', 'Curaçao', 'CONCACAF', 'E', 85, 'Remko Bicentini', 0, 0, NULL),
('CIV', 'Côte d''Ivoire', 'CAF', 'E', 33, 'Emerse Faé', 0, 3, 'Group stage'),
('ECU', 'Ecuador', 'CONMEBOL', 'E', 44, 'Sebastián Beccacece', 0, 4, 'Round of 16'),

-- GROUP F
('NED', 'Netherlands', 'UEFA', 'F', 7, 'Ronald Koeman', 0, 11, 'Runner-up'),
('JPN', 'Japan', 'AFC', 'F', 18, 'Hajime Moriyasu', 0, 7, 'Round of 16'),
('SWE', 'Sweden', 'UEFA', 'F', 25, 'Jon Dahl Tomasson', 0, 12, 'Runner-up'),
('TUN', 'Tunisia', 'CAF', 'F', 34, 'Faouzi Benzarti', 0, 6, 'Group stage'),

-- GROUP G
('BEL', 'Belgium', 'UEFA', 'G', 3, 'Rudi Garcia', 0, 14, 'Third place'),
('EGY', 'Egypt', 'CAF', 'G', 41, 'Hossam Hassan', 0, 3, 'Round of 16'),
('IRN', 'IR Iran', 'AFC', 'G', 21, 'Amir Ghalenoei', 0, 6, 'Group stage'),
('NZL', 'New Zealand', 'OFC', 'G', 97, 'Darren Bazeley', 0, 2, 'Group stage'),

-- GROUP H
('ESP', 'Spain', 'UEFA', 'H', 2, 'Luis de la Fuente', 0, 16, 'Champion'),
('CPV', 'Cabo Verde', 'CAF', 'H', 71, 'Bubista', 0, 0, NULL),
('KSA', 'Saudi Arabia', 'AFC', 'H', 56, 'Hervé Renard', 0, 6, 'Round of 16'),
('URU', 'Uruguay', 'CONMEBOL', 'H', 17, 'Marcelo Bielsa', 0, 14, 'Champion'),

-- GROUP I
('FRA', 'France', 'UEFA', 'I', 1, 'Didier Deschamps', 0, 17, 'Champion'),
('SEN', 'Senegal', 'CAF', 'I', 20, 'Aliou Cissé', 0, 3, 'Quarterfinals'),
('IRQ', 'Iraq', 'AFC', 'I', 55, 'Jesús Casas', 0, 1, 'Group stage'),
('NOR', 'Norway', 'UEFA', 'I', 24, 'Ståle Solbakken', 0, 3, 'Round of 16'),

-- GROUP J
('ARG', 'Argentina', 'CONMEBOL', 'J', 3, 'Lionel Scaloni', 0, 18, 'Champion'),
('ALG', 'Algeria', 'CAF', 'J', 36, 'Vladimir Petkovic', 0, 4, 'Round of 16'),
('AUT', 'Austria', 'UEFA', 'J', 28, 'Ralf Rangnick', 0, 8, 'Third place'),
('JOR', 'Jordan', 'AFC', 'J', 82, 'Hossam Hassan', 0, 0, NULL),

-- GROUP K
('POR', 'Portugal', 'UEFA', 'K', 5, 'Roberto Martínez', 0, 8, 'Third place'),
('COD', 'DR Congo', 'CAF', 'K', 61, 'Sébastien Desabre', 0, 1, 'Group stage'),
('UZB', 'Uzbekistan', 'AFC', 'K', 74, 'Srecko Katanec', 0, 0, NULL),
('COL', 'Colombia', 'CONMEBOL', 'K', 13, 'Néstor Lorenzo', 0, 6, 'Quarterfinals'),

-- GROUP L
('ENG', 'England', 'UEFA', 'L', 4, 'Thomas Tuchel', 0, 16, 'Champion'),
('CRO', 'Croatia', 'UEFA', 'L', 10, 'Zlatko Dalic', 0, 6, 'Runner-up'),
('GHA', 'Ghana', 'CAF', 'L', 60, 'Otto Addo', 0, 4, 'Quarterfinals'),
('PAN', 'Panama', 'CONCACAF', 'L', 77, 'Thomas Christiansen', 0, 1, 'Group stage');


-- ============================================================
-- Transfermarkt squad metrics — snapshot 2026-06-16
-- squad_size, avg_age (years), market_value_m (total squad value, EUR millions)
-- ============================================================
UPDATE teams SET market_value_m=1520.0 WHERE team_id='FRA';
UPDATE teams SET market_value_m=1360.0 WHERE team_id='ENG';
UPDATE teams SET market_value_m=1220.0 WHERE team_id='ESP';
UPDATE teams SET market_value_m=1010.0 WHERE team_id='POR';
UPDATE teams SET market_value_m=947.0 WHERE team_id='GER';
UPDATE teams SET market_value_m=928.2 WHERE team_id='BRA';
UPDATE teams SET market_value_m=807.5 WHERE team_id='ARG';
UPDATE teams SET market_value_m=754.2 WHERE team_id='NED';
UPDATE teams SET market_value_m=589.9 WHERE team_id='NOR';
UPDATE teams SET market_value_m=547.5 WHERE team_id='BEL';
UPDATE teams SET market_value_m=522.1 WHERE team_id='CIV';
UPDATE teams SET market_value_m=478.1 WHERE team_id='SEN';
UPDATE teams SET market_value_m=473.7 WHERE team_id='TUR';
UPDATE teams SET market_value_m=447.7 WHERE team_id='MAR';
UPDATE teams SET market_value_m=406.08 WHERE team_id='SWE';
UPDATE teams SET market_value_m=387.3 WHERE team_id='CRO';
UPDATE teams SET market_value_m=385.65 WHERE team_id='USA';
UPDATE teams SET market_value_m=368.7 WHERE team_id='ECU';
UPDATE teams SET market_value_m=359.3 WHERE team_id='URU';
UPDATE teams SET market_value_m=332.5 WHERE team_id='SUI';
UPDATE teams SET market_value_m=302.35 WHERE team_id='COL';
UPDATE teams SET market_value_m=270.85 WHERE team_id='JPN';
UPDATE teams SET market_value_m=256.9 WHERE team_id='ALG';
UPDATE teams SET market_value_m=245.2 WHERE team_id='AUT';
UPDATE teams SET market_value_m=234.35 WHERE team_id='GHA';
UPDATE teams SET market_value_m=198.65 WHERE team_id='CAN';
UPDATE teams SET market_value_m=191.85 WHERE team_id='MEX';
UPDATE teams SET market_value_m=188.18 WHERE team_id='CZE';
UPDATE teams SET market_value_m=170.25 WHERE team_id='SCO';
UPDATE teams SET market_value_m=153.65 WHERE team_id='PAR';
UPDATE teams SET market_value_m=146.4 WHERE team_id='BIH';
UPDATE teams SET market_value_m=143.9 WHERE team_id='COD';
UPDATE teams SET market_value_m=139.05 WHERE team_id='KOR';
UPDATE teams SET market_value_m=116.48 WHERE team_id='EGY';
UPDATE teams SET market_value_m=85.33 WHERE team_id='UZB';
UPDATE teams SET market_value_m=77.45 WHERE team_id='AUS';
UPDATE teams SET market_value_m=69.95 WHERE team_id='TUN';
UPDATE teams SET market_value_m=55.9 WHERE team_id='HAI';
UPDATE teams SET market_value_m=54.5 WHERE team_id='CPV';
UPDATE teams SET market_value_m=49.25 WHERE team_id='RSA';
UPDATE teams SET market_value_m=40.68 WHERE team_id='KSA';
UPDATE teams SET market_value_m=34.55 WHERE team_id='PAN';
UPDATE teams SET market_value_m=34.3 WHERE team_id='NZL';
UPDATE teams SET market_value_m=32.05 WHERE team_id='IRN';
UPDATE teams SET market_value_m=25.78 WHERE team_id='CUW';
UPDATE teams SET market_value_m=21.2 WHERE team_id='IRQ';
UPDATE teams SET market_value_m=20.3 WHERE team_id='JOR';
UPDATE teams SET market_value_m=19.93 WHERE team_id='QAT';

-- ============================================================
-- SEED: players
-- Full 26-man squads for 6 teams (real data from FIFA).
-- Remaining 42 teams: placeholder GKs only — enough to run
-- confederation-level queries. Expand per session.
-- ============================================================

-- ---------------------------
-- MEXICO (Group A) — full 26
-- ---------------------------
INSERT INTO players (fbref_id, team_id, name, position, shirt_number, birthday, birthplace, club) VALUES
('30885199', 'ALG', 'Achref Abada', 'DF', 3, '1999-06-15', 'Tebesbest, Algeria', 'USM Alger'),
('9b398aea', 'ALG', 'Rayan Aït-Nouri', 'DF', 15, '2001-06-06', 'Montreuil, France', 'Manchester City'),
('ca9f89a4', 'ALG', 'Mohamed Amine Tougai', 'DF', 4, '2000-01-22', 'Bourouba, Algeria', 'Espérance Tunis'),
('6597f8b6', 'ALG', 'Mohamed Amoura', 'FW,MF', 18, '2000-05-09', 'Jijel, Algeria', 'Wolfsburg'),
('a5db0bec', 'ALG', 'Houssem Aouar', 'MF', 8, '1998-06-30', 'Lyon, France', 'Al-Ittihad'),
('b2562589', 'ALG', 'Zineddine Belaïd', 'DF', 5, '1999-03-20', 'Thenia, Algeria', 'JS Kabylie'),
('0abcb968', 'ALG', 'Rafik Belghali', 'DF', 17, '2002-06-07', 'Leuven, Belgium', 'Hellas Verona'),
('dcae580c', 'ALG', 'Oussama Benbot', 'GK', 16, '1994-10-11', 'Aïn M''Lila, Algeria', 'USM Alger'),
('cd25f2b3', 'ALG', 'Nadhir Benbouali', 'FW', 12, '2000-04-17', 'Chlef, Algeria', 'Győr'),
('378825c7', 'ALG', 'Ramy Bensebaini', 'DF', 21, '1995-04-16', 'Constantine, Algeria', 'Dortmund'),
('3189f61a', 'ALG', 'Nabil Bentaleb', 'MF', 19, '1994-11-24', 'Lille, France', 'Lille'),
('f9d5908e', 'ALG', 'Hicham Boudaoui', 'MF', 14, '1999-09-23', 'Béchar, Algeria', 'Nice'),
('12f7f264', 'ALG', 'Adil Boulbina', 'FW', 20, '2003-05-02', 'El Milia, Algeria', 'Al Duhail SC'),
('357103bd', 'ALG', 'Fares Chaïbi', 'MF', 10, '2002-11-28', 'Lyon, France', 'Frankfurt'),
('4b6ab1da', 'ALG', 'Samir Chergui', 'DF', 26, '1999-02-06', 'Brétigny-sur-Orge, France', 'Paris FC'),
('14aac43e', 'ALG', 'Farés Ghedjemis', 'FW,MF', 25, '2002-09-06', 'Montreuil, France', 'Frosinone'),
('aad56ca3', 'ALG', 'Amine Gouiri', 'FW', 9, '2000-02-16', 'Bourgoin-Jallieu, France', 'Marseille'),
('7bc7eef2', 'ALG', 'Anis Hadj Moussa', 'MF', 11, '2002-02-11', 'France, France', 'Feyenoord'),
('576817b7', 'ALG', 'Jaouen Hadjam', 'DF', 13, '2003-03-26', 'Paris, France', 'Young Boys'),
('892d5bb1', 'ALG', 'Riyad Mahrez', 'MF', 7, '1991-02-21', 'Sarcelles, France', 'Al-Ahli'),
('fbd6378b', 'ALG', 'Aïssa Mandi', 'DF', 2, '1991-10-22', 'Châlons-en-Champagne, France', 'Lille'),
('b2f66efb', 'ALG', 'Melvin Mastil', 'GK', 1, '2000-02-19', 'Thonon-les-Bains, France', 'FC Stade Nyonnais'),
('89b3bc5e', 'ALG', 'Ibrahim Maza', 'MF', 22, '2005-11-24', 'Berlin, Germany', 'Leverkusen'),
('553c40f2', 'ALG', 'Yassine Titraoui', 'MF', 24, '2003-07-26', 'M''sila, Algeria', 'Charleroi'),
('c762b1a6', 'ALG', 'Ramiz Zerrouki', 'MF', 6, '1998-05-26', 'Amsterdam, Netherlands', 'Twente'),
('c818c4d9', 'ALG', 'Luca Zidane', 'GK', 23, '1998-05-13', 'Marseille, France', 'Granada'),
('27f33438', 'ARG', 'Thiago Almada', 'MF', 16, '2001-04-26', 'Ciudadela, Argentina', 'Atlético Madrid'),
('15ab5a2b', 'ARG', 'Julián Álvarez', 'FW,MF', 9, '2000-01-31', 'Calchín, Argentina', 'Atlético Madrid'),
('7c3ed041', 'ARG', 'Leonardo Balerdi', 'DF', NULL, '1999-01-26', 'Villa Mercedes, Argentina', 'Marseille'),
('b9f282ec', 'ARG', 'Valentín Barco', 'DF,MF', 8, '2004-07-23', 'Veinticinco de Mayo, Argentina', 'Strasbourg'),
('162efffd', 'ARG', 'Rodrigo De Paul', 'MF', 7, '1994-05-24', 'Sarandí, Argentina', 'Inter Miami'),
('5ff4ab71', 'ARG', 'Enzo Fernández', 'MF', 24, '2001-01-17', 'General San Martín, Argentina', 'Chelsea'),
('2374aaca', 'ARG', 'Nicolás González', 'FW,MF', 15, '1998-04-06', 'Belén de Escobar, Argentina', 'Atlético Madrid'),
('d7553721', 'ARG', 'Giovani Lo Celso', 'FW,MF', 11, '1996-04-09', 'Rosario, Argentina', 'Real Betis'),
('e1426a52', 'ARG', 'Flaco López', 'FW', 21, '2000-12-06', 'Departamento de Saladas, Argentina', 'Palmeiras'),
('83d074ff', 'ARG', 'Alexis Mac Allister', 'MF', 20, '1998-12-24', 'Santa Rosa, Argentina', 'Liverpool'),
('7956236f', 'ARG', 'Emiliano Martínez', 'GK', 23, '1992-09-02', 'Mar del Plata, Argentina', 'Aston Villa'),
('f7036e1c', 'ARG', 'Lautaro Martínez', 'FW', 22, '1997-08-22', 'Bahía Blanca, Argentina', 'Inter'),
('bac46a10', 'ARG', 'Lisandro Martínez', 'DF', 6, '1998-01-18', 'Gualeguay, Argentina', 'Manchester Utd'),
('6f5ec8bb', 'ARG', 'Facundo Medina', 'DF', 25, '1999-05-28', 'Fiorito, Argentina', 'Marseille'),
('d70ce98e', 'ARG', 'Lionel Messi', 'FW', 10, '1987-06-24', 'Rosario, Argentina', 'Inter Miami'),
('23610943', 'ARG', 'Nahuel Molina', 'DF', 26, '1998-04-06', 'Embalse, Argentina', 'Atlético Madrid'),
('374d5158', 'ARG', 'Gonzalo Montiel', 'DF', 4, '1997-01-01', 'González Catán, Argentina', 'River Plate'),
('a111cf41', 'ARG', 'Juan Musso', 'GK', 1, '1994-05-06', 'San Nicolás de los Arroyos, Argentina', 'Atlético Madrid'),
('0d267745', 'ARG', 'Nicolás Otamendi', 'DF', 19, '1988-02-12', 'Buenos Aires, Argentina', 'Benfica'),
('e82adcab', 'ARG', 'Exequiel Palacios', 'DF,MF', 14, '1998-10-05', 'Famaillá, Argentina', 'Leverkusen'),
('dff153a4', 'ARG', 'Leandro Paredes', 'MF', 5, '1994-06-29', 'San Justo, Argentina', 'Boca Juniors'),
('01bb93d5', 'ARG', 'Nicolás Paz', 'MF', 18, '2004-09-08', 'Santa Cruz de Tenerife, Spain', 'Como'),
('a3d94a58', 'ARG', 'Cristian Romero', 'DF', 13, '1998-04-27', 'Córdoba, Argentina', 'Tottenham'),
('625c144a', 'ARG', 'Gerónimo Rulli', 'GK', 12, '1992-05-20', 'La Plata, Argentina', 'Marseille'),
('35141f4c', 'ARG', 'Marcos Senesi', 'DF', 2, '1997-05-10', 'Concordia, Argentina', 'Bournemouth'),
('a6536561', 'ARG', 'Giuliano Simeone', 'FW,MF', 17, '2002-12-18', 'Rome, Italy', 'Atlético Madrid'),
('f0661424', 'ARG', 'Nicolás Tagliafico', 'DF', 3, '1992-08-31', 'Buenos Aires, Argentina', 'Lyon'),
('3cc64624', 'AUS', 'Patrick Beach', 'GK', 18, '2003-08-06', 'Sydney, Australia', 'Melb City'),
('b6867b96', 'AUS', 'Aziz Behich', 'MF', 16, '1990-12-16', 'Moonee Ponds, Australia', 'Melb City'),
('8070a9fd', 'AUS', 'Jordy Bos', 'DF,MF', 5, '2002-10-29', 'Melbourne, Australia', 'Feyenoord'),
('da61ca98', 'AUS', 'Cameron Burgess', 'DF', 21, '1995-10-21', 'Aberdeen, Scotland, United Kingdom', 'Swansea City'),
('1223765c', 'AUS', 'Alessandro Circati', 'DF', 3, '2003-10-10', 'Fidenza, Italy', 'Parma'),
('c8e65157', 'AUS', 'Miloš Degenek', 'DF,MF', 2, '1994-04-28', 'Knin, Croatia', 'APOEL FC'),
('fd53ed00', 'AUS', 'Cammy Devlin', 'MF', 14, '1998-06-07', 'Sydney, Australia', 'Hearts'),
('cd494a8d', 'AUS', 'Jason Geria', 'DF', 6, '1993-05-10', 'Canberra, Australia', 'Albirex Niigata'),
('6f808c85', 'AUS', 'Lucas Herrington', 'DF', 25, '2007-09-05', 'Brisbane, Australia', 'Colorado Rapids'),
('1f2d714c', 'AUS', 'Ajdin Hrustic', 'MF', 10, '1996-07-05', 'Melbourne, Australia', 'Heracles Almelo'),
('4ac730b2', 'AUS', 'Nestory Irankunda', 'MF,FW', 17, '2006-02-09', 'Kibondo, Tanzania', 'Watford'),
('4637747c', 'AUS', 'Jackson Irvine', 'MF', 22, '1993-03-07', 'Melbourne, Australia', 'St Pauli'),
('2eb0ee9a', 'AUS', 'Jacob Italiano', 'DF', 4, '2001-07-30', 'Perth, Australia', 'Grazer AK'),
('f3c4d6ac', 'AUS', 'Paul Izzo', 'GK', 12, '1995-01-06', 'Adelaide, Australia', 'Randers'),
('b93b7882', 'AUS', 'Mathew Leckie', 'MF', 7, '1991-02-04', 'Melbourne, Australia', 'Melb City'),
('922da988', 'AUS', 'Awer Mabil', 'FW,MF', 11, '1995-09-15', 'Kakuma, Kenya', 'Castellón'),
('73ce4d7d', 'AUS', 'Connor Metcalfe', 'MF', 8, '1999-11-05', 'Newcastle, Australia', 'St Pauli'),
('c7aee75b', 'AUS', 'Aiden O''Neill', 'MF', 13, '1998-07-04', 'Brisbane, Australia', 'NYCFC'),
('ecd6464a', 'AUS', 'Paul Okon-Engstler', 'MF', 24, '2005-01-24', 'Gent, Belgium', 'Sydney FC'),
('4535e4bb', 'AUS', 'Mathew Ryan', 'GK', 1, '1992-04-08', 'Plumpton, Australia', 'Levante'),
('0a6cb1b1', 'AUS', 'Harry Souttar', 'DF', 19, '1998-10-22', 'Aberdeen, Scotland, United Kingdom', 'Leicester City'),
('8ac64b4e', 'AUS', 'Mo Touré', 'FW', 9, '2004-03-26', 'Conakry, Guinea', 'Norwich City'),
('1ab3d134', 'AUS', 'Kai Trewin', 'DF,MF', 15, '2001-05-18', 'Batemans Bay, Australia', 'NYCFC'),
('40cb6b33', 'AUS', 'Nishan Velupillay', 'MF', 23, '2001-05-07', 'Melbourne, Australia', 'Melb. Victory'),
('72f87f25', 'AUS', 'Cristian Volpato', 'MF', 20, '2003-11-15', 'Camperdown, Australia', 'Sassuolo'),
('1c215c70', 'AUS', 'Tete Yengi', 'FW', 26, '2000-11-28', 'Adelaide, Australia', 'Machida Zelvia'),
('4b00cd47', 'AUT', 'David Affengruber', 'DF', 2, '2001-03-19', 'Scheibbs, Austria', 'Elche'),
('05439de2', 'AUT', 'David Alaba', 'DF', 8, '1992-06-24', 'Austria', 'Real Madrid'),
('00459419', 'AUT', 'Marko Arnautović', 'FW,MF', 7, '1989-04-19', 'Austria', 'Red Star'),
('437f2b00', 'AUT', 'Christoph Baumgartner', 'FW,MF', NULL, '1999-08-01', 'Horn, Austria', 'RB Leipzig'),
('b2f9c73e', 'AUT', 'Carney Chukwuemeka', 'MF', 17, '2003-10-20', 'Eisenstadt, Austria', 'Dortmund'),
('6e33125f', 'AUT', 'Kevin Danso', 'DF', 3, '1998-09-19', 'Voitsberg, Austria', 'Tottenham'),
('f86ad3f5', 'AUT', 'Marco Friedl', 'DF', 23, '1998-03-16', 'Kirchbichl, Austria', 'Werder Bremen'),
('8e235926', 'AUT', 'Michael Gregoritsch', 'FW', 11, '1994-04-18', 'Graz, Austria', 'Augsburg'),
('ffbbc83b', 'AUT', 'Florian Grillitsch', 'DF,MF', 10, '1995-08-07', 'Neunkirchen, Austria', 'Braga'),
('15f24fe7', 'AUT', 'Saša Kalajdžić', 'FW', 14, '1997-07-07', 'Austria', 'LASK'),
('c1b7847c', 'AUT', 'Konrad Laimer', 'MF,DF', 20, '1997-05-27', 'Austria', 'Bayern Munich'),
('302527b2', 'AUT', 'Philipp Lienhart', 'DF', 15, '1996-07-11', 'Lilienfeld, Austria', 'Freiburg'),
('c455a2b2', 'AUT', 'Dejan Ljubičić', 'MF', 19, '1997-10-08', 'Austria', 'Schalke 04'),
('2ff76adc', 'AUT', 'Phillipp Mwene', 'DF', 16, '1994-01-29', 'Austria', 'Mainz 05'),
('0810b6df', 'AUT', 'Patrick Pentz', 'GK', 13, '1997-01-02', 'Austria', 'Brøndby'),
('7f609bfc', 'AUT', 'Stefan Posch', 'DF', 5, '1997-05-14', 'Judenburg, Austria', 'Mainz 05'),
('6637e6a7', 'AUT', 'Alexander Prass', 'DF,MF', 22, '2001-05-26', 'Hellmonsödt, Austria', 'Hoffenheim'),
('e280527c', 'AUT', 'Marcel Sabitzer', 'MF', 9, '1994-03-17', 'Graz, Austria', 'Dortmund'),
('6fe5c35b', 'AUT', 'Alexander Schlager', 'GK', 1, '1996-02-01', 'Austria', 'RB Salzburg'),
('8f056768', 'AUT', 'Xaver Schlager', 'MF', 4, '1997-09-28', 'Austria', 'RB Leipzig'),
('220ace7e', 'AUT', 'Romano Schmid', 'MF', 18, '2000-01-27', 'Graz, Austria', 'Werder Bremen'),
('106bca06', 'AUT', 'Alessandro Schöpf', 'MF', 26, '1994-02-07', 'Umhausen, Austria', 'RZ Pellets WAC'),
('28c6e925', 'AUT', 'Nicolas Seiwald', 'MF', 6, '2001-05-04', 'Kuchl, Austria', 'RB Leipzig'),
('8abd174d', 'AUT', 'Michael Svoboda', 'DF', 25, '1998-10-15', 'Austria', 'Venezia'),
('cb64672e', 'AUT', 'Paul Wanner', 'MF', 24, '2005-12-23', 'Dornbirn, Austria', 'PSV'),
('67db5f7f', 'AUT', 'Florian Wiegele', 'GK', 12, '2001-03-21', 'Graz Stadt, Austria', 'Viktoria Plzeň'),
('cb11b429', 'AUT', 'Patrick Wimmer', 'FW,MF', 21, '2001-05-30', 'Tulln, Austria', 'Wolfsburg'),
('197640fd', 'BEL', 'Timothy Castagne', 'DF', 21, '1995-12-05', 'Arlon, Belgium', 'Fulham'),
('1840e36d', 'BEL', 'Thibaut Courtois', 'GK', 1, '1992-05-11', 'Bree, Belgium', 'Real Madrid'),
('e46012d4', 'BEL', 'Kevin De Bruyne', 'MF', 7, '1991-06-28', 'Gent, Belgium', 'Napoli'),
('d494882e', 'BEL', 'Maxim De Cuyper', 'DF', 5, '2000-12-22', 'Knokke-Heist, Belgium', 'Brighton'),
('2ef7c612', 'BEL', 'Charles De Ketelaere', 'FW', 17, '2001-03-10', 'Brugge, Belgium', 'Atalanta'),
('f4797849', 'BEL', 'Koni De Winter', 'DF', 16, '2002-06-12', 'Antwerpen, Belgium', 'Milan'),
('064461b7', 'BEL', 'Zeno Debast', 'DF', 2, '2003-10-24', 'Halle, Belgium', 'Sporting CP'),
('fffea3e5', 'BEL', 'Jeremy Doku', 'MF', 11, '2002-05-27', 'Antwerpen, Belgium', 'Manchester City'),
('0cdb6a2a', 'BEL', 'Matias Fernandez-Pardo', 'FW,MF', 26, '2005-02-03', 'Brussels, Belgium', 'Lille'),
('8e6d2fcd', 'BEL', 'Senne Lammens', 'GK', 12, '2002-07-07', 'Zottegem, Belgium', 'Manchester Utd'),
('5eae500a', 'BEL', 'Romelu Lukaku', 'FW', 9, '1993-05-13', 'Antwerpen, Belgium', 'Napoli'),
('0c61c77c', 'BEL', 'Dodi Lukebakio', 'FW,MF', 14, '1997-09-24', 'Asse, Belgium', 'Benfica'),
('0a6dbbf7', 'BEL', 'Brandon Mechele', 'DF', 4, '1993-01-28', 'Bredene, Belgium', 'Club Brugge'),
('e162b013', 'BEL', 'Thomas Meunier', 'DF', 15, '1991-09-12', 'Sainte-Ode, Belgium', 'Lille'),
('12de1b0d', 'BEL', 'Diego Moreira', 'MF', 19, '2004-08-06', 'Liège, Belgium', 'Strasbourg'),
('eb7abf2e', 'BEL', 'Nathan Ngoy', 'DF', 25, '2003-06-10', 'Brussels, Belgium', 'Lille'),
('828657ff', 'BEL', 'Amadou Onana', 'MF', 24, '2001-08-16', 'Brussels, Belgium', 'Aston Villa'),
('074e1710', 'BEL', 'Mike Penders', 'GK', 13, '2005-07-31', 'Maasmechelen, Belgium', 'Strasbourg'),
('dba1f190', 'BEL', 'Nicolas Raskin', 'MF', 23, '2001-02-23', 'Liège, Belgium', 'Rangers'),
('ee251371', 'BEL', 'Alexis Saelemaekers', 'MF', 22, '1999-06-27', 'Sint-Agatha-Berchem, Belgium', 'Milan'),
('0beabf0a', 'BEL', 'Joaquin Seys', 'DF', 18, '2005-03-28', 'Oostende, Belgium', 'Club Brugge'),
('df8d6029', 'BEL', 'Arthur Theate', 'DF', 3, '2000-05-25', 'Liège, Belgium', 'Frankfurt'),
('56f7a928', 'BEL', 'Youri Tielemans', 'MF', 8, '1997-05-07', 'Sint-Pieters-Leeuw, Belgium', 'Aston Villa'),
('38ceb24a', 'BEL', 'Leandro Trossard', 'MF', 10, '1994-12-04', 'Maasmechelen, Belgium', 'Arsenal'),
('392a7aea', 'BEL', 'Hans Vanaken', 'MF', 20, '1992-08-24', 'Neerpelt, Belgium', 'Club Brugge'),
('5dfc6ad5', 'BEL', 'Axel Witsel', 'DF,MF', 6, '1989-01-12', 'Liège, Belgium', 'Girona'),
('f3d9291e', 'BIH', 'Kerim Alajbegović', 'MF', 19, '2007-09-21', 'Köln, Germany', 'RB Salzburg'),
('dff24174', 'BIH', 'Esmir Bajraktarevic', 'MF', 20, '2005-03-10', 'Appleton, WI, United States', 'PSV'),
('9b0a0d51', 'BIH', 'Ivan Bašić', 'MF', 13, '2002-04-30', 'Imotski, Croatia', 'FC Astana'),
('e59c9d0d', 'BIH', 'Samed Baždar', 'FW', 9, '2004-01-31', 'Novi Pazar, Serbia', 'Gladbach'),
('0dabaf14', 'BIH', 'Dženis Burnić', 'MF', 17, '1998-05-22', 'Hamm, Germany', 'Karlsruher'),
('4e0d2a01', 'BIH', 'Nidal Čelik', 'DF', NULL, '2006-07-17', 'Sarajevo, Bosnia and Herzegovina', 'Lens'),
('bc6e544a', 'BIH', 'Amar Dedić', 'DF', 7, '2002-08-18', 'Zell am See, Austria', 'Benfica'),
('ed79b7d3', 'BIH', 'Ermedin Demirović', 'FW', 10, '1998-03-25', 'Hamburg, Germany', 'Stuttgart'),
('3bb7f478', 'BIH', 'Edin Džeko', 'FW', 11, '1986-03-17', 'Sarajevo, Bosnia and Herzegovina', 'Schalke 04'),
('d0a0858e', 'BIH', 'Armin Gigovic', 'MF', 8, '2002-04-06', 'Lund, Sweden', 'Young Boys'),
('e8213ed3', 'BIH', 'Amir Hadžiahmetović', 'MF', 16, '1997-03-08', 'Nexø, Denmark', 'Hull City'),
('82cfae2a', 'BIH', 'Dennis Hadžikadunić', 'DF', 3, '1998-07-09', 'Malmö, Sweden', 'Sampdoria'),
('549922a7', 'BIH', 'Osman Hadžikić', 'GK', NULL, '1996-03-12', 'Klosterneuburg, Austria', 'Slaven Belupo'),
('4cf89690', 'BIH', 'Mladen Jurkas', 'GK', 12, '2007-10-07', 'Doboj, Bosnia and Herzegovina', 'B. Banja Luka'),
('35bd124a', 'BIH', 'Nikola Katić', 'DF', 18, '1996-10-10', 'Ljubuški, Bosnia and Herzegovina', 'Schalke 04'),
('3935e52e', 'BIH', 'Sead Kolašinac', 'DF', 5, '1993-06-20', 'Karlsruhe, Germany', 'Atalanta'),
('a2056e82', 'BIH', 'Jovo Lukić', 'FW', 25, '1998-11-28', 'Banja Luka, Bosnia and Herzegovina', 'Univ. Cluj'),
('86e34165', 'BIH', 'Ermin Mahmić', 'MF', 26, '2005-03-14', 'Wels Stadt, Austria', 'Slovan Liberec'),
('de57cd45', 'BIH', 'Arjan Malic', 'DF', 24, '2005-08-28', 'Slovenia, Slovenia', 'Sturm Graz'),
('918c187c', 'BIH', 'Amar Memić', 'MF', 15, '2001-01-20', 'Sarajevo, Bosnia and Herzegovina', 'Viktoria Plzeň'),
('426dda23', 'BIH', 'Tarik Muharemovic', 'DF', 4, '2003-02-28', 'Slovenia, Slovenia', 'Sassuolo'),
('8eff6286', 'BIH', 'Nihad Mujakić', 'DF', 2, '1998-04-15', 'Sarajevo, Bosnia and Herzegovina', 'Gaziantep'),
('30e03a25', 'BIH', 'Stjepan Radeljić', 'DF', 21, '1997-09-05', 'Nova Bila, Bosnia and Herzegovina', 'Rijeka'),
('e18098de', 'BIH', 'Ivan Šunjić', 'MF', 14, '1996-10-09', 'Zenica, Bosnia and Herzegovina', 'Pafos FC'),
('723b19c7', 'BIH', 'Haris Tabaković', 'FW', 23, '1994-06-20', 'Grenchen, Switzerland', 'Schalke 04'),
('eb3022c3', 'BIH', 'Benjamin Tahirovic', 'MF', 6, '2003-03-03', 'Spånga, Sweden', 'Brøndby'),
('f038585f', 'BIH', 'Nikola Vasilj', 'GK', 1, '1995-12-02', 'Mostar, Bosnia and Herzegovina', 'St Pauli'),
('7d7cb997', 'BIH', 'Martin Zlomislić', 'GK', 22, '1998-08-16', 'Općina Posušje, Bosnia and Herzegovina', 'Rijeka'),
('7a2e46a8', 'BRA', 'Alisson', 'GK', 1, '1992-10-02', 'Novo Hamburgo, Brazil', 'Liverpool'),
('5fd5ed86', 'BRA', 'Gleison Bremer', 'DF', 14, '1997-03-18', 'Itapiranga, Brazil', 'Juventus'),
('4d224fe8', 'BRA', 'Casemiro', 'MF', 5, '1992-02-23', 'São José dos Campos, Brazil', 'Manchester Utd'),
('dc62b55d', 'BRA', 'Matheus Cunha', 'FW', 9, '1999-05-27', 'João Pessoa, Brazil', 'Manchester Utd'),
('94b2001f', 'BRA', 'Danilo', 'DF', 13, '1991-07-15', 'Bicas, Brazil', 'Flamengo'),
('a2728fbf', 'BRA', 'Endrick', 'FW', 19, '2006-07-21', 'Taguatinga, Brazil', 'Lyon'),
('7f3b388c', 'BRA', 'Fabinho', 'DF,MF', 17, '1993-10-23', 'Campinas, Brazil', 'Al-Ittihad'),
('82518f62', 'BRA', 'Bruno Guimarães', 'MF', 8, '1997-11-16', 'Rio de Janeiro, Brazil', 'Newcastle'),
('8059806f', 'BRA', 'Luiz Henrique', 'FW,MF', 21, '2001-01-02', 'Petrópolis, Brazil', 'Zenit'),
('82efe6fa', 'BRA', 'Roger Ibanez', 'DF', 24, '1998-11-23', 'Canela, Brazil', 'Al-Ahli'),
('7111d552', 'BRA', 'Vinicius Júnior', 'FW', 7, '2000-07-12', 'São Gonçalo, Brazil', 'Real Madrid'),
('67ac5bb8', 'BRA', 'Gabriel Magalhães', 'DF', 3, '1997-12-19', 'São Paulo, Brazil', 'Arsenal'),
('d5f2f82b', 'BRA', 'Marquinhos', 'DF', 4, '1994-05-14', 'São Paulo, Brazil', 'PSG'),
('48a5a5d6', 'BRA', 'Gabriel Martinelli', 'FW,MF', 22, '2001-06-18', 'Guarulhos, Brazil', 'Arsenal'),
('3bb7b8b4', 'BRA', 'Ederson Moraes', 'GK', 23, '1993-08-17', 'Osasco, Brazil', 'Fenerbahçe'),
('69384e5d', 'BRA', 'Neymar', 'FW,MF', 10, '1992-02-05', 'Mogi das Cruzes, Brazil', 'Santos'),
('9b6f7fd5', 'BRA', 'Lucas Paquetá', 'MF', 20, '1997-08-27', 'Rio de Janeiro, Brazil', 'Flamengo'),
('bd247251', 'BRA', 'Léo Pereira', 'DF', 15, '1996-01-31', 'Curitiba, Brazil', 'Flamengo'),
('3423f250', 'BRA', 'Raphinha', 'MF,FW', 11, '1996-12-14', 'Porto Alegre, Brazil', 'Barcelona'),
('288647fc', 'BRA', 'Rayan', 'FW', 26, '2006-08-03', 'Rio de Janeiro, Brazil', 'Bournemouth'),
('0d82903c', 'BRA', 'Alex Sandro', 'DF,MF', 6, '1991-01-26', 'Catanduva, Brazil', 'Flamengo'),
('a816dbfb', 'BRA', 'Danilo Santos', 'MF', 18, '2001-04-29', 'Salvador, Brazil', 'Botafogo–RJ'),
('c50e5bba', 'BRA', 'Douglas Santos', 'DF', 16, '1994-03-22', 'João Pessoa, Brazil', 'Zenit'),
('a9202def', 'BRA', 'Éderson Silva', 'MF', 2, '1999-07-07', 'Campo Grande, Brazil', 'Atalanta'),
('dc45ac24', 'BRA', 'Igor Thiago', 'FW', 25, '2001-06-26', 'Brasília, Brazil', 'Brentford'),
('f2c49c79', 'BRA', 'Wesley', 'DF,MF', NULL, '2003-09-06', 'São Luís, Brazil', 'Roma'),
('81be82e9', 'BRA', 'Wéverton', 'GK', 12, '1987-12-13', 'Rio Branco, Brazil', 'Grêmio'),
('c692cef2', 'CPV', 'Telmo Arcanjo', 'MF', 18, '2001-06-21', 'Lisbon, Portugal', 'Vit. Guimarães'),
('eae26fce', 'CPV', 'Gilson Benchimol', 'FW', 9, '2001-12-29', 'Praia, Cape Verde', 'Akron Tolyatti'),
('e34e086c', 'CPV', 'Jovane Cabral', 'FW', 7, '1998-06-14', 'Assomada, Cape Verde', 'Estrela'),
('bfb2056e', 'CPV', 'Logan Costa', 'DF', 5, '2001-04-01', 'Saint-Denis, France', 'Villarreal'),
('909222de', 'CPV', 'Nuno da Costa', 'FW,MF', 21, '1991-02-10', 'Praia, Cape Verde', 'Başakşehir'),
('d2e33ba2', 'CPV', 'Diney', 'DF', 3, '1995-01-17', 'Tarrafal, Cape Verde', 'Al Bataeh'),
('e329eaa6', 'CPV', 'C.J. dos Santos', 'GK', 23, '2000-08-24', 'Philadelphia, PA, United States', 'San Diego FC'),
('6af8fc5b', 'CPV', 'Deroy Duarte', 'MF', 14, '1999-07-04', 'Rotterdam, Netherlands', 'Ludogorets'),
('4af3d3c8', 'CPV', 'Laros Duarte', 'MF', 15, '1997-02-28', 'Rotterdam, Netherlands', 'Puskás Akad.'),
('c115db1e', 'CPV', 'Dailon Livramento', 'FW', 19, '2001-05-04', 'Rotterdam, Netherlands', 'Casa Pia'),
('20700569', 'CPV', 'Sidny Lopes Cabral', 'DF', 13, '2002-09-18', 'Rotterdam, Netherlands', 'Benfica'),
('ba6e01ab', 'CPV', 'Ryan Mendes', 'MF,FW', 20, '1990-01-08', 'Mindelo, Cape Verde', '76 Iğdır Belediyespor'),
('d384bddd', 'CPV', 'Jamiro Monteiro', 'MF', 10, '1993-11-23', 'Rotterdam, Netherlands', 'Zwolle'),
('f10983ae', 'CPV', 'Steven Moreira', 'DF', 22, '1994-08-13', 'Noisy-le-Grand, France', 'Columbus Crew'),
('afcac9da', 'CPV', 'João Paulo Fernandes', 'DF,MF', 8, '1998-05-26', 'Cape Verde', 'FCSB'),
('faef0f92', 'CPV', 'Pico', 'DF', 4, '1992-06-17', 'Dublin, Republic of Ireland', 'Shamrock'),
('296026ae', 'CPV', 'Kevin Pina', 'MF', 6, '1997-01-27', 'Praia, Cape Verde', 'Krasnodar'),
('9bf22b95', 'CPV', 'Wagner Pina', 'DF,MF', 24, '2002-11-03', 'Lisbon, Portugal', 'Trabzonspor'),
('8fe1e61b', 'CPV', 'Kelvin Pires', 'DF', 25, '2000-06-05', 'Mindelo, Cape Verde', 'SJK'),
('149895bf', 'CPV', 'Garry Rodrigues', 'MF', 11, '1990-11-27', 'Rotterdam, Netherlands', 'Apollon Limassol'),
('87e907ff', 'CPV', 'Márcio Rosa', 'GK', 12, '1997-02-23', 'Praia, Cape Verde', 'Montana'),
('d1edc98f', 'CPV', 'Willy Semedo', 'FW,MF', 17, '1994-04-27', 'Paris, France', 'AC Omonia'),
('e9517008', 'CPV', 'Stopira', 'DF', 2, '1988-05-20', 'Praia, Cape Verde', 'Torreense'),
('91c99fec', 'CPV', 'Hélio Varela', 'FW', 26, '2002-05-03', 'Almada, Portugal', 'Maccabi Tel Aviv'),
('dc04ac24', 'CPV', 'Vozinha', 'GK', 1, '1986-06-03', 'Mindelo, Cape Verde', 'Chaves'),
('6246aa55', 'CPV', 'Yannick', 'MF', 16, '1995-12-29', 'Praia, Cape Verde', 'Farense'),
('540a5be1', 'CAN', 'Ali Ahmed', 'MF', 20, '2000-10-10', 'Toronto, ON, Canada', 'Norwich City'),
('c2f23fc8', 'CAN', 'Moïse Bombito', 'DF', 15, '2000-03-30', 'Montréal, QC, Canada', 'Nice'),
('3aca6420', 'CAN', 'Tajon Buchanan', 'MF', 17, '1999-02-08', 'Brampton, ON, Canada', 'Villarreal'),
('017459bb', 'CAN', 'Mathieu Choinière', 'MF', 6, '1999-02-07', 'Saint-Jean-sur-Richelieu, QC, Canada', 'LAFC'),
('577744b8', 'CAN', 'Derek Cornelius', 'DF', 13, '1997-11-25', 'Ajax, ON, Canada', 'Marseille'),
('ea42e480', 'CAN', 'Maxime Crépeau', 'GK', 16, '1994-05-11', 'Greenfield Park, QC, Canada', 'Orlando City'),
('ce50fd99', 'CAN', 'Jonathan David', 'FW', 10, '2000-01-14', 'Brooklyn, NY, United States', 'Juventus'),
('dbe19468', 'CAN', 'Promise David', 'FW', 24, '2001-07-03', 'Brampton, ON, Canada', 'Union SG'),
('d781d855', 'CAN', 'Alphonso Davies', 'DF,FW', 19, '2000-11-02', 'Monrovia, Liberia', 'Bayern Munich'),
('45c427ff', 'CAN', 'Luc De Fougerolles', 'DF', 4, '2005-10-12', 'London, England, United Kingdom', 'Fulham'),
('577efaec', 'CAN', 'Stephen Eustáquio', 'MF', 7, '1996-12-21', 'Leamington, ON, Canada', 'Porto'),
('937b36b1', 'CAN', 'Marcelo Flores', 'MF', NULL, '2003-10-01', 'Estado de México, Mexico', 'UANL'),
('8074e66f', 'CAN', 'Owen Goodman', 'GK', 18, '2003-11-27', 'England, United Kingdom', 'Barnsley'),
('4fb17e20', 'CAN', 'Alistair Johnston', 'DF', 2, '1998-10-08', 'Vancouver, BC, Canada', 'Celtic'),
('e5c107a1', 'CAN', 'Alfie Jones', 'DF,MF', 3, '1997-10-07', 'England, United Kingdom', 'Middlesbrough'),
('e0220b70', 'CAN', 'Ismaël Koné', 'MF', 8, '2002-06-16', 'Abidjan, Côte d''Ivoire', 'Sassuolo'),
('e7af9060', 'CAN', 'Cyle Larin', 'FW', 9, '1995-04-17', 'Brampton, ON, Canada', 'Mallorca'),
('276fdbe4', 'CAN', 'Richie Laryea', 'DF', 22, '1995-01-07', 'Toronto, ON, Canada', 'Toronto FC'),
('983515f8', 'CAN', 'Liam Millar', 'MF', 11, '1999-09-27', 'Toronto, ON, Canada', 'Hull City'),
('92305a81', 'CAN', 'Jayden Nelson', 'FW,MF', 26, '2002-09-26', 'Toronto, ON, Canada', 'Austin FC'),
('950ef017', 'CAN', 'Tani Oluwaseyi', 'FW', 12, '2000-05-15', 'Abuja, Nigeria', 'Villarreal'),
('70106ff6', 'CAN', 'Jonathan Osorio', 'MF', 21, '1992-06-12', 'Toronto, ON, Canada', 'Toronto FC'),
('44cfc681', 'CAN', 'Nathan Saliba', 'MF', 25, '2004-02-07', 'Longueuil, QC, Canada', 'Anderlecht'),
('339a2561', 'CAN', 'Jacob Shaffelburg', 'MF', 14, '1999-11-26', 'Kentville, NS, Canada', 'LAFC'),
('5c56986b', 'CAN', 'Niko Sigur', 'DF,MF', 23, '2003-09-09', 'Burnaby, BC, Canada', 'Hajduk Split'),
('3f41d25f', 'CAN', 'Dayne St. Clair', 'GK', 1, '1997-05-09', 'Pickering, ON, Canada', 'Inter Miami'),
('47ddcc22', 'CAN', 'Joel Waterman', 'DF', 5, '1996-01-24', 'Langley, BC, Canada', 'Chicago Fire'),
('86d96066', 'COL', 'Jhon Arias', 'MF', 11, '1997-09-21', 'Quibdó, Colombia', 'Palmeiras'),
('fdd60087', 'COL', 'Santiago Arias', 'DF,MF', 4, '1992-01-13', 'Medellín, Colombia', 'Independiente'),
('ad49f7fb', 'COL', 'Juan Camilo Portilla', 'MF', 15, '1998-09-12', 'Cali, Colombia', 'Athletico–PR'),
('8d5ceef2', 'COL', 'Jaminton Campaz', 'FW,MF', 21, '2000-05-24', 'Tumaco, Colombia', 'Rosario Central'),
('3f9f0d62', 'COL', 'Jorge Carrascal', 'FW,MF', 8, '1998-05-25', 'Cartagena, Colombia', 'Flamengo'),
('c393c3d9', 'COL', 'Kevin Castaño', 'MF', 5, '2000-09-29', 'Itagüí, Colombia', 'River Plate'),
('9f381d8b', 'COL', 'Jhon Córdoba', 'FW', 9, '1993-05-11', 'Istmina, Colombia', 'Krasnodar'),
('71b47ab9', 'COL', 'Cucho', 'FW,MF', 19, '1999-04-20', 'Pereira, Colombia', 'Real Betis'),
('2e3dbaa5', 'COL', 'Álvaro David Montero', 'GK', 24, '1995-03-29', 'El Molino, Colombia', 'Vélez Sarsfield'),
('4a1a9578', 'COL', 'Luis Díaz', 'FW', 7, '1997-01-13', 'Barrancas, Colombia', 'Bayern Munich'),
('95c2f969', 'COL', 'Willer Ditta', 'DF', 18, '1998-01-23', 'La Jagua de Ibirico, Colombia', 'Cruz Azul'),
('76a82373', 'COL', 'Andrés Gómez', 'MF', 26, '2002-09-12', 'Quibdó, Colombia', 'Vasco da Gama'),
('9b5ce51a', 'COL', 'Jefferson Lerma', 'MF', 16, '1994-10-25', 'El Cerrito, Colombia', 'Crystal Palace'),
('80490d7f', 'COL', 'Jhon Lucumí', 'DF', 3, '1998-06-26', 'Cali, Colombia', 'Bologna'),
('b3f8bdef', 'COL', 'Deiver Machado', 'DF,MF', 22, '1993-09-02', 'Tadó, Colombia', 'Nantes'),
('6d5701f2', 'COL', 'Yerry Mina', 'DF', 13, '1994-09-23', 'Guachené, Colombia', 'Cagliari'),
('608f2092', 'COL', 'Johan Mojica', 'DF', 17, '1992-08-21', 'Cali, Colombia', 'Mallorca'),
('778ef829', 'COL', 'Daniel Muñoz', 'DF', 2, '1996-05-26', 'Amalfi, Colombia', 'Crystal Palace'),
('82b1198a', 'COL', 'David Ospina', 'GK', 1, '1988-08-31', 'Medellín, Colombia', 'Atlético Nacional'),
('2c08cab0', 'COL', 'Gustavo Puerta', 'MF', 14, '2003-07-23', 'La Victoria, Colombia', 'Racing Sant'),
('540d0b37', 'COL', 'Juan Quintero', 'FW,MF', 20, '1993-01-18', 'Barranquilla, Colombia', 'River Plate'),
('72da065d', 'COL', 'Richard Ríos', 'MF', 6, '2000-06-02', 'Vegachí, Colombia', 'Benfica'),
('715bf047', 'COL', 'James Rodríguez', 'FW', 10, '1991-07-12', 'Cúcuta, Colombia', 'Minnesota Utd'),
('da7b447d', 'COL', 'Davinson Sánchez', 'DF', 23, '1996-06-12', 'Caloto, Colombia', 'Galatasaray'),
('eeba07f8', 'COL', 'Luis Suárez', 'FW', 25, '1997-12-02', 'Santa Marta, Colombia', 'Sporting CP'),
('004e3d0f', 'COL', 'Camilo Vargas', 'GK', 12, '1989-03-09', 'Bogotá, Colombia', 'Atlas'),
('0af4dcf0', 'COD', 'Cédric Bakambu', 'FW', 17, '1991-04-11', 'Ivry-sur-Seine, France', 'Real Betis'),
('be47b750', 'COD', 'Simon Banza', 'FW,MF', 23, '1996-08-13', 'Creil, France', 'Al Jazira Club'),
('37d39918', 'COD', 'Dylan Batubinsika', 'DF', 5, '1996-02-15', 'Cergy-Pontoise, France', 'AEL Limassol'),
('0da6a13e', 'COD', 'Theo Bongonda', 'FW,MF', 10, '1995-11-20', 'Charleroi, Belgium', 'Spartak Moscow'),
('e1378bd5', 'COD', 'Rocky Bushiri', 'DF', NULL, '1999-11-30', 'Duffel, Belgium', 'Hibernian'),
('e4787d6f', 'COD', 'Brian Cipenga', 'MF', 9, '1998-03-11', 'Kinshasa, Congo DR', 'Castellón'),
('5d51b074', 'COD', 'Meschak Elia', 'FW,MF', 13, '1997-08-06', 'Kinshasa, Congo DR', 'Alanyaspor'),
('6ee69cca', 'COD', 'Matthieu Epolo', 'GK', 21, '2005-01-15', 'Brussels, Belgium', 'Standard Liège'),
('03b8f96e', 'COD', 'Timothy Fayulu', 'GK', 16, '1999-07-24', 'Genève, Switzerland', 'FC Noah'),
('5b1bf5e3', 'COD', 'Gaël Kakuta', 'FW,MF', 11, '1991-06-21', 'Lille, France', 'AEL Limassol'),
('dd211559', 'COD', 'Gédéon Kalulu', 'DF', 24, '1997-08-29', 'Lyon, France', 'Aris Limassol'),
('3f3c941a', 'COD', 'Steve Kapuadi', 'DF', 3, '1998-04-30', 'Le Mans, France', 'Widzew Łódź'),
('f99b71de', 'COD', 'Edo Kayembe', 'MF', 25, '1998-06-03', 'Kananga, Congo DR', 'Watford'),
('4657faba', 'COD', 'Joris Kayembe', 'DF,FW', 12, '1994-08-08', 'Brussels, Belgium', 'Genk'),
('57df7a11', 'COD', 'Arthur Masuaku', 'DF', 26, '1993-11-07', 'Lille, France', 'Lens'),
('0d113a00', 'COD', 'Fiston Mayele', 'FW', 19, '1994-06-24', 'Mbuji-Mayi City, Congo DR', 'Pyramids FC'),
('e76cb9cc', 'COD', 'Chancel Mbemba', 'DF', 22, '1994-08-08', 'Kinshasa, Congo DR', 'Lille'),
('46750e9c', 'COD', 'Nathanaël Mbuku', 'MF', 7, '2002-03-16', 'Villeneuve-Saint-Georges, France', 'Montpellier'),
('af0c835b', 'COD', 'Samuel Moutoussamy', 'MF', 8, '1996-08-12', 'Paris, France', 'Atromitos'),
('5c6b0637', 'COD', 'Lionel Mpasi', 'GK', 1, '1994-08-01', 'Meaux, France', 'Le Havre'),
('bb461b8a', 'COD', 'Ngal''Ayel Mukau', 'MF', 6, '2004-11-03', 'Antwerpen, Belgium', 'Lille'),
('f71ad8cb', 'COD', 'Charles Pickel', 'DF,MF', 18, '1997-05-15', 'Solothurn, Switzerland', 'Espanyol'),
('645481cc', 'COD', 'Noah Sadiki', 'MF', 14, '2004-12-17', 'Brussels, Belgium', 'Sunderland'),
('8ce9cfdd', 'COD', 'Aaron Tshibola', 'MF', 15, '1995-01-02', 'Newham, England, United Kingdom', 'Kilmarnock'),
('2baec6ce', 'COD', 'Axel Tuanzebe', 'DF', 4, '1997-11-14', 'Bunia, Congo DR', 'Burnley'),
('9e525177', 'COD', 'Aaron Wan-Bissaka', 'DF', 2, '1997-11-26', 'Croydon, England, United Kingdom', 'West Ham'),
('2500cef9', 'COD', 'Yoane Wissa', 'FW', 20, '1996-09-03', 'Épinay-sous-Sénart, France', 'Newcastle'),
('4dcec659', 'CIV', 'Simon Adingra', 'FW,MF', 10, '2002-01-01', 'Abidjan, Côte d''Ivoire', 'Monaco'),
('75f1ed80', 'CIV', 'Emmanuel Agbadou', 'DF', 20, '1997-06-17', 'Abidjan, Côte d''Ivoire', 'Beşiktaş'),
('0abb5072', 'CIV', 'Clément Akpa', 'DF', NULL, '2001-11-24', 'Meudon, France', 'Auxerre'),
('64629ba4', 'CIV', 'Ange-Yoan Bonny', 'FW', 9, '2003-10-25', 'Aubervilliers, France', 'Inter'),
('44435c8f', 'CIV', 'Oumar Diakité', 'FW', 14, '2003-12-20', 'Bingerville, Côte d''Ivoire', 'Cercle Brugge'),
('9dc96f10', 'CIV', 'Amad Diallo', 'MF,FW', 15, '2002-07-11', 'Abidjan, Côte d''Ivoire', 'Manchester Utd'),
('394be156', 'CIV', 'Ousmane Diomande', 'DF', 2, '2003-12-04', 'Abidjan, Côte d''Ivoire', 'Sporting CP'),
('919f5f54', 'CIV', 'Yan Diomandé', 'MF,FW', 11, '2006-11-14', 'Abidjan, Côte d''Ivoire', 'RB Leipzig'),
('b4ef3fb5', 'CIV', 'Guéla Doué', 'DF', 17, '2002-10-17', 'Angers, France', 'Strasbourg'),
('5313ed43', 'CIV', 'Seko Fofana', 'MF', 6, '1995-05-07', 'Paris, France', 'Porto'),
('9d420dad', 'CIV', 'Yahia Fofana', 'GK', 1, '2000-08-21', 'Paris, France', 'Rizespor'),
('b73f17f8', 'CIV', 'Evann Guessand', 'FW,MF', 22, '2001-07-01', 'Ajaccio, France', 'Crystal Palace'),
('5d8c77cf', 'CIV', 'Parfait Guiagon', 'MF', 25, '2001-02-22', 'Côte d''Ivoire', 'Charleroi'),
('62709ee4', 'CIV', 'Christ Inao Oulaï', 'MF', 26, '2006-04-06', 'Yopougon, Côte d''Ivoire', 'Trabzonspor'),
('05e19d6a', 'CIV', 'Franck Kessié', 'MF', 8, '1996-12-19', 'Ouragahio, Côte d''Ivoire', 'Al-Ahli'),
('6b2c894b', 'CIV', 'Ghislain Konan', 'DF', 3, '1995-12-27', 'Abidjan, Côte d''Ivoire', 'Gil Vicente FC'),
('24f1fe8c', 'CIV', 'Mohamed Koné', 'GK', 16, '2002-03-07', 'Adjame, Côte d''Ivoire', 'Charleroi'),
('1f3afdcb', 'CIV', 'Odilon Kossounou', 'DF', 7, '2001-01-04', 'Abidjan, Côte d''Ivoire', 'Atalanta'),
('4e7db402', 'CIV', 'Alban Lafont', 'GK', 23, '1999-01-23', 'Ouagadougou, Burkina Faso', 'Panathinaikos'),
('441197b8', 'CIV', 'Obite N''Dicka', 'DF', 21, '1999-08-20', 'Paris, France', 'Roma'),
('914bb955', 'CIV', 'Christopher Opéri', 'DF', 13, '1997-04-29', 'Abidjan, Côte d''Ivoire', 'Başakşehir'),
('57e3f0c7', 'CIV', 'Nicolas Pépé', 'FW', 19, '1995-05-29', 'Mantes-la-Jolie, France', 'Villarreal'),
('bced0375', 'CIV', 'Ibrahim Sangaré', 'MF', 18, '1997-12-02', 'Koumassi, Côte d''Ivoire', 'Nottingham'),
('10efd0e1', 'CIV', 'Jean Seri', 'MF', 4, '1991-07-19', 'Grand Béréby, Côte d''Ivoire', 'NK Maribor'),
('8b609c34', 'CIV', 'Wilfried Singo', 'DF', 5, '2000-12-25', 'Ouragahio, Côte d''Ivoire', 'Galatasaray'),
('93945a50', 'CIV', 'Bazoumana Touré', 'MF', 24, '2006-03-02', 'Bouaké, Côte d''Ivoire', 'Hoffenheim'),
('0d7b6576', 'CIV', 'Elye Wahi', 'FW', 12, '2003-01-02', 'Courcouronnes, France', 'Nice'),
('d1eda5f0', 'CRO', 'Martin Baturina', 'MF,FW', 16, '2003-02-16', 'Zürich, Switzerland', 'Como'),
('8f3565b3', 'CRO', 'Ante Budimir', 'FW', 11, '1991-07-22', 'Zenica, Bosnia and Herzegovina', 'Osasuna'),
('94f8d10c', 'CRO', 'Duje Ćaleta-Car', 'DF', 5, '1996-09-17', 'Grad Šibenik, Croatia', 'Real Sociedad'),
('0fee6bda', 'CRO', 'Martin Erlić', 'DF', 25, '1998-01-24', 'Zadar, Croatia', 'Midtjylland'),
('e030ce13', 'CRO', 'Toni Fruk', 'FW,MF', 19, '2001-03-09', 'Grad Našice, Croatia', 'Rijeka'),
('5ad50391', 'CRO', 'Joško Gvardiol', 'DF', 4, '2002-01-23', 'Zagreb, Croatia', 'Manchester City'),
('a8ee54ad', 'CRO', 'Kristijan Jakić', 'DF,MF', 18, '1997-05-14', 'Grad Split, Croatia', 'Augsburg'),
('b298716e', 'CRO', 'Dominik Kotarski', 'GK', 23, '2000-02-10', 'Zabok, Croatia', 'FC Copenhagen'),
('79c0821a', 'CRO', 'Mateo Kovačić', 'MF', 8, '1994-05-06', 'Linz, Austria', 'Manchester City'),
('603cb947', 'CRO', 'Andrej Kramarić', 'FW,MF', 9, '1991-06-19', 'Zagreb, Croatia', 'Hoffenheim'),
('58f077c0', 'CRO', 'Dominik Livaković', 'GK', 1, '1995-01-09', 'Zadar, Croatia', 'Dinamo Zagreb'),
('948e1292', 'CRO', 'Igor Matanović', 'FW', 20, '2003-03-31', 'Hamburg, Germany', 'Freiburg'),
('6025fab1', 'CRO', 'Luka Modrić', 'MF', 10, '1985-09-09', 'Zadar, Croatia', 'Milan'),
('ff579c7e', 'CRO', 'Nikola Moro', 'MF', 7, '1998-03-12', 'Grad Split, Croatia', 'Bologna'),
('4567a0b4', 'CRO', 'Petar Musa', 'FW', 26, '1998-03-04', 'Zagreb, Croatia', 'FC Dallas'),
('457cb02f', 'CRO', 'Ivor Pandur', 'GK', 12, '2000-03-25', 'Sušak, Croatia', 'Hull City'),
('1866b0f1', 'CRO', 'Marco Pašalić', 'MF', 24, '2000-09-14', 'Karlsruhe, Germany', 'Orlando City'),
('e599253a', 'CRO', 'Mario Pašalić', 'MF', 15, '1995-02-09', 'Mainz, Germany', 'Atalanta'),
('6fe90922', 'CRO', 'Ivan Perišić', 'MF', 14, '1989-02-02', 'Grad Split, Croatia', 'PSV'),
('2a6cd437', 'CRO', 'Marin Pongračić', 'DF', 3, '1997-09-11', 'Landshut, Germany', 'Fiorentina'),
('7ed08d5c', 'CRO', 'Josip Stanišić', 'MF,DF', 2, '2000-04-02', 'München, Germany', 'Bayern Munich'),
('1e1378e1', 'CRO', 'Luka Sučić', 'FW,MF', 21, '2002-09-08', 'Linz, Austria', 'Real Sociedad'),
('23fb46ea', 'CRO', 'Petar Sučić', 'FW', 17, '2003-10-25', 'Livno, Bosnia and Herzegovina', 'Inter'),
('33a6a650', 'CRO', 'Josip Šutalo', 'DF', 6, '2000-02-28', 'Čapljina, Bosnia and Herzegovina', 'Ajax'),
('aa8e289e', 'CRO', 'Nikola Vlašić', 'FW,MF', 13, '1997-10-04', 'Grad Split, Croatia', 'Torino'),
('fd6bdbce', 'CRO', 'Luka Vušković', 'DF', 22, '2007-02-24', 'Croatia, Croatia', 'Hamburger SV'),
('6011e63a', 'CUW', 'Jeremy Antonisse', 'FW,MF', 11, '2002-03-29', 'Rosmalen, Netherlands', 'AE Kifisia'),
('aaf1bf05', 'CUW', 'Juninho Bacuna', 'MF', 7, '1997-08-07', 'Groningen, Netherlands', 'Volendam'),
('9dc69d38', 'CUW', 'Leandro Bacuna', 'MF', 10, '1991-08-21', 'Groningen, Netherlands', '76 Iğdır Belediyespor'),
('da59a197', 'CUW', 'Riechedly Bazoer', 'DF', 23, '1996-10-12', 'Gemeente Utrecht, Netherlands', 'Konyaspor'),
('502cae35', 'CUW', 'Tyrick Bodak', 'GK', 25, '2002-05-15', 'Gemeente Almere, Netherlands', 'Telstar'),
('2b5527c4', 'CUW', 'Joshua Brenet', 'DF', 20, '1994-03-20', 'Gemeente Kerkrade, Netherlands', 'Kayserispor'),
('2696b6a9', 'CUW', 'Tahith Chong', 'MF', 21, '1999-12-04', 'Willemstad, Curaçao', 'Sheffield United'),
('c9d96dc1', 'CUW', 'Livano Comenencia', 'MF', 8, '2004-02-03', 'Breda, Netherlands', 'Zürich'),
('b5285a98', 'CUW', 'Trevor Doornbusch', 'GK', 26, '1999-07-06', 'Haarlem, Netherlands', 'VVV-Venlo'),
('130368de', 'CUW', 'Roshon van Eijma', 'DF', 4, '1998-06-09', 'Gemeente Tilburg, Netherlands', 'RKC Waalwijk'),
('20f6dec7', 'CUW', 'Kevin Felida', 'MF', 22, '1999-11-11', 'Gemeente Spijkenisse, Netherlands', 'Den Bosch'),
('5ad49fbb', 'CUW', 'Sherel Floranus', 'DF', 5, '1998-08-23', 'Rotterdam, Netherlands', 'Zwolle'),
('21932982', 'CUW', 'Deveron Fonville', 'DF', 24, '2003-05-16', 'Gemeente Nieuwegein, Netherlands', 'NEC Nijmegen'),
('bf7a9d1a', 'CUW', 'Juriën Gaari', 'DF', 3, '1993-12-23', 'Gemeente Kerkrade, Netherlands', 'Abha'),
('52d1a4c6', 'CUW', 'Kenji Gorré', 'FW,MF', 14, '1994-09-29', 'Gemeente Spijkenisse, Netherlands', 'Maccabi Haifa'),
('70bad10b', 'CUW', 'Sontje Hansen', 'FW', 12, '2002-05-18', 'Gemeente Hoorn, Netherlands', 'Middlesbrough'),
('0c142e14', 'CUW', 'Gervane Kastaneer', 'FW,MF', 19, '1996-06-09', 'Rotterdam, Netherlands', 'Terengganu City FC'),
('42c94967', 'CUW', 'Brandley Kuwas', 'FW,MF', 17, '1992-09-19', 'Gemeente Hoorn, Netherlands', 'Volendam'),
('6cc47ae1', 'CUW', 'Jürgen Locadia', 'FW', 9, '1993-11-07', 'Gemeente Emmen, Netherlands', 'Miami FC'),
('be915a68', 'CUW', 'Jearl Margaritha', 'FW,MF', 16, '2000-04-10', 'Groningen, Netherlands', 'Beveren'),
('364f602a', 'CUW', 'Ar''jany Martha', 'DF,FW', 15, '2003-09-04', 'Rotterdam, Netherlands', 'Rotherham'),
('c3709bd2', 'CUW', 'Tyrese Noslin', 'MF', 13, '2002-09-11', 'Amsterdam, Netherlands', 'Telstar'),
('2ffa6348', 'CUW', 'Armando Obispo', 'DF', 18, '1999-03-05', 'Boxtel, Netherlands', 'PSV'),
('a646b710', 'CUW', 'Godfried Roemeratoe', 'MF', 6, '1999-08-19', 'Oost-Souburg, Netherlands', 'RKC Waalwijk'),
('6b33d86b', 'CUW', 'Eloy Room', 'GK', 1, '1989-02-06', 'Gemeente Nijmegen, Netherlands', 'Miami FC'),
('4b1d5a70', 'CUW', 'Shurandy Sambo', 'DF', 2, '2001-08-19', 'Geldrop, Netherlands', 'Sparta R.'),
('bb4a41bc', 'CZE', 'Lukáš Červ', 'MF', 12, '2001-04-10', 'Prague, Czech Republic', 'Viktoria Plzeň'),
('ded82b9a', 'CZE', 'Štěpán Chaloupek', 'DF', 6, '2003-03-08', 'Meziboři, Czech Republic', 'Slavia Prague'),
('163bbd4a', 'CZE', 'Tomáš Chorý', 'FW', 19, '1995-01-26', 'Olomouc, Czech Republic', 'Slavia Prague'),
('01a08323', 'CZE', 'Mojmír Chytil', 'FW', 13, '1999-04-29', 'Skalka, Czech Republic', 'Slavia Prague'),
('fdf3cb77', 'CZE', 'Vladimír Coufal', 'MF,DF', 5, '1992-08-22', 'Liberec, Czech Republic', 'Hoffenheim'),
('3eb0f2df', 'CZE', 'Vladimír Darida', 'MF', 8, '1990-08-08', 'Sokolov, Czech Republic', 'Hradec Králové'),
('e95b4604', 'CZE', 'David Douděra', 'MF', 21, '1998-05-31', 'Brandýs nad Labem-Stará Boleslav, Czech Republic', 'Slavia Prague'),
('5521f419', 'CZE', 'Adam Hložek', 'FW', 9, '2002-07-25', 'Ivančice, Czech Republic', 'Hoffenheim'),
('e03c2d97', 'CZE', 'Tomáš Holeš', 'DF', 3, '1993-03-31', 'Polička, Czech Republic', 'Slavia Prague'),
('cc8312b4', 'CZE', 'Lukáš Horníček', 'GK', 23, '2002-07-13', 'Vysoké Mýto, Czech Republic', 'Braga'),
('95d5aea2', 'CZE', 'Robin Hranáč', 'DF', 4, '2000-01-29', 'Pilsen, Czech Republic', 'Hoffenheim'),
('d7a03bf3', 'CZE', 'David Jurásek', 'DF,MF', 14, '2000-08-07', 'Uherské Hradiště, Czech Republic', 'Slavia Prague'),
('bc67a0e1', 'CZE', 'Matej Kovar', 'GK', 1, '2000-05-17', 'Uherské Hradiště, Czech Republic', 'PSV'),
('5b5c2228', 'CZE', 'Ladislav Krejčí', 'DF', 7, '1999-04-20', 'Praha, Czech Republic', 'Wolves'),
('4bce9c16', 'CZE', 'Jan Kuchta', 'FW', 11, '1997-01-08', 'Liberec, Czech Republic', 'Sparta Prague'),
('8f21b7bd', 'CZE', 'Lukáš Provod', 'FW', 17, '1996-10-23', 'Pilsen, Czech Republic', 'Slavia Prague'),
('7c9fa389', 'CZE', 'Michal Sadílek', 'MF', 18, '1999-05-31', 'Uherské Hradiště, Czech Republic', 'Slavia Prague'),
('5d4f7d61', 'CZE', 'Patrik Schick', 'FW', 10, '1996-01-24', 'Prague, Czech Republic', 'Leverkusen'),
('c75bba87', 'CZE', 'Hugo Sochůrek', 'MF', 25, '2008-06-07', 'Tábor, Czech Republic', 'Sparta Prague'),
('765b7bfc', 'CZE', 'Alexandr Sojka', 'MF,DF', 24, '2003-04-02', 'Pilsen, Czech Republic', 'Viktoria Plzeň'),
('6613c819', 'CZE', 'Tomáš Souček', 'MF', 22, '1995-02-27', 'Havlíčkův Brod, Czech Republic', 'West Ham'),
('eca17cf2', 'CZE', 'Jindřich Staněk', 'GK', 16, '1996-04-27', 'Strakonice, Czech Republic', 'Slavia Prague'),
('e9b893af', 'CZE', 'Pavel Šulc', 'FW', 15, '2000-12-29', 'Karlovy Vary, Czech Republic', 'Lyon'),
('d5aac0e9', 'CZE', 'Denis Višinský', 'FW', 26, '2003-03-21', 'Hořín, Czech Republic', 'Viktoria Plzeň'),
('bc647827', 'CZE', 'Jaroslav Zelený', 'MF', 20, '1992-08-20', 'Hradec Králové, Czech Republic', 'Sparta Prague'),
('acf7e795', 'CZE', 'David Zima', 'DF', 2, '2000-11-08', 'Olomouc, Czech Republic', 'Slavia Prague'),
('6e98c19f', 'ECU', 'Jordy Alcivar', 'MF', 5, '1999-08-05', 'Manta, Ecuador', 'Independiente'),
('a9b9d89c', 'ECU', 'Nilson Angulo', 'MF', 20, '2003-06-19', 'Quininde, Ecuador', 'Sunderland'),
('70676088', 'ECU', 'Jeremy Arévalo', 'FW', 24, '2005-03-19', 'Maliaño, Spain', 'Stuttgart'),
('7fcb27d8', 'ECU', 'Jordy Caicedo', 'FW', 16, '1997-11-18', 'Machala, Ecuador', 'Huracán'),
('16264a81', 'ECU', 'Moisés Caicedo', 'MF', 23, '2001-11-02', 'Santo Domingo de los Colorados, Ecuador', 'Chelsea'),
('97975540', 'ECU', 'Denil Castillo', 'MF', 18, '2004-03-24', 'Cantón Eloy Alfaro, Ecuador', 'Midtjylland'),
('d38fdf53', 'ECU', 'Pervis Estupiñán', 'MF', 7, '1998-01-21', 'Esmeraldas, Ecuador', 'Milan'),
('c76b161b', 'ECU', 'Alan Franco', 'DF', 21, '1998-08-21', 'Alfredo Baquerizo Moreno, Ecuador', 'Atlético Mineiro'),
('89c136f6', 'ECU', 'Hernán Galíndez', 'GK', 1, '1987-03-30', 'Rosario, Argentina', 'Huracán'),
('0c7a48f8', 'ECU', 'Piero Hincapié', 'DF', 3, '2002-01-09', 'Esmeraldas, Ecuador', 'Arsenal'),
('1fe8ecf7', 'ECU', 'Yaimar Medina', 'DF,MF', 26, '2004-11-05', 'Cantón Eloy Alfaro, Ecuador', 'Genk'),
('9cfd5b00', 'ECU', 'Alan Minda', 'MF', 14, '2003-05-14', 'Esmeraldas, Ecuador', 'Atlético Mineiro'),
('2990a15c', 'ECU', 'Joel Ordóñez', 'DF', 4, '2004-04-21', 'Guayaquil, Ecuador', 'Club Brugge'),
('ecbe2839', 'ECU', 'Willian Pacho', 'DF', 6, '2001-10-16', 'Quininde, Ecuador', 'PSG'),
('f3bb9f59', 'ECU', 'Kendry Páez', 'MF', 10, '2007-05-04', 'Guayaquil, Ecuador', 'River Plate'),
('54bcdeb0', 'ECU', 'Gonzalo Plata', 'FW', 19, '2000-11-01', 'Guayaquil, Ecuador', 'Flamengo'),
('7d704e92', 'ECU', 'Jackson Porozo', 'DF', 25, '2000-08-04', 'San Lorenzo, Ecuador', 'Tijuana'),
('eadc8e4f', 'ECU', 'Ángelo Preciado', 'DF,MF', 17, '1998-02-18', 'Shushufindi, Ecuador', 'Atlético Mineiro'),
('edf42402', 'ECU', 'Moisés Ramírez', 'GK', 12, '2000-09-09', 'Guayaquil, Ecuador', 'AE Kifisia'),
('189fb038', 'ECU', 'Kevin Rodríguez', 'FW', 11, '2000-03-04', 'Ibarra, Ecuador', 'Union SG'),
('c0a8860f', 'ECU', 'Félix Torres Caicedo', 'DF', 2, '1997-01-11', 'San Lorenzo, Ecuador', 'Internacional'),
('674dee62', 'ECU', 'Anthony Valencia', 'MF', 8, '2003-07-21', 'Guayaquil, Ecuador', 'Antwerp'),
('fb485406', 'ECU', 'Enner Valencia', 'FW', 13, '1989-11-04', 'San Lorenzo, Ecuador', 'Pachuca'),
('7340dadf', 'ECU', 'Gonzalo Valle', 'GK', 22, '1996-02-28', 'Riobamba, Ecuador', 'LDU Quito'),
('9c146b36', 'ECU', 'Pedro Vite', 'MF', 15, '2002-03-09', 'Babahoyo, Ecuador', 'UNAM'),
('8dfdc6c3', 'ECU', 'John Yeboah', 'MF', 9, '2000-06-23', 'Hamburg, Germany', 'Venezia'),
('057d8f12', 'EGY', 'Hamza Abdelkarim', 'FW', 9, '2008-01-01', 'Cairo, Egypt', 'Barcelona B'),
('accbfc94', 'EGY', 'Hossam Abdelmaguid', 'DF', 4, '2001-04-30', 'Egypt', 'Zamalek SC'),
('bff15d74', 'EGY', 'Mohamed Abdelmonem', 'DF', 6, '1999-02-01', 'Zagazig, Egypt', 'Nice'),
('4869216e', 'EGY', 'Ibrahim Adel', 'MF', 20, '2001-04-23', 'Port Said, Egypt', 'Nordsjælland'),
('83ba02b3', 'EGY', 'Mohamed Alaa', 'GK', 26, '1999-01-01', 'Egypt', 'El Gouna FC'),
('bf73f76b', 'EGY', 'Tarek Alaa', 'DF', 24, '2002-01-05', 'Egypt', 'ZED'),
('31b7d437', 'EGY', 'Emam Ashour', 'MF', 8, '1998-02-20', 'As Sinbillāwayn, Egypt', 'Al Ahly'),
('1ea3d7ec', 'EGY', 'Marwan Attia', 'MF', 19, '1998-08-12', 'Kafr ad Dawwār, Egypt', 'Al Ahly'),
('464e8c21', 'EGY', 'Nabil Dunga', 'MF', 18, '1996-04-06', 'Al Maḩallah al Kubrá, Egypt', 'Al-Najma'),
('c8ef4955', 'EGY', 'Hamdy Fathy', 'DF', 14, '1994-09-29', 'Egypt', 'Al-Wakrah'),
('de13286d', 'EGY', 'Ahmed Fatouh', 'DF', 13, '1998-03-22', 'Cairo, Egypt', 'Zamalek SC'),
('d2debf23', 'EGY', 'Karim Hafez', 'DF', 15, '1996-03-12', 'Egypt', 'Pyramids FC'),
('9bcf1513', 'EGY', 'Mohamed Hany', 'DF', 3, '1996-01-25', 'Cairo, Egypt', 'Al Ahly'),
('e0979e74', 'EGY', 'Haissem Hassan', 'MF', 12, '2002-02-08', 'Paris, France', 'Oviedo'),
('0b89ad1b', 'EGY', 'Yasser Ibrahim', 'DF', 2, '1993-02-10', 'Al Manşūrah, Egypt', 'Al Ahly'),
('bad461f1', 'EGY', 'El Mahdy Soliman', 'GK', 16, '1986-11-30', 'Cairo, Egypt', 'Zamalek SC'),
('0e0102eb', 'EGY', 'Omar Marmoush', 'FW', 22, '1999-02-07', 'Cairo, Egypt', 'Manchester City'),
('d12fad9f', 'EGY', 'Mohanad Mostafa', NULL, 17, '1996-05-29', 'Cairo, Egypt', 'Pyramids FC'),
('e32afa36', 'EGY', 'Ramy Rabia', 'DF,MF', 5, '1993-05-20', 'Cairo, Egypt', 'Al Ain'),
('632c42f5', 'EGY', 'Mahmoud Saber', 'MF', 21, '2001-07-30', 'Egypt', 'ZED'),
('e342ad68', 'EGY', 'Mohamed Salah', 'MF,FW', 10, '1992-06-15', 'Basyūn, Egypt', 'Liverpool'),
('b3b16d95', 'EGY', 'Mohamed El-Shenawy', 'GK', 1, '1988-12-18', 'Cairo, Egypt', 'Al Ahly'),
('0cb1d2ba', 'EGY', 'Mostafa Shobeir', 'GK', 23, '2000-05-15', 'Giza, Egypt', 'Al Ahly'),
('3ae14ed1', 'EGY', 'Trézéguet', 'FW,MF', 7, '1994-10-01', 'Kafr El Sheikh, Egypt', 'Al Ahly'),
('68ff8437', 'EGY', 'Mostafa Ziko', 'MF', 11, '1997-04-27', 'Alexandria, Egypt', 'Pyramids FC'),
('c6415ba9', 'EGY', 'Zizo', 'MF', 25, '1996-01-10', 'Cairo, Egypt', 'Al Ahly'),
('de31038e', 'ENG', 'Elliot Anderson', 'MF', 8, '2002-11-06', 'Whitley Bay, England, United Kingdom', 'Nottingham'),
('57d88cf9', 'ENG', 'Jude Bellingham', 'MF', 10, '2003-06-29', 'Stourbridge, England, United Kingdom', 'Real Madrid'),
('b2d31e83', 'ENG', 'Dan Burn', 'DF', 15, '1992-05-09', 'Blyth, England, United Kingdom', 'Newcastle'),
('5515376c', 'ENG', 'Trevoh Chalobah', 'DF,MF', 12, '1999-07-05', 'Freetown, Sierra Leone', 'Chelsea'),
('ae4fc6a4', 'ENG', 'Eberechi Eze', 'FW,MF', 21, '1998-06-29', 'Greenwich, England, United Kingdom', 'Arsenal'),
('2bd83368', 'ENG', 'Anthony Gordon', 'MF', 18, '2001-02-24', 'Liverpool, England, United Kingdom', 'Barcelona'),
('d0706b27', 'ENG', 'Marc Guéhi', 'DF', 6, '2000-07-13', 'Abidjan, Côte d''Ivoire', 'Manchester City'),
('e5a76dfe', 'ENG', 'Dean Henderson', 'GK', 13, '1997-03-12', 'Whitehaven, England, United Kingdom', 'Crystal Palace'),
('935e6b8f', 'ENG', 'Jordan Henderson', 'MF', 14, '1990-06-17', 'Sunderland, England, United Kingdom', 'Brentford'),
('1265a93a', 'ENG', 'Reece James', 'DF', 24, '1999-12-08', 'London, England, United Kingdom', 'Chelsea'),
('21a66f6a', 'ENG', 'Harry Kane', 'FW', 9, '1993-07-28', 'Walthamstow, England, United Kingdom', 'Bayern Munich'),
('0313a347', 'ENG', 'Ezri Konsa', 'DF', 2, '1997-10-23', 'London, England, United Kingdom', 'Aston Villa'),
('afed6722', 'ENG', 'Tino Livramento', 'DF,MF', NULL, '2002-11-12', 'Croydon, England, United Kingdom', 'Newcastle'),
('bf34eebd', 'ENG', 'Noni Madueke', 'MF', 20, '2002-03-10', 'Barnet, England, United Kingdom', 'Arsenal'),
('c6220452', 'ENG', 'Kobbie Mainoo', 'MF', 16, '2005-04-19', 'Stockport, England, United Kingdom', 'Manchester Utd'),
('91ca4a16', 'ENG', 'Nico O''Reilly', 'DF', 3, '2005-03-21', 'Manchester, England, United Kingdom', 'Manchester City'),
('4806ec67', 'ENG', 'Jordan Pickford', 'GK', 1, '1994-03-07', 'Washington, England, United Kingdom', 'Everton'),
('4125cb98', 'ENG', 'Jarell Quansah', 'DF', 26, '2003-01-29', 'Warrington, England, United Kingdom', 'Leverkusen'),
('a1d5bd30', 'ENG', 'Marcus Rashford', 'FW,MF', 11, '1997-10-31', 'Wythenshawe, England, United Kingdom', 'Barcelona'),
('1c7012b8', 'ENG', 'Declan Rice', 'MF', 4, '1999-01-14', 'London, England, United Kingdom', 'Arsenal'),
('2e5915f1', 'ENG', 'Morgan Rogers', 'FW,MF', 17, '2002-07-26', 'Halesowen, England, United Kingdom', 'Aston Villa'),
('bc7dc64d', 'ENG', 'Bukayo Saka', 'FW,MF', 7, '2001-09-05', 'Ealing, England, United Kingdom', 'Arsenal'),
('9bc9a519', 'ENG', 'Djed Spence', 'DF', 25, '2000-08-09', 'London, England, United Kingdom', 'Tottenham'),
('5eecec3d', 'ENG', 'John Stones', 'DF', 5, '1994-05-28', 'Barnsley, England, United Kingdom', 'Manchester City'),
('e09f279b', 'ENG', 'Ivan Toney', 'FW', 22, '1996-03-16', 'Northampton, England, United Kingdom', 'Al-Ahli'),
('259fea27', 'ENG', 'James Trafford', 'GK', 23, '2002-10-10', 'Cockermouth, England, United Kingdom', 'Manchester City'),
('aed3a70f', 'ENG', 'Ollie Watkins', 'FW,MF', 19, '1995-12-30', 'Borough of Torbay, England, United Kingdom', 'Aston Villa'),
('b625b241', 'FRA', 'Maghnes Akliouche', 'MF', 25, '2002-02-25', 'Tremblay-en-France, France', 'Monaco'),
('a0d55a09', 'FRA', 'Bradley Barcola', 'MF', 12, '2002-09-02', 'Villeurbanne, France', 'PSG'),
('b34c63a5', 'FRA', 'Rayan Cherki', 'FW,MF', 24, '2003-08-17', 'Pusignan, France', 'Manchester City'),
('b19db005', 'FRA', 'Ousmane Dembélé', 'MF', 7, '1997-05-15', 'Vernon, France', 'PSG'),
('1b84dbe1', 'FRA', 'Lucas Digne', 'DF', 3, '1993-07-20', 'Meaux, France', 'Aston Villa'),
('9e7483ff', 'FRA', 'Désiré Doué', 'MF', 20, '2005-06-03', 'Angers, France', 'PSG'),
('d56b9520', 'FRA', 'Malo Gusto', 'DF,MF', 2, '2003-05-19', 'Lyon, France', 'Chelsea'),
('c3ee18ef', 'FRA', 'Lucas Hernández', 'DF', 21, '1996-02-14', 'Marseille, France', 'PSG'),
('d4c9725f', 'FRA', 'Theo Hernández', 'DF', 19, '1997-10-06', 'Marseille, France', 'Al-Hilal'),
('b9fbae28', 'FRA', 'N''Golo Kanté', 'MF', 13, '1991-03-29', 'Paris, France', 'Fenerbahçe'),
('5ed9b537', 'FRA', 'Ibrahima Konaté', 'DF', 15, '1999-05-25', 'Paris, France', 'Liverpool'),
('86574238', 'FRA', 'Manu Koné', 'MF', 6, '2001-05-17', 'Colombes, France', 'Roma'),
('4d1666ff', 'FRA', 'Jules Koundé', 'DF', 5, '1998-11-12', 'Paris, France', 'Barcelona'),
('277c49ed', 'FRA', 'Maxence Lacroix', 'DF', 26, '2000-04-06', 'Villeneuve-Saint-Georges, France', 'Crystal Palace'),
('fcb38f57', 'FRA', 'Mike Maignan', 'GK', 16, '1995-07-03', 'Cayenne, French Guiana', 'Milan'),
('50e6dc35', 'FRA', 'Jean-Philippe Mateta', 'FW', 22, '1997-06-28', 'Châteauroux, France', 'Crystal Palace'),
('42fd9c7f', 'FRA', 'Kylian Mbappé', 'FW', 10, '1998-12-20', 'Paris 19 Buttes-Chaumont, France', 'Real Madrid'),
('c4486bac', 'FRA', 'Michael Olise', 'MF', 11, '2001-12-12', 'England, United Kingdom', 'Bayern Munich'),
('8794e251', 'FRA', 'Adrien Rabiot', 'MF', 14, '1995-04-03', 'Saint-Maurice, France', 'Milan'),
('56a66faa', 'FRA', 'Robin Risser', 'GK', 23, '2004-12-02', 'Colmar, France', 'Lens'),
('972aeb2a', 'FRA', 'William Saliba', 'DF', 17, '2001-03-24', 'Bondy, France', 'Arsenal'),
('60d90c55', 'FRA', 'Brice Samba', 'GK', 1, '1994-04-25', 'Linzolo, Congo', 'Rennes'),
('4f255115', 'FRA', 'Aurélien Tchouaméni', 'MF', 8, '2000-01-27', 'Rouen, France', 'Real Madrid'),
('6f8cd6d0', 'FRA', 'Marcus Thuram', 'FW,MF', 9, '1997-08-06', 'Provincia di Parma, Italy', 'Inter'),
('d248cd8f', 'FRA', 'Dayot Upamecano', 'DF', 4, '1998-10-27', 'Évreux, France', 'Bayern Munich'),
('6b9960cf', 'FRA', 'Warren Zaïre-Emery', 'DF,MF', 18, '2006-03-08', 'Montreuil, France', 'PSG'),
('555d5edd', 'GER', 'Nadiem Amiri', 'MF', 20, '1996-10-27', 'Kreisfreie Stadt Ludwigshafen am Rhein, Germany', 'Mainz 05'),
('5e66fa06', 'GER', 'Waldemar Anton', 'DF,MF', 3, '1996-07-20', 'Olmaliq, Uzbekistan', 'Dortmund'),
('47064058', 'GER', 'Oliver Baumann', 'GK', 12, '1990-06-02', 'Breisach am Rhein, Germany', 'Hoffenheim'),
('5db45ee5', 'GER', 'Maximilian Beier', 'FW,MF', 14, '2002-10-17', 'Kreisfreie Stadt Brandenburg an der Havel, Germany', 'Dortmund'),
('abc79c47', 'GER', 'Nathaniel Brown', 'DF', 18, '2003-06-16', 'Amberg, Germany', 'Frankfurt'),
('cc86b9a3', 'GER', 'Leon Goretzka', 'MF', 8, '1995-02-06', 'Bochum, Germany', 'Bayern Munich'),
('8aec0537', 'GER', 'Pascal Groß', 'DF,MF', 13, '1991-06-15', 'Mannheim, Germany', 'Brighton'),
('fed7cb61', 'GER', 'Kai Havertz', 'FW', 7, '1999-06-11', 'Aachen, Germany', 'Arsenal'),
('a0deb1e9', 'GER', 'Lennart Karl', 'MF', NULL, '2008-02-22', 'Frammersbach, Markt, Germany', 'Bayern Munich'),
('49296448', 'GER', 'Joshua Kimmich', 'DF', 6, '1995-02-08', 'Rottweil, Germany', 'Bayern Munich'),
('13fe7b69', 'GER', 'Jamie Leweling', 'FW,MF', 9, '2001-02-26', 'Nürnberg, Germany', 'Stuttgart'),
('2c0558b8', 'GER', 'Jamal Musiala', 'MF', 10, '2003-02-26', 'Stuttgart, Germany', 'Bayern Munich'),
('8778c910', 'GER', 'Manuel Neuer', 'GK', 1, '1986-03-27', 'Gelsenkirchen, Germany', 'Bayern Munich'),
('091c86e2', 'GER', 'Felix Nmecha', 'MF', 23, '2000-10-10', 'England, United Kingdom', 'Dortmund'),
('afb0c500', 'GER', 'Alexander Nübel', 'GK', 21, '1996-09-30', 'Paderborn, Germany', 'Stuttgart'),
('75e6fc2f', 'GER', 'Assan Ouédraogo', 'MF', 25, '2006-05-09', 'Mülheim an der Ruhr, Germany', 'RB Leipzig'),
('2658c82f', 'GER', 'Aleksandar Pavlovic', 'MF', 5, '2004-05-03', 'München, Landeshauptstadt, Germany', 'Bayern Munich'),
('7d450ed3', 'GER', 'David Raum', 'DF', 22, '1998-04-22', 'Nürnberg, Germany', 'RB Leipzig'),
('18b896d6', 'GER', 'Antonio Rüdiger', 'DF', 2, '1993-03-03', 'Berlin, Germany', 'Real Madrid'),
('2b114be3', 'GER', 'Leroy Sané', 'MF', 19, '1996-01-11', 'Essen, Germany', 'Galatasaray'),
('34e12499', 'GER', 'Nico Schlotterbeck', 'DF', 15, '1999-12-01', 'Waiblingen, Germany', 'Dortmund'),
('3b1ed320', 'GER', 'Angelo Stiller', 'MF', 16, '2001-04-04', 'München, Germany', 'Stuttgart'),
('bd142efb', 'GER', 'Jonathan Tah', 'DF', 4, '1996-02-11', 'Hamburg, Germany', 'Bayern Munich'),
('ff5ea0bf', 'GER', 'Malick Thiaw', 'DF,MF', 24, '2001-08-08', 'Düsseldorf, Germany', 'Newcastle'),
('dd549382', 'GER', 'Deniz Undav', 'FW,MF', 26, '1996-07-19', 'Achim, Germany', 'Stuttgart'),
('e7fcf289', 'GER', 'Florian Wirtz', 'MF', 17, '2003-05-03', 'Brauweiler, Germany', 'Liverpool'),
('7ca196eb', 'GER', 'Nick Woltemade', 'FW,MF', 11, '2002-02-14', 'Bremen, Germany', 'Newcastle'),
('bdbf78cd', 'GHA', 'Jonas Adjetey', 'DF', 4, '2003-12-13', 'Accra, Ghana', 'Wolfsburg'),
('21a866b7', 'GHA', 'Joseph Anang', 'GK', 12, '2000-06-08', 'Teshi Old Town, Ghana', 'St Patrick''s'),
('4bb65492', 'GHA', 'Benjamin Asare', 'GK', 16, '1992-07-13', 'Ghana', 'Accra Hearts of Oak SC'),
('a12402c3', 'GHA', 'Lawrence Ati-Zigi', 'GK', 1, '1996-11-29', 'Accra, Ghana', 'St. Gallen'),
('da052c14', 'GHA', 'Jordan Ayew', 'FW', 9, '1991-09-11', 'Marseille, France', 'Leicester City'),
('59e9edb5', 'GHA', 'Augustine Boakye', 'FW,MF', 20, '2000-11-03', 'Bompata, Ghana', 'Saint-Étienne'),
('b636755a', 'GHA', 'Christopher Bonsu-Baah', 'MF', 13, '2004-12-14', 'Ghana', 'Al-Qadsiah'),
('bceda5ff', 'GHA', 'Abdul Fatawu Issahaku', 'FW,MF', 7, '2004-03-08', 'Tamale, Ghana', 'Leicester City'),
('36bdd145', 'GHA', 'Prince Kwabena Adu', 'FW', 25, '2003-09-23', 'Sampa, Ghana', 'Viktoria Plzeň'),
('30a09cb5', 'GHA', 'Derrick Luckassen', 'DF,MF', 23, '1995-07-03', 'Amsterdam, Netherlands', 'Pafos FC'),
('9bdd8118', 'GHA', 'Gideon Mensah', 'DF', 14, '1998-07-18', 'Accra, Ghana', 'Auxerre'),
('5487adcd', 'GHA', 'Abdul Mumin', 'DF', 6, '1998-06-06', 'Accra, Ghana', 'Rayo Vallecano'),
('234a703c', 'GHA', 'Ernest Nuamah', 'MF', 24, '2003-11-01', 'Kumasi, Ghana', 'Lyon'),
('091d6ee5', 'GHA', 'Jerome Opoku', 'DF', 18, '1998-10-14', 'England, United Kingdom', 'Başakşehir'),
('e2781082', 'GHA', 'Elisha Owusu', 'MF', 15, '1997-11-07', 'Montreuil, France', 'Auxerre'),
('529f49ab', 'GHA', 'Thomas Partey', 'MF', 5, '1993-06-13', 'Odumase Krobo, Ghana', 'Villarreal'),
('37a6fdb3', 'GHA', 'Kojo Peprah Oppong', 'DF', 21, '2004-06-04', 'Accra, Ghana', 'Nice'),
('e4086af3', 'GHA', 'Abdul Rahman Baba', 'DF,MF', 17, '1994-07-02', 'Tamale, Ghana', 'PAOK'),
('cea59f02', 'GHA', 'Alidu Seidu', 'DF', 2, '2000-06-04', 'Accra, Ghana', 'Rennes'),
('efd2ec23', 'GHA', 'Antoine Semenyo', 'MF', 11, '2000-01-07', 'London, England, United Kingdom', 'Manchester City'),
('1d383c10', 'GHA', 'Marvin Senaya', 'DF', 26, '2001-01-28', 'Saint-Maurice, France', 'Auxerre'),
('be834ad7', 'GHA', 'Kwasi Sibo', 'MF', 8, '1998-06-24', 'Wa, Ghana', 'Oviedo'),
('a62f8bf1', 'GHA', 'Kamaldeen Sulemana', 'MF', 22, '2002-02-15', 'Techiman, Ghana', 'Atlanta Utd'),
('fb152f96', 'GHA', 'Brandon Thomas-Asante', 'FW,MF', 10, '1998-12-29', 'Milton Keynes, England, United Kingdom', 'Coventry City'),
('6a99e0b1', 'GHA', 'Iñaki Williams', 'MF', 19, '1994-06-15', 'Bilbao, Spain', 'Athletic Club'),
('d40ce7b0', 'GHA', 'Caleb Yirenkyi', 'MF', 3, '2006-01-15', 'Bechem, Ghana', 'Nordsjælland'),
('a9ee5e81', 'HAI', 'Ricardo Adé', 'DF', 4, '1990-05-21', 'Saint-Marc, Haiti', 'LDU Quito'),
('5e837126', 'HAI', 'Carlens Arcus', 'MF,DF', 2, '1996-06-28', 'Port-au-Prince, Haiti', 'Angers'),
('10f0fdd3', 'HAI', 'Jean-Ricner Bellegarde', 'MF', 10, '1998-06-27', 'Colombes, France', 'Wolves'),
('481f76cf', 'HAI', 'Josué Casimir', 'MF', 21, '2001-09-24', 'Baie-Mahault, Guadeloupe', 'Auxerre'),
('f7059bb1', 'HAI', 'Louicius Deedson', 'MF', 11, '2001-02-11', 'Tabarre, Haiti', 'FC Dallas'),
('b737f944', 'HAI', 'Hannes Delcroix', 'DF', 5, '1999-02-28', 'Ti Rivyè Latibonit, Haiti', 'Lugano'),
('47e3c58c', 'HAI', 'Josué Duverger', 'GK', 23, '2000-04-27', 'Montréal, QC, Canada', 'Cosmos Koblenz'),
('0cbc8baa', 'HAI', 'Jean-Kevin Duverne', 'DF', 22, '1997-07-12', 'Paris, France', 'Gent'),
('59059f1e', 'HAI', 'Derrick Etienne', 'FW,MF', 7, '1996-11-25', 'Richmond, VA, United States', 'Toronto FC'),
('9edb83f4', 'HAI', 'Martin Expérience', 'DF,MF', 8, '1999-03-09', 'Châteaubriant, France', 'Nancy'),
('ddcc9e22', 'HAI', 'Yassin Fortuné', 'FW,MF', 19, '1999-01-30', 'Aubervilliers, France', 'Vizela'),
('2928c948', 'HAI', 'Carl Fred Sainté', 'MF', 6, '2002-08-09', 'Grangwav, Haiti', 'El Paso'),
('a671316d', 'HAI', 'Wilson Isidor', 'FW', 18, '2000-08-27', 'Rennes, France', 'Sunderland'),
('59fcbd6d', 'HAI', 'Danley Jean-Jacques', 'MF', 17, '2000-05-20', 'Tigwav, Haiti', 'Philadelphia'),
('d1828392', 'HAI', 'Lenny Joseph', 'FW', 16, '2000-10-12', 'Paris, France', 'Ferencváros'),
('bce0d6f6', 'HAI', 'Duke Lacroix', 'DF,FW', 13, '1993-10-14', 'New Egypt, NJ, United States', 'CS Switchbacks'),
('3fb38040', 'HAI', 'Garven Metusala', 'DF', 14, '1999-12-31', 'Terrebonne, QC, Canada', 'CS Switchbacks'),
('20e87a42', 'HAI', 'Duckens Nazon', 'FW,MF', 9, '1994-04-07', 'Paris, France', 'Esteghlal'),
('4385ee98', 'HAI', 'Wilguens Paugain', 'DF', 24, '2001-08-24', 'Thomazeau, Haiti', 'Zulte Waregem'),
('d0fc9f5f', 'HAI', 'Alexandre Pierre', 'GK', 12, '2001-02-25', 'Aubervilliers, France', 'Sochaux'),
('dcaa55af', 'HAI', 'Leverton Pierre', 'MF', NULL, '1998-03-09', 'Tabarre, Haiti', 'Vizela'),
('1b452afb', 'HAI', 'Woodensky Pierre', 'MF', 26, '2004-12-30', 'Cité Soleil, Haiti', 'Violette AC'),
('307877be', 'HAI', 'Frantzdy Pierrot', 'FW', 20, '1995-03-29', 'Port-au-Prince, Haiti', 'Rizespor'),
('f1666a9d', 'HAI', 'Johny Placide', 'GK', 1, '1988-01-29', 'Montfermeil, France', 'Bastia'),
('26bab383', 'HAI', 'Ruben Providence', 'MF', 15, '2001-07-07', 'Lagny-sur-Marne, France', 'Almere City'),
('ffd8e8c5', 'HAI', 'Dominique Simon', 'MF', 25, '2000-07-29', 'Paris, France', '1. FC Tatran Prešov B'),
('596ab864', 'HAI', 'Keeto Thermoncy', 'DF', 3, '2006-03-29', 'Fribourg, Switzerland', 'Young Boys'),
('488ee64c', 'IRN', 'Ali Alipour', 'FW', 11, '1995-11-11', 'Qā''em Shahr, Iran', 'Persepolis'),
('6ca0b04a', 'IRN', 'Alireza Beiranvand', 'GK', 1, '1992-09-21', 'Khorramabad, Iran', 'Tractor'),
('87c75fb3', 'IRN', 'Rouzbeh Cheshmi', 'DF,MF', 15, '1993-07-24', 'Tehran, Iran', 'Esteghlal'),
('7f8fb807', 'IRN', 'Dennis Eckert', 'FW', 24, '1997-01-09', 'Bonn, Germany', 'Standard Liège'),
('d7c9d069', 'IRN', 'Danial Eiri', 'DF', 25, '2003-10-26', 'Gonbad-e Kāvūs, Iran', 'Malavan'),
('314d95ac', 'IRN', 'Saeid Ezatolahi', 'MF', 6, '1996-10-01', 'Bandar-e Anzalī, Iran', 'Al-Ahli Dubai FC'),
('b6c90b4b', 'IRN', 'Mehdi Ghayedi', 'FW', 10, '1998-12-05', 'Bushehr, Iran', 'Al-Nasr Dubai SC'),
('f7b1d4e0', 'IRN', 'Saman Ghoddos', 'MF', 14, '1993-09-06', 'Malmö, Sweden', 'Al-Ittihad Kalba SC'),
('4a078e18', 'IRN', 'Mohammad Ghorbani', 'MF', 21, '2001-05-21', 'Arāk, Iran', 'Al-Wahda FC'),
('b060e3b8', 'IRN', 'Ehsan Hajsafi', 'DF', 3, '1990-02-25', 'Kāshān, Iran', 'Sepahan'),
('3a9b682b', 'IRN', 'Saleh Hardani', 'DF', 2, '1998-12-26', 'Shahrestān-e Bahma''ī, Iran', 'Esteghlal'),
('fb24817c', 'IRN', 'Hossein Hosseini', 'GK', 22, '1992-06-30', 'Shiraz, Iran', 'Sepahan'),
('47270f0c', 'IRN', 'Amirhossein Hosseinzadeh', 'FW', 18, '2000-10-30', 'Tehrān, Iran', 'Tractor'),
('08452314', 'IRN', 'Alireza Jahanbakhsh', 'FW,MF', 7, '1993-08-11', 'Jīrandeh, Iran', 'Dender'),
('24353c25', 'IRN', 'Hossein Kanaanizadegan', 'DF', 13, '1994-03-23', 'Bandar-e Māhshahr, Iran', 'Persepolis'),
('0aed29f1', 'IRN', 'Shoja'' Khalilzadeh', 'DF', 4, '1989-05-14', 'Bahnemīr, Iran', 'Tractor'),
('92f69be8', 'IRN', 'Shahriar Moghanlou', 'FW', 20, '1994-12-21', 'Zanjān, Iran', 'Al-Ittihad Kalba SC'),
('740a0e28', 'IRN', 'Milad Mohammadi', 'DF', 5, '1993-09-29', 'Tehran, Iran', 'Persepolis'),
('7b6b53c3', 'IRN', 'Mohammad Mohebi', 'MF', 8, '1998-12-20', 'Bushehr, Iran', 'Rostov'),
('19a221f7', 'IRN', 'Ali Nemati', 'DF', 19, '1996-02-08', 'Neyshābūr, Iran', 'Foolad'),
('7b2ed47e', 'IRN', 'Payam Niazmand', 'GK', 12, '1995-04-06', 'Tehran, Iran', 'Persepolis'),
('ac3242eb', 'IRN', 'Amirmohammad Razzaghinia', 'MF', 26, '2006-04-11', 'Yazd, Iran', 'Esteghlal'),
('c0ae3446', 'IRN', 'Ramin Rezaeian', 'MF,DF', 23, '1990-03-21', 'Sarī, Iran', 'Foolad'),
('4c2a5d34', 'IRN', 'Mehdi Taremi', 'FW', 9, '1992-07-18', 'Karaj, Iran', 'Olympiacos'),
('74567feb', 'IRN', 'Mehdi Torabi', 'MF', 16, '1994-09-10', 'Eshtehārd, Iran', 'Tractor'),
('fd069512', 'IRN', 'Aria Yousefi', 'MF', 17, '2002-04-22', 'Bandar-e Māhshahr, Iran', 'Sepahan'),
('b8a919ad', 'IRQ', 'Hussein Ali', 'DF', 3, '2002-03-01', 'Malmö, Sweden', 'Pogoń Szczecin'),
('f929049b', 'IRQ', 'Mohanad Ali', 'FW', 10, '2000-06-20', 'Baghdad, Iraq', 'Dibba Al Fujairah'),
('9f65be73', 'IRQ', 'Amir Al Ammari', 'MF', 16, '1997-07-27', 'Jönköping, Sweden', 'Cracovia'),
('10c12f22', 'IRQ', 'Youssef Amyn', 'MF', 7, '2003-08-21', 'Essen, Germany', 'AEK Larnaca'),
('3bf9e631', 'IRQ', 'Ahmed Basil', 'GK', 22, '1996-08-19', 'Baghdad, Iraq', 'Al-Shorta'),
('2f2003ba', 'IRQ', 'Ibrahim Bayesh', 'MF,FW', 8, '2000-05-01', 'Baghdad, Iraq', 'Al Dhafra SCC'),
('0102aa7e', 'IRQ', 'Frans Dhia Putros', 'DF', 26, '1993-07-14', 'Århus, Denmark', 'Persib Bandung'),
('fdf4cfe5', 'IRQ', 'Merchas Doski', 'DF', 23, '1999-12-07', 'Hannover, Landeshauptstadt, Germany', 'Viktoria Plzeň'),
('e046cff6', 'IRQ', 'Marko Farji', 'MF', 21, '2004-03-16', 'Grimstad, Norway', 'Venezia'),
('8450467d', 'IRQ', 'Ali Al Hamadi', 'FW', 9, '2002-03-01', 'England, United Kingdom', 'Ipswich Town'),
('f8416e89', 'IRQ', 'Akam Hashim', 'DF', 5, '1998-08-16', 'Arbil, Iraq', 'Al-Zawra''a SC'),
('87351c2e', 'IRQ', 'Jalal Hassan', 'GK', 12, '1991-05-18', 'Baghdad, Iraq', 'Al-Zawra''a SC'),
('8b574de7', 'IRQ', 'Ayman Hussein', 'FW', 18, '1996-03-22', 'Ḩawījah, Iraq', 'Al-Karma'),
('6fa3c28e', 'IRQ', 'Zidane Iqbal', 'MF', 14, '2003-04-27', 'England, United Kingdom', 'Utrecht'),
('c65effaa', 'IRQ', 'Zaid Ismail', 'MF', 24, '2002-01-03', 'Iraq', 'Al-Talaba'),
('1a927a6f', 'IRQ', 'Ali Jasim', 'MF', 17, '2004-01-20', 'Baghdad, Iraq', 'Al-Najma'),
('f95ac2b6', 'IRQ', 'Ahmed Maknzi', 'DF', 15, '2001-09-24', 'Baghdad, Iraq', 'Al-Karma'),
('27219ecb', 'IRQ', 'Ahmed Qasem', 'FW', 11, '2003-07-12', 'Motala, Sweden', 'Nashville SC'),
('928dc5c9', 'IRQ', 'Mustafa Saadoon', 'DF', 25, '2001-05-25', 'Iraq', 'Al-Shorta'),
('ef301f96', 'IRQ', 'Aimar Sher', 'MF', 20, '2002-12-20', 'Kirkuk, Iraq', 'Sarpsborg 08'),
('928bec06', 'IRQ', 'Rebin Sulaka', 'DF', 2, '1992-04-12', '‘Aynkāwah, Iraq', 'Port FC'),
('f3380f7e', 'IRQ', 'Zaid Tahseen', 'DF', 4, '2001-01-29', 'Najaf, Iraq', 'Pakhtakor Tashkent FK'),
('c01d9e76', 'IRQ', 'Fahad Talib', 'GK', 1, '1994-10-21', 'Baghdad, Iraq', 'Al-Talaba'),
('929da297', 'IRQ', 'Ahmed Yahya', 'DF', NULL, '1995-07-01', NULL, 'Al-Shorta'),
('18d3b8df', 'IRQ', 'Kevin Yakob', 'MF', 19, '2000-10-10', 'Göteborg, Sweden', 'AGF'),
('b798826e', 'IRQ', 'Manaf Younis', 'DF', 6, '1996-11-16', 'Tikrīt, Iraq', 'Al-Shorta'),
('943fd50a', 'IRQ', 'Ali Yousif', 'FW', 13, '1996-01-19', 'Baghdad, Iraq', 'Al-Talaba'),
('d01bbb6f', 'JPN', 'Ritsu Doan', 'MF', 10, '1998-06-16', 'Amagasaki Shi, Japan', 'Frankfurt'),
('c149016b', 'JPN', 'Wataru Endo', 'DF,MF', NULL, '1993-02-09', 'Yokohama Shi, Japan', 'Liverpool'),
('82a2ca86', 'JPN', 'Keisuke Gotō', 'FW', 9, '2005-06-03', 'Hamamatsu-shi, Japan', 'Sint-Truiden'),
('4a0023c9', 'JPN', 'Tomoki Hayakawa', 'GK', 23, '1999-03-03', 'Japan', 'Kashima Antlers'),
('97d545ae', 'JPN', 'Ko Itakura', 'DF', 4, '1997-01-27', 'Yokohama Shi, Japan', 'Ajax'),
('204dded0', 'JPN', 'Hiroki Ito', 'DF', 21, '1999-05-12', 'Hamamatsu-shi, Japan', 'Bayern Munich'),
('dbd3a428', 'JPN', 'Junya Itō', 'MF', 14, '1993-03-09', 'Yokosuka, Japan', 'Genk'),
('15b287da', 'JPN', 'Daichi Kamada', 'MF', 15, '1996-08-05', 'Japan', 'Crystal Palace'),
('16aa3654', 'JPN', 'Takefusa Kubo', 'MF', 8, '2001-06-04', 'Kawasaki-shi, Japan', 'Real Sociedad'),
('964dde35', 'JPN', 'Shuto Machino', 'FW', 6, '1999-09-30', 'Iga-shi, Japan', 'Gladbach'),
('395451fc', 'JPN', 'Daizen Maeda', 'MF', 11, '1997-10-20', 'Japan', 'Celtic'),
('4b6960d2', 'JPN', 'Yūto Nagatomo', 'DF,MF', 5, '1986-09-12', 'Saijō Shi, Japan', 'FC Tokyo'),
('d97af612', 'JPN', 'Keito Nakamura', 'MF', 13, '2000-07-28', 'Osaka-shi, Japan', 'Reims'),
('3d2e8955', 'JPN', 'Kōki Ogawa', 'FW', 19, '1997-08-08', 'Japan', 'NEC Nijmegen'),
('3980aeaf', 'JPN', 'Keisuke Ōsako', 'GK', 12, '1999-07-28', 'Izumi, Japan', 'Sanf. Hiroshima'),
('7a7a6361', 'JPN', 'Kaishū Sano', 'MF', 24, '2000-12-30', 'Tsuyama, Japan', 'Mainz 05'),
('5c6a4059', 'JPN', 'Ayumu Seko', 'DF', 20, '2000-06-07', 'Japan', 'Le Havre'),
('6bc2fef7', 'JPN', 'Kento Shiogai', 'FW', 26, '2005-03-26', 'Japan', 'Wolfsburg'),
('580bcd18', 'JPN', 'Yukinari Sugawara', 'MF', 2, '2000-06-28', 'Toyokawa, Japan', 'Werder Bremen'),
('77428b1e', 'JPN', 'Junnosuke Suzuki', 'DF', 25, '2003-07-12', 'Kakamigahara, Japan', 'FC Copenhagen'),
('c25a7a2a', 'JPN', 'Yuito Suzuki', 'FW,MF', 17, '2001-10-25', 'Hayama-machi, Japan', 'Freiburg'),
('51e1f4f5', 'JPN', 'Zion Suzuki', 'GK', 1, '2002-08-21', 'Newark, NJ, United States', 'Parma'),
('1d36d6b6', 'JPN', 'Ao Tanaka', 'MF', 7, '1998-09-10', 'Kawasaki, Japan', 'Leeds United'),
('828a9c47', 'JPN', 'Shogo Taniguchi', 'DF', 3, '1991-07-15', 'Kumamoto Shi, Japan', 'Sint-Truiden'),
('b3af9be1', 'JPN', 'Takehiro Tomiyasu', 'DF', 22, '1998-11-05', 'Fukuoka, Japan', 'Ajax'),
('c0295327', 'JPN', 'Ayase Ueda', 'FW', 18, '1998-09-10', 'Mito, Japan', 'Feyenoord'),
('d5f5955a', 'JPN', 'Tsuyoshi Watanabe', 'DF', 16, '1997-02-05', 'Saitama-shi, Japan', 'Feyenoord'),
('300aaeb6', 'JOR', 'Husam Abu Dahab', 'DF', 4, '2000-05-13', 'Amman, Jordan', 'Al-Salmiya SC'),
('72c2fa7a', 'JOR', 'Mohammad Abu Hasheesh', 'DF', 2, '1995-05-09', 'Iraq', 'Al-Karma'),
('5c4bac6c', 'JOR', 'Mohannad Abu Taha', 'DF', 20, '2003-02-02', 'Amman, Jordan', 'Al-Quwa Al-Jawiya'),
('4bff62e4', 'JOR', 'Mo Abualnadi', 'DF', 16, '2001-02-08', 'Overland Park, KS, United States', 'Selangor FA'),
('5d11fc17', 'JOR', 'Yazeed Abulaila', 'GK', 1, '1993-01-08', 'Amman, Jordan', 'Al-Hussein SC'),
('32878a09', 'JOR', 'Yazan Al-Arab', 'DF', 5, '1996-01-31', 'Russeifa, Jordan', 'FC Seoul'),
('b71e02c7', 'JOR', 'Rajaei Ayed', 'MF', 14, '1993-07-25', 'Amman, Jordan', 'Al-Hussein SC'),
('3a46ac67', 'JOR', 'Ali Azaizeh', 'MF', 24, '2004-04-13', 'Germany', 'Al-Shabab'),
('3f4b7442', 'JOR', 'Anas Badawi', 'DF', 26, '1997-09-13', 'Jordan', 'Al-Faisaly'),
('b06f02f9', 'JOR', 'Nour Bani Attiah', 'GK', 12, '1993-01-25', 'Amman, Jordan', 'Al-Faisaly'),
('e645c3fc', 'JOR', 'Mohammad Al-Dawud', 'FW,MF', 25, '1992-04-12', 'Ar Ramthā, Jordan', 'Al-Wehdat SC'),
('a152685a', 'JOR', 'Abdallah Al-Fakhouri', 'GK', 22, '2000-01-22', 'Russeifa, Jordan', 'Al-Wehdat SC'),
('30591ae5', 'JOR', 'Odeh Al-Fakhouri', 'MF', 11, '2005-11-22', 'Amman, Jordan', 'Pyramids FC'),
('85660a5d', 'JOR', 'Ihsan Haddad', 'DF', 23, '1994-02-05', 'Irbid, Jordan', 'Al-Hussein SC'),
('32d4f1e1', 'JOR', 'Amer Jamous', 'MF', 6, '2002-07-03', 'Saḩāb, Jordan', 'Al-Zawra''a SC'),
('1eedc1ea', 'JOR', 'Mahmoud Al-Mardi', 'MF', 13, '1993-10-06', 'Aqaba, Jordan', 'Al-Hussein SC'),
('aaab3072', 'JOR', 'Abdallah Nasib', 'DF', 3, '1994-02-25', 'Aqaba, Jordan', 'Al-Zawra''a SC'),
('f494bf5f', 'JOR', 'Salim Obaid', 'DF', 17, '1992-01-17', 'Amman, Jordan', 'Al-Hussein SC'),
('33c1d68d', 'JOR', 'Ali Olwan', 'MF', 9, '2000-03-26', 'Amman, Jordan', 'Al-Sailiya SC'),
('feaa0ffd', 'JOR', 'Nizar Al Rashdan', 'MF', 21, '1999-03-23', 'Jordan', 'Qatar SC'),
('3bb06c86', 'JOR', 'Noor Al Rawabdeh', 'MF', 8, '1997-02-24', 'Amman, Jordan', 'Selangor FA'),
('f3115445', 'JOR', 'Saed Al-Rosan', 'DF', 19, '1997-02-01', 'Jordan', 'Al-Hussein SC'),
('eb63719c', 'JOR', 'Ibrahim Sabra', 'FW', NULL, '2006-02-01', 'Saḩāb, Jordan', 'Lokomotiva'),
('4bdf95b2', 'JOR', 'Ibrahim Sadeh', 'MF', 15, '2000-04-27', 'Zarqa, Jordan', 'Al-Karma'),
('67e2aed8', 'JOR', 'Sharara', 'FW', 7, '1997-12-30', 'Ar Ramthā, Jordan', 'Raja Casablanca'),
('f15f8b2b', 'JOR', 'Musa Al-Taamari', 'FW', 10, '1997-06-10', 'Amman, Jordan', 'Rennes'),
('4f1daaf3', 'JOR', 'Mohammad Taha', 'MF', 18, '2005-07-13', 'Amman, Jordan', 'Al-Hussein SC'),
('2455c2d6', 'KOR', 'Song Bum-keun', 'GK', 12, '1997-10-15', 'Seongnam-si, Korea Republic', 'Jeonbuk'),
('03fee7de', 'KOR', 'Jens Castrop', 'MF', 23, '2003-07-29', 'Düsseldorf, Germany', 'Gladbach'),
('a6828876', 'KOR', 'Lee Dong-gyeong', 'FW,MF', 26, '1997-09-20', 'Korea Republic', 'Ulsan HD'),
('18c8c3c7', 'KOR', 'Lee Gi-hyuk', 'DF', 3, '2000-07-07', 'Seoul, Korea Republic', 'Gangwon FC'),
('ccfa8e5e', 'KOR', 'Cho Gue-sung', 'FW', 9, '1998-01-25', 'Ansan-si, Korea Republic', 'Midtjylland'),
('071f2dd3', 'KOR', 'Lee Han-beom', 'DF', 2, '2002-06-17', 'Korea Republic', 'Midtjylland'),
('169fd162', 'KOR', 'Hwang Hee-chan', 'FW', 11, '1996-01-26', 'Chuncheon, Korea Republic', 'Wolves'),
('92e7e919', 'KOR', 'Son Heung-min', 'FW', 7, '1992-07-08', 'Chuncheon, Korea Republic', 'LAFC'),
('d25422fb', 'KOR', 'Oh Hyeon-gyu', 'FW', 18, '2001-04-12', 'Namyangju-si, Korea Republic', 'Beşiktaş'),
('c75a3145', 'KOR', 'Jo Hyeon-woo', 'GK', 21, '1991-09-25', 'Seoul, Korea Republic', 'Ulsan HD'),
('f4cda99f', 'KOR', 'Yang Hyun-jun', 'FW,MF', 20, '2002-05-25', 'Korea Republic', 'Celtic'),
('92fa5d28', 'KOR', 'Hwang In-beom', 'MF', 6, '1996-09-20', 'Korea Republic', 'Feyenoord'),
('34b0387f', 'KOR', 'Lee Jae-sung', 'FW', 10, '1992-08-10', 'Korea Republic', 'Mainz 05'),
('3a049da1', 'KOR', 'Eom Ji-sung', 'MF', 25, '2002-05-09', 'Kimje, Korea Republic', 'Swansea City'),
('7c0479b1', 'KOR', 'Kim Jin-gyu', 'MF', 24, '1997-02-24', 'Pohang, Korea Republic', 'Jeonbuk'),
('3316967a', 'KOR', 'Park Jinseob', 'DF,MF', 16, '1995-10-23', 'Jeonju, Korea Republic', 'Zhejiang'),
('0895ffb1', 'KOR', 'Bae Jun-ho', 'FW,MF', 17, '2003-08-21', 'Korea Republic', 'Stoke City'),
('8455ad90', 'KOR', 'Lee Kang-in', 'FW', 19, '2001-02-19', 'Korea Republic', 'PSG'),
('e0f8151c', 'KOR', 'Kim Min-jae', 'DF', 4, '1996-11-15', 'Tongyeong, Korea Republic', 'Bayern Munich'),
('6bce7dd8', 'KOR', 'Kim Moon-hwan', 'MF', 15, '1995-08-01', 'Hwaseong-si, Korea Republic', 'Daejeon Hana'),
('eabaafa6', 'KOR', 'Kim Seung-gyu', 'GK', 1, '1990-09-30', 'Korea Republic', 'FC Tokyo'),
('1e1bea09', 'KOR', 'Paik Seung-ho', 'MF', 8, '1997-03-17', 'Seoul, Korea Republic', 'Birmingham City'),
('3ab57a75', 'KOR', 'Kim Tae-hyeon', 'DF', 5, '2000-09-17', 'Gimpo-si, Korea Republic', 'Kashima Antlers'),
('32257cce', 'KOR', 'Lee Tae-seok', 'MF', 13, '2002-07-28', 'Korea Republic', 'Austria Wien'),
('dcf21532', 'KOR', 'Cho Wi-je', 'DF', 14, '2001-08-25', 'Korea Republic', 'Jeonbuk'),
('8e577e1d', 'KOR', 'Seol Young-woo', 'MF', 22, '1998-12-05', 'Korea Republic', 'Red Star'),
('7a4529dc', 'KOR', 'Cho Yu-min', 'DF', NULL, '1996-11-17', 'Korea Republic', 'Al-Sharjah SCC'),
('0810e384', 'MEX', 'Carlos Acevedo', 'GK', 12, '1996-04-19', 'Torreón, Estado de Coahuila de Zaragoza, Mexico', 'Santos Laguna'),
('ff871e14', 'MEX', 'Roberto Alvarado', 'FW,MF', 25, '1998-09-07', 'Salamanca, Estado de Guanajuato, Mexico', 'Guadalajara'),
('8b3ab7ad', 'MEX', 'Edson Álvarez', 'MF,DF', 4, '1997-10-24', 'Tlalnepantla de Baz, Estado de México, Mexico', 'West Ham'),
('e50949ea', 'MEX', 'Luis Chávez', 'MF', 24, '1996-01-15', 'Cihuatlán, Estado de Jalisco, Mexico', 'Dynamo Moskva'),
('f82246a1', 'MEX', 'Mateo Chávez', 'DF', 20, '2004-05-12', 'México, Estado de México, Mexico', 'AZ Alkmaar'),
('c705cdc4', 'MEX', 'Álvaro Fidalgo', 'MF', 8, '1997-04-09', 'Pola de Siero, Spain', 'Real Betis'),
('d0846b6c', 'MEX', 'Jesús Gallardo', 'DF', 23, '1994-08-15', 'Cárdenas, Estado de Tabasco, Mexico', 'Toluca'),
('37337aea', 'MEX', 'Santiago Giménez', 'FW', 11, '2001-04-18', 'Buenos Aires, Argentina', 'Milan'),
('1278bc9a', 'MEX', 'Armando González', 'FW', 14, '2003-04-20', 'México, Estado de México, Mexico', 'Guadalajara'),
('d88f31db', 'MEX', 'Brian Gutiérrez', 'MF', 26, '2003-06-17', 'Berwyn, IL, United States', 'Guadalajara'),
('de2f44ce', 'MEX', 'César Huerta', 'FW,MF', 21, '2000-12-03', 'Guadalajara, Estado de Jalisco, Mexico', 'Anderlecht'),
('b561db50', 'MEX', 'Raúl Jiménez', 'FW', 9, '1991-05-05', 'Tepeji del Río de Ocampo, Estado de Hidalgo, Mexico', 'Fulham'),
('7b2c24ed', 'MEX', 'Erik Lira', 'MF', 6, '2000-05-08', 'México, Estado de México, Mexico', 'Cruz Azul'),
('59146354', 'MEX', 'Guillermo Martínez Ayala', 'FW', 22, '1995-03-15', 'Celaya, Estado de Guanajuato, Mexico', 'UNAM'),
('28e957d7', 'MEX', 'César Montes', 'DF', 3, '1997-02-24', 'Hermosillo, Estado de Sonora, Mexico', 'Loko Moscow'),
('69c9ffe8', 'MEX', 'Gilberto Mora', 'MF', 19, '2008-10-14', 'México, Estado de México, Mexico', 'Tijuana'),
('1e9bde92', 'MEX', 'Guillermo Ochoa', 'GK', 13, '1985-07-13', 'Guadalajara, Estado de Jalisco, Mexico', 'AEL Limassol'),
('411fabd7', 'MEX', 'Orbelín Pineda', 'FW,MF', 17, '1996-03-24', 'Coyuca de Catalán, Estado de Guerrero, Mexico', 'AEK Athens'),
('5535c728', 'MEX', 'Julián Quiñones', 'FW,MF', 16, '1997-03-24', 'Payán, Colombia', 'Al-Qadsiah'),
('15f733fb', 'MEX', 'Raúl Rangel', 'GK', 1, '2000-02-25', 'Estado de México, Mexico', 'Guadalajara'),
('0db8bbc4', 'MEX', 'Israel Reyes', 'DF', 15, '2000-05-23', 'Autlán de Navarro, Estado de Jalisco, Mexico', 'América'),
('e590bb10', 'MEX', 'Luis Romo', 'MF', 7, '1995-06-05', 'Ahome, Estado de Sinaloa, Mexico', 'Guadalajara'),
('c8d1c3a5', 'MEX', 'Jorge Sánchez', 'DF', 2, '1997-12-10', 'Torreón, Estado de Coahuila de Zaragoza, Mexico', 'PAOK'),
('9cc1fde4', 'MEX', 'Obed Vargas', 'MF', 18, '2005-08-05', 'Anchorage, AK, United States', 'Atlético Madrid'),
('5eaed77a', 'MEX', 'Johan Vásquez', 'DF', 5, '1998-10-22', 'Navojoa, Estado de Sonora, Mexico', 'Genoa'),
('f40f4c38', 'MEX', 'Alexis Vega', 'FW,MF', 10, '1997-11-25', 'Cuauhtémoc, Ciudad de México, Mexico', 'Toluca'),
('288e1e13', 'MAR', 'Nayef Aguerd', 'DF', NULL, '1996-03-30', 'Kenitra, Morocco', 'Marseille'),
('c5a07a5e', 'MAR', 'Ayoube Amaimouni', 'MF', 21, '2004-11-30', 'Vic, Spain', 'Frankfurt'),
('5a2cb25d', 'MAR', 'Sofyan Amrabat', 'MF', 4, '1996-08-21', 'Gemeente Huizen, Netherlands', 'Real Betis'),
('17e1261b', 'MAR', 'Neil El Aynaoui', 'MF', 24, '2001-07-02', 'Nancy, France', 'Roma'),
('67fe537d', 'MAR', 'Youssef Belammari', 'DF', 19, '1998-09-20', 'Casablanca, Morocco', 'Al Ahly'),
('8006228f', 'MAR', 'Ayyoub Bouaddi', 'MF', 6, '2007-10-02', 'Senlis, France', 'Lille'),
('f6798fc3', 'MAR', 'Yassine Bounou', 'GK', 1, '1991-04-05', 'Montréal, QC, Canada', 'Al-Hilal'),
('407feb71', 'MAR', 'Brahim Díaz', 'MF', 10, '1999-08-03', 'Málaga, Spain', 'Real Madrid'),
('a712ca2b', 'MAR', 'Issa Diop', 'DF', 14, '1997-01-09', 'Toulouse, France', 'Fulham'),
('bed68338', 'MAR', 'Abde Ezzalzouli', 'FW,MF', NULL, '2001-12-17', 'Beni Mellal, Morocco', 'Real Betis'),
('e42d61c7', 'MAR', 'Achraf Hakimi', 'DF', 2, '1998-11-04', 'Getafe, Spain', 'PSG'),
('e17c2cec', 'MAR', 'Redouane Halhal', 'DF', 25, '2003-03-05', 'Montpellier, France', 'Mechelen'),
('b1bfd1d4', 'MAR', 'Ayoub El Kaabi', 'FW', 20, '1993-06-26', 'Casablanca, Morocco', 'Olympiacos'),
('f7042636', 'MAR', 'Bilal El Khannouss', 'MF', 23, '2004-05-10', 'Strombeek-Bever, Belgium', 'Stuttgart'),
('b74277a0', 'MAR', 'Noussair Mazraoui', 'DF', 3, '1997-11-14', 'Leiderdorp, Netherlands', 'Manchester Utd'),
('1a03d055', 'MAR', 'Samir El Mourabet', 'MF', 15, '2005-10-06', 'France, France', 'Strasbourg'),
('fc8287db', 'MAR', 'Munir', 'GK', 12, '1989-05-10', 'Spain', 'RS Berkane'),
('a3d79d3c', 'MAR', 'Zakaria El Ouahdi', 'DF,MF', 13, '2001-12-31', 'Hoboken, Belgium', 'Genk'),
('83299cc0', 'MAR', 'Azzedine Ounahi', 'MF', 8, '2000-04-19', 'Casablanca, Morocco', 'Girona'),
('f126a259', 'MAR', 'Soufiane Rahimi', 'FW', 9, '1996-06-02', 'Casablanca, Morocco', 'Al Ain'),
('12e12fd9', 'MAR', 'Ahmed Reda Tagnaouti', 'GK', 22, '1996-04-05', 'Casablanca, Morocco', 'AS FAR'),
('b3b9b8b8', 'MAR', 'Chadi Riad', 'DF', 18, '2003-06-17', 'Palma, Spain', 'Crystal Palace'),
('14f47102', 'MAR', 'Marwane Saâdane', 'DF,MF', 5, '1992-01-17', 'Mohammedia, Morocco', 'Al-Fateh'),
('3ec9f005', 'MAR', 'Ismael Saibari', 'FW', 11, '2001-01-28', 'Terrassa, Spain', 'PSV'),
('0d274394', 'MAR', 'Anass Salah-Eddine', 'DF', 26, '2002-01-18', 'Amsterdam, Netherlands', 'PSV'),
('bafbe06a', 'MAR', 'Amine Sbai', 'FW,MF', 17, '2000-11-05', 'Sidi Qacem, Morocco', 'Angers'),
('47ce793b', 'MAR', 'Chemsdine Talbi', 'MF', 7, '2005-05-09', 'Auvelais, Belgium', 'Sunderland'),
('f5ccae19', 'MAR', 'Gessime Yassine', 'MF', 16, '2005-11-22', 'Salon-de-Provence, France', 'Strasbourg'),
('eaeca114', 'NED', 'Nathan Aké', 'DF', 5, '1995-02-18', 'The Hague, Netherlands', 'Manchester City'),
('4c184730', 'NED', 'Brian Brobbey', 'FW', 19, '2002-02-01', 'Amsterdam, Netherlands', 'Sunderland'),
('481c9ece', 'NED', 'Denzel Dumfries', 'DF', 22, '1996-04-18', 'Rotterdam, Netherlands', 'Inter'),
('a92ab7be', 'NED', 'Mark Flekken', 'GK', 23, '1993-06-13', 'Gemeente Kerkrade, Netherlands', 'Leverkusen'),
('1971591f', 'NED', 'Cody Gakpo', 'FW', 11, '1999-05-07', 'Gemeente Eindhoven, Netherlands', 'Liverpool'),
('242e1043', 'NED', 'Lutsharel Geertruida', 'DF', 2, '2000-07-18', 'Rotterdam, Netherlands', 'Sunderland'),
('b8e740fb', 'NED', 'Ryan Gravenberch', 'MF', 8, '2002-05-16', 'Amsterdam, Netherlands', 'Liverpool'),
('bde35051', 'NED', 'Jorrel Hato', 'DF', 25, '2006-03-07', 'Rotterdam, Netherlands', 'Chelsea'),
('4fd08daa', 'NED', 'Jan Paul van Hecke', 'DF', 6, '2000-06-08', 'Arnemuiden, Netherlands', 'Brighton'),
('1bacc518', 'NED', 'Frenkie de Jong', 'MF', 21, '1997-05-12', 'Arkel, Netherlands', 'Barcelona'),
('4c3a6744', 'NED', 'Justin Kluivert', 'FW,MF', 7, '1999-05-05', 'Amsterdam, Netherlands', 'Bournemouth'),
('a26fb8aa', 'NED', 'Teun Koopmeiners', 'DF,MF', 20, '1998-02-28', 'Gemeente Castricum, Netherlands', 'Juventus'),
('8e034340', 'NED', 'Noa Lang', 'FW,MF', 17, '1999-06-17', 'Capelle aan den IJssel, Netherlands', 'Galatasaray'),
('116c35df', 'NED', 'Donyell Malen', 'FW', 18, '1999-01-09', 'Wieringen, Netherlands', 'Roma'),
('8f696594', 'NED', 'Memphis', 'FW,MF', 10, '1994-02-13', 'Moordrecht, Netherlands', 'Corinthians'),
('afb61630', 'NED', 'Tijjani Reijnders', 'MF', 14, '1998-07-29', 'Zwolle, Netherlands', 'Manchester City'),
('349fa918', 'NED', 'Robin Roefs', 'GK', 13, '2003-01-17', 'Chiwawa Horse Camp, WA, United States', 'Sunderland'),
('2a1beb34', 'NED', 'Marten de Roon', 'DF,MF', 3, '1991-03-29', 'Zwijndrecht, Netherlands', 'Atalanta'),
('df04eb4b', 'NED', 'Crysencio Summerville', 'FW', 24, '2001-10-30', 'Rotterdam, Netherlands', 'West Ham'),
('6e44569a', 'NED', 'Guus Til', 'FW,MF', 16, '1997-12-22', 'Amsterdam, Netherlands', 'PSV'),
('41034650', 'NED', 'Jurriën Timber', 'DF', NULL, '2001-06-17', 'Utrecht, Netherlands', 'Arsenal'),
('803e7aca', 'NED', 'Quinten Timber', 'MF', 26, '2001-06-17', 'Utrecht, Netherlands', 'Marseille'),
('e06683ca', 'NED', 'Virgil van Dijk', 'DF', 4, '1991-07-08', 'Breda, Netherlands', 'Liverpool'),
('8fe2a392', 'NED', 'Micky van de Ven', 'DF', 15, '2001-04-19', 'Wormer, Netherlands', 'Tottenham'),
('cf134113', 'NED', 'Bart Verbruggen', 'GK', 1, '2002-08-18', 'Breda, Netherlands', 'Brighton'),
('c4e87b8b', 'NED', 'Wout Weghorst', 'FW', 9, '1992-08-07', 'Gemeente Borne, Netherlands', 'Ajax'),
('4876c9ab', 'NED', 'Mats Wieffer', 'DF,MF', 12, '1999-11-16', 'Gemeente Borne, Netherlands', 'Brighton'),
('b2bef13f', 'NZL', 'Kosta Barbarouses', 'FW,MF', 17, '1990-02-19', 'Wellington, New Zealand', 'Western Sydney'),
('68e991fc', 'NZL', 'Lachlan Bayliss', 'MF', 25, '2002-07-24', 'Darwin, Australia', 'Newcastle Jets'),
('7825847e', 'NZL', 'Joe Bell', 'MF', 6, '1999-04-27', 'Bristol, England, United Kingdom', 'Viking'),
('3575e5eb', 'NZL', 'Tyler Bindon', 'DF', 4, '2005-01-27', 'United States', 'Sheffield United'),
('6bfa0d3a', 'NZL', 'Michael Boxall', 'DF', 5, '1988-08-18', 'Auckland, New Zealand', 'Minnesota Utd'),
('dd86e8e4', 'NZL', 'Liberato Cacace', 'DF', 13, '2000-09-27', 'Wellington, New Zealand', 'Wrexham'),
('fdf47077', 'NZL', 'Max Crocombe', 'GK', 1, '1993-08-12', 'Auckland, New Zealand', 'Millwall'),
('9d6968a3', 'NZL', 'Callan Elliot', 'DF', 24, '1999-07-07', 'Dumfries, Scotland, United Kingdom', 'Auckland FC'),
('dece7370', 'NZL', 'Matt Garbett', 'MF', NULL, '2002-04-13', 'London, England, United Kingdom', 'Peterborough'),
('0c295d6e', 'NZL', 'Elijah Just', 'MF', 11, '2000-05-01', 'Palmerston North, New Zealand', 'Motherwell'),
('3fc42049', 'NZL', 'Callum McCowatt', 'MF', 20, '1999-04-30', 'Auckland, New Zealand', 'Silkeborg'),
('e14e818c', 'NZL', 'Ben Old', 'MF', 19, '2002-08-13', 'Auckland, New Zealand', 'Saint-Étienne'),
('2da46a72', 'NZL', 'Alex Paulsen', 'GK', 12, '2002-07-04', 'Auckland, New Zealand', 'Lechia Gdańsk'),
('4e86877c', 'NZL', 'Tim Payne', 'DF', 2, '1994-01-10', 'Auckland, New Zealand', 'Wellington'),
('92afdf2a', 'NZL', 'Nando Pijnaker', 'DF', 15, '1999-02-25', 'Gemeente Brummen, Netherlands', 'Auckland FC'),
('513ec88e', 'NZL', 'Jesse Randall', 'MF', 21, '2002-08-19', 'Wellington, New Zealand', 'Auckland FC'),
('9538d1a4', 'NZL', 'Logan Rogerson', 'FW,MF', 7, '1998-05-28', 'Wellington, New Zealand', 'Auckland FC'),
('53be5103', 'NZL', 'Alex Rufer', 'MF', 14, '1996-06-12', 'Geneva, Switzerland', 'Wellington'),
('4ba886c6', 'NZL', 'Sarpreet Singh', 'MF', 10, '1999-02-20', 'Auckland, New Zealand', 'Wellington'),
('26a48676', 'NZL', 'Tommy Smith', 'DF', 26, '1990-03-31', 'Macclesfield, England, United Kingdom', 'Braintree Town'),
('690d1049', 'NZL', 'Marko Stamenic', 'MF', 8, '2002-02-19', 'Wellington, New Zealand', 'Swansea City'),
('016e419b', 'NZL', 'Finn Surman', 'DF', 16, '2003-09-23', 'Cardiff, Wales, United Kingdom', 'Portland Timbers'),
('95efdac2', 'NZL', 'Ryan Thomas', 'FW,MF', 23, '1994-12-20', 'Te Puke, New Zealand', 'Zwolle'),
('90a63dda', 'NZL', 'Francis de Vries', 'DF', 3, '1994-11-28', 'Christchurch, New Zealand', 'Auckland FC'),
('1510013c', 'NZL', 'Ben Waine', 'FW', 18, '2001-06-11', 'Wellington, New Zealand', 'Port Vale'),
('4e9a0555', 'NZL', 'Chris Wood', 'FW', 9, '1991-12-07', 'Auckland, New Zealand', 'Nottingham'),
('c9551400', 'NZL', 'Michael Woud', 'GK', 22, '1999-01-16', 'Auckland, New Zealand', 'Auckland FC'),
('c88a28b9', 'NOR', 'Thelo Aasgaard', 'MF', 19, '2002-05-02', 'Liverpool, England, United Kingdom', 'Rangers'),
('a8c0acb7', 'NOR', 'Kristoffer Ajer', 'DF', 3, '1998-04-17', 'Rælingen, Norway', 'Brentford'),
('3724baa1', 'NOR', 'Fredrik André Bjørkan', 'DF', 15, '1998-08-21', 'Bodø, Norway', 'Bodø/Glimt'),
('f0677ed7', 'NOR', 'Fredrik Aursnes', 'MF', 14, '1995-12-10', 'Hareid, Norway', 'Benfica'),
('e4114f5d', 'NOR', 'Patrick Berg', 'DF,MF', 6, '1997-11-24', 'Bodø, Norway', 'Bodø/Glimt'),
('d0b6129f', 'NOR', 'Sander Berge', 'MF', 8, '1998-02-14', 'Bærum, Norway', 'Fulham'),
('eed2427e', 'NOR', 'Oscar Bobb', 'FW,MF', 22, '2003-07-12', 'Oslo, Norway', 'Fulham'),
('57fe6b9b', 'NOR', 'Henrik Falchener', 'DF', 25, '2003-05-08', 'Tønsberg, Norway', 'Viking'),
('1f44ac21', 'NOR', 'Erling Haaland', 'FW', 9, '2000-07-21', 'Leeds, England, United Kingdom', 'Manchester City'),
('834fea76', 'NOR', 'Torbjørn Heggem', 'DF', 17, '1999-01-12', 'Trondheim, Norway', 'Bologna'),
('107e4890', 'NOR', 'Sondre Langås', 'DF', 24, '2001-02-02', 'Namsos, Norway', 'Derby County'),
('9affc5f2', 'NOR', 'David Møller Wolfe', 'DF', 5, '2002-04-23', 'Bergen, Norway', 'Wolves'),
('4ab12002', 'NOR', 'Antonio Nusa', 'FW', 20, '2005-04-17', 'Oslo, Norway', 'RB Leipzig'),
('bdedffac', 'NOR', 'Ørjan Nyland', 'GK', 1, '1990-09-10', 'Volda, Norway', 'Sevilla'),
('596cc50e', 'NOR', 'Marcus Pedersen', 'DF,MF', 16, '2000-07-16', 'Hammerfest, Norway', 'Torino'),
('12c35abe', 'NOR', 'Jens Petter Hauge', 'DF,FW', 23, '1999-10-12', 'Bodø, Norway', 'Bodø/Glimt'),
('009a4f60', 'NOR', 'Julian Ryerson', 'DF', 26, '1997-11-17', 'Lyngdal, Norway', 'Dortmund'),
('a427724f', 'NOR', 'Andreas Schjelderup', 'FW,MF', 21, '2004-06-01', 'Bodø, Norway', 'Benfica'),
('05d89c1c', 'NOR', 'Egil Selvik', 'GK', 13, '1997-07-30', 'Sandnes, Norway', 'Watford'),
('f553b2b3', 'NOR', 'Jørgen Strand Larsen', 'FW', 11, '2000-02-06', 'Halden, Norway', 'Crystal Palace'),
('e92cd3f7', 'NOR', 'Alexander Sørloth', 'FW', 7, '1995-12-05', 'Trondheim, Norway', 'Atlético Madrid'),
('93525deb', 'NOR', 'Sander Tangvik', 'GK', 12, '2002-11-29', 'Trondheim, Norway', 'Hamburger SV'),
('d1b49282', 'NOR', 'Morten Thorsby', 'MF', 2, '1996-05-05', 'Oslo, Norway', 'Cremonese'),
('76ff8d0d', 'NOR', 'Kristian Thorstvedt', 'MF', 18, '1999-03-13', 'Stavanger, Norway', 'Sassuolo'),
('79300479', 'NOR', 'Martin Ødegaard', 'MF', 10, '1998-12-17', 'Drammen, Norway', 'Arsenal'),
('b35a7399', 'NOR', 'Leo Østigård', 'DF,FW', 4, '1999-11-28', 'Molde, Norway', 'Genoa'),
('349cae8f', 'PAN', 'Michael Amir Murillo', 'MF,DF', 23, '1996-02-11', 'Ciudad de Panamá, Panama', 'Beşiktaş'),
('6ea23758', 'PAN', 'Andrés Andrade Cedeño', 'DF', 16, '1998-10-16', 'Ciudad de Panamá, Panama', 'LASK'),
('b39849eb', 'PAN', 'Yoel Bárcenas', 'MF', 11, '1993-10-23', 'Colón, Panama', 'Mazatlán'),
('c2b11050', 'PAN', 'César Blackman', 'MF,DF', 2, '1998-04-02', 'Ciudad de Panamá, Panama', 'Slovan Bratislava'),
('f087912d', 'PAN', 'Adalberto Carrasquilla', 'MF', 8, '1998-11-28', 'Ciudad de Panamá, Panama', 'UNAM'),
('bec98750', 'PAN', 'José Córdoba', 'DF', 3, '2001-03-06', 'Ciudad de Panamá, Panama', 'Norwich City'),
('2ffb0739', 'PAN', 'Erick Davis', 'DF', 15, '1991-03-31', 'Colón, Panama', 'Plaza Amador'),
('f2a276d1', 'PAN', 'Ismael Díaz', 'FW,MF', 10, '1997-05-12', 'Ciudad de Panamá, Panama', 'León'),
('4991ec66', 'PAN', 'Fidel Escobar', 'DF', 4, '1995-01-09', 'Ciudad de Panamá, Panama', 'Saprissa'),
('682e47b3', 'PAN', 'José Fajardo', 'FW', 17, '1993-08-18', 'Colón, Panama', 'Univ Católica'),
('c8e2e64a', 'PAN', 'Edgardo Fariña', 'DF', 5, '2001-10-19', 'Ciudad de Panamá, Panama', 'Nizhny Novgorod'),
('2d496ca3', 'PAN', 'Aníbal Godoy', 'MF', 20, '1990-02-10', 'Ciudad de Panamá, Panama', 'San Diego FC'),
('56f6d192', 'PAN', 'Jorge Gutiérrez', 'DF', 26, '1998-09-01', 'Ciudad de Panamá, Panama', 'Dep. La Guaira'),
('3f18600c', 'PAN', 'Carlos Harvey', 'MF', 14, '2000-02-03', 'Ciudad de Panamá, Panama', 'Minnesota Utd'),
('31d68775', 'PAN', 'Azarías Londoño', 'MF', 24, '2001-06-21', 'Ciudad de Panamá, Panama', 'Univ Católica'),
('b333b014', 'PAN', 'José Luis Rodríguez', 'MF,FW', 7, '1998-06-19', 'Ciudad de Panamá, Panama', 'FC Juárez'),
('fdb15495', 'PAN', 'Cristian Martínez', 'MF,FW', 6, '1997-02-06', 'Ciudad de Panamá, Panama', 'Kiryat Shmona'),
('2390dcad', 'PAN', 'Luis Mejía', 'GK', 1, '1991-03-16', 'Ciudad de Panamá, Panama', 'Nacional'),
('2b80837f', 'PAN', 'Roderick Miller', 'DF', 25, '1992-04-03', 'Ciudad de Panamá, Panama', 'Turan Tovuz'),
('ea34d827', 'PAN', 'Orlando Mosquera', 'GK', 22, '1994-12-25', 'Ciudad de Panamá, Panama', 'Al-Fayha'),
('5854ae43', 'PAN', 'Alberto Quintero', 'FW,MF', 19, '1987-12-18', 'Ciudad de Panamá, Panama', 'Plaza Amador'),
('30cda59f', 'PAN', 'Jiovany Ramos', 'DF', 13, '1997-01-26', 'Ciudad de Panamá, Panama', 'Puerto Cabello'),
('59f97bc8', 'PAN', 'Tomás Rodríguez', 'FW', 9, '1999-03-09', 'Ciudad de Panamá, Panama', 'Saprissa'),
('4eb9cc0f', 'PAN', 'César Samudio', 'GK', 12, '1994-02-23', 'Ciudad de Panamá, Panama', 'Marathón'),
('ddd5637f', 'PAN', 'Cecilio Waterman', 'FW', 18, '1991-04-13', 'Ciudad de Panamá, Panama', 'U Concepción'),
('d6cc3b04', 'PAN', 'César Yanis', 'MF', 21, '1996-01-28', 'Ciudad de Panamá, Panama', 'Cobresal'),
('bb08bce9', 'PAR', 'Omar Alderete', 'DF', 3, '1996-12-26', 'Asunción, Paraguay', 'Sunderland'),
('862a1c15', 'PAR', 'Miguel Almirón', 'MF', 10, '1994-02-10', 'Asunción, Paraguay', 'Atlanta Utd'),
('b18a3023', 'PAR', 'Júnior Alonso', 'DF', 6, '1993-02-09', 'Asunción, Paraguay', 'Atlético Mineiro'),
('10411db2', 'PAR', 'Álex Arce', 'FW', 18, '1995-06-16', 'Carapeguá, Paraguay', 'Ind. Rivadavia'),
('b6781b67', 'PAR', 'Gabriel Ávalos', 'FW', 21, '1990-10-12', 'Hohenau, Paraguay', 'Independiente'),
('3626f7d9', 'PAR', 'Fabián Balbuena', 'DF', 5, '1991-08-23', 'Ciudad del Este, Paraguay', 'Grêmio'),
('ad7d6437', 'PAR', 'Damián Bobadilla', 'MF', 16, '2001-07-11', 'Asunción, Paraguay', 'São Paulo'),
('90a38ca7', 'PAR', 'Gustavo Caballero', 'FW,MF', 24, '2001-09-21', 'San Lorenzo, Paraguay', 'Portsmouth'),
('db887bdf', 'PAR', 'Juan Cáceres', 'DF', 4, '2000-06-01', 'Dock Sud, Argentina', 'Dynamo Moskva'),
('97d24b73', 'PAR', 'José Canale', 'DF', 13, '1996-07-20', 'Itauguá, Paraguay', 'Lanús'),
('9b40a6ea', 'PAR', 'Andrés Cubas', 'MF', 14, '1996-05-22', 'Aristóbulo del Valle, Argentina', 'Vancouver'),
('9cfbad36', 'PAR', 'Julio Enciso', 'FW', 19, '2004-01-23', 'Caaguazú, Paraguay', 'Strasbourg'),
('9a82f79a', 'PAR', 'Gatito Fernández', 'GK', 1, '1988-03-29', 'Asunción, Paraguay', 'Cerro Porteño'),
('8e97a57b', 'PAR', 'Matías Galarza', 'MF', 23, '2002-02-11', 'Asunción, Paraguay', 'Atlanta Utd'),
('0d425331', 'PAR', 'Orlando Gill', 'GK', 12, '2000-06-11', 'San Lorenzo, Paraguay', 'San Lorenzo'),
('916728da', 'PAR', 'Diego Gómez', 'MF', 8, '2003-03-27', 'San Juan Bautista, Paraguay', 'Brighton'),
('d5ce52a5', 'PAR', 'Gustavo Gómez', 'DF', 15, '1993-05-06', 'San Juan Bautista, Paraguay', 'Palmeiras'),
('cb01ad74', 'PAR', 'Kaku', 'MF', 17, '1995-01-11', 'Ciudadela, Argentina', 'Al Ain'),
('4d0d5020', 'PAR', 'Alexandro Maidana', 'DF', 26, '2005-07-26', 'Caacupé, Paraguay', 'Talleres–C'),
('bf4cbc22', 'PAR', 'Mauricio', 'MF', 11, '2001-05-22', 'São Paulo, Brazil', 'Palmeiras'),
('60953af0', 'PAR', 'Braian Ojeda', 'MF', 20, '2000-06-27', 'Itauguá, Paraguay', 'Orlando City'),
('556f8f36', 'PAR', 'Gastón Olveira', 'GK', 22, '1993-04-21', 'Montevideo, Uruguay', 'Olimpia'),
('e9fc7295', 'PAR', 'Isidro Pitta', 'FW', 25, '1999-08-14', 'Asunción, Paraguay', 'RB Bragantino'),
('0a447501', 'PAR', 'Antonio Sanabria', 'FW', 9, '1996-03-04', 'San Lorenzo, Paraguay', 'Cremonese'),
('2d3417a1', 'PAR', 'Ramón Sosa', 'FW,MF', 7, '1999-08-31', 'Maracana, Paraguay', 'Palmeiras'),
('b99b4cf5', 'PAR', 'Gustavo Velásquez', 'DF', 2, '1991-04-17', 'Itauguá, Paraguay', 'Cerro Porteño'),
('0fa11d7d', 'POR', 'Tomás Araújo', 'DF', 4, '2002-05-16', 'Vila Nova de Famalicão, Portugal', 'Benfica'),
('bd6351cd', 'POR', 'João Cancelo', 'DF', 20, '1994-05-27', 'Barreiro, Portugal', 'Barcelona'),
('5ef3d210', 'POR', 'Francisco Conceição', 'MF', 26, '2002-12-14', 'Coimbra, Portugal', 'Juventus'),
('93fffbcf', 'POR', 'Diogo Costa', 'GK', 1, '1999-09-19', 'Rothrist, Switzerland', 'Porto'),
('76c2a023', 'POR', 'Samu Costa', 'MF', 24, '2000-11-27', 'Aveiro, Portugal', 'Mallorca'),
('d9565625', 'POR', 'Diogo Dalot', 'DF,MF', 5, '1999-03-18', 'Braga, Portugal', 'Manchester Utd'),
('31c69ef1', 'POR', 'Rúben Dias', 'DF', 3, '1997-05-14', 'Amadora, Portugal', 'Manchester City'),
('8aafd64f', 'POR', 'João Félix', 'MF', 11, '1999-11-10', 'Viseu, Portugal', 'Al-Nassr'),
('507c7bdf', 'POR', 'Bruno Fernandes', 'MF', 8, '1994-09-08', 'Maia, Portugal', 'Manchester Utd'),
('e6bc67d7', 'POR', 'Gonçalo Guedes', 'FW,MF', 19, '1996-11-29', 'Benavente, Portugal', 'Real Sociedad'),
('33651873', 'POR', 'Gonçalo Inácio', 'DF', 14, '2001-08-25', 'Almada, Portugal', 'Sporting CP'),
('20730eae', 'POR', 'Rafael Leão', 'FW,MF', 17, '1999-06-10', 'Almada, Portugal', 'Milan'),
('f20e4cc9', 'POR', 'Nuno Mendes', 'DF', 25, '2002-06-19', 'Sintra, Portugal', 'PSG'),
('7ba2eaa9', 'POR', 'Pedro Neto', 'MF', 18, '2000-03-09', 'Viana do Castelo, Portugal', 'Chelsea'),
('c2a15a27', 'POR', 'João Neves', 'MF', 15, '2004-09-27', 'Tavira, Portugal', 'PSG'),
('44bfb6c5', 'POR', 'Rúben Neves', 'MF', 21, '1997-03-13', 'Mozelos, Portugal', 'Al-Hilal'),
('e6af02e0', 'POR', 'Matheus Nunes', 'DF,MF', 6, '1998-08-27', 'Rio de Janeiro, Brazil', 'Manchester City'),
('f63cda26', 'POR', 'Gonçalo Ramos', 'FW', 9, '2001-06-20', 'Olhão, Portugal', 'PSG'),
('dea698d9', 'POR', 'Cristiano Ronaldo', 'FW', 7, '1985-02-05', 'Funchal, Portugal', 'Al-Nassr'),
('903b6e8b', 'POR', 'José Sá', 'GK', 12, '1993-01-17', 'Braga, Portugal', 'Wolves'),
('d04b94db', 'POR', 'Nélson Semedo', 'DF,MF', 2, '1993-11-16', 'Lisbon, Portugal', 'Fenerbahçe'),
('3eb22ec9', 'POR', 'Bernardo Silva', 'MF', 10, '1994-08-10', 'Lisbon, Portugal', 'Manchester City'),
('ea83bfa6', 'POR', 'Rui Silva', 'GK', 22, '1994-02-07', 'Maia, Portugal', 'Sporting CP'),
('77e39b04', 'POR', 'Francisco Trincão', 'FW,MF', 16, '1999-12-29', 'Viana do Castelo, Portugal', 'Sporting CP'),
('fc8fcbd1', 'POR', 'Renato Veiga', 'DF', 13, '2003-07-29', 'Lisbon, Portugal', 'Villarreal'),
('3b029691', 'POR', 'Vitinha', 'MF', 23, '2000-02-13', 'Aves, Portugal', 'PSG'),
('13c8f40b', 'QAT', 'Yusuf Abdurisag', 'FW', 15, '1999-08-06', 'Mogadishu, Somalia', 'Al-Wakrah'),
('27e7e545', 'QAT', 'Mahmoud Abunada', 'GK', 1, '2000-02-05', 'Doha, Qatar', 'Al Rayyan SC'),
('fd53d9e7', 'QAT', 'Akram Afif', 'FW,MF', 11, '1996-11-18', 'Doha, Qatar', 'Al Sadd'),
('a62fa158', 'QAT', 'Homam Ahmed', 'DF', 14, '1999-08-25', 'Doha, Qatar', 'Cultural Leonesa'),
('74fbbb3c', 'QAT', 'Ahmed Alaaeldin', 'FW', 7, '1993-01-31', 'Ismailia, Egypt', 'Al Rayyan SC'),
('bae045a9', 'QAT', 'Almoez Ali', 'FW', 19, '1996-08-19', 'Khartoum, Sudan', 'Al Duhail SC'),
('8d3e92e0', 'QAT', 'Meshaal Barsham', 'GK', 22, '1998-02-14', 'Doha, Qatar', 'Al Sadd'),
('a38f33fd', 'QAT', 'Karim Boudiaf', 'MF', 12, '1990-09-16', 'Rouen, France', 'Al Duhail SC'),
('fcaa2400', 'QAT', 'Sultan Al-Brake', 'DF', 18, '1996-04-07', 'Doha, Qatar', 'Al Duhail SC'),
('f2369793', 'QAT', 'Ahmed Fathy', 'MF', 20, '1993-01-25', 'Aswan, Egypt', 'Al-Arabi'),
('af9ef8aa', 'QAT', 'Jassem Gaber', 'MF', 5, '2002-02-20', 'Doha, Qatar', 'Al Rayyan SC'),
('efcf04d2', 'QAT', 'Ahmed Al-Ganehi', 'FW', 17, '2000-09-22', 'Doha, Qatar', 'Al-Gharafa Sports Club'),
('c5065ef8', 'QAT', 'Abdulaziz Hatem', 'MF', 6, '1990-01-01', 'Doha, Qatar', 'Al Rayyan SC'),
('41bd6c64', 'QAT', 'Hassan Al-Haydos', 'MF', 10, '1990-12-11', 'Doha, Qatar', 'Al Sadd'),
('c164fda2', 'QAT', 'Al-Hashmi Al-Hussain', 'MF', 25, '2003-08-15', 'Qaţar, Qatar', 'Al-Arabi'),
('efdcf1c7', 'QAT', 'Tahsin Jamshid', 'FW', 24, '2006-06-16', 'Qaţar, Qatar', 'Al Duhail SC'),
('620764f4', 'QAT', 'Edmilson Junior', 'MF,FW', 8, '1994-08-19', 'Liège, Belgium', 'Al Duhail SC'),
('7be5ad52', 'QAT', 'Boualem Khoukhi', 'DF', 16, '1990-07-09', 'Bou Ismaïl, Algeria', 'Al Sadd'),
('c078667a', 'QAT', 'Issa Laye', 'MF,DF', 4, '1997-12-22', 'Senegal', 'Al-Arabi'),
('2b1d2ada', 'QAT', 'Assim Madibo', 'MF', 23, '1996-10-22', 'Doha, Qatar', 'Al-Wakrah'),
('1e20b706', 'QAT', 'Mohamed Manai', 'DF', 26, '2002-10-25', 'Doha, Qatar', 'Al-Shamal Sports Club'),
('5169f27f', 'QAT', 'Lucas Mendes', 'DF', 3, '1990-07-03', 'Curitiba, Brazil', 'Al-Wakrah'),
('da38f46e', 'QAT', 'Mohammed Muntari', 'FW', 9, '1993-12-20', 'Kumasi, Ghana', 'Al-Gharafa Sports Club'),
('010e5bae', 'QAT', 'Ayoub Al-Oui', 'DF', 13, '2005-03-11', 'Qaţar, Qatar', 'Al-Gharafa Sports Club'),
('8735fe66', 'QAT', 'Ró-Ró', 'DF', 2, '1990-08-06', 'Algueirão-Mem Martins, Portugal', 'Al Sadd'),
('aed851da', 'QAT', 'Salah Zakaria', 'GK', 21, '1999-04-24', 'Egypt', 'Al Duhail SC'),
('caa254e4', 'KSA', 'Saud Abdulhamid', 'DF', 12, '1999-07-18', 'Jiddah, Saudi Arabia', 'Lens'),
('2b03b136', 'KSA', 'Abdulelah Al-Amri', NULL, 4, '1997-01-15', 'Ta''if, Saudi Arabia', 'Al-Nassr'),
('70f3a9d1', 'KSA', 'Nawaf Al Aqidi', 'GK', 1, '2000-05-10', 'Riyadh, Saudi Arabia', 'Al-Nassr'),
('7dc1c2c6', 'KSA', 'Nawaf Boushal', 'DF', 13, '1999-09-16', 'Al Hufūf, Saudi Arabia', 'Al-Nassr'),
('ac717a23', 'KSA', 'Firas Al-Buraikan', 'FW', 9, '2000-05-14', 'Riyadh, Saudi Arabia', 'Al-Ahli'),
('7709e4a6', 'KSA', 'Nasser Al-Dawsari', 'MF', 6, '1998-12-19', 'Riyadh, Saudi Arabia', 'Al-Hilal'),
('60ee859c', 'KSA', 'Salem Al-Dawsari', 'MF', 10, '1991-08-19', 'Riyadh, Saudi Arabia', 'Al-Hilal'),
('c16843c7', 'KSA', 'Khalid Al Ghannam', 'MF', 17, '2000-11-08', 'Khobar, Saudi Arabia', 'Al-Ettifaq'),
('cc4b5436', 'KSA', 'Abdullah Al-Hamdan', 'FW', 19, '1999-09-13', 'Riyadh, Saudi Arabia', 'Al-Nassr'),
('1d88554c', 'KSA', 'Moteb Al-Harbi', 'DF', 24, '2000-02-20', 'Riyadh, Saudi Arabia', 'Al-Hilal'),
('6d258576', 'KSA', 'Alaa Al Hejji', 'MF', 18, '1995-12-03', 'Sakakah, Saudi Arabia', 'Neom'),
('ac0a9132', 'KSA', 'Ziyad Al Johani', 'MF', 16, '2001-11-11', 'Jiddah, Saudi Arabia', 'Al-Ahli'),
('62592fc1', 'KSA', 'Musab Al Juwayr', 'MF,FW', 7, '2003-06-20', 'Riyadh, Saudi Arabia', 'Al-Qadsiah'),
('7165f2e9', 'KSA', 'Hassan Kadesh', 'DF', 14, '1992-09-06', 'Dammam, Saudi Arabia', 'Al-Ittihad'),
('74ccf212', 'KSA', 'Mohamed Kanno', 'MF', 23, '1994-09-22', 'Khobar, Saudi Arabia', 'Al-Hilal'),
('eedb42fd', 'KSA', 'Ahmed Al-Kassar', 'GK', 22, '1991-05-08', 'Jubayl al Qawm, Saudi Arabia', 'Al-Qadsiah'),
('ab47ae1c', 'KSA', 'Abdullah Al-Khaibari', 'MF', 15, '1996-08-16', 'Riyadh, Saudi Arabia', 'Al-Nassr'),
('46f7ab4f', 'KSA', 'Ali Lajami', 'DF', 3, '1996-04-24', 'Sayhāt, Saudi Arabia', 'Al-Hilal'),
('cd23146c', 'KSA', 'Ali Majrashi', 'DF', 2, '1999-10-02', 'Al Ḩamīmah, Saudi Arabia', 'Al-Ahli'),
('8738a7a1', 'KSA', 'Sultan Mendash', 'FW,MF', 20, '1994-10-17', 'Jeddah, Saudi Arabia', 'Al-Hilal'),
('f2c060c6', 'KSA', 'Mohammed Al-Owais', 'GK', 21, '1991-10-10', 'Al Hufūf, Saudi Arabia', 'Al-Ula'),
('dd65e243', 'KSA', 'Mohammed Abu Al-Shamat', 'MF', 26, '2002-08-11', 'Jiddah, Saudi Arabia', 'Al-Qadsiah'),
('f4377d0f', 'KSA', 'Saleh Al-Shehri', 'FW', 11, '1993-11-01', 'Jeddah, Saudi Arabia', 'Al-Ittihad'),
('6d78c320', 'KSA', 'Hassan Al Tambakti', 'DF', 5, '1999-02-09', 'Riyadh, Saudi Arabia', 'Al-Hilal'),
('cf4eaaa7', 'KSA', 'Jehad Thakri', 'DF', 25, '2001-07-21', 'Khobar, Saudi Arabia', 'Al-Qadsiah'),
('650eaf9c', 'KSA', 'Ayman Yahya', 'MF', 8, '2001-05-14', 'Riyadh, Saudi Arabia', 'Al-Nassr'),
('f2bf1b0f', 'SCO', 'Ché Adams', 'FW', 10, '1996-07-13', 'Leicester, England, United Kingdom', 'Torino'),
('26ce2263', 'SCO', 'Ryan Christie', 'MF', 11, '1995-02-22', 'Inverness, Scotland, United Kingdom', 'Bournemouth'),
('e2a68b89', 'SCO', 'Findlay Curtis', 'MF', 25, '2006-10-01', 'Balfron, Scotland, United Kingdom', 'Kilmarnock'),
('cd92357a', 'SCO', 'Lyndon Dykes', 'FW,MF', 9, '1995-10-07', 'Gold Coast, Australia', 'Charlton Athletic'),
('ee64a822', 'SCO', 'Lewis Ferguson', 'MF', 19, '1999-08-24', 'Hamilton, Scotland, United Kingdom', 'Bologna'),
('81a92add', 'SCO', 'Tyler Fletcher', 'MF', 8, '2007-03-19', 'Manchester, England, United Kingdom', 'Manchester Utd'),
('733f1a7d', 'SCO', 'Ben Gannon-Doak', 'MF', 17, '2005-11-11', 'Dalry, Scotland, United Kingdom', 'Bournemouth'),
('df10e27c', 'SCO', 'Billy Gilmour', 'MF', NULL, '2001-06-11', 'Irvine, Scotland, United Kingdom', 'Napoli'),
('b15780e3', 'SCO', 'Craig Gordon', 'GK', 21, '1982-12-31', 'Edinburgh, Scotland, United Kingdom', 'Hearts'),
('e082af5b', 'SCO', 'Angus Gunn', 'GK', 1, '1996-01-22', 'Norwich, England, United Kingdom', 'Nottingham'),
('e9254eec', 'SCO', 'Grant Hanley', 'DF', 5, '1991-11-20', 'Dumfries, Scotland, United Kingdom', 'Hibernian'),
('ffed43e3', 'SCO', 'Jack Hendry', 'DF', 13, '1995-05-07', 'Glasgow, Scotland, United Kingdom', 'Al-Ettifaq'),
('1780bb4a', 'SCO', 'Aaron Hickey', 'DF', 2, '2002-06-10', 'Glasgow, Scotland, United Kingdom', 'Brentford'),
('78e87179', 'SCO', 'George Hirst', 'FW', 18, '1999-02-15', 'Sheffield, England, United Kingdom', 'Ipswich Town'),
('ce95958a', 'SCO', 'Dominic Hyam', 'DF', 16, '1995-12-20', 'Leuchars, Scotland, United Kingdom', 'Wrexham'),
('d8c74957', 'SCO', 'Liam Kelly', 'GK', 12, '1996-01-23', 'Glasgow, Scotland, United Kingdom', 'Rangers'),
('90f91999', 'SCO', 'John McGinn', 'MF', 7, '1994-10-18', 'Glasgow, Scotland, United Kingdom', 'Aston Villa'),
('4e5a4cbc', 'SCO', 'Scott McKenna', 'DF', 26, '1996-11-12', 'Dundee, Scotland, United Kingdom', 'Dinamo Zagreb'),
('471f16b3', 'SCO', 'Kenny McLean', 'MF', 23, '1992-01-08', 'Rutherglen, Scotland, United Kingdom', 'Norwich City'),
('d93c2511', 'SCO', 'Scott McTominay', 'MF', 4, '1996-12-08', 'Lancaster, England, United Kingdom', 'Napoli'),
('230f0471', 'SCO', 'Nathan Patterson', 'DF', 22, '2001-10-16', 'Glasgow, Scotland, United Kingdom', 'Everton'),
('56208b05', 'SCO', 'Anthony Ralston', 'DF', 24, '1998-11-16', 'Glasgow, Scotland, United Kingdom', 'Celtic'),
('2e4f5f03', 'SCO', 'Andy Robertson', 'DF', 3, '1994-03-11', 'Glasgow, Scotland, United Kingdom', 'Liverpool'),
('63b1a176', 'SCO', 'Lawrence Shankland', 'FW', 20, '1995-08-10', 'Glasgow, Scotland, United Kingdom', 'Hearts'),
('312d7b42', 'SCO', 'John Souttar', 'DF', 15, '1996-09-25', 'Aberdeen, Scotland, United Kingdom', 'Rangers'),
('18986367', 'SCO', 'Ross Stewart', 'FW', 14, '1996-07-11', 'Irvine, Scotland, United Kingdom', 'Southampton'),
('fce2302c', 'SCO', 'Kieran Tierney', 'MF', 6, '1997-06-05', 'Douglas, Isle of Man', 'Celtic'),
('19c2ffa4', 'SEN', 'Lamine Camara', 'MF', 8, '2004-01-01', 'Bignona, Senegal', 'Monaco'),
('9a0408b6', 'SEN', 'Pathé Ciss', 'DF,MF', 6, '1994-03-16', 'Senegal', 'Rayo Vallecano'),
('8ae7d0ec', 'SEN', 'Assane Diao', 'MF', 7, '2005-09-07', 'Ndagam, Senegal', 'Como'),
('6d0fe035', 'SEN', 'Habib Diarra', 'MF', 21, '2004-01-03', 'Guédiawaye, Senegal', 'Sunderland'),
('8104e41e', 'SEN', 'Krépin Diatta', 'DF', 15, '1999-02-25', 'Senegal', 'Monaco'),
('f41a69e6', 'SEN', 'Mory Diaw', 'GK', 23, '1993-06-22', 'Poissy, France', 'Le Havre'),
('40774c6b', 'SEN', 'Bamba Dieng', 'FW', 9, '2000-03-23', 'Pikine, Senegal', 'Lorient'),
('bd5eb2e5', 'SEN', 'El Hadji Malick Diouf', 'DF', 25, '2004-12-28', 'Dakar, Senegal', 'West Ham'),
('eedea60b', 'SEN', 'Yehvann Diouf', 'GK', 1, '1999-11-16', 'Montreuil, France', 'Nice'),
('72c812f3', 'SEN', 'Idrissa Gueye', 'MF', 5, '1989-09-26', 'Senegal', 'Everton'),
('7155e3e1', 'SEN', 'Pape Gueye', 'MF', 26, '1999-01-24', 'Montreuil, France', 'Villarreal'),
('9c36ed83', 'SEN', 'Nicolas Jackson', 'FW', 11, '2001-06-20', 'Banjul, Gambia', 'Bayern Munich'),
('a0415710', 'SEN', 'Ismail Jakobs', 'DF,MF', 14, '1999-08-17', 'Köln, Germany', 'Galatasaray'),
('da974c7b', 'SEN', 'Kalidou Koulibaly', 'DF', 3, '1991-06-20', 'Saint-Dié-des-Vosges, France', 'Al-Hilal'),
('c691bfe2', 'SEN', 'Sadio Mané', 'MF', 10, '1992-04-10', 'Sédhiou, Senegal', 'Al-Nassr'),
('feb5d972', 'SEN', 'Pape Matar Sarr', 'MF', 17, '2002-09-14', 'Thiaroye, Senegal', 'Tottenham'),
('201b4ee4', 'SEN', 'Ibrahim Mbaye', 'FW', 20, '2008-01-24', 'France, France', 'PSG'),
('3322e296', 'SEN', 'Antoine Mendy', 'DF', 24, '2004-05-27', 'Marseille, France', 'Nice'),
('33887998', 'SEN', 'Édouard Mendy', 'GK', 16, '1992-03-01', 'Montivilliers, France', 'Al-Ahli'),
('858a54c3', 'SEN', 'Cherif Ndiaye', 'FW,MF', 12, '1996-01-23', 'Senegal', 'Samsunspor'),
('5ed97752', 'SEN', 'Iliman Ndiaye', 'FW,MF', 13, '2000-03-06', 'Rouen, France', 'Everton'),
('00242715', 'SEN', 'Moussa Niakhaté', 'DF', 19, '1996-03-08', 'Roubaix, France', 'Lyon'),
('fa080d50', 'SEN', 'Bara Sapoko Ndiaye', 'MF', 22, '2007-12-31', 'Mékhé, Senegal', 'Bayern Munich'),
('bfdb33aa', 'SEN', 'Ismaila Sarr', 'MF', 18, '1998-02-25', 'Saint-Louis, Senegal', 'Crystal Palace'),
('61f80c89', 'SEN', 'Mamadou Sarr', 'DF', 2, '2005-08-29', 'Martigues, France', 'Chelsea'),
('f07a0fe5', 'SEN', 'Abdoulaye Seck', 'DF', 4, '1992-06-04', 'Senegal', 'Maccabi Haifa'),
('259affab', 'RSA', 'Jayden Adams', 'MF', 23, '2001-05-05', 'Cape Town, South Africa', 'Sundowns'),
('e8933eb0', 'RSA', 'Oswin Appollis', 'MF,FW', 7, '2001-08-25', 'Bishop Lavis, South Africa', 'Orlando Pirates'),
('c9f36f66', 'RSA', 'Sipho Chaine', 'GK', 16, '1996-12-14', 'South Africa, South Africa', 'Orlando Pirates'),
('9df63a1b', 'RSA', 'Bradley Cross', 'DF', 26, '2001-01-30', 'Kempton Park, South Africa', 'Kaizer Chiefs'),
('f84a807c', 'RSA', 'Lyle Foster', 'FW', 9, '2000-09-03', 'Carletonville, South Africa', 'Burnley'),
('707d1d95', 'RSA', 'Ricardo Goss', 'GK', 22, '1994-04-02', 'Durban, South Africa', 'Siwelele'),
('70b480d3', 'RSA', 'Samukele Kabini', 'DF', 18, '2004-03-15', 'South Africa', 'Molde'),
('4d76d03b', 'RSA', 'Evidence Makgopa', 'FW', 17, '2000-06-05', 'South Africa, South Africa', 'Orlando Pirates'),
('1627e6b5', 'RSA', 'Olwethu Makhanya', 'DF', 24, '2004-04-30', 'South Africa, South Africa', 'Philadelphia'),
('498d45f7', 'RSA', 'Thapelo Maseko', 'MF,FW', 12, '2003-11-11', 'South Africa, South Africa', 'AEL Limassol'),
('8a77ded2', 'RSA', 'Thabang Matuludi', 'DF', 2, '1999-01-14', 'Ngwaritsi, South Africa', 'Polokwane City'),
('f6272be9', 'RSA', 'Thalente Mbatha', 'MF', 5, '2000-03-16', 'South Africa, South Africa', 'Orlando Pirates'),
('13398d42', 'RSA', 'Mbekezeli Mbokazi', 'DF', 14, '2005-09-19', 'Hluhluwe, South Africa', 'Chicago Fire'),
('bb1f97f2', 'RSA', 'Aubrey Modiba', 'DF', 6, '1995-07-22', 'Polokwane, South Africa', 'Sundowns'),
('25c3fb97', 'RSA', 'Relebohile Mofokeng', 'MF', 10, '2004-10-23', 'Sharpeville, South Africa', 'Orlando Pirates'),
('00029b1e', 'RSA', 'Teboho Mokoena', 'MF', 4, '1997-01-24', 'Bethlehem, South Africa', 'Sundowns'),
('546d38f9', 'RSA', 'Tshepang Moremi', 'MF', 8, '2000-10-02', 'South Africa, South Africa', 'Orlando Pirates'),
('75388f92', 'RSA', 'Khuliso Mudau', 'DF', 20, '1995-04-26', 'South Africa, South Africa', 'Sundowns'),
('0ebbc4f3', 'RSA', 'Khulumani Ndamane', 'DF', 3, '2004-02-05', NULL, 'Sundowns'),
('3cb58055', 'RSA', 'Ime Okon', 'DF', 21, '2004-02-20', 'South Africa', 'Hannover 96'),
('190b0d5e', 'RSA', 'Iqraam Rayners', 'FW', 15, '1995-12-19', 'South Africa, South Africa', 'Sundowns'),
('cc014f7d', 'RSA', 'Kamogelo Sebelebele', 'DF,MF', 25, '2002-07-21', 'South Africa, South Africa', 'Orlando Pirates'),
('932f8e2b', 'RSA', 'Nkosinathi Sibisi', 'DF', 19, '1995-09-22', 'South Africa, South Africa', 'Orlando Pirates'),
('33bcd4b3', 'RSA', 'Sphephelo Sithole', 'MF', 13, '1999-03-03', 'South Africa, South Africa', 'Tondela'),
('a66cc153', 'RSA', 'Ronwen Williams', 'GK', 1, '1992-01-21', 'Gqeberha, South Africa', 'Sundowns'),
('c6f21aa8', 'RSA', 'Themba Zwane', 'FW,MF', 11, '1989-08-03', 'Tembisa, South Africa', 'Sundowns'),
('518f2234', 'ESP', 'Álex Baena', 'FW', 15, '2001-07-20', 'Roquetas de Mar, Spain', 'Atlético Madrid'),
('cc7888f3', 'ESP', 'Pau Cubarsí', 'DF', 22, '2007-01-22', 'Bescanó, Spain', 'Barcelona'),
('1daec722', 'ESP', 'Marc Cucurella', 'DF', 24, '1998-07-22', 'Alella, Spain', 'Chelsea'),
('2bed3eab', 'ESP', 'Eric García', 'DF,MF', 4, '2001-01-09', 'Barcelona, Spain', 'Barcelona'),
('87b498b0', 'ESP', 'Joan García', 'GK', 13, '2001-05-04', 'Sallent, Spain', 'Barcelona'),
('19cae58d', 'ESP', 'Gavi', 'FW', 9, '2004-08-05', 'Los Palacios y Villafranca, Spain', 'Barcelona'),
('b1f4086c', 'ESP', 'Álex Grimaldo', 'DF,MF', 3, '1995-09-20', 'Valencia, Spain', 'Leverkusen'),
('75645f0e', 'ESP', 'Borja Iglesias', 'FW', 26, '1993-01-17', 'Santiago de Compostela, Spain', 'Celta Vigo'),
('119b9a8e', 'ESP', 'Aymeric Laporte', 'DF', 14, '1994-05-27', 'Agen, France', 'Athletic Club'),
('02c15616', 'ESP', 'Marcos Llorente', 'DF', 5, '1995-01-30', 'Madrid, Spain', 'Atlético Madrid'),
('d080ed5e', 'ESP', 'Mikel Merino', 'MF', 6, '1996-06-22', 'Pamplona, Spain', 'Arsenal'),
('f8b5680f', 'ESP', 'Víctor Muñoz', 'MF', 25, '2003-07-13', 'Barcelona, Spain', 'Osasuna'),
('ae44e8e2', 'ESP', 'Dani Olmo', 'MF', 10, '1998-05-07', 'Terrassa, Spain', 'Barcelona'),
('8c3c640c', 'ESP', 'Mikel Oyarzabal', 'FW', 21, '1997-04-21', 'Eibar, Spain', 'Real Sociedad'),
('0d9b2d31', 'ESP', 'Pedri', 'MF', 20, '2002-11-25', 'Bajamar, Spain', 'Barcelona'),
('540ec57b', 'ESP', 'Yéremy Pino', 'FW,MF', 11, '2002-10-20', 'Las Palmas de Gran Canaria, Spain', 'Crystal Palace'),
('27d0a506', 'ESP', 'Pedro Porro', 'DF', 12, '1999-09-13', 'Don Benito, Spain', 'Tottenham'),
('365113c0', 'ESP', 'Marc Pubill', 'DF', 2, '2003-06-20', 'Terrassa, Spain', 'Atlético Madrid'),
('98ea5115', 'ESP', 'David Raya', 'GK', 1, '1995-09-15', 'Barcelona, Spain', 'Arsenal'),
('6434f10d', 'ESP', 'Rodri', 'MF', 16, '1996-06-22', 'Madrid, Spain', 'Manchester City'),
('c0c7ff58', 'ESP', 'Fabián Ruiz Peña', 'MF', 8, '1996-04-03', 'Los Palacios y Villafranca, Spain', 'PSG'),
('5dcf3e90', 'ESP', 'Unai Simón', 'GK', 23, '1997-06-11', 'Gasteiz / Vitoria, Spain', 'Athletic Club'),
('9e1035f8', 'ESP', 'Ferrán Torres', 'FW', 7, '2000-02-29', 'Foios, Spain', 'Barcelona'),
('afdc14d7', 'ESP', 'Nico Williams', 'MF', 17, '2002-07-12', 'Pamplona, Spain', 'Athletic Club'),
('82ec26c1', 'ESP', 'Lamine Yamal', 'FW', 19, '2007-07-13', 'Mataró, Spain', 'Barcelona'),
('3ee0dd59', 'ESP', 'Martín Zubimendi', 'MF', 18, '1999-02-02', 'Donostia / San Sebastián, Spain', 'Arsenal'),
('da4b8a4e', 'SWE', 'Taha Ali', 'FW,MF', 26, '1998-07-01', 'Tensta, Sweden', 'Malmö'),
('f173303a', 'SWE', 'Yasin Ayari', 'MF', 18, '2003-10-06', 'Solna Kommun, Sweden', 'Brighton'),
('a109e5c8', 'SWE', 'Lucas Bergvall', 'MF', 7, '2006-02-02', 'Stockholm, Sweden', 'Tottenham'),
('dea1d183', 'SWE', 'Alexander Bernhardsson', 'MF', 21, '1998-09-08', 'Göteborg, Sweden', 'Holstein Kiel'),
('3d554589', 'SWE', 'Hjalmar Ekdal', 'DF', 14, '1998-10-21', 'Stockholm, Sweden', 'Burnley'),
('2fba6108', 'SWE', 'Anthony Elanga', 'FW', 11, '2002-04-27', 'Malmö, Sweden', 'Newcastle'),
('d5d22a58', 'SWE', 'Gabriel Gudmundsson', 'MF,DF', 5, '1999-04-29', 'Malmö, Sweden', 'Leeds United'),
('4d5a9185', 'SWE', 'Viktor Gyökeres', 'FW', 17, '1998-06-04', 'Bromölla, Sweden', 'Arsenal'),
('12806697', 'SWE', 'Isak Hien', 'DF', 4, '1999-01-13', 'Stockholm, Sweden', 'Atalanta'),
('c2357b65', 'SWE', 'Emil Holm', 'DF,MF', NULL, '2000-05-13', 'Göteborg, Sweden', 'Juventus'),
('8e92be30', 'SWE', 'Alexander Isak', 'FW', 9, '1999-09-21', 'Solna, Sweden', 'Liverpool'),
('6f864562', 'SWE', 'Herman Johansson', 'MF', 6, '1997-10-16', 'Örnsköldsvik, Sweden', 'FC Dallas'),
('e4a588a7', 'SWE', 'Viktor Johansson', 'GK', 12, '1998-09-14', 'Stockholm, Sweden', 'Stoke City'),
('e0a1f4eb', 'SWE', 'Jesper Karlström', 'MF', 16, '1995-06-21', 'Stockholm, Sweden', 'Udinese'),
('9e39fa2d', 'SWE', 'Gustaf Lagerbielke', 'DF', 2, '2000-04-10', 'Stockholm, Sweden', 'Braga'),
('f5deef4c', 'SWE', 'Victor Lindelöf', 'DF,MF', 3, '1994-07-17', 'Västerås, Sweden', 'Aston Villa'),
('a7d48b00', 'SWE', 'Gustaf Nilsson', 'FW', 25, '1997-05-23', 'Falkenberg, Sweden', 'Club Brugge'),
('78549904', 'SWE', 'Kristoffer Nordfeldt', 'GK', 23, '1989-06-23', 'Stockholm, Sweden', 'AIK Stockholm'),
('d6ebf67f', 'SWE', 'Benjamin Nygren', 'MF', 10, '2001-07-08', 'Göteborg, Sweden', 'Celtic'),
('1770bd68', 'SWE', 'Ken Sema', 'FW,MF', 13, '1993-09-30', 'Norrköping, Sweden', 'Pafos FC'),
('8817312f', 'SWE', 'Eric Smith', 'DF,MF', 20, '1997-01-08', 'Halmstad, Sweden', 'St Pauli'),
('5cfec13d', 'SWE', 'Carl Starfelt', 'DF', 15, '1995-06-01', 'Stockholm, Sweden', 'Celta Vigo'),
('ff11bdec', 'SWE', 'Elliot Stroud', 'MF', 24, '2002-06-22', 'Uddevalla, Sweden', 'Mjällby'),
('92d83c27', 'SWE', 'Mattias Svanberg', 'MF', 19, '1999-01-05', 'NY, United States', 'Wolfsburg'),
('124c9382', 'SWE', 'Daniel Svensson', 'DF,MF', 8, '2002-02-12', 'Stockholm, Sweden', 'Dortmund'),
('ac5120d8', 'SWE', 'Jacob Widell Zetterström', 'GK', 1, '1998-07-11', 'Stockholm, Sweden', 'Derby County'),
('6be253bf', 'SWE', 'Besfort Zeneli', 'MF', 22, '2002-11-21', 'Säter, Sweden', 'Union SG'),
('f9c927de', 'SUI', 'Michel Aebischer', 'MF,FW', 20, '1997-01-06', 'Genève, Switzerland', 'Pisa'),
('89ac64a6', 'SUI', 'Manuel Akanji', 'DF', 5, '1995-07-19', 'Wiesendangen / Wiesendangen (Dorf), Switzerland', 'Inter'),
('2ee5b0c9', 'SUI', 'Zeki Amdouni', 'FW,MF', 23, '2000-12-04', 'Genève, Switzerland', 'Burnley'),
('1227a22d', 'SUI', 'Aurèle Amenda', 'DF', 24, '2003-07-31', 'Biel/Bienne, Switzerland', 'Frankfurt'),
('15937e17', 'SUI', 'Eray Cömert', 'DF', 18, '1998-02-04', 'Basel, Switzerland', 'Valencia'),
('48035304', 'SUI', 'Nico Elvedi', 'DF', 4, '1996-09-30', 'Zürich, Switzerland', 'Gladbach'),
('0b4f388a', 'SUI', 'Breel Embolo', 'FW', 7, '1997-02-14', 'Yaoundé, Cameroon', 'Rennes'),
('0aeeed3f', 'SUI', 'Christian Fassnacht', 'FW,MF', 16, '1993-11-11', 'Zürich, Switzerland', 'Young Boys'),
('98d2c2c4', 'SUI', 'Remo Freuler', 'MF', 8, '1992-04-15', 'Ennenda, Switzerland', 'Bologna'),
('ef233486', 'SUI', 'Cedric Itten', 'FW,MF', 26, '1996-12-27', 'Basel, Switzerland', 'Düsseldorf'),
('a400da8e', 'SUI', 'Luca Jaquez', 'DF', 25, '2003-06-02', 'Luzern, Switzerland', 'Stuttgart'),
('889588db', 'SUI', 'Ardon Jashari', 'MF', 14, '2002-07-30', 'Cham, Switzerland', 'Milan'),
('80d5345f', 'SUI', 'Marvin Keller', 'GK', 21, '2002-07-03', 'London, England, United Kingdom', 'Young Boys'),
('cd59b9df', 'SUI', 'Gregor Kobel', 'GK', 1, '1997-12-06', 'Zürich, Switzerland', 'Dortmund'),
('8fcf0e12', 'SUI', 'Johan Manzambi', 'FW', 9, '2005-10-14', 'Genève, Switzerland', 'Freiburg'),
('844c6a91', 'SUI', 'Miro Muheim', 'DF,MF', 2, '1998-03-24', 'Zürich, Switzerland', 'Hamburger SV'),
('dc29b608', 'SUI', 'Yvon Mvogo', 'GK', 12, '1994-06-06', 'Marly, Switzerland', 'Lorient'),
('8e697a8f', 'SUI', 'Dan Ndoye', 'MF,FW', 11, '2000-10-25', 'Nyon, Switzerland', 'Nottingham'),
('ca607d59', 'SUI', 'Noah Okafor', 'FW,MF', 19, '2000-05-24', 'Binningen, Switzerland', 'Leeds United'),
('c2bd8585', 'SUI', 'Fabian Rieder', 'MF', 22, '2002-02-16', 'Koppigen, Switzerland', 'Augsburg'),
('7f78ad23', 'SUI', 'Ricardo Rodríguez', 'DF', 13, '1992-08-25', 'Zürich, Switzerland', 'Real Betis'),
('4c6facae', 'SUI', 'Djibril Sow', 'MF', 15, '1997-02-06', 'Zürich, Switzerland', 'Sevilla'),
('6ecbddf6', 'SUI', 'Ruben Vargas', 'MF', 17, '1998-08-05', 'Adligenswil, Switzerland', 'Sevilla'),
('f68b64fc', 'SUI', 'Silvan Widmer', 'DF', 3, '1993-03-05', 'Aarau, Switzerland', 'Mainz 05'),
('e61b8aee', 'SUI', 'Granit Xhaka', 'MF', 10, '1992-09-27', 'Basel, Switzerland', 'Sunderland'),
('384d58d9', 'SUI', 'Denis Zakaria', 'DF', 6, '1996-11-20', 'Kinshasa, Congo DR', 'Monaco'),
('ad7cdb35', 'TUN', 'Ali Abdi', 'DF', 2, '1993-12-20', 'Sfax, Tunisia', 'Nice'),
('4dd2a0be', 'TUN', 'Elias Achouri', 'FW,MF', 7, '1999-02-10', 'Saint-Denis, Réunion', 'FC Copenhagen'),
('9fce7801', 'TUN', 'Adem Arous', 'DF', 5, '2004-07-17', 'Medina, Saudi Arabia', 'Kasımpaşa'),
('9370f210', 'TUN', 'Khalil Ayari', 'FW', 14, '2005-02-02', 'Tunis, Tunisia', 'PSG'),
('ab8ef45d', 'TUN', 'Sabri Ben Hassen', 'GK', 22, '1996-06-13', 'Sfax, Tunisia', 'Étoile du Sahel'),
('1798891a', 'TUN', 'Mortadha Ben Ouanes', 'DF,MF', 12, '1994-07-02', 'Sousse, Tunisia', 'Kasımpaşa'),
('9ade9ce1', 'TUN', 'Anis Ben Slimane', 'MF,FW', 25, '2001-03-16', 'Copenhagen, Denmark', 'Norwich City'),
('edd81e2a', 'TUN', 'Dylan Bronn', 'DF', 6, '1995-06-19', 'Cannes, France', 'Servette FC'),
('9627f87b', 'TUN', 'Mouhib Chamakh', 'GK', 1, '2001-08-25', 'Medenine, Tunisia', 'Club Africain'),
('7fa8ef98', 'TUN', 'Firas Chaouat', 'FW', 19, '1996-05-08', 'Sfax, Tunisia', 'Club Africain'),
('e2161158', 'TUN', 'Raed Chikhaoui', 'DF', 24, '2004-06-09', 'Sakiet Ezzit, Tunisia', 'Monastir'),
('8bf49030', 'TUN', 'Aymen Dahmen', 'GK', 16, '1997-01-28', 'Sfax, Tunisia', 'Ahly Sfaxien'),
('7cd21bce', 'TUN', 'Rayan Elloumi', 'FW', 18, '2007-09-17', 'St. Albert, AB, Canada', 'Vancouver'),
('5b3cfa12', 'TUN', 'Ismaël Gharbi', 'MF', 11, '2004-04-10', 'Paris, France', 'Augsburg'),
('2a5e8f82', 'TUN', 'Mohamed Amine Ben Hamida', 'DF', 21, '1995-12-15', 'Tunis, Tunisia', 'Espérance Tunis'),
('59e4b92e', 'TUN', 'Rani Khedira', 'MF', 13, '1994-01-27', 'Stuttgart, Germany', 'Union Berlin'),
('081048c2', 'TUN', 'Hadj Mahmoud', 'MF', 15, '2000-04-24', 'Sousse, Tunisia', 'Lugano'),
('c88f913e', 'TUN', 'Hazem Mastouri', 'FW', 9, '1997-06-18', 'Tunis, Tunisia', 'D. Makhachkala'),
('ca22ccb0', 'TUN', 'Hannibal Mejbri', 'MF', 10, '2003-01-21', 'Ivry-sur-Seine, France', 'Burnley'),
('f440d45f', 'TUN', 'Moutaz Neffati', 'DF', 23, '2004-09-04', 'Norrköping, Sweden', 'Norrköping'),
('e69e0f7b', 'TUN', 'Omar Rekik', 'DF', 4, '2001-12-20', 'Gemeente Helmond, Netherlands', 'NK Maribor'),
('78a2284f', 'TUN', 'Elias Saad', 'MF,FW', 8, '1999-12-27', 'Hamburg, Germany', 'Hannover 96'),
('c2211709', 'TUN', 'Ellyes Skhiri', 'MF,DF', 17, '1995-05-10', 'Lunel, France', 'Frankfurt'),
('a4a44eb0', 'TUN', 'Montassar Talbi', 'DF', 3, '1998-05-26', 'Paris, France', 'Lorient'),
('584fee1f', 'TUN', 'Sebastian Tounekti', 'FW', 26, '2002-07-13', 'Tromsø, Norway', 'Celtic'),
('531a4aa8', 'TUN', 'Yan Valery', 'DF', 20, '1999-02-22', 'Champigny-sur-Marne, France', 'Young Boys'),
('7328bee5', 'TUR', 'Samet Akaydın', 'DF', 25, '1994-03-13', 'Turkey', 'Rizespor'),
('1453e3cf', 'TUR', 'Yunus Akgün', 'MF', 19, '2000-07-07', 'Küçükçekmece, Turkey', 'Galatasaray'),
('f28659fb', 'TUR', 'Kerem Aktürkoğlu', 'FW', 7, '1998-10-21', 'Kocaeli, Turkey', 'Fenerbahçe'),
('414b2ce4', 'TUR', 'Barış Alper Yılmaz', 'MF,FW', 21, '2000-05-23', 'Turkey', 'Galatasaray'),
('a7b98226', 'TUR', 'Oğuz Aydın', 'DF', 24, '2000-10-27', 'Gemeente Den Haag, Netherlands', 'Fenerbahçe'),
('2200181e', 'TUR', 'Kaan Ayhan', 'DF,MF', 22, '1994-11-10', 'Gelsenkirchen, Germany', 'Galatasaray'),
('5d9cff53', 'TUR', 'Abdülkerim Bardakcı', 'DF', 14, '1994-09-07', 'Meram, Turkey', 'Galatasaray'),
('072e68ed', 'TUR', 'Altay Bayındır', 'GK', 12, '1998-04-14', 'Turkey', 'Manchester Utd'),
('f63a8347', 'TUR', 'Uğurcan Çakır', 'GK', 23, '1996-04-05', 'Antalya, Turkey', 'Galatasaray'),
('cd0fa27b', 'TUR', 'Hakan Çalhanoğlu', 'MF', 10, '1994-02-08', 'Mannheim, Germany', 'Inter'),
('d2800f47', 'TUR', 'İrfan Can Kahveci', 'MF', 17, '1995-07-15', 'Çorum, Turkey', 'Kasımpaşa'),
('31a62dc7', 'TUR', 'Zeki Çelik', 'DF', 2, '1997-02-17', 'Yıldırım, Turkey', 'Roma'),
('e3cceee6', 'TUR', 'Merih Demiral', 'DF', 3, '1998-03-05', 'Karamürsel İlçesi, Turkey', 'Al-Ahli'),
('8eeb8ba4', 'TUR', 'Eren Elmalı', 'DF', 13, '2000-07-07', 'Kartal, Turkey', 'Galatasaray'),
('f0fb443e', 'TUR', 'Deniz Gül', 'FW', 9, '2004-07-02', 'Stockholm, Sweden', 'Porto'),
('3741ca58', 'TUR', 'Arda Güler', 'MF', 8, '2005-02-25', 'Altındağ, Turkey', 'Real Madrid'),
('b583aef5', 'TUR', 'Mert Günok', 'GK', 1, '1989-03-01', 'Karabük, Turkey', 'Fenerbahçe'),
('2d61d13a', 'TUR', 'Ozan Kabak', 'DF', 15, '2000-03-25', 'Çankaya, Turkey', 'Hoffenheim'),
('66c52a77', 'TUR', 'Ferdi Kadioglu', 'DF', 20, '1999-10-07', 'Gemeente Arnhem, Netherlands', 'Brighton'),
('9bf914b4', 'TUR', 'Orkun Kökçü', 'MF', 6, '2000-12-29', 'Haarlem, Netherlands', 'Beşiktaş'),
('1295552e', 'TUR', 'Mert Müldür', 'DF', 18, '1999-04-03', 'Austria', 'Fenerbahçe'),
('15413fa5', 'TUR', 'Salih Özcan', 'MF', 5, '1998-01-11', 'Köln, Germany', 'Dortmund'),
('21166ff4', 'TUR', 'Çağlar Söyüncü', 'DF', 4, '1996-05-23', 'İzmir, Turkey', 'Fenerbahçe'),
('1d0b134a', 'TUR', 'Can Uzun', 'MF', 26, '2005-11-11', 'Regensburg, Germany', 'Frankfurt'),
('d8cda243', 'TUR', 'Kenan Yıldız', 'MF', 11, '2005-05-04', 'Regensburg, Germany', 'Juventus'),
('6c5af908', 'TUR', 'İsmail Yüksek', 'MF', 16, '1999-01-26', 'İznik, Turkey', 'Fenerbahçe'),
('5bc43860', 'USA', 'Brenden Aaronson', 'MF', 11, '2000-10-22', 'Medford, NJ, United States', 'Leeds United'),
('2b09d998', 'USA', 'Tyler Adams', 'MF', 4, '1999-02-14', 'Wappingers Falls, NY, United States', 'Bournemouth'),
('668f881e', 'USA', 'Max Arfsten', 'MF', 18, '2001-04-19', 'Fresno, TX, United States', 'Columbus Crew'),
('31822f8c', 'USA', 'Folarin Balogun', 'FW', 20, '2001-07-03', 'Brooklyn, NY, United States', 'Monaco'),
('f33ee427', 'USA', 'Sebastian Berhalter', 'MF', 14, '2001-05-10', 'London, England, United Kingdom', 'Vancouver'),
('a71768a2', 'USA', 'Chris Brady', 'GK', 25, '2004-03-03', 'Naperville, IL, United States', 'Chicago Fire'),
('5976f83e', 'USA', 'Sergiño Dest', 'MF', 2, '2000-11-03', 'Almere Stad, Netherlands', 'PSV'),
('754f150b', 'USA', 'Alex Freeman', 'DF', 16, '2004-08-09', 'Baltimore, MD, United States', 'Villarreal'),
('2f49476c', 'USA', 'Matt Freese', 'GK', 24, '1998-09-02', 'Wayne, PA, United States', 'NYCFC'),
('01c3aff5', 'USA', 'Weston McKennie', 'MF', 8, '1998-08-28', 'Little Elm, TX, United States', 'Juventus'),
('a5f5d094', 'USA', 'Mark McKenzie', 'DF', 22, '1999-02-25', 'The Bronx, NY, United States', 'Toulouse'),
('a2b1ed42', 'USA', 'Ricardo Pepi', 'FW', 9, '2003-01-09', 'El Paso, TX, United States', 'PSV'),
('1bf33a9a', 'USA', 'Christian Pulisic', 'MF', 10, '1998-09-18', 'Easton, PA, United States', 'Milan'),
('28b40c9c', 'USA', 'Tim Ream', 'DF', 13, '1987-10-05', 'St. Louis, MO, United States', 'Charlotte'),
('7fa4e703', 'USA', 'Gio Reyna', 'MF', 7, '2002-11-13', 'Durham, England, United Kingdom', 'Gladbach'),
('0a3d6d2b', 'USA', 'Chris Richards', 'DF', 3, '2000-03-28', 'Birmingham, AL, United States', 'Crystal Palace'),
('289601e6', 'USA', 'Antonee Robinson', 'MF,DF', 5, '1997-08-08', 'Milton Keynes, England, United Kingdom', 'Fulham'),
('782a95d9', 'USA', 'Miles Robinson', 'DF', 12, '1997-03-14', 'Arlington, MA, United States', 'FC Cincinnati'),
('48875649', 'USA', 'Cristian Roldan', 'MF', 15, '1995-06-03', 'Pico Rivera, CA, United States', 'Seattle Sounders'),
('236f02cd', 'USA', 'Joe Scally', 'DF', 23, '2002-12-31', 'Lake Grove, NY, United States', 'Gladbach'),
('a5420709', 'USA', 'Malik Tillman', 'MF', 17, '2002-05-28', 'Nürnberg, Germany', 'Leverkusen'),
('cddf767b', 'USA', 'Auston Trusty', 'DF', 6, '1998-08-12', 'Media, PA, United States', 'Celtic'),
('4a51ba65', 'USA', 'Matt Turner', 'GK', 1, '1994-06-24', 'Park Ridge, NJ, United States', 'NE Revolution'),
('8eec784d', 'USA', 'Timothy Weah', 'MF', 21, '2000-02-22', 'Brooklyn, NY, United States', 'Marseille'),
('91cd37b7', 'USA', 'Haji Wright', 'FW,MF', 19, '1998-03-27', 'Los Angeles, CA, United States', 'Coventry City'),
('d717b80e', 'USA', 'Alejandro Zendejas', 'FW,MF', 26, '1998-02-07', 'Ciudad Juárez, Estado de Chihuahua, Mexico', 'América'),
('b5691f5d', 'URU', 'Rodrigo Aguirre', 'FW', 19, '1994-10-01', 'Montevideo, Uruguay', 'América'),
('f9ab3f4a', 'URU', 'Maxi Araújo', 'MF,FW', 20, '2000-02-15', 'Montevideo, Uruguay', 'Sporting CP'),
('2bef2bca', 'URU', 'Ronald Araújo', 'DF', 4, '1999-03-07', 'Rivera, Uruguay', 'Barcelona'),
('be8d02dd', 'URU', 'Giorgian de Arrascaeta', 'FW,MF', 10, '1994-06-01', 'Nuevo Berlín, Uruguay', 'Flamengo'),
('3b8674e6', 'URU', 'Rodrigo Bentancur', 'MF', 6, '1997-06-25', 'Colonia del Sacramento, Uruguay', 'Tottenham'),
('edc98fac', 'URU', 'Santiago Bueno', 'DF', 24, '1998-11-09', 'Montevideo, Uruguay', 'Wolves'),
('7091c68e', 'URU', 'Sebastián Cáceres', 'DF', 3, '1999-08-18', 'Montevideo, Uruguay', 'América'),
('4f5a2f38', 'URU', 'Agustín Canobbio', 'FW', 14, '1998-10-01', 'Montevideo, Uruguay', 'Fluminense'),
('8fda5c72', 'URU', 'Nicolás De La Cruz', 'MF', 7, '1997-06-01', 'Montevideo, Uruguay', 'Flamengo'),
('f1d74479', 'URU', 'Juan Manuel Sanabria', 'DF', 25, '2000-03-29', 'Florida, Uruguay', 'Atlético San Luis'),
('f0da930c', 'URU', 'José María Giménez', 'DF', 2, '1995-01-20', 'Toledo, Uruguay', 'Atlético Madrid'),
('52061089', 'URU', 'Emiliano Martínez', 'MF', 15, '1999-08-17', 'Punta del Este, Uruguay', 'Palmeiras'),
('62849d22', 'URU', 'Santiago Mele', 'GK', 12, '1997-09-06', 'Montevideo, Uruguay', 'Junior'),
('a2abe631', 'URU', 'Fernando Muslera', 'GK', 23, '1986-06-16', 'Buenos Aires, Argentina', 'Galatasaray'),
('4d77b365', 'URU', 'Darwin Núñez', 'FW', 9, '1999-06-24', 'Artigas, Uruguay', 'Al-Hilal'),
('41c12f75', 'URU', 'Mathías Olivera', 'DF', 16, '1997-10-31', 'Montevideo, Uruguay', 'Napoli'),
('ac7e7b1c', 'URU', 'Facundo Pellistri', 'FW,MF', 11, '2001-12-20', 'Montevideo, Uruguay', 'Panathinaikos'),
('46009f44', 'URU', 'Joaquín Piquerez', 'DF,MF', 22, '1998-08-24', 'Montevideo, Uruguay', 'Palmeiras'),
('81b99b9e', 'URU', 'Sergio Rochet', 'GK', 1, '1993-03-23', 'Nueva Palmira, Uruguay', 'Internacional'),
('c86041d7', 'URU', 'Brian Rodríguez', 'FW,MF', 18, '2000-05-20', 'Tranqueras, Uruguay', 'América'),
('c9817014', 'URU', 'Manuel Ugarte', 'MF', 5, '2001-04-11', 'Montevideo, Uruguay', 'Manchester Utd'),
('0959c2a2', 'URU', 'Federico Valverde', 'MF', 8, '1998-07-22', 'Montevideo, Uruguay', 'Real Madrid'),
('5c961282', 'URU', 'Guillermo Varela', 'DF', 13, '1993-03-24', 'Montevideo, Uruguay', 'Flamengo'),
('08eb3b58', 'URU', 'Matías Viña', 'DF', 17, '1997-11-09', 'Empalme Olmos, Uruguay', 'Flamengo'),
('d30c7094', 'URU', 'Federico Viñas', 'FW', 21, '1998-06-30', 'Montevideo, Uruguay', 'Oviedo'),
('fc3697dd', 'URU', 'Rodrigo Zalazar', 'FW,MF', 26, '1999-08-12', 'Albacete, Spain', 'Braga'),
('03053fbf', 'UZB', 'Abdulla Abdullaev', 'DF', 18, '1997-09-01', 'Qo''rg''ontepa, Uzbekistan', 'Dibba Al Fujairah'),
('e53cbd7a', 'UZB', 'Khojiakbar Alijonov', 'DF', 3, '1997-04-19', 'Toshkent, Uzbekistan', 'Pakhtakor Tashkent FK'),
('f487314f', 'UZB', 'Azizbek Amonov', 'FW', 20, '1997-10-30', 'Zarafshon, Uzbekistan', 'FK Bukhara Nurafshon'),
('a0ecd397', 'UZB', 'Rustam Ashurmatov', 'DF', 5, '1996-07-07', 'Qo''qon, Uzbekistan', 'Esteghlal'),
('7fbb2bac', 'UZB', 'Botirali Ergashev', 'GK', 16, '1995-06-23', 'Pop, Uzbekistan', 'Neftchi FK'),
('bd6667ba', 'UZB', 'Sherzod Esanov', 'MF', 23, '2003-02-01', 'Navoiy, Uzbekistan', 'FK Bukhara Nurafshon'),
('d7cb0b13', 'UZB', 'Umar Eshmurodov', 'DF', 15, '1992-11-30', 'Koson, Uzbekistan', 'FC Nasaf'),
('ef1d36a1', 'UZB', 'Abbosbek Fayzullayev', 'MF', 22, '2003-10-03', 'Sirdaryo, Uzbekistan', 'Başakşehir'),
('e00fa339', 'UZB', 'Aziz Ganiev', 'MF', 19, '1998-02-22', 'Jizzax, Uzbekistan', 'Al Bataeh'),
('03f63e77', 'UZB', 'Odiljon Hamrobekov', 'MF', 9, '1996-02-13', 'Namingan, Uzbekistan', 'Tractor'),
('3b8abe7c', 'UZB', 'Jamshid Iskanderov', 'FW,MF', 8, '1993-10-16', 'Uzbekistan', 'Neftchi FK'),
('3c181746', 'UZB', 'Ruslanbek Jiyanov', 'FW', 10, '2001-06-05', 'Uzbekistan', 'Navbahor'),
('74cdaeba', 'UZB', 'Bekhruz Karimov', 'DF', 24, '2007-08-07', 'Namangan, Uzbekistan', 'FC Surkhon'),
('d2dd2ffb', 'UZB', 'Dostonbek Khamdamov', 'MF', 17, '1996-07-24', 'Bekobod, Uzbekistan', 'Pakhtakor Tashkent FK'),
('d17ce930', 'UZB', 'Abdukodir Khusanov', 'DF', 2, '2004-02-29', 'Toshkent, Uzbekistan', 'Manchester City'),
('e309042b', 'UZB', 'Jaloliddin Masharipov', 'FW,MF', NULL, '1993-09-01', 'Uzbekistan', 'Esteghlal'),
('114cb95b', 'UZB', 'Akmal Mozgovoy', 'MF', 6, '1999-04-02', 'Qarshi, Uzbekistan', 'Pakhtakor Tashkent FK'),
('aeb0c7f7', 'UZB', 'Sherzod Nasrullaev', 'DF', 13, '1998-07-23', 'Koson, Uzbekistan', 'FC Nasaf'),
('25e45f2a', 'UZB', 'Abduvohid Nematov', 'GK', 12, '2001-03-20', 'Jizzax, Uzbekistan', 'FC Nasaf'),
('bad66fb5', 'UZB', 'Farrukh Sayfiev', 'DF,MF', 4, '1991-01-17', 'Samarkand, Uzbekistan', 'Neftchi FK'),
('8df41977', 'UZB', 'Igor Sergeev', 'FW', 21, '1993-04-30', 'Uzbekistan', 'Persepolis'),
('57469b2d', 'UZB', 'Eldor Shomurodov', 'FW', 14, '1995-06-29', 'Jarqo''rg''on, Uzbekistan', 'Başakşehir'),
('62032a56', 'UZB', 'Otabek Shukurov', 'MF', 7, '1996-06-22', 'Chiroqchi, Uzbekistan', 'Baniyas FC'),
('e30a1d73', 'UZB', 'Avazbek Ulmasaliev', 'DF', 25, '2000-03-27', 'Fergana, Uzbekistan', 'OKMK'),
('71210bed', 'UZB', 'Jakhongir Urozov', 'DF', 26, '2004-01-18', 'Zomin, Uzbekistan', 'FK Dinamo Samarqand'),
('56521adf', 'UZB', 'Oston Urunov', 'MF', 11, '2000-12-19', 'Navoiy, Uzbekistan', 'Persepolis'),
('31caffaf', 'UZB', 'Utkir Yusupov', 'GK', 1, '1991-01-04', 'Sayramsu, Kazakhstan', 'Navbahor');


-- ============================================================
-- GROUP STAGE MATCHES (72 total, goals NULL until played)
-- Dates verified against Wikipedia schedule 2026-06-17
-- MD1: A→Jun11 | B→Jun12/13 | C→Jun13 | D→Jun12/13 | E/F→Jun14 | G/H→Jun15 | I/J→Jun16 | K/L→Jun17
-- MD2: A/B→Jun18 | C/D→Jun19 | E/F→Jun20 | G/H→Jun21 | I/J→Jun22 | K/L→Jun23
-- MD3: A/B/C→Jun24 | D/E/F→Jun25 | G/H/I→Jun26 | J/K/L→Jun27 (simultaneous per group)
-- ============================================================
INSERT INTO stadiums (stadium_id, name, city, state, country, capacity, timezone, elevation_m, surface_native, surface_wc, roof) VALUES
(1, 'AT&T Stadium', 'Arlington', 'Texas', 'USA', 94000, 'America/Chicago', 180, 'Artificial turf', 'Grass', 'Retractable'),
(2, 'Estadio Azteca', 'Mexico City', 'Ciudad de México', 'Mexico', 83000, 'America/Mexico_City', 2240, 'Grass', 'Grass', 'Open'),
(3, 'MetLife Stadium', 'East Rutherford', 'New Jersey', 'USA', 82500, 'America/New_York', 7, 'Artificial turf', 'Grass', 'Open'),
(4, 'Mercedes-Benz Stadium', 'Atlanta', 'Georgia', 'USA', 75000, 'America/New_York', 320, 'Artificial turf', 'Grass', 'Retractable'),
(5, 'Arrowhead Stadium', 'Kansas City', 'Missouri', 'USA', 73000, 'America/Chicago', 270, 'Grass', 'Grass', 'Open'),
(6, 'NRG Stadium', 'Houston', 'Texas', 'USA', 72000, 'America/Chicago', 15, 'Artificial turf', 'Grass', 'Retractable'),
(7, 'Levi''s Stadium', 'Santa Clara', 'California', 'USA', 71000, 'America/Los_Angeles', 3, 'Grass', 'Grass', 'Open'),
(8, 'SoFi Stadium', 'Inglewood', 'California', 'USA', 70000, 'America/Los_Angeles', 30, 'Artificial turf', 'Grass', 'Fixed canopy'),
(9, 'Lincoln Financial Field', 'Philadelphia', 'Pennsylvania', 'USA', 69000, 'America/New_York', 10, 'Grass', 'Grass', 'Open'),
(10, 'Lumen Field', 'Seattle', 'Washington', 'USA', 69000, 'America/Los_Angeles', 5, 'Artificial turf', 'Grass', 'Partial'),
(11, 'Gillette Stadium', 'Foxborough', 'Massachusetts', 'USA', 65000, 'America/New_York', 90, 'Artificial turf', 'Grass', 'Open'),
(12, 'Hard Rock Stadium', 'Miami Gardens', 'Florida', 'USA', 65000, 'America/New_York', 2, 'Grass', 'Grass', 'Canopy'),
(13, 'BC Place', 'Vancouver', 'British Columbia', 'Canada', 54000, 'America/Vancouver', 3, 'Artificial turf', 'Grass', 'Retractable'),
(14, 'Estadio BBVA', 'Guadalupe', 'Nuevo León', 'Mexico', 53500, 'America/Monterrey', 500, 'Grass', 'Grass', 'Open'),
(15, 'Estadio Akron', 'Zapopan', 'Jalisco', 'Mexico', 48000, 'America/Mexico_City', 1560, 'Grass', 'Grass', 'Open'),
(16, 'BMO Field', 'Toronto', 'Ontario', 'Canada', 45000, 'America/Toronto', 80, 'Artificial turf', 'Grass', 'Open');

INSERT INTO matches (match_id, fifa_match_no, team_home, team_away, goals_home, goals_away, stage, group_name, match_date, match_time, stadium, city, stadium_id) VALUES
-- Group A: MD1 Jun 11 | MD2 Jun 18 | MD3 Jun 24
(1, 1, 'MEX', 'RSA', NULL, NULL, 'group', 'A', '2026-06-11', '13:00', 'Estadio Azteca', 'Mexico City', 2),
(2, 2, 'KOR', 'CZE', NULL, NULL, 'group', 'A', '2026-06-11', '20:00', 'Estadio Akron', 'Guadalajara', 15),
(3, 28, 'MEX', 'KOR', NULL, NULL, 'group', 'A', '2026-06-18', '19:00', 'Estadio Akron', 'Guadalajara', 15),
(4, 25, 'CZE', 'RSA', NULL, NULL, 'group', 'A', '2026-06-18', '10:00', 'Mercedes-Benz Stadium', 'Atlanta', 4),
(5, 53, 'CZE', 'MEX', NULL, NULL, 'group', 'A', '2026-06-24', '19:00', 'Estadio Azteca', 'Mexico City', 2),
(6, 54, 'RSA', 'KOR', NULL, NULL, 'group', 'A', '2026-06-24', '19:00', 'Estadio BBVA', 'Monterrey', 14),
-- Group B: MD1 Jun 12 (CAN) / Jun 13 (QAT) | MD2 Jun 18 | MD3 Jun 24
(7, 3, 'CAN', 'BIH', NULL, NULL, 'group', 'B', '2026-06-12', '13:00', 'BMO Field', 'Toronto', 16),
(8, 5, 'QAT', 'SUI', NULL, NULL, 'group', 'B', '2026-06-13', '13:00', 'Levi''s Stadium', 'San Francisco Bay Area', 7),
(9, 27, 'CAN', 'QAT', NULL, NULL, 'group', 'B', '2026-06-18', '16:00', 'BC Place', 'Vancouver', 13),
(10, 26, 'SUI', 'BIH', NULL, NULL, 'group', 'B', '2026-06-18', '13:00', 'SoFi Stadium', 'Los Angeles', 8),
(11, 49, 'SUI', 'CAN', NULL, NULL, 'group', 'B', '2026-06-24', '13:00', 'BC Place', 'Vancouver', 13),
(12, 50, 'BIH', 'QAT', NULL, NULL, 'group', 'B', '2026-06-24', '13:00', 'Lumen Field', 'Seattle', 10),
-- Group C: MD1 Jun 13 | MD2 Jun 19 | MD3 Jun 24
(13, 6, 'BRA', 'MAR', NULL, NULL, 'group', 'C', '2026-06-13', '16:00', 'MetLife Stadium', 'New York/New Jersey', 3),
(14, 7, 'HAI', 'SCO', NULL, NULL, 'group', 'C', '2026-06-13', '19:00', 'Gillette Stadium', 'Boston', 11),
(15, 31, 'BRA', 'HAI', NULL, NULL, 'group', 'C', '2026-06-19', '18:30', 'Lincoln Financial Field', 'Philadelphia', 9),
(16, 30, 'SCO', 'MAR', NULL, NULL, 'group', 'C', '2026-06-19', '16:00', 'Gillette Stadium', 'Boston', 11),
(17, 51, 'SCO', 'BRA', NULL, NULL, 'group', 'C', '2026-06-24', '16:00', 'Hard Rock Stadium', 'Miami', 12),
(18, 52, 'MAR', 'HAI', NULL, NULL, 'group', 'C', '2026-06-24', '16:00', 'Mercedes-Benz Stadium', 'Atlanta', 4),
-- Group D: MD1 Jun 12 (USA) / Jun 13 (AUS) | MD2 Jun 19 | MD3 Jun 25
(19, 4, 'USA', 'PAR', NULL, NULL, 'group', 'D', '2026-06-12', '19:00', 'SoFi Stadium', 'Los Angeles', 8),
(20, 8, 'AUS', 'TUR', NULL, NULL, 'group', 'D', '2026-06-13', '22:00', 'BC Place', 'Vancouver', 13),
(21, 29, 'USA', 'AUS', NULL, NULL, 'group', 'D', '2026-06-19', '13:00', 'Lumen Field', 'Seattle', 10),
(22, 32, 'TUR', 'PAR', NULL, NULL, 'group', 'D', '2026-06-19', '21:00', 'Levi''s Stadium', 'San Francisco Bay Area', 7),
(23, 59, 'TUR', 'USA', NULL, NULL, 'group', 'D', '2026-06-25', '20:00', 'SoFi Stadium', 'Los Angeles', 8),
(24, 60, 'PAR', 'AUS', NULL, NULL, 'group', 'D', '2026-06-25', '20:00', 'Levi''s Stadium', 'San Francisco Bay Area', 7),
-- Group E: MD1 Jun 14 | MD2 Jun 20 | MD3 Jun 25
(25, 9, 'GER', 'CUW', NULL, NULL, 'group', 'E', '2026-06-14', '11:00', 'NRG Stadium', 'Houston', 6),
(26, 11, 'CIV', 'ECU', NULL, NULL, 'group', 'E', '2026-06-14', '17:00', 'Lincoln Financial Field', 'Philadelphia', 9),
(27, 34, 'GER', 'CIV', NULL, NULL, 'group', 'E', '2026-06-20', '14:00', 'BMO Field', 'Toronto', 16),
(28, 35, 'ECU', 'CUW', NULL, NULL, 'group', 'E', '2026-06-20', '18:00', 'Arrowhead Stadium', 'Kansas City', 5),
(29, 56, 'ECU', 'GER', NULL, NULL, 'group', 'E', '2026-06-25', '14:00', 'MetLife Stadium', 'New York/New Jersey', 3),
(30, 55, 'CUW', 'CIV', NULL, NULL, 'group', 'E', '2026-06-25', '14:00', 'Lincoln Financial Field', 'Philadelphia', 9),
-- Group F: MD1 Jun 14 | MD2 Jun 20 | MD3 Jun 25
(31, 10, 'NED', 'JPN', NULL, NULL, 'group', 'F', '2026-06-14', '14:00', 'AT&T Stadium', 'Dallas', 1),
(32, 12, 'SWE', 'TUN', NULL, NULL, 'group', 'F', '2026-06-14', '20:00', 'Estadio BBVA', 'Monterrey', 14),
(33, 33, 'NED', 'SWE', NULL, NULL, 'group', 'F', '2026-06-20', '11:00', 'NRG Stadium', 'Houston', 6),
(34, 36, 'TUN', 'JPN', NULL, NULL, 'group', 'F', '2026-06-20', '22:00', 'Estadio BBVA', 'Monterrey', 14),
(35, 58, 'TUN', 'NED', NULL, NULL, 'group', 'F', '2026-06-25', '17:00', 'Arrowhead Stadium', 'Kansas City', 5),
(36, 57, 'JPN', 'SWE', NULL, NULL, 'group', 'F', '2026-06-25', '17:00', 'AT&T Stadium', 'Dallas', 1),
-- Group G: MD1 Jun 15 | MD2 Jun 21 | MD3 Jun 26
(37, 14, 'BEL', 'EGY', NULL, NULL, 'group', 'G', '2026-06-15', '13:00', 'Lumen Field', 'Seattle', 10),
(38, 16, 'IRN', 'NZL', NULL, NULL, 'group', 'G', '2026-06-15', '19:00', 'SoFi Stadium', 'Los Angeles', 8),
(39, 38, 'BEL', 'IRN', NULL, NULL, 'group', 'G', '2026-06-21', '13:00', 'SoFi Stadium', 'Los Angeles', 8),
(40, 40, 'NZL', 'EGY', NULL, NULL, 'group', 'G', '2026-06-21', '19:00', 'BC Place', 'Vancouver', 13),
(41, 66, 'NZL', 'BEL', NULL, NULL, 'group', 'G', '2026-06-26', '21:00', 'BC Place', 'Vancouver', 13),
(42, 65, 'EGY', 'IRN', NULL, NULL, 'group', 'G', '2026-06-26', '21:00', 'Lumen Field', 'Seattle', 10),
-- Group H: MD1 Jun 15 | MD2 Jun 21 | MD3 Jun 26
(43, 13, 'ESP', 'CPV', NULL, NULL, 'group', 'H', '2026-06-15', '10:00', 'Mercedes-Benz Stadium', 'Atlanta', 4),
(44, 15, 'KSA', 'URU', NULL, NULL, 'group', 'H', '2026-06-15', '16:00', 'Hard Rock Stadium', 'Miami', 12),
(45, 37, 'ESP', 'KSA', NULL, NULL, 'group', 'H', '2026-06-21', '10:00', 'Mercedes-Benz Stadium', 'Atlanta', 4),
(46, 39, 'URU', 'CPV', NULL, NULL, 'group', 'H', '2026-06-21', '16:00', 'Hard Rock Stadium', 'Miami', 12),
(47, 64, 'URU', 'ESP', NULL, NULL, 'group', 'H', '2026-06-26', '18:00', 'Estadio Akron', 'Guadalajara', 15),
(48, 63, 'CPV', 'KSA', NULL, NULL, 'group', 'H', '2026-06-26', '18:00', 'NRG Stadium', 'Houston', 6),
-- Group I: MD1 Jun 16 | MD2 Jun 22 | MD3 Jun 26
(49, 17, 'FRA', 'SEN', NULL, NULL, 'group', 'I', '2026-06-16', '13:00', 'MetLife Stadium', 'New York/New Jersey', 3),
(50, 18, 'IRQ', 'NOR', NULL, NULL, 'group', 'I', '2026-06-16', '16:00', 'Gillette Stadium', 'Boston', 11),
(51, 42, 'FRA', 'IRQ', NULL, NULL, 'group', 'I', '2026-06-22', '15:00', 'Lincoln Financial Field', 'Philadelphia', 9),
(52, 43, 'NOR', 'SEN', NULL, NULL, 'group', 'I', '2026-06-22', '18:00', 'MetLife Stadium', 'New York/New Jersey', 3),
(53, 61, 'NOR', 'FRA', NULL, NULL, 'group', 'I', '2026-06-26', '13:00', 'Gillette Stadium', 'Boston', 11),
(54, 62, 'SEN', 'IRQ', NULL, NULL, 'group', 'I', '2026-06-26', '13:00', 'BMO Field', 'Toronto', 16),
-- Group J: MD1 Jun 16 | MD2 Jun 22 | MD3 Jun 27
(55, 19, 'ARG', 'ALG', NULL, NULL, 'group', 'J', '2026-06-16', '19:00', 'Arrowhead Stadium', 'Kansas City', 5),
(56, 20, 'AUT', 'JOR', NULL, NULL, 'group', 'J', '2026-06-16', '22:00', 'Levi''s Stadium', 'San Francisco Bay Area', 7),
(57, 41, 'ARG', 'AUT', NULL, NULL, 'group', 'J', '2026-06-22', '11:00', 'AT&T Stadium', 'Dallas', 1),
(58, 44, 'JOR', 'ALG', NULL, NULL, 'group', 'J', '2026-06-22', '21:00', 'Levi''s Stadium', 'San Francisco Bay Area', 7),
(59, 72, 'JOR', 'ARG', NULL, NULL, 'group', 'J', '2026-06-27', '20:00', 'AT&T Stadium', 'Dallas', 1),
(60, 71, 'ALG', 'AUT', NULL, NULL, 'group', 'J', '2026-06-27', '20:00', 'Arrowhead Stadium', 'Kansas City', 5),
-- Group K: MD1 Jun 17 | MD2 Jun 23 | MD3 Jun 27
(61, 21, 'POR', 'COD', NULL, NULL, 'group', 'K', '2026-06-17', '11:00', 'NRG Stadium', 'Houston', 6),
(62, 24, 'UZB', 'COL', NULL, NULL, 'group', 'K', '2026-06-17', '20:00', 'Estadio Azteca', 'Mexico City', 2),
(63, 45, 'POR', 'UZB', NULL, NULL, 'group', 'K', '2026-06-23', '11:00', 'NRG Stadium', 'Houston', 6),
(64, 48, 'COL', 'COD', NULL, NULL, 'group', 'K', '2026-06-23', '20:00', 'Estadio Akron', 'Guadalajara', 15),
(65, 69, 'COL', 'POR', NULL, NULL, 'group', 'K', '2026-06-27', '17:30', 'Hard Rock Stadium', 'Miami', 12),
(66, 70, 'COD', 'UZB', NULL, NULL, 'group', 'K', '2026-06-27', '17:30', 'Mercedes-Benz Stadium', 'Atlanta', 4),
-- Group L: MD1 Jun 17 | MD2 Jun 23 | MD3 Jun 27
(67, 22, 'ENG', 'CRO', NULL, NULL, 'group', 'L', '2026-06-17', '14:00', 'AT&T Stadium', 'Dallas', 1),
(68, 23, 'GHA', 'PAN', NULL, NULL, 'group', 'L', '2026-06-17', '17:00', 'BMO Field', 'Toronto', 16),
(69, 46, 'ENG', 'GHA', NULL, NULL, 'group', 'L', '2026-06-23', '14:00', 'Gillette Stadium', 'Boston', 11),
(70, 47, 'PAN', 'CRO', NULL, NULL, 'group', 'L', '2026-06-23', '17:00', 'BMO Field', 'Toronto', 16),
(71, 67, 'PAN', 'ENG', NULL, NULL, 'group', 'L', '2026-06-27', '15:00', 'MetLife Stadium', 'New York/New Jersey', 3),
(72, 68, 'CRO', 'GHA', NULL, NULL, 'group', 'L', '2026-06-27', '15:00', 'Lincoln Financial Field', 'Philadelphia', 9);

-- ============================================================
-- KNOCKOUT STAGE (matches 73-104)
-- team_home / team_away NULL until group stage settles.
-- Bracket per FIFA official draw; dates/venues TBD for R32-SF.
-- Source: Wikipedia 2026 FIFA World Cup knockout stage
-- ============================================================

-- ROUND OF 32 (Jun 28 – Jul 3)
-- Bracket positions (bracket label → feeds into R16 match):
--   73: RU-A vs RU-B   → feeds 90
--   74: W-E  vs B3-ABCDF → feeds 89
--   75: W-F  vs RU-C   → feeds 90
--   76: W-C  vs RU-F   → feeds 91
--   77: W-I  vs B3-CDFGH → feeds 89
--   78: RU-E vs RU-I   → feeds 91
--   79: W-A  vs B3-CEFHI → feeds 92
--   80: W-L  vs B3-EHIJK → feeds 92
--   81: W-D  vs B3-BEFIJ → feeds 94
--   82: W-G  vs B3-AEHIJ → feeds 94
--   83: RU-K vs RU-L   → feeds 93
--   84: W-H  vs RU-J   → feeds 93
--   85: W-B  vs B3-EFGIJ → feeds 96
--   86: W-J  vs RU-H   → feeds 95
--   87: W-K  vs B3-DEIJL → feeds 96
--   88: RU-D vs RU-G   → feeds 95
INSERT INTO matches (match_id, fifa_match_no, team_home, team_away, goals_home, goals_away, stage, group_name, match_date, match_time, stadium, city, stadium_id) VALUES
(73, 73, NULL, NULL, NULL, NULL, 'r32', 'knock-out', '2026-06-28', '13:00', 'SoFi Stadium', 'Los Angeles', 8),
(74, 74, NULL, NULL, NULL, NULL, 'r32', 'knock-out', '2026-06-29', '14:30', 'Gillette Stadium', 'Boston', 11),
(75, 75, NULL, NULL, NULL, NULL, 'r32', 'knock-out', '2026-06-29', '19:00', 'Estadio BBVA', 'Monterrey', 14),
(76, 76, NULL, NULL, NULL, NULL, 'r32', 'knock-out', '2026-06-29', '11:00', 'NRG Stadium', 'Houston', 6),
(77, 77, NULL, NULL, NULL, NULL, 'r32', 'knock-out', '2026-06-30', '15:00', 'MetLife Stadium', 'New York/New Jersey', 3),
(78, 78, NULL, NULL, NULL, NULL, 'r32', 'knock-out', '2026-06-30', '11:00', 'AT&T Stadium', 'Dallas', 1),
(79, 79, NULL, NULL, NULL, NULL, 'r32', 'knock-out', '2026-06-30', '19:00', 'Estadio Azteca', 'Mexico City', 2),
(80, 80, NULL, NULL, NULL, NULL, 'r32', 'knock-out', '2026-07-01', '10:00', 'Mercedes-Benz Stadium', 'Atlanta', 4),
(81, 81, NULL, NULL, NULL, NULL, 'r32', 'knock-out', '2026-07-01', '18:00', 'Levi''s Stadium', 'San Francisco Bay Area', 7),
(82, 82, NULL, NULL, NULL, NULL, 'r32', 'knock-out', '2026-07-01', '14:00', 'Lumen Field', 'Seattle', 10),
(83, 83, NULL, NULL, NULL, NULL, 'r32', 'knock-out', '2026-07-02', '17:00', 'BMO Field', 'Toronto', 16),
(84, 84, NULL, NULL, NULL, NULL, 'r32', 'knock-out', '2026-07-02', '13:00', 'SoFi Stadium', 'Los Angeles', 8),
(85, 85, NULL, NULL, NULL, NULL, 'r32', 'knock-out', '2026-07-02', '21:00', 'BC Place', 'Vancouver', 13),
(86, 86, NULL, NULL, NULL, NULL, 'r32', 'knock-out', '2026-07-03', '16:00', 'Hard Rock Stadium', 'Miami', 12),
(87, 87, NULL, NULL, NULL, NULL, 'r32', 'knock-out', '2026-07-03', '19:30', 'Arrowhead Stadium', 'Kansas City', 5),
(88, 88, NULL, NULL, NULL, NULL, 'r32', 'knock-out', '2026-07-03', '12:00', 'AT&T Stadium', 'Dallas', 1);

-- ROUND OF 16 (Jul 4–7)
-- 89: W74 vs W77 | 90: W73 vs W75 | 91: W76 vs W78 | 92: W79 vs W80
-- 93: W83 vs W84 | 94: W81 vs W82 | 95: W86 vs W88 | 96: W85 vs W87
INSERT INTO matches (match_id, fifa_match_no, team_home, team_away, goals_home, goals_away, stage, group_name, match_date, match_time, stadium, city, stadium_id) VALUES
(89, 89, NULL, NULL, NULL, NULL, 'r16', 'knock-out', '2026-07-04', '15:00', 'Lincoln Financial Field', 'Philadelphia', 9),
(90, 90, NULL, NULL, NULL, NULL, 'r16', 'knock-out', '2026-07-04', '11:00', 'NRG Stadium', 'Houston', 6),
(91, 91, NULL, NULL, NULL, NULL, 'r16', 'knock-out', '2026-07-05', '14:00', 'MetLife Stadium', 'New York/New Jersey', 3),
(92, 92, NULL, NULL, NULL, NULL, 'r16', 'knock-out', '2026-07-05', '18:00', 'Estadio Azteca', 'Mexico City', 2),
(93, 93, NULL, NULL, NULL, NULL, 'r16', 'knock-out', '2026-07-06', '13:00', 'AT&T Stadium', 'Dallas', 1),
(94, 94, NULL, NULL, NULL, NULL, 'r16', 'knock-out', '2026-07-06', '18:00', 'Lumen Field', 'Seattle', 10),
(95, 95, NULL, NULL, NULL, NULL, 'r16', 'knock-out', '2026-07-07', '10:00', 'Mercedes-Benz Stadium', 'Atlanta', 4),
(96, 96, NULL, NULL, NULL, NULL, 'r16', 'knock-out', '2026-07-07', '14:00', 'BC Place', 'Vancouver', 13);

-- QUARTERFINALS (Jul 9–11)
-- 97: W89 vs W90 | 98: W91 vs W92 | 99: W93 vs W94 | 100: W95 vs W96
INSERT INTO matches (match_id, fifa_match_no, team_home, team_away, goals_home, goals_away, stage, group_name, match_date, match_time, stadium, city, stadium_id) VALUES
(97, 97, NULL, NULL, NULL, NULL, 'qf', 'knock-out', '2026-07-09', '14:00', 'Gillette Stadium', 'Boston', 11),
(98, 98, NULL, NULL, NULL, NULL, 'qf', 'knock-out', '2026-07-10', '13:00', 'SoFi Stadium', 'Los Angeles', 8),
(99, 99, NULL, NULL, NULL, NULL, 'qf', 'knock-out', '2026-07-11', '15:00', 'Hard Rock Stadium', 'Miami', 12),
(100, 100, NULL, NULL, NULL, NULL, 'qf', 'knock-out', '2026-07-11', '19:00', 'Arrowhead Stadium', 'Kansas City', 5);

-- SEMIFINALS (Jul 14–15)
-- 101: W97 vs W98 | 102: W99 vs W100
INSERT INTO matches (match_id, fifa_match_no, team_home, team_away, goals_home, goals_away, stage, group_name, match_date, match_time, stadium, city, stadium_id) VALUES
(101, 101, NULL, NULL, NULL, NULL, 'sf', 'knock-out', '2026-07-14', '13:00', 'AT&T Stadium', 'Dallas', 1),
(102, 102, NULL, NULL, NULL, NULL, 'sf', 'knock-out', '2026-07-15', '13:00', 'Mercedes-Benz Stadium', 'Atlanta', 4);

-- THIRD PLACE (Jul 18)
INSERT INTO matches (match_id, fifa_match_no, team_home, team_away, goals_home, goals_away, stage, group_name, match_date, match_time, stadium, city, stadium_id) VALUES
(103, 103, NULL, NULL, NULL, NULL, 'third_place', 'knock-out', '2026-07-18', '15:00', 'Hard Rock Stadium', 'Miami', 12);

-- FINAL (Jul 19 — MetLife Stadium confirmed)
INSERT INTO matches (match_id, fifa_match_no, team_home, team_away, goals_home, goals_away, stage, group_name, match_date, match_time, stadium, city, stadium_id) VALUES
(104, 104, NULL, NULL, NULL, NULL, 'final', 'knock-out', '2026-07-19', '13:00', 'MetLife Stadium', 'New York/New Jersey', 3);

-- ============================================================
-- TEAM BASE CAMPS — city, State/Province
-- Source: Wikipedia "2026 FIFA World Cup" base camp table
-- Snapshot: 2026-06-17
-- ============================================================
UPDATE teams SET base_camp = 'Lawrence, Kansas'                WHERE team_id = 'ALG';
UPDATE teams SET base_camp = 'Kansas City, Missouri'           WHERE team_id = 'ARG';
UPDATE teams SET base_camp = 'Berkeley, California'            WHERE team_id = 'AUS';
UPDATE teams SET base_camp = 'Santa Barbara, California'       WHERE team_id = 'AUT';
UPDATE teams SET base_camp = 'Renton, Washington'              WHERE team_id = 'BEL';
UPDATE teams SET base_camp = 'Salt Lake City, Utah'            WHERE team_id = 'BIH';
UPDATE teams SET base_camp = 'Basking Ridge, New Jersey'       WHERE team_id = 'BRA';
UPDATE teams SET base_camp = 'Vancouver, British Columbia'     WHERE team_id = 'CAN';
UPDATE teams SET base_camp = 'Tampa, Florida'                  WHERE team_id = 'CPV';
UPDATE teams SET base_camp = 'Wilmington, Delaware'            WHERE team_id = 'CIV';
UPDATE teams SET base_camp = 'Houston, Texas'                  WHERE team_id = 'COD';
UPDATE teams SET base_camp = 'Guadalajara, Jalisco'            WHERE team_id = 'COL';
UPDATE teams SET base_camp = 'Alexandria, Virginia'            WHERE team_id = 'CRO';
UPDATE teams SET base_camp = 'Boca Raton, Florida'             WHERE team_id = 'CUW';
UPDATE teams SET base_camp = 'Mansfield, Texas'                WHERE team_id = 'CZE';
UPDATE teams SET base_camp = 'Columbus, Ohio'                  WHERE team_id = 'ECU';
UPDATE teams SET base_camp = 'Spokane, Washington'             WHERE team_id = 'EGY';
UPDATE teams SET base_camp = 'Kansas City, Missouri'           WHERE team_id = 'ENG';
UPDATE teams SET base_camp = 'Chattanooga, Tennessee'          WHERE team_id = 'ESP';
UPDATE teams SET base_camp = 'Boston, Massachusetts'           WHERE team_id = 'FRA';
UPDATE teams SET base_camp = 'Winston-Salem, North Carolina'   WHERE team_id = 'GER';
UPDATE teams SET base_camp = 'Providence, Rhode Island'        WHERE team_id = 'GHA';
UPDATE teams SET base_camp = 'Atlantic City, New Jersey'       WHERE team_id = 'HAI';
UPDATE teams SET base_camp = 'Tijuana, Baja California'        WHERE team_id = 'IRN';
UPDATE teams SET base_camp = 'White Sulphur Springs, West Virginia' WHERE team_id = 'IRQ';
UPDATE teams SET base_camp = 'Portland, Oregon'                WHERE team_id = 'JOR';
UPDATE teams SET base_camp = 'Nashville, Tennessee'            WHERE team_id = 'JPN';
UPDATE teams SET base_camp = 'Guadalajara, Jalisco'            WHERE team_id = 'KOR';
UPDATE teams SET base_camp = 'Austin, Texas'                   WHERE team_id = 'KSA';
UPDATE teams SET base_camp = 'Warren, New Jersey'              WHERE team_id = 'MAR';
UPDATE teams SET base_camp = 'Mexico City, Mexico'             WHERE team_id = 'MEX';
UPDATE teams SET base_camp = 'Kansas City, Missouri'           WHERE team_id = 'NED';
UPDATE teams SET base_camp = 'Greensboro, North Carolina'      WHERE team_id = 'NOR';
UPDATE teams SET base_camp = 'San Diego, California'           WHERE team_id = 'NZL';
UPDATE teams SET base_camp = 'New Tecumseth, Ontario'          WHERE team_id = 'PAN';
UPDATE teams SET base_camp = 'San José, California'            WHERE team_id = 'PAR';
UPDATE teams SET base_camp = 'Palm Beach Gardens, Florida'     WHERE team_id = 'POR';
UPDATE teams SET base_camp = 'Santa Barbara, California'       WHERE team_id = 'QAT';
UPDATE teams SET base_camp = 'Pachuca, Hidalgo'                WHERE team_id = 'RSA';
UPDATE teams SET base_camp = 'Charlotte, North Carolina'       WHERE team_id = 'SCO';
UPDATE teams SET base_camp = 'New Brunswick, New Jersey'       WHERE team_id = 'SEN';
UPDATE teams SET base_camp = 'San Diego, California'           WHERE team_id = 'SUI';
UPDATE teams SET base_camp = 'Frisco, Texas'                   WHERE team_id = 'SWE';
UPDATE teams SET base_camp = 'Monterrey, Nuevo León'           WHERE team_id = 'TUN';
UPDATE teams SET base_camp = 'Mesa, Arizona'                   WHERE team_id = 'TUR';
UPDATE teams SET base_camp = 'Playa del Carmen, Quintana Roo'  WHERE team_id = 'URU';
UPDATE teams SET base_camp = 'Irvine, California'              WHERE team_id = 'USA';
UPDATE teams SET base_camp = 'Atlanta, Georgia'                WHERE team_id = 'UZB';

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     