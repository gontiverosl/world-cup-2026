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
    team_id         TEXT NOT NULL REFERENCES teams(team_id),
    name            TEXT NOT NULL,
    position        TEXT NOT NULL,         -- GK / DF / MF / FW
    shirt_number    INTEGER,
    footed          TEXT,
    birthday        TEXT,
    birthplace      TEXT,
    league          TEXT,
    club            TEXT,
    matches_played  INTEGER,
    matches_started INTEGER,
    minutes_played  INTEGER,
    goals           INTEGER,
    assists         INTEGER,
    yellow_cards    INTEGER,
    red_cards       INTEGER
);

-- ============================================================
-- TABLE: matches
-- ============================================================
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
    attendance      INTEGER,                  -- dynamic; from FBref match page
    referee         TEXT                      -- dynamic; from FBref match page
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

INSERT INTO teams (team_id, country, confederation, group_name, fifa_ranking, coach, host) VALUES
-- GROUP A
('MEX', 'Mexico',       'CONCACAF', 'A', 16,  'Javier Aguirre', 1),
('RSA', 'South Africa', 'CAF',      'A', 67,  'Hugo Broos',     0),
('KOR', 'South Korea',  'AFC',      'A', 22,  'Hong Myung-bo',  0),
('CZE', 'Czechia',      'UEFA',     'A', 38,  'Miroslav Koubek',0),

-- GROUP B
('CAN', 'Canada',           'CONCACAF', 'B', 48,  'Jesse Marsch',   1),
('BIH', 'Bosnia & Herz.',   'UEFA',     'B', 63,  'Sergej Barbarez',0),
('QAT', 'Qatar',            'AFC',      'B', 58,  'Markus Babbel',  0),
('SUI', 'Switzerland',      'UEFA',     'B', 19,  'Murat Yakin',    0),

-- GROUP C
('BRA', 'Brazil',    'CONMEBOL', 'C', 6,   'Dorival Junior', 0),
('MAR', 'Morocco',   'CAF',      'C', 14,  'Walid Regragui', 0),
('HAI', 'Haiti',     'CONCACAF', 'C', 92,  'Marc Collat',    0),
('SCO', 'Scotland',  'UEFA',     'C', 39,  'Steve Clarke',   0),

-- GROUP D
('USA', 'United States', 'CONCACAF', 'D', 11,  'Mauricio Pochettino', 1),
('PAR', 'Paraguay',      'CONMEBOL', 'D', 53,  'Gustavo Alfaro',     0),
('AUS', 'Australia',     'AFC',      'D', 23,  'Tony Popovic',       0),
('TUR', 'Türkiye',       'UEFA',     'D', 26,  'Vincenzo Montella',  0),

-- GROUP E
('GER', 'Germany',    'UEFA',     'E', 12,  'Julian Nagelsmann', 0),
('CUW', 'Curaçao',    'CONCACAF', 'E', 85,  'Remko Bicentini',   0),
('CIV', 'Côte d''Ivoire', 'CAF',  'E', 33,  'Emerse Faé',        0),
('ECU', 'Ecuador',    'CONMEBOL', 'E', 44,  'Sebastián Beccacece',0),

-- GROUP F
('NED', 'Netherlands', 'UEFA',    'F', 7,   'Ronald Koeman',  0),
('JPN', 'Japan',       'AFC',     'F', 18,  'Hajime Moriyasu',0),
('SWE', 'Sweden',      'UEFA',    'F', 25,  'Jon Dahl Tomasson',0),
('TUN', 'Tunisia',     'CAF',     'F', 34,  'Faouzi Benzarti', 0),

-- GROUP G
('BEL', 'Belgium',     'UEFA',    'G', 3,   'Rudi Garcia',   0),
('EGY', 'Egypt',       'CAF',     'G', 41,  'Hossam Hassan', 0),
('IRN', 'IR Iran',     'AFC',     'G', 21,  'Amir Ghalenoei',0),
('NZL', 'New Zealand', 'OFC',     'G', 97,  'Darren Bazeley',0),

-- GROUP H
('ESP', 'Spain',       'UEFA',    'H', 2,   'Luis de la Fuente',0),
('CPV', 'Cabo Verde',  'CAF',     'H', 71,  'Bubista',          0),
('KSA', 'Saudi Arabia','AFC',     'H', 56,  'Hervé Renard',     0),
('URU', 'Uruguay',     'CONMEBOL','H', 17,  'Marcelo Bielsa',   0),

-- GROUP I
('FRA', 'France',  'UEFA',     'I', 1,   'Didier Deschamps', 0),
('SEN', 'Senegal', 'CAF',      'I', 20,  'Aliou Cissé',      0),
('IRQ', 'Iraq',    'AFC',      'I', 55,  'Jesús Casas',      0),
('NOR', 'Norway',  'UEFA',     'I', 24,  'Ståle Solbakken',  0),

-- GROUP J
('ARG', 'Argentina', 'CONMEBOL', 'J', 3,  'Lionel Scaloni', 0),
('ALG', 'Algeria',   'CAF',      'J', 36, 'Vladimir Petkovic',0),
('AUT', 'Austria',   'UEFA',     'J', 28, 'Ralf Rangnick',   0),
('JOR', 'Jordan',    'AFC',      'J', 82, 'Hossam Hassan',   0),

-- GROUP K
('POR', 'Portugal',  'UEFA',     'K', 5,  'Roberto Martínez', 0),
('COD', 'DR Congo',  'CAF',      'K', 61, 'Sébastien Desabre',0),
('UZB', 'Uzbekistan','AFC',      'K', 74, 'Srecko Katanec',   0),
('COL', 'Colombia',  'CONMEBOL', 'K', 13, 'Néstor Lorenzo',   0),

-- GROUP L
('ENG', 'England',   'UEFA',     'L', 4,  'Thomas Tuchel',    0),
('CRO', 'Croatia',   'UEFA',     'L', 10, 'Zlatko Dalic',     0),
('GHA', 'Ghana',     'CAF',      'L', 60, 'Otto Addo',        0),
('PAN', 'Panama',    'CONCACAF', 'L', 77, 'Thomas Christiansen',0);


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
INSERT INTO players (team_id, name, position, club) VALUES
('MEX', 'Guillermo Ochoa', 'GK', 'AEL Limassol'),
('MEX', 'Raúl Rangel', 'GK', 'Guadalajara'),
('MEX', 'Carlos Acevedo', 'GK', 'Santos Laguna'),
('MEX', 'Jesús Gallardo', 'DF', 'Toluca'),
('MEX', 'César Montes', 'DF', 'Lokomotiv Moscow'),
('MEX', 'Jorge Sánchez', 'DF', 'PAOK'),
('MEX', 'Johan Vásquez', 'DF', 'Genoa'),
('MEX', 'Israel Reyes', 'DF', 'América'),
('MEX', 'Mateo Chávez', 'DF', 'AZ'),
('MEX', 'Edson Álvarez', 'MF', 'Fenerbahçe'),
('MEX', 'Orbelín Pineda', 'MF', 'AEK Athens'),
('MEX', 'Roberto Alvarado', 'MF', 'Guadalajara'),
('MEX', 'Luis Romo', 'MF', 'Guadalajara'),
('MEX', 'Luis Chávez', 'MF', 'Dynamo Moscow'),
('MEX', 'Érik Lira', 'MF', 'Cruz Azul'),
('MEX', 'Gilberto Mora', 'MF', 'Tijuana'),
('MEX', 'Brian Gutiérrez', 'MF', 'Guadalajara'),
('MEX', 'Obed Vargas', 'MF', 'Atlético Madrid'),
('MEX', 'Álvaro Fidalgo', 'MF', 'Real Betis'),
('MEX', 'Raúl Jiménez', 'FW', 'Fulham FC'),
('MEX', 'Alexis Vega', 'FW', 'Toluca'),
('MEX', 'Santiago Giménez', 'FW', 'AC Milan'),
('MEX', 'César Huerta', 'FW', 'RSC Anderlecht'),
('MEX', 'Julián Quiñones', 'FW', 'Al-Qadsiah'),
('MEX', 'Guillermo Martínez', 'FW', 'UNAM'),
('MEX', 'Armando González', 'FW', 'Guadalajara');

-- ---------------------------
-- ARGENTINA (Group J) — full 26
-- ---------------------------
INSERT INTO players (team_id, name, position, club) VALUES
('ARG', 'Emiliano Martínez', 'GK', 'Aston Villa FC'),
('ARG', 'Gerónimo Rulli', 'GK', 'Olympique Marseille'),
('ARG', 'Juan Musso', 'GK', 'Atlético Madrid'),
('ARG', 'Cristian Romero', 'DF', 'Tottenham Hotspur FC'),
('ARG', 'Lisandro Martínez', 'DF', 'Manchester United FC'),
('ARG', 'Nicolás Otamendi', 'DF', 'Benfica'),
('ARG', 'Nahuel Molina', 'DF', 'Atlético Madrid'),
('ARG', 'Gonzalo Montiel', 'DF', 'Nottingham Forest FC'),
('ARG', 'Nicolás Tagliafico', 'DF', 'Olympique Lyonnais'),
('ARG', 'Germán Pezzella', 'DF', 'Real Betis'),
('ARG', 'Rodrigo De Paul', 'MF', 'Atlético Madrid'),
('ARG', 'Enzo Fernández', 'MF', 'Chelsea FC'),
('ARG', 'Alexis Mac Allister', 'MF', 'Liverpool FC'),
('ARG', 'Leandro Paredes', 'MF', 'AS Roma'),
('ARG', 'Giovani Lo Celso', 'MF', 'Villarreal CF'),
('ARG', 'Thiago Almada', 'MF', 'Botafogo'),
('ARG', 'Exequiel Palacios', 'MF', 'Bayer 04 Leverkusen'),
('ARG', 'Lionel Messi', 'FW', 'Inter Miami CF'),
('ARG', 'Lautaro Martínez', 'FW', 'Inter Milan'),
('ARG', 'Julián Álvarez', 'FW', 'Atlético Madrid'),
('ARG', 'Paulo Dybala', 'FW', 'AS Roma'),
('ARG', 'Ángel Correa', 'FW', 'Atlético Madrid'),
('ARG', 'Alejandro Garnacho', 'FW', 'Manchester United FC'),
('ARG', 'Valentín Castellanos', 'FW', 'Lazio'),
('ARG', 'Nicolás González', 'FW', 'Juventus FC'),
('ARG', 'Facundo Buonanotte', 'MF', 'Leicester City FC');

-- ---------------------------
-- BRAZIL (Group C) — full 26
-- ---------------------------
INSERT INTO players (team_id, name, position, club) VALUES
('BRA', 'Ederson', 'GK', 'Manchester City FC'),
('BRA', 'Alisson', 'GK', 'Liverpool FC'),
('BRA', 'Bento', 'GK', 'Al-Qadsiah'),
('BRA', 'Marquinhos', 'DF', 'Paris Saint-Germain'),
('BRA', 'Gabriel Magalhães', 'DF', 'Arsenal FC'),
('BRA', 'Éder Militão', 'DF', 'Real Madrid'),
('BRA', 'Danilo', 'DF', 'Juventus FC'),
('BRA', 'Alex Sandro', 'DF', 'São Paulo'),
('BRA', 'Vanderson', 'DF', 'AS Monaco'),
('BRA', 'Guilherme Arana', 'DF', 'Atlético Mineiro'),
('BRA', 'Casemiro', 'MF', 'Manchester United FC'),
('BRA', 'Bruno Guimarães', 'MF', 'Newcastle United FC'),
('BRA', 'Lucas Paquetá', 'MF', 'West Ham United FC'),
('BRA', 'Gerson', 'MF', 'CR Flamengo'),
('BRA', 'Andreas Pereira', 'MF', 'Fulham FC'),
('BRA', 'Rodrygo', 'FW', 'Real Madrid'),
('BRA', 'Vinicius Jr.', 'FW', 'Real Madrid'),
('BRA', 'Neymar', 'FW', 'Santos'),
('BRA', 'Raphinha', 'FW', 'FC Barcelona'),
('BRA', 'Gabriel Martinelli', 'FW', 'Arsenal FC'),
('BRA', 'Endrick', 'FW', 'Real Madrid'),
('BRA', 'Gabriel Barbosa', 'FW', 'CR Flamengo'),
('BRA', 'Savinho', 'FW', 'Manchester City FC'),
('BRA', 'Yan Couto', 'DF', 'Manchester City FC'),
('BRA', 'André', 'MF', 'Wolverhampton Wanderers FC'),
('BRA', 'Igor Jesus', 'FW', 'Botafogo');

-- ---------------------------
-- SPAIN (Group H) — full 26
-- ---------------------------
INSERT INTO players (team_id, name, position, club) VALUES
('ESP', 'Unai Simón', 'GK', 'Athletic Bilbao'),
('ESP', 'David Raya', 'GK', 'Arsenal FC'),
('ESP', 'Álex Remiro', 'GK', 'Real Sociedad'),
('ESP', 'Dani Carvajal', 'DF', 'Real Madrid'),
('ESP', 'Alejandro Balde', 'DF', 'FC Barcelona'),
('ESP', 'Aymeric Laporte', 'DF', 'Al-Nassr'),
('ESP', 'Robin Le Normand', 'DF', 'Atlético Madrid'),
('ESP', 'Pau Cubarsí', 'DF', 'FC Barcelona'),
('ESP', 'Pedro Porro', 'DF', 'Tottenham Hotspur FC'),
('ESP', 'Marc Cucurella', 'DF', 'Chelsea FC'),
('ESP', 'Rodri', 'MF', 'Manchester City FC'),
('ESP', 'Pedri', 'MF', 'FC Barcelona'),
('ESP', 'Fabian Ruiz', 'MF', 'Paris Saint-Germain'),
('ESP', 'Dani Olmo', 'MF', 'FC Barcelona'),
('ESP', 'Martín Zubimendi', 'MF', 'Arsenal FC'),
('ESP', 'Mikel Merino', 'MF', 'Arsenal FC'),
('ESP', 'Álex Baena', 'MF', 'Villarreal CF'),
('ESP', 'Lamine Yamal', 'FW', 'FC Barcelona'),
('ESP', 'Álvaro Morata', 'FW', 'AC Milan'),
('ESP', 'Mikel Oyarzabal', 'FW', 'Real Sociedad'),
('ESP', 'Ferran Torres', 'FW', 'FC Barcelona'),
('ESP', 'Nico Williams', 'FW', 'Athletic Bilbao'),
('ESP', 'Bryan Gil', 'FW', 'Sevilla'),
('ESP', 'Joselu', 'FW', 'RCD Espanyol'),
('ESP', 'Yeremy Pino', 'FW', 'Villarreal CF'),
('ESP', 'Aitor Paredes', 'DF', 'Athletic Bilbao');

-- ---------------------------
-- FRANCE (Group I) — full 26
-- ---------------------------
INSERT INTO players (team_id, name, position, club) VALUES
('FRA', 'Mike Maignan', 'GK', 'AC Milan'),
('FRA', 'Alphonse Areola', 'GK', 'West Ham United FC'),
('FRA', 'Brice Samba', 'GK', 'RC Lens'),
('FRA', 'William Saliba', 'DF', 'Arsenal FC'),
('FRA', 'Dayot Upamecano', 'DF', 'FC Bayern München'),
('FRA', 'Ibrahima Konaté', 'DF', 'Liverpool FC'),
('FRA', 'Jules Koundé', 'DF', 'FC Barcelona'),
('FRA', 'Theo Hernández', 'DF', 'AC Milan'),
('FRA', 'Benjamin Pavard', 'DF', 'Inter Milan'),
('FRA', 'Lucas Hernandez', 'DF', 'Paris Saint-Germain'),
('FRA', 'N''Golo Kanté',      'MF', 'Al-Ittihad'),
('FRA', 'Aurélien Tchouaméni', 'MF', 'Real Madrid'),
('FRA', 'Adrien Rabiot', 'MF', 'Olympique Marseille'),
('FRA', 'Eduardo Camavinga', 'MF', 'Real Madrid'),
('FRA', 'Warren Zaïre-Emery', 'MF', 'Paris Saint-Germain'),
('FRA', 'Ousmane Dembélé', 'FW', 'Paris Saint-Germain'),
('FRA', 'Kylian Mbappé', 'FW', 'Real Madrid'),
('FRA', 'Antoine Griezmann', 'FW', 'Atlético Madrid'),
('FRA', 'Marcus Thuram', 'FW', 'Inter Milan'),
('FRA', 'Randal Kolo Muani', 'FW', 'Paris Saint-Germain'),
('FRA', 'Bradley Barcola', 'FW', 'Paris Saint-Germain'),
('FRA', 'Kingsley Coman', 'FW', 'FC Bayern München'),
('FRA', 'Christopher Nkunku', 'FW', 'Chelsea FC'),
('FRA', 'Youssouf Fofana', 'MF', 'AC Milan'),
('FRA', 'Matteo Guendouzi', 'MF', 'Lazio'),
('FRA', 'Jonathan Clauss', 'DF', 'Nice');

-- ---------------------------
-- MOROCCO (Group C) — full 26
-- ---------------------------
INSERT INTO players (team_id, name, position, club) VALUES
('MAR', 'Yassine Bounou', 'GK', 'Al-Hilal'),
('MAR', 'Munir Mohamedi', 'GK', 'Villarreal CF'),
('MAR', 'Ahmed Reda Tagnaouti', 'GK', 'Wydad AC'),
('MAR', 'Achraf Hakimi', 'DF', 'Paris Saint-Germain'),
('MAR', 'Nayef Aguerd', 'DF', 'West Ham United FC'),
('MAR', 'Romain Saiss', 'DF', 'Beşiktaş JK'),
('MAR', 'Jawad El Yamiq', 'DF', 'Real Valladolid'),
('MAR', 'Noussair Mazraoui', 'DF', 'Manchester United FC'),
('MAR', 'Adam Masina', 'DF', 'Udinese'),
('MAR', 'Yahia Attiyat Allah', 'DF', 'Wydad AC'),
('MAR', 'Sofiane Boufal', 'MF', 'Southampton FC'),
('MAR', 'Selim Amallah', 'MF', 'Standard Liège'),
('MAR', 'Azzedine Ounahi', 'MF', 'Olympique Marseille'),
('MAR', 'Bilal El Khannous', 'MF', 'KRC Genk'),
('MAR', 'Abdessamad Ezzalzouli', 'MF', 'Barcelona B'),
('MAR', 'Ilias Chair', 'MF', 'QPR'),
('MAR', 'Hamza Mendyl', 'DF', 'Kasimpasa'),
('MAR', 'Youssef En-Nesyri', 'FW', 'Fenerbahçe'),
('MAR', 'Sofiane Chakib Ahannach', 'FW', 'Moroccan'),
('MAR', 'Hakim Ziyech', 'FW', 'Galatasaray SK'),
('MAR', 'Munir El Haddadi', 'FW', 'Angers'),
('MAR', 'Zakaria Aboukhlal', 'FW', 'Toulouse'),
('MAR', 'Ibrahim Salah Ezzaki', 'FW', 'Raja Casablanca'),
('MAR', 'Ryan Mmaee', 'FW', 'AC Sparta Praha'),
('MAR', 'Walid Cheddira', 'FW', 'Parma'),
('MAR', 'Amine Harit', 'MF', 'Olympique Marseille');


-- ============================================================
-- FULL 26-PLAYER SQUADS — 42 teams
-- Sources: FIFA PDF (19) | Wikipedia (11) | worldcuppass (11) | compiled (TUR)
-- ============================================================

-- ---------------------------
-- Czechia (Group A) - 26 players (FIFA official)
-- ---------------------------
INSERT INTO players (team_id, name, position, club) VALUES
('CZE', 'Matej Kovar', 'GK', 'PSV Eindhoven'),
('CZE', 'David Zima', 'DF', 'SK Slavia Praha'),
('CZE', 'Tomas Holes', 'DF', 'SK Slavia Praha'),
('CZE', 'Robin Hranac', 'DF', 'TSG Hoffenheim'),
('CZE', 'Vladimir Coufal', 'DF', 'TSG Hoffenheim'),
('CZE', 'Stepan Chaloupek', 'DF', 'SK Slavia Praha'),
('CZE', 'Ladislav Krejci', 'DF', 'Wolverhampton Wanderers FC'),
('CZE', 'Vladimir Darida', 'MF', 'FC Hradec Králové'),
('CZE', 'Adam Hlozek', 'FW', 'TSG Hoffenheim'),
('CZE', 'Patrik Schick', 'FW', 'Bayer 04 Leverkusen'),
('CZE', 'Jan Kuchta', 'FW', 'AC Sparta Praha'),
('CZE', 'Lukas Cerv', 'MF', 'FC Viktoria Plzeň'),
('CZE', 'Mojmir Chytil', 'FW', 'SK Slavia Praha'),
('CZE', 'David Jurasek', 'DF', 'SK Slavia Praha'),
('CZE', 'Pavel Sulc', 'FW', 'Olympique Lyonnais'),
('CZE', 'Jindrich Stanek', 'GK', 'SK Slavia Praha'),
('CZE', 'Lukas Provod', 'MF', 'SK Slavia Praha'),
('CZE', 'Michal Sadilek', 'MF', 'SK Slavia Praha'),
('CZE', 'Tomas Chory', 'FW', 'SK Slavia Praha'),
('CZE', 'Jaroslav Zeleny', 'DF', 'AC Sparta Praha'),
('CZE', 'David Doudera', 'DF', 'SK Slavia Praha'),
('CZE', 'Tomas Soucek', 'MF', 'West Ham United FC'),
('CZE', 'Lukas Hornicek', 'GK', 'SC Braga'),
('CZE', 'Alexandr Sojka', 'MF', 'FC Viktoria Plzeň'),
('CZE', 'Hugo Sochurek', 'MF', 'AC Sparta Praha'),
('CZE', 'Denis Visinsky', 'FW', 'FC Viktoria Plzeň');

-- ---------------------------
-- Bosnia & Herz. (Group B) - 26 players (FIFA official)
-- ---------------------------
INSERT INTO players (team_id, name, position, club) VALUES
('BIH', 'Nikola Vasilj', 'GK', 'FC St. Pauli'),
('BIH', 'Nihad Mujakic', 'DF', 'Gaziantep FK'),
('BIH', 'Dennis Hadzikadunic', 'DF', 'UC Sampdoria'),
('BIH', 'Tarik Muharemovic', 'DF', 'US Sassuolo'),
('BIH', 'Sead Kolasinac', 'DF', 'Atalanta Bergamo'),
('BIH', 'Benjamin Tahirovic', 'MF', 'Brøndby IF'),
('BIH', 'Amar Dedic', 'DF', 'Benfica'),
('BIH', 'Armin Gigovic', 'MF', 'BSC Young Boys'),
('BIH', 'Samed Bazdar', 'FW', 'Jagiellonia Białystok'),
('BIH', 'Ermedin Demirovic', 'FW', 'VfB Stuttgart'),
('BIH', 'Edin Dzeko', 'FW', 'FC Schalke 04'),
('BIH', 'Mladen Jurkas', 'GK', 'FK Borac Banja Luka'),
('BIH', 'Ivan Basic', 'MF', 'FC Astana'),
('BIH', 'Ivan Sunjic', 'MF', 'Pafos FC'),
('BIH', 'Amar Memic', 'MF', 'FC Viktoria Plzeň'),
('BIH', 'Amir Hadziahmetovic', 'MF', 'Hull City FC'),
('BIH', 'Dzenis Burnic', 'MF', 'Karlsruher SC'),
('BIH', 'Nikola Katic', 'DF', 'FC Schalke 04'),
('BIH', 'Kerim Alajbegovic', 'FW', 'FC Red Bull Salzburg'),
('BIH', 'Esmir Bajraktarevic', 'FW', 'PSV Eindhoven'),
('BIH', 'Stjepan Radeljic', 'DF', 'HNK Rijeka'),
('BIH', 'Martin Zlomislic', 'GK', 'HNK Rijeka'),
('BIH', 'Haris Tabakovic', 'FW', 'Borussia Mönchengladbach'),
('BIH', 'Arjan Malic', 'DF', 'SK Sturm Graz'),
('BIH', 'Jovo Lukic', 'FW', 'Universitatea Cluj'),
('BIH', 'Ermin Mahmic', 'MF', 'FC Slovan Liberec');

-- ---------------------------
-- Canada (Group B) - 26 players (FIFA official)
-- ---------------------------
INSERT INTO players (team_id, name, position, club) VALUES
('CAN', 'ST.', 'GK', 'Inter Miami CF'),
('CAN', 'Alistair Johnston', 'DF', 'Celtic FC'),
('CAN', 'Ale Jones', 'DF', 'Middlesbrough FC'),
('CAN', 'Luc De Fougerolles', 'DF', 'FCV Dender EH'),
('CAN', 'Joel Waterman', 'DF', 'Chicago Fire FC'),
('CAN', 'Mathieu Choiniere', 'MF', 'LAFC'),
('CAN', 'Stephen Eustaquio', 'MF', 'LAFC'),
('CAN', 'Ismael Kone', 'MF', 'US Sassuolo'),
('CAN', 'Cyle Larin', 'FW', 'Southampton FC'),
('CAN', 'Jonathan David', 'FW', 'Juventus FC'),
('CAN', 'Liam Millar', 'MF', 'Hull City FC'),
('CAN', 'Tani Oluwaseyi', 'FW', 'Villarreal CF'),
('CAN', 'Derek Cornelius', 'DF', 'Rangers FC'),
('CAN', 'Jacob Shaffelburg', 'MF', 'LAFC'),
('CAN', 'Moise Bombito', 'DF', 'OGC Nice'),
('CAN', 'Maxime Crepeau', 'GK', 'Orlando City SC'),
('CAN', 'Tajon Buchanan', 'FW', 'Villarreal CF'),
('CAN', 'Owen Goodman', 'GK', 'Barnsley'),
('CAN', 'Alphonso Davies', 'DF', 'FC Bayern München'),
('CAN', 'Ali Ahmed', 'FW', 'Norwich City FC'),
('CAN', 'Jonathan Osorio', 'MF', 'Toronto FC'),
('CAN', 'Richie Laryea', 'DF', 'Toronto FC'),
('CAN', 'Niko Sigur', 'DF', 'HNK Hajduk Split'),
('CAN', 'Promise David', 'FW', 'Royale Union Saint-Gilloise'),
('CAN', 'Nathan Saliba', 'MF', 'RSC Anderlecht'),
('CAN', 'Jayden Nelson', 'FW', 'Austin FC');

-- ---------------------------
-- Haiti (Group C) - 26 players (FIFA official)
-- ---------------------------
INSERT INTO players (team_id, name, position, club) VALUES
('HAI', 'Johny Placide', 'GK', 'SC Bastia'),
('HAI', 'Carlens Arcus', 'DF', 'Angers SCO'),
('HAI', 'Keeto Thermoncy', 'DF', 'BSC Young Boys'),
('HAI', 'Ricardo Ade', 'DF', 'LDU Quito'),
('HAI', 'Hannes Delcroix', 'DF', 'FC Lugano'),
('HAI', 'Carl Sainte', 'MF', 'El Paso Locomotive FC'),
('HAI', 'Derrick Etienne', 'FW', 'Toronto FC'),
('HAI', 'Martin Experience', 'DF', 'AS Nancy'),
('HAI', 'Duckens Nazon', 'FW', 'Esteghlal'),
('HAI', 'Jean-Ricner Bellegarde', 'MF', 'Wolverhampton Wanderers FC'),
('HAI', 'Louicius Deedson', 'FW', 'FC Dallas'),
('HAI', 'Alexandre Pierre', 'GK', 'FC Sochaux-Montbéliard'),
('HAI', 'Markhus Lacroix', 'DF', 'Colorado Springs Switchbacks FC'),
('HAI', 'Garven Metusala', 'DF', 'Colorado Springs Switchbacks FC'),
('HAI', 'Ruben Providence', 'FW', 'Almere City FC'),
('HAI', 'Lenny Joseph', 'FW', 'Ferencvárosi TC'),
('HAI', 'Danley Jean Jacques', 'MF', 'Philadelphia Union'),
('HAI', 'Wilson Isidor', 'FW', 'Sunderland AFC'),
('HAI', 'Yassin Fortune', 'FW', 'FC Vizela'),
('HAI', 'Frantzdy Pierrot', 'FW', 'Çaykur Rizespor'),
('HAI', 'Josue Casimir', 'FW', 'AJ Auxerre'),
('HAI', 'Jean-Kevin Duverne', 'DF', 'KAA Gent'),
('HAI', 'Josue Duverger', 'GK', 'FC Cosmos Koblenz'),
('HAI', 'Wilguens Paugain', 'DF', 'SV Zulte Waregem'),
('HAI', 'Dominique Simon', 'MF', 'FC Tatran Prešov'),
('HAI', 'Woodensky Pierre', 'MF', 'Violette AC');

-- ---------------------------
-- Australia (Group D) - 26 players (FIFA official)
-- ---------------------------
INSERT INTO players (team_id, name, position, club) VALUES
('AUS', 'Mathew Ryan', 'GK', 'Levante UD'),
('AUS', 'Milos Degenek', 'DF', 'APOEL FC'),
('AUS', 'Alessandro Circati', 'DF', 'Parma'),
('AUS', 'Jacob Italiano', 'DF', 'Grazer AK'),
('AUS', 'Jordan Bos', 'DF', 'Feyenoord Rotterdam'),
('AUS', 'Jason Geria', 'DF', 'Albirex Niigata'),
('AUS', 'Mathew Leckie', 'FW', 'Melbourne City FC'),
('AUS', 'Connor Metcalfe', 'MF', 'FC St. Pauli'),
('AUS', 'Mohamed Toure', 'FW', 'Norwich City FC'),
('AUS', 'Ajdin Hrustic', 'FW', 'SC Heracles Almelo'),
('AUS', 'Awer Mabil', 'FW', 'CD Castellón'),
('AUS', 'Paul Izzo', 'GK', 'Randers FC'),
('AUS', 'Aiden Oneill', 'MF', 'New York City FC'),
('AUS', 'Cameron Devlin', 'MF', 'Heart Of Midlothian FC'),
('AUS', 'Kai Trewin', 'DF', 'New York City FC'),
('AUS', 'Aziz Behich', 'DF', 'Melbourne City FC'),
('AUS', 'Nestory Irankunda', 'FW', 'Watford FC'),
('AUS', 'Patrick Beach', 'GK', 'Melbourne City FC'),
('AUS', 'Harry Souttar', 'DF', 'Leicester City FC'),
('AUS', 'Cristian Volpato', 'FW', 'US Sassuolo'),
('AUS', 'Cameron Burgess', 'DF', 'Swansea City AFC'),
('AUS', 'Jackson Irvine', 'MF', 'FC St. Pauli'),
('AUS', 'Nishan Velupillay', 'FW', 'Melbourne Victory FC'),
('AUS', 'Paul Okon-engstler', 'MF', 'Sydney FC'),
('AUS', 'Lucas Herrington', 'DF', 'Colorado Rapids'),
('AUS', 'Tete Yengi', 'FW', 'FC Machida Zelvia');

-- ---------------------------
-- Cote d'Ivoire (Group E) - 26 players (FIFA official)
-- ---------------------------
INSERT INTO players (team_id, name, position, club) VALUES
('CIV', 'Yahia Fofana', 'GK', 'Çaykur Rizespor'),
('CIV', 'Ousmane Diomande', 'DF', 'Sporting CP'),
('CIV', 'Ghislain Konan', 'DF', 'Gil Vicente FC'),
('CIV', 'Jean Seri', 'MF', 'NK Maribor'),
('CIV', 'Wilfried Singo', 'DF', 'Galatasaray SK'),
('CIV', 'Seko Fofana', 'MF', 'FC Porto'),
('CIV', 'Odilon Kossounou', 'DF', 'Atalanta Bergamo'),
('CIV', 'Franck Kessie', 'MF', 'Al Ahli'),
('CIV', 'Ange-Yoan Bonny', 'FW', 'Inter Milan'),
('CIV', 'Simon Adingra', 'FW', 'AS Monaco'),
('CIV', 'Yan Diomande', 'FW', 'RB Leipzig'),
('CIV', 'Elye Wahi', 'FW', 'OGC Nice'),
('CIV', 'Christopher Operi', 'DF', 'Başakşehir FK'),
('CIV', 'Oumar Diakite', 'FW', 'Cercle Brugge'),
('CIV', 'Amad Diallo', 'FW', 'Manchester United FC'),
('CIV', 'Mohamed Kone', 'GK', 'Sporting Charleroi'),
('CIV', 'Guela Doue', 'DF', 'RC Strasbourg'),
('CIV', 'Ibrahim Sangare', 'MF', 'Nottingham Forest FC'),
('CIV', 'Nicolas Pepe', 'FW', 'Villarreal CF'),
('CIV', 'Emmanuel Agbadou', 'DF', 'Beşiktaş JK'),
('CIV', 'Evan Ndicka', 'DF', 'AS Roma'),
('CIV', 'Evann Guessand', 'FW', 'Crystal Palace FC'),
('CIV', 'Alban Lafont', 'GK', 'Panathinaikos FC'),
('CIV', 'Bazoumana Toure', 'FW', 'TSG Hoffenheim'),
('CIV', 'Parfait Guiagon', 'MF', 'Sporting Charleroi'),
('CIV', 'Christ Oulai', 'MF', 'Trabzonspor');

-- ---------------------------
-- Curacao (Group E) - 26 players (FIFA official)
-- ---------------------------
INSERT INTO players (team_id, name, position, club) VALUES
('CUW', 'Eloy Room', 'GK', 'Miami FC'),
('CUW', 'Shurandy Sambo', 'DF', 'Sparta Rotterdam'),
('CUW', 'Jurien Gaari', 'DF', 'Abha Club'),
('CUW', 'Roshon Van Eijma', 'DF', 'RKC Waalwijk'),
('CUW', 'Sherel Floranus', 'DF', 'PEC Zwolle'),
('CUW', 'Godfried Roemeratoe', 'MF', 'RKC Waalwijk'),
('CUW', 'Juninho Bacuna', 'MF', 'FC Volendam'),
('CUW', 'Livano Comenencia', 'MF', 'FC Zürich'),
('CUW', 'Juergen Locadia', 'FW', 'Miami FC'),
('CUW', 'Leandro Bacuna', 'MF', 'Iğdır FK'),
('CUW', 'Jeremy Antonisse', 'FW', 'AE Kisia FC'),
('CUW', 'Sontje Hansen', 'FW', 'Middlesbrough FC'),
('CUW', 'Tyrese Noslin', 'FW', 'SC Telstar'),
('CUW', 'Kenji Gorre', 'FW', 'Maccabi Haifa FC'),
('CUW', 'Arjany Martha', 'MF', 'Rotherham United FC'),
('CUW', 'Jearl Margaritha', 'FW', 'SK Beveren'),
('CUW', 'Brandley Kuwas', 'FW', 'FC Volendam'),
('CUW', 'Armando Obispo', 'DF', 'PSV Eindhoven'),
('CUW', 'Gervane Kastaneer', 'FW', 'Terengganu FC'),
('CUW', 'Joshua Brenet', 'DF', 'Kayserispor'),
('CUW', 'Tahith Chong', 'MF', 'Sheeld United FC'),
('CUW', 'Kevin Felida', 'MF', 'FC Den Bosch'),
('CUW', 'Riechedly Bazoer', 'DF', 'Konyaspor'),
('CUW', 'Deveron Fonville', 'DF', 'NEC Nijmegen'),
('CUW', 'Tyrick Bodak', 'GK', 'SC Telstar'),
('CUW', 'Trevor Doornbusch', 'GK', 'VVV Venlo');

-- ---------------------------
-- Ecuador (Group E) - 26 players (FIFA official)
-- ---------------------------
INSERT INTO players (team_id, name, position, club) VALUES
('ECU', 'Hernan Galindez', 'GK', 'CA Huracán'),
('ECU', 'Felix Torres', 'DF', 'SC Internacional'),
('ECU', 'Piero Hincapie', 'DF', 'Arsenal FC'),
('ECU', 'Joel Ordonez', 'DF', 'Club Brugge'),
('ECU', 'Jordy Alcivar', 'MF', 'Independiente Del Valle'),
('ECU', 'Willian Pacho', 'DF', 'Paris Saint-Germain'),
('ECU', 'Pervis Estupinan', 'DF', 'AC Milan'),
('ECU', 'Anthony Valencia', 'MF', 'Royal Antwerp FC'),
('ECU', 'John Yeboah', 'FW', 'Venezia FC'),
('ECU', 'Kendry Paez', 'MF', 'CA River Plate'),
('ECU', 'Kevin Rodriguez', 'FW', 'Royale Union Saint-Gilloise'),
('ECU', 'Moises Ramirez', 'GK', 'AE Kisia FC'),
('ECU', 'Enner Valencia', 'FW', 'CF Pachuca'),
('ECU', 'Alan Minda', 'MF', 'Atlético Mineiro'),
('ECU', 'Pedro Vite', 'MF', 'Pumas UNAM'),
('ECU', 'Jordy Caicedo', 'FW', 'CA Huracán'),
('ECU', 'Angelo Preciado', 'DF', 'Atlético Mineiro'),
('ECU', 'Denil Castillo', 'MF', 'FC Midtjylland'),
('ECU', 'Gonzalo Plata', 'FW', 'CR Flamengo'),
('ECU', 'Nilson Angulo', 'FW', 'Sunderland AFC'),
('ECU', 'Alan Franco', 'MF', 'Atlético Mineiro'),
('ECU', 'Gonzalo Valle', 'GK', 'LDU Quito'),
('ECU', 'Moises Caicedo', 'MF', 'Chelsea FC'),
('ECU', 'Jeremy Arevalo', 'FW', 'VfB Stuttgart'),
('ECU', 'Jackson Porozo', 'DF', 'Club Tijuana'),
('ECU', 'Yaimar Medina', 'DF', 'KRC Genk');

-- ---------------------------
-- Germany (Group E) - 26 players (FIFA official)
-- ---------------------------
INSERT INTO players (team_id, name, position, club) VALUES
('GER', 'Manuel Neuer', 'GK', 'FC Bayern München'),
('GER', 'Antonio Ruediger', 'DF', 'Real Madrid'),
('GER', 'Waldemar Anton', 'DF', 'Borussia Dortmund'),
('GER', 'Jonathan Tah', 'DF', 'FC Bayern München'),
('GER', 'Aleksandar Pavlovic', 'MF', 'FC Bayern München'),
('GER', 'Joshua Kimmich', 'DF', 'FC Bayern München'),
('GER', 'Kai Havertz', 'FW', 'Arsenal FC'),
('GER', 'Leon Goretzka', 'MF', 'FC Bayern München'),
('GER', 'Jamie Leweling', 'MF', 'VfB Stuttgart'),
('GER', 'Jamal Musiala', 'MF', 'FC Bayern München'),
('GER', 'Nick Woltemade', 'FW', 'Newcastle United FC'),
('GER', 'Oliver Baumann', 'GK', 'TSG Hoffenheim'),
('GER', 'Pascal Gross', 'MF', 'Brighton & Hove Albion FC'),
('GER', 'Maximilian Beier', 'FW', 'Borussia Dortmund'),
('GER', 'Nico Schlotterbeck', 'DF', 'Borussia Dortmund'),
('GER', 'Angelo Stiller', 'MF', 'VfB Stuttgart'),
('GER', 'Florian Wirtz', 'MF', 'Liverpool FC'),
('GER', 'Nathaniel Brown', 'DF', 'Eintracht Frankfurt'),
('GER', 'Leroy Sane', 'MF', 'Galatasaray SK'),
('GER', 'Nadiem Amiri', 'MF', '1. FSV Mainz 05'),
('GER', 'Alexander Nuebel', 'GK', 'VfB Stuttgart'),
('GER', 'David Raum', 'DF', 'RB Leipzig'),
('GER', 'Felix Nmecha', 'MF', 'Borussia Dortmund'),
('GER', 'Malick Thiaw', 'DF', 'Newcastle United FC'),
('GER', 'Assan Ouedraogo', 'MF', 'RB Leipzig'),
('GER', 'Deniz Undav', 'FW', 'VfB Stuttgart');

-- ---------------------------
-- Belgium (Group G) - 26 players (FIFA official)
-- ---------------------------
INSERT INTO players (team_id, name, position, club) VALUES
('BEL', 'Thibaut Courtois', 'GK', 'Real Madrid'),
('BEL', 'Zeno Debast', 'DF', 'Sporting CP'),
('BEL', 'Arthur Theate', 'DF', 'Eintracht Frankfurt'),
('BEL', 'Brandon Mechele', 'DF', 'Club Brugge'),
('BEL', 'Maxim De Cuyper', 'DF', 'Brighton & Hove Albion FC'),
('BEL', 'Axel Witsel', 'MF', 'Girona FC'),
('BEL', 'Kevin De Bruyne', 'MF', 'SSC Napoli'),
('BEL', 'Youri Tielemans', 'MF', 'Aston Villa FC'),
('BEL', 'Romelu Lukaku', 'FW', 'SSC Napoli'),
('BEL', 'Leandro Trossard', 'FW', 'Arsenal FC'),
('BEL', 'Jeremy Doku', 'FW', 'Manchester City FC'),
('BEL', 'Senne Lammens', 'GK', 'Manchester United FC'),
('BEL', 'Mike Penders', 'GK', 'RC Strasbourg'),
('BEL', 'Dodi Lukebakio', 'FW', 'Benfica'),
('BEL', 'Thomas Meunier', 'DF', 'Lille OSC'),
('BEL', 'Koni De Winter', 'DF', 'AC Milan'),
('BEL', 'Charles De Ketelaere', 'FW', 'Atalanta Bergamo'),
('BEL', 'Joaquin Seys', 'DF', 'Club Brugge'),
('BEL', 'Diego Moreira', 'MF', 'RC Strasbourg'),
('BEL', 'Hans Vanaken', 'MF', 'Club Brugge'),
('BEL', 'Timothy Castagne', 'DF', 'Fulham FC'),
('BEL', 'Alexis Saelemaekers', 'MF', 'AC Milan'),
('BEL', 'Nicolas Raskin', 'MF', 'Rangers FC'),
('BEL', 'Amadou Onana', 'MF', 'Aston Villa FC'),
('BEL', 'Nathan Ngoy', 'DF', 'Lille OSC'),
('BEL', 'Matias Fernandez-pardo', 'FW', 'Lille OSC');

-- ---------------------------
-- Egypt (Group G) - 26 players (FIFA official)
-- ---------------------------
INSERT INTO players (team_id, name, position, club) VALUES
('EGY', 'Mohamed Mohamed Elshenawy', 'GK', 'Al Ahly FC'),
('EGY', 'Yasser Yasser Ibrahim', 'DF', 'Al Ahly FC'),
('EGY', 'Mohamed Mohamed Hany', 'DF', 'Al Ahly FC'),
('EGY', 'Hossam Hossam Abdelmaguid', 'DF', 'Zamalek SC'),
('EGY', 'Ramy Ramy Rabia', 'DF', 'Al-Ain'),
('EGY', 'Mohamed Mohamed Abdelmoneim', 'DF', 'OGC Nice'),
('EGY', 'Mahmoud Trezeguet', 'FW', 'Al Ahly FC'),
('EGY', 'Emam Emam Ashour', 'MF', 'Al Ahly FC'),
('EGY', 'Hamza Hamza Abdelkarim', 'FW', 'FC Barcelona'),
('EGY', 'Mohamed Mohamed Salah', 'FW', 'Liverpool FC'),
('EGY', 'Mostafa Mostafa Zico', 'MF', 'Pyramids FC'),
('EGY', 'Haissem Haissem Hassan', 'FW', 'Real Oviedo'),
('EGY', 'Ahmed Ahmed Fatouh', 'DF', 'Zamalek SC'),
('EGY', 'Hamdy Hamdy Fathy', 'MF', 'Al-Wakrah'),
('EGY', 'Karim Karim Hafez', 'DF', 'Pyramids FC'),
('EGY', 'Mahdy Mahdy Soliman', 'GK', 'Zamalek SC'),
('EGY', 'Mohanad Mohanad Lashin', 'MF', 'Pyramids FC'),
('EGY', 'Nabil Nabil Donga', 'MF', 'Al Najmah SC'),
('EGY', 'Marawan Marawan Attia', 'MF', 'Al Ahly FC'),
('EGY', 'Ibrahim Ibrahim Adel', 'FW', 'FC Nordsjælland'),
('EGY', 'Mahmoud Mahmoud Saber', 'MF', 'ZED FC'),
('EGY', 'Omar Omar Marmoush', 'FW', 'Manchester City FC'),
('EGY', 'Mostafa Mostafa Shoubir', 'GK', 'Al Ahly FC'),
('EGY', 'Tarek Tarek Alaa', 'DF', 'ZED FC'),
('EGY', 'Ahmed Zizo', 'FW', 'Al Ahly FC'),
('EGY', 'Mohamed Mohamed Alaa', 'GK', 'El Gouna FC');

-- ---------------------------
-- Cabo Verde (Group H) - 26 players (FIFA official)
-- ---------------------------
INSERT INTO players (team_id, name, position, club) VALUES
('CPV', 'Josimar Vozinha', 'GK', 'GD Chaves'),
('CPV', 'Ianique Stopira', 'DF', 'SCU Torreense'),
('CPV', 'Edilson Diney Borges', 'DF', 'Al Bataeh'),
('CPV', 'Roberto Pico Lopes', 'DF', 'Shamrock Rovers FC'),
('CPV', 'Logan Logan Costa', 'DF', 'Villarreal CF'),
('CPV', 'Kevin Kevin Pina', 'MF', 'FC Krasnodar'),
('CPV', 'Jovane Jovane Cabral', 'MF', 'CF Estrela Da Amadora'),
('CPV', 'João Joao Paulo', 'MF', 'FC FCSB'),
('CPV', 'Gilson Gilson Benchimol', 'FW', 'FC Akron Tolyatti'),
('CPV', 'Jamiro Jamiro Monteiro', 'MF', 'PEC Zwolle'),
('CPV', 'Garry Garry Rodrigues', 'MF', 'Apollon Limassol'),
('CPV', 'Márcio Marcio Rosa', 'GK', 'PFC Montana'),
('CPV', 'Sidny Sidny Lopes Cabral', 'DF', 'Benfica'),
('CPV', 'Deroy Deroy Duarte', 'MF', 'PFC Ludogorets Razgrad'),
('CPV', 'Laros Laros Duarte', 'MF', 'Puskás Akadémia FC'),
('CPV', 'Jair Yannick Semedo', 'MF', 'SC Farense'),
('CPV', 'Willy Willy Semedo', 'MF', 'AC Omonia'),
('CPV', 'Telmo Telmo Arcanjo', 'MF', 'Vitória SC'),
('CPV', 'Dailon Dailon Livramento', 'FW', 'Casa Pia AC'),
('CPV', 'Ryan Ryan Mendes', 'FW', 'Iğdır FK'),
('CPV', 'Nuno Nuno Da Costa', 'MF', 'Başakşehir FK'),
('CPV', 'Steven Steven Moreira', 'DF', 'Columbus Crew'),
('CPV', 'Carlos Cj Dos Santos', 'GK', 'San Diego FC'),
('CPV', 'Wagner Wagner Pina', 'DF', 'Trabzonspor'),
('CPV', 'Kelvin Kelvin Pires', 'DF', 'SJK'),
('CPV', 'Hélio Helio Varela', 'MF', 'Maccabi Tel-Aviv FC');

-- ---------------------------
-- Algeria (Group J) - 26 players (FIFA official)
-- ---------------------------
INSERT INTO players (team_id, name, position, club) VALUES
('ALG', 'Melvin Mastil', 'GK', 'FC Stade Nyonnais'),
('ALG', 'Aissa Mandi', 'DF', 'Lille OSC'),
('ALG', 'Achref Abada', 'DF', 'USM Alger'),
('ALG', 'Mohamed Tougai', 'DF', 'Espérance de Tunis'),
('ALG', 'Zineddine Belaid', 'DF', 'JS Kabylie'),
('ALG', 'Ramiz Zerrouki', 'MF', 'FC Twente'),
('ALG', 'Riyad Mahrez', 'FW', 'Al Ahli'),
('ALG', 'Houssem Aouar', 'MF', 'Al Ittihad'),
('ALG', 'Amine Gouiri', 'FW', 'Olympique Marseille'),
('ALG', 'Fares Chaibi', 'MF', 'Eintracht Frankfurt'),
('ALG', 'Anis Hadj Moussa', 'FW', 'Feyenoord Rotterdam'),
('ALG', 'Nadhir Benbouali', 'FW', 'Györi ETO FC'),
('ALG', 'Jaouen Hadjam', 'DF', 'BSC Young Boys'),
('ALG', 'Hicham Boudaoui', 'MF', 'OGC Nice'),
('ALG', 'Rayan Ait-nouri', 'DF', 'Manchester City FC'),
('ALG', 'Oussama Benbot', 'GK', 'USM Alger'),
('ALG', 'Rak Belghali', 'DF', 'Hellas Verona FC'),
('ALG', 'Mohamed Amoura', 'FW', 'VfL Wolfsburg'),
('ALG', 'Nabil Bentaleb', 'MF', 'Lille OSC'),
('ALG', 'Adil Boulbina', 'FW', 'Al-Duhail'),
('ALG', 'Ramy Bensebaini', 'DF', 'Borussia Dortmund'),
('ALG', 'Ibrahim Maza', 'MF', 'Bayer 04 Leverkusen'),
('ALG', 'Luca Zidane', 'GK', 'Granada CF'),
('ALG', 'Yassine Titraoui', 'MF', 'Sporting Charleroi'),
('ALG', 'Fares Ghedjemis', 'FW', 'Frosinone'),
('ALG', 'Samir Chergui', 'DF', 'Paris FC');

-- ---------------------------
-- Austria (Group J) - 26 players (FIFA official)
-- ---------------------------
INSERT INTO players (team_id, name, position, club) VALUES
('AUT', 'Alexander Schlager', 'GK', 'FC Red Bull Salzburg'),
('AUT', 'David Affengruber', 'DF', 'Elche CF'),
('AUT', 'Kevin Danso', 'DF', 'Tottenham Hotspur FC'),
('AUT', 'Xaver Schlager', 'MF', 'RB Leipzig'),
('AUT', 'Stefan Posch', 'DF', '1. FSV Mainz 05'),
('AUT', 'Nicolas Seiwald', 'MF', 'RB Leipzig'),
('AUT', 'Marko Arnautovic', 'FW', 'FK Crvena Zvezda'),
('AUT', 'David Alaba', 'DF', 'Real Madrid'),
('AUT', 'Marcel Sabitzer', 'MF', 'Borussia Dortmund'),
('AUT', 'Florian Grillitsch', 'MF', 'SC Braga'),
('AUT', 'Michael Gregoritsch', 'FW', 'FC Augsburg'),
('AUT', 'Florian Wiegele', 'GK', 'FC Viktoria Plzeň'),
('AUT', 'Patrick Pentz', 'GK', 'Brøndby IF'),
('AUT', 'Sasa Kalajdzic', 'FW', 'LASK Linz'),
('AUT', 'Philipp Lienhart', 'DF', 'SC Freiburg'),
('AUT', 'Phillip Mwene', 'DF', '1. FSV Mainz 05'),
('AUT', 'Carney Chukwuemeka', 'MF', 'Borussia Dortmund'),
('AUT', 'Romano Schmid', 'MF', 'SV Werder Bremen'),
('AUT', 'Dejan Ljubicic', 'MF', 'FC Schalke 04'),
('AUT', 'Konrad Laimer', 'MF', 'FC Bayern München'),
('AUT', 'Patrick Wimmer', 'FW', 'VfL Wolfsburg'),
('AUT', 'Alexander Prass', 'MF', 'TSG Hoffenheim'),
('AUT', 'Marco Friedl', 'DF', 'SV Werder Bremen'),
('AUT', 'Paul Wanner', 'MF', 'PSV Eindhoven'),
('AUT', 'Michael Svoboda', 'DF', 'Venezia FC'),
('AUT', 'Alessandro Schoepf', 'MF', 'Wolfsberger AC');

-- ---------------------------
-- DR Congo (Group K) - 26 players (FIFA official)
-- ---------------------------
INSERT INTO players (team_id, name, position, club) VALUES
('COD', 'Lionel Mpasi', 'GK', 'Le Havre AC'),
('COD', 'Aaron Wan-bissaka', 'DF', 'West Ham United FC'),
('COD', 'Steve Kapuadi', 'DF', 'Widzew Łódź'),
('COD', 'Axel Tuanzebe', 'DF', 'Burnley FC'),
('COD', 'Dylan Batubinsika', 'DF', 'AEL FC'),
('COD', 'Ngalayel Mukau', 'MF', 'Lille OSC'),
('COD', 'Nathanael Mbuku', 'MF', 'Montpellier HSC'),
('COD', 'Samuel Moutoussamy', 'MF', 'Atromitos FC'),
('COD', 'Brian Cipenga', 'FW', 'CD Castellón'),
('COD', 'Theo Bongonda', 'MF', 'FC Spartak Moscow'),
('COD', 'Gael Kakuta', 'FW', 'AEL FC'),
('COD', 'Joris Kayembe', 'DF', 'KRC Genk'),
('COD', 'Meschack Elia', 'FW', 'Alanyaspor'),
('COD', 'Noah Sadiki', 'MF', 'Sunderland AFC'),
('COD', 'Aaron Tshibola', 'MF', 'Kilmarnock FC'),
('COD', 'Timothy Fayulu', 'GK', 'FC Noah'),
('COD', 'Cedric Bakambu', 'FW', 'Real Betis'),
('COD', 'Charles Pickel', 'MF', 'RCD Espanyol'),
('COD', 'Fiston Mayele', 'FW', 'Pyramids FC'),
('COD', 'Yoane Wissa', 'FW', 'Newcastle United FC'),
('COD', 'Matthieu Epolo', 'GK', 'Standard Liège'),
('COD', 'Chancel Mbemba', 'DF', 'Lille OSC'),
('COD', 'Simon Banza', 'FW', 'Al Jazira'),
('COD', 'Gedeon Kalulu', 'DF', 'Aris Limassol FC'),
('COD', 'Edo Kayembe', 'MF', 'Watford FC'),
('COD', 'Arthur Masuaku', 'DF', 'RC Lens');

-- ---------------------------
-- Colombia (Group K) - 26 players (FIFA official)
-- ---------------------------
INSERT INTO players (team_id, name, position, club) VALUES
('COL', 'David Ospina', 'GK', 'Atlético Nacional'),
('COL', 'Daniel Munoz', 'DF', 'Crystal Palace FC'),
('COL', 'Jhon Lucumi', 'DF', 'Bologna FC'),
('COL', 'Santiago Arias', 'DF', 'CA Independiente'),
('COL', 'Kevin Castano', 'MF', 'CA River Plate'),
('COL', 'Richard Rios', 'MF', 'Benfica'),
('COL', 'Luis Diaz', 'FW', 'FC Bayern München'),
('COL', 'Jorge Carrascal', 'MF', 'CR Flamengo'),
('COL', 'Jhon Cordoba', 'FW', 'FC Krasnodar'),
('COL', 'James Rodriguez', 'MF', 'Minnesota United FC'),
('COL', 'Jhon Arias', 'MF', 'SE Palmeiras'),
('COL', 'Camilo Vargas', 'GK', 'Atlas FC'),
('COL', 'Yerry Mina', 'DF', 'Cagliari'),
('COL', 'Gustavo Puerta', 'DF', 'Racing Santander'),
('COL', 'Juan Portilla', 'MF', 'Athletico Paranaense'),
('COL', 'Jefferson Lerma', 'MF', 'Crystal Palace FC'),
('COL', 'Johan Mojica', 'DF', 'RCD Mallorca'),
('COL', 'Willer Ditta', 'DF', 'Cruz Azul'),
('COL', 'Cucho Hernandez', 'FW', 'Real Betis'),
('COL', 'Juan Quintero', 'MF', 'CA River Plate'),
('COL', 'Jaminton Campaz', 'FW', 'CA Rosario Central'),
('COL', 'Deiver Machado', 'DF', 'FC Nantes'),
('COL', 'Davinson Sanchez', 'DF', 'Galatasaray SK'),
('COL', 'Alvaro Montero', 'GK', 'CA Vélez Sarseld'),
('COL', 'Luis Suarez', 'FW', 'Sporting CP'),
('COL', 'Andres Gomez', 'FW', 'CR Vasco Da Gama');

-- ---------------------------
-- Croatia (Group L) - 26 players (FIFA official)
-- ---------------------------
INSERT INTO players (team_id, name, position, club) VALUES
('CRO', 'Dominik Livakovic', 'GK', 'GNK Dinamo Zagreb'),
('CRO', 'Josip Stanisic', 'DF', 'FC Bayern München'),
('CRO', 'Marin Pongracic', 'DF', 'ACF Fiorentina'),
('CRO', 'Josko Gvardiol', 'DF', 'Manchester City FC'),
('CRO', 'Duje Caleta-car', 'DF', 'Real Sociedad'),
('CRO', 'Josip Sutalo', 'DF', 'AFC Ajax'),
('CRO', 'Nikola Moro', 'MF', 'Bologna FC'),
('CRO', 'Mateo Kovacic', 'MF', 'Manchester City FC'),
('CRO', 'Andrej Kramaric', 'FW', 'TSG Hoffenheim'),
('CRO', 'Luka Modric', 'MF', 'AC Milan'),
('CRO', 'Ante Budimir', 'FW', 'CA Osasuna'),
('CRO', 'Ivor Pandur', 'GK', 'Hull City FC'),
('CRO', 'Nikola Vlasic', 'MF', 'Torino FC'),
('CRO', 'Ivan Perisic', 'FW', 'PSV Eindhoven'),
('CRO', 'Mario Pasalic', 'MF', 'Atalanta Bergamo'),
('CRO', 'Martin Baturina', 'MF', 'Como'),
('CRO', 'Petar Sucic', 'MF', 'Inter Milan'),
('CRO', 'Kristijan Jakic', 'DF', 'FC Augsburg'),
('CRO', 'Toni Fruk', 'MF', 'HNK Rijeka'),
('CRO', 'Igor Matanovic', 'FW', 'SC Freiburg'),
('CRO', 'Luka Sucic', 'MF', 'Real Sociedad'),
('CRO', 'Luka Vuskovic', 'DF', 'Hamburger SV'),
('CRO', 'Dominik Kotarski', 'GK', 'FC København'),
('CRO', 'Marco Pasalic', 'FW', 'Orlando City SC'),
('CRO', 'Martin Erlic', 'DF', 'FC Midtjylland'),
('CRO', 'Petar Musa', 'FW', 'FC Dallas');

-- ---------------------------
-- England (Group L) - 26 players (FIFA official)
-- ---------------------------
INSERT INTO players (team_id, name, position, club) VALUES
('ENG', 'Jordan Pickford', 'GK', 'Everton FC'),
('ENG', 'Ezri Konsa', 'DF', 'Aston Villa FC'),
('ENG', 'Nico Oreilly', 'DF', 'Manchester City FC'),
('ENG', 'Declan Rice', 'MF', 'Arsenal FC'),
('ENG', 'John Stones', 'DF', 'Manchester City FC'),
('ENG', 'Marc Guehi', 'DF', 'Manchester City FC'),
('ENG', 'Bukayo Saka', 'FW', 'Arsenal FC'),
('ENG', 'Elliot Anderson', 'MF', 'Nottingham Forest FC'),
('ENG', 'Harry Kane', 'FW', 'FC Bayern München'),
('ENG', 'Jude Bellingham', 'MF', 'Real Madrid'),
('ENG', 'Marcus Rashford', 'FW', 'FC Barcelona'),
('ENG', 'Tino Livramento', 'DF', 'Newcastle United FC'),
('ENG', 'Dean Henderson', 'GK', 'Crystal Palace FC'),
('ENG', 'Jordan Henderson', 'MF', 'Brentford FC'),
('ENG', 'Dan Burn', 'DF', 'Newcastle United FC'),
('ENG', 'Kobbie Mainoo', 'MF', 'Manchester United FC'),
('ENG', 'Morgan Rogers', 'MF', 'Aston Villa FC'),
('ENG', 'Anthony Gordon', 'FW', 'Newcastle United FC'),
('ENG', 'Ollie Watkins', 'FW', 'Aston Villa FC'),
('ENG', 'Noni Madueke', 'FW', 'Arsenal FC'),
('ENG', 'Eberechi Eze', 'MF', 'Arsenal FC'),
('ENG', 'Ivan Toney', 'FW', 'Al Ahli'),
('ENG', 'James Trafford', 'GK', 'Manchester City FC'),
('ENG', 'Reece James', 'DF', 'Chelsea FC'),
('ENG', 'Djed Spence', 'DF', 'Tottenham Hotspur FC'),
('ENG', 'Jarell Quansah', 'DF', 'Bayer 04 Leverkusen');

-- ---------------------------
-- Ghana (Group L) - 26 players (FIFA official)
-- ---------------------------
INSERT INTO players (team_id, name, position, club) VALUES
('GHA', 'Lawrence Zigi', 'GK', 'FC St. Gallen'),
('GHA', 'Alidu Seidu', 'DF', 'Stade Rennais FC'),
('GHA', 'Caleb Yirenkyi', 'MF', 'FC Nordsjælland'),
('GHA', 'Jonas Adjetey', 'DF', 'VfL Wolfsburg'),
('GHA', 'Thomas Partey', 'MF', 'Villarreal CF'),
('GHA', 'Abdul Mumin', 'DF', 'Rayo Vallecano'),
('GHA', 'Abdul Fatawu', 'FW', 'Leicester City FC'),
('GHA', 'Kwasi Sibo', 'MF', 'Real Oviedo'),
('GHA', 'Jordan Ayew', 'FW', 'Leicester City FC'),
('GHA', 'Brandon Thomas-asante', 'FW', 'Coventry City FC'),
('GHA', 'Antoine Semenyo', 'MF', 'Manchester City FC'),
('GHA', 'Joseph Anang', 'GK', 'St Patrick''s Athletic FC'),
('GHA', 'Christopher Bonsu Baah', 'FW', 'Al-Qadsiah'),
('GHA', 'Gideon Mensah', 'DF', 'AJ Auxerre'),
('GHA', 'Elisha Owusu', 'MF', 'AJ Auxerre'),
('GHA', 'Benjamin Asare', 'GK', 'Hearts Of Oak SC'),
('GHA', 'Baba Rahman', 'DF', 'PAOK Saloniki'),
('GHA', 'Jerome Opoku', 'DF', 'Başakşehir FK'),
('GHA', 'Inaki Williams', 'FW', 'Athletic Club'),
('GHA', 'Augustine Boakye', 'MF', 'AS Saint-Etienne'),
('GHA', 'Kojo Oppong', 'DF', 'OGC Nice'),
('GHA', 'Kamaldeen Sulemana', 'FW', 'Atalanta Bergamo'),
('GHA', 'Derrick Luckassen', 'DF', 'Pafos FC'),
('GHA', 'Ernest Nuamah', 'FW', 'Olympique Lyonnais'),
('GHA', 'Prince Adu', 'FW', 'FC Viktoria Plzeň'),
('GHA', 'Marvin Senaya', 'DF', 'AJ Auxerre');


-- ---------------------------
-- South Korea (Group A) - 26 players
-- ---------------------------
INSERT INTO players (team_id, name, position, club) VALUES
('KOR', 'Kim Seung-gyu', 'GK', 'FC Tokyo'),
('KOR', 'Jo Hyeon-woo', 'GK', 'Ulsan HD'),
('KOR', 'Song Bum-keun', 'GK', 'Jeonbuk Hyundai Motors'),
('KOR', 'Kim Min-jae', 'DF', 'FC Bayern München'),
('KOR', 'Kim Moon-hwan', 'DF', 'Daejeon Hana Citizen'),
('KOR', 'Seol Young-woo', 'DF', 'Red Star Belgrade'),
('KOR', 'Lee Tae-seok', 'DF', 'Austria Wien'),
('KOR', 'Park Jin-seob', 'DF', 'Zhejiang'),
('KOR', 'Kim Tae-hyeon', 'DF', 'Kashima Antlers'),
('KOR', 'Lee Han-beom', 'DF', 'FC Midtjylland'),
('KOR', 'Jens Castrop', 'DF', 'Borussia Mönchengladbach'),
('KOR', 'Lee Ki-hyuk', 'DF', 'Gangwon FC'),
('KOR', 'Cho Wi-je', 'DF', 'Jeonbuk Hyundai Motors'),
('KOR', 'Lee Jae-sung', 'MF', 'Mainz 05'),
('KOR', 'Hwang Hee-chan', 'MF', 'Wolverhampton Wanderers FC'),
('KOR', 'Hwang In-beom', 'MF', 'Feyenoord'),
('KOR', 'Lee Kang-in', 'MF', 'Paris Saint-Germain'),
('KOR', 'Paik Seung-ho', 'MF', 'Birmingham City'),
('KOR', 'Kim Jin-gyu', 'MF', 'Jeonbuk Hyundai Motors'),
('KOR', 'Lee Dong-gyeong', 'MF', 'Ulsan HD'),
('KOR', 'Bae Jun-ho', 'MF', 'Stoke City'),
('KOR', 'Eom Ji-sung', 'MF', 'Swansea City AFC'),
('KOR', 'Yang Hyun-jun', 'MF', 'Celtic FC'),
('KOR', 'Son Heung-min', 'FW', 'LAFC'),
('KOR', 'Cho Gue-sung', 'FW', 'FC Midtjylland'),
('KOR', 'Oh Hyeon-gyu', 'FW', 'Beşiktaş JK');

-- ---------------------------
-- South Africa (Group A) - 26 players
-- ---------------------------
INSERT INTO players (team_id, name, position, club) VALUES
('RSA', 'Ronwen Williams', 'GK', 'Mamelodi Sundowns'),
('RSA', 'Ricardo Goss', 'GK', 'Siwelele'),
('RSA', 'Sipho Chaine', 'GK', 'Orlando Pirates'),
('RSA', 'Aubrey Modiba', 'DF', 'Mamelodi Sundowns'),
('RSA', 'Khuliso Mudau', 'DF', 'Mamelodi Sundowns'),
('RSA', 'Nkosinathi Sibisi', 'DF', 'Orlando Pirates'),
('RSA', 'Mbekezeli Mbokazi', 'DF', 'Chicago Fire FC'),
('RSA', 'Ime Okon', 'DF', 'Hannover 96'),
('RSA', 'Samukele Kabini', 'DF', 'Molde'),
('RSA', 'Khulumani Ndamane', 'DF', 'Mamelodi Sundowns'),
('RSA', 'Thabang Matuludi', 'DF', 'Polokwane City'),
('RSA', 'Kamogelo Sebelebele', 'DF', 'Orlando Pirates'),
('RSA', 'Bradley Cross', 'DF', 'Kaizer Chiefs'),
('RSA', 'Olwethu Makhanya', 'DF', 'Philadelphia Union'),
('RSA', 'Teboho Mokoena', 'MF', 'Mamelodi Sundowns'),
('RSA', 'Sphephelo Sithole', 'MF', 'Tondela'),
('RSA', 'Thalente Mbatha', 'MF', 'Orlando Pirates'),
('RSA', 'Jayden Adams', 'MF', 'Mamelodi Sundowns'),
('RSA', 'Themba Zwane', 'FW', 'Mamelodi Sundowns'),
('RSA', 'Lyle Foster', 'FW', 'Burnley FC'),
('RSA', 'Evidence Makgopa', 'FW', 'Orlando Pirates'),
('RSA', 'Oswin Appollis', 'FW', 'Orlando Pirates'),
('RSA', 'Iqraam Rayners', 'FW', 'Mamelodi Sundowns'),
('RSA', 'Relebohile Mofokeng', 'FW', 'Orlando Pirates'),
('RSA', 'Thapelo Maseko', 'FW', 'AEL Limassol'),
('RSA', 'Tshepang Moremi', 'FW', 'Orlando Pirates');

-- ---------------------------
-- Qatar (Group B) - 26 players
-- ---------------------------
INSERT INTO players (team_id, name, position, club) VALUES
('QAT', 'Mahmud Abunada', 'GK', 'Al-Rayyan'),
('QAT', 'Pedro Miguel', 'DF', 'Al-Sadd'),
('QAT', 'Lucas Mendes', 'DF', 'Al-Wakrah'),
('QAT', 'Issa Laye', 'DF', 'Al-Arabi'),
('QAT', 'Jassem Gaber', 'MF', 'Al-Rayyan'),
('QAT', 'Abdulaziz Hatem', 'MF', 'Al-Rayyan'),
('QAT', 'Ahmed Alaaeldin', 'FW', 'Al-Rayyan'),
('QAT', 'Edmilson Junior', 'FW', 'Al-Duhail'),
('QAT', 'Mohammed Muntari', 'FW', 'Al-Gharafa'),
('QAT', 'Hassan Al-Haydos', 'FW', 'Al-Sadd'),
('QAT', 'Akram Afif', 'FW', 'Al-Sadd'),
('QAT', 'Karim Boudiaf', 'MF', 'Al-Duhail'),
('QAT', 'Ayoub Al-Oui', 'DF', 'Al-Gharafa'),
('QAT', 'Homam Ahmed', 'DF', 'Cultural Leonesa'),
('QAT', 'Yusuf Abdurisag', 'FW', 'Al-Wakrah'),
('QAT', 'Boualem Khoukhi', 'DF', 'Al-Sadd'),
('QAT', 'Ahmed Al-Ganehi', 'FW', 'Al-Gharafa'),
('QAT', 'Sultan Al-Brake', 'DF', 'Al-Duhail'),
('QAT', 'Almoez Ali', 'FW', 'Al-Duhail'),
('QAT', 'Ahmed Fathy', 'MF', 'Al-Arabi'),
('QAT', 'Salah Zakaria', 'GK', 'Al-Duhail'),
('QAT', 'Meshaal Barsham', 'GK', 'Al-Sadd'),
('QAT', 'Assim Madibo', 'MF', 'Al-Wakrah'),
('QAT', 'Tahsin Jamshid', 'FW', 'Al-Duhail'),
('QAT', 'Al-Hashmi Al-Hussain', 'DF', 'Al-Arabi'),
('QAT', 'Mohamed Al-Mannai', 'MF', 'Al-Shamal');

-- ---------------------------
-- Switzerland (Group B) - 26 players
-- ---------------------------
INSERT INTO players (team_id, name, position, club) VALUES
('SUI', 'Gregor Kobel', 'GK', 'Borussia Dortmund'),
('SUI', 'Miro Muheim', 'DF', 'Hamburger SV'),
('SUI', 'Silvan Widmer', 'DF', 'Mainz 05'),
('SUI', 'Nico Elvedi', 'DF', 'Borussia Mönchengladbach'),
('SUI', 'Manuel Akanji', 'DF', 'Inter Milan'),
('SUI', 'Denis Zakaria', 'MF', 'AS Monaco'),
('SUI', 'Breel Embolo', 'FW', 'Rennes'),
('SUI', 'Remo Freuler', 'MF', 'Bologna FC'),
('SUI', 'Johan Manzambi', 'MF', 'SC Freiburg'),
('SUI', 'Granit Xhaka', 'MF', 'Sunderland AFC'),
('SUI', 'Dan Ndoye', 'FW', 'Nottingham Forest FC'),
('SUI', 'Yvon Mvogo', 'GK', 'Lorient'),
('SUI', 'Ricardo Rodriguez', 'DF', 'Real Betis'),
('SUI', 'Ardon Jashari', 'MF', 'AC Milan'),
('SUI', 'Djibril Sow', 'MF', 'Sevilla'),
('SUI', 'Christian Fassnacht', 'MF', 'BSC Young Boys'),
('SUI', 'Rubén Vargas', 'FW', 'Sevilla'),
('SUI', 'Eray Cömert', 'DF', 'Valencia'),
('SUI', 'Noah Okafor', 'FW', 'Leeds United'),
('SUI', 'Michel Aebischer', 'MF', 'Pisa'),
('SUI', 'Marvin Keller', 'GK', 'BSC Young Boys'),
('SUI', 'Fabian Rieder', 'MF', 'FC Augsburg'),
('SUI', 'Zeki Amdouni', 'FW', 'Burnley FC'),
('SUI', 'Aurèle Amenda', 'DF', 'Eintracht Frankfurt'),
('SUI', 'Luca Jaquez', 'DF', 'VfB Stuttgart'),
('SUI', 'Cedric Itten', 'FW', 'Fortuna Düsseldorf');

-- ---------------------------
-- Scotland (Group C) - 26 players
-- ---------------------------
INSERT INTO players (team_id, name, position, club) VALUES
('SCO', 'Craig Gordon', 'GK', 'Heart Of Midlothian FC'),
('SCO', 'Angus Gunn', 'GK', 'Nottingham Forest FC'),
('SCO', 'Liam Kelly', 'GK', 'Rangers FC'),
('SCO', 'Andy Robertson', 'DF', 'Liverpool FC'),
('SCO', 'Grant Hanley', 'DF', 'Hibernian'),
('SCO', 'Kieran Tierney', 'DF', 'Celtic FC'),
('SCO', 'Scott McKenna', 'DF', 'GNK Dinamo Zagreb'),
('SCO', 'Jack Hendry', 'DF', 'Al-Ettifaq'),
('SCO', 'Nathan Patterson', 'DF', 'Everton FC'),
('SCO', 'Anthony Ralston', 'DF', 'Celtic FC'),
('SCO', 'John Souttar', 'DF', 'Rangers FC'),
('SCO', 'Aaron Hickey', 'DF', 'Brentford FC'),
('SCO', 'Dominic Hyam', 'DF', 'Wrexham AFC'),
('SCO', 'John McGinn', 'MF', 'Aston Villa FC'),
('SCO', 'Scott McTominay', 'MF', 'SSC Napoli'),
('SCO', 'Ryan Christie', 'MF', 'Bournemouth'),
('SCO', 'Kenny McLean', 'MF', 'Norwich City FC'),
('SCO', 'Lewis Ferguson', 'MF', 'Bologna FC'),
('SCO', 'Ben Gannon-Doak', 'MF', 'Bournemouth'),
('SCO', 'Findlay Curtis', 'MF', 'Kilmarnock FC'),
('SCO', 'Tyler Fletcher', 'MF', 'Manchester United FC'),
('SCO', 'Lyndon Dykes', 'FW', 'Charlton Athletic'),
('SCO', 'Ché Adams', 'FW', 'Torino FC'),
('SCO', 'Lawrence Shankland', 'FW', 'Heart Of Midlothian FC'),
('SCO', 'George Hirst', 'FW', 'Ipswich Town'),
('SCO', 'Ross Stewart', 'FW', 'Southampton FC');

-- ---------------------------
-- Paraguay (Group D) - 26 players
-- ---------------------------
INSERT INTO players (team_id, name, position, club) VALUES
('PAR', 'Gatito Fernández', 'GK', 'Cerro Porteño'),
('PAR', 'Orlando Gill', 'GK', 'San Lorenzo'),
('PAR', 'Gastón Olveira', 'GK', 'Olimpia'),
('PAR', 'Gustavo Gómez', 'DF', 'SE Palmeiras'),
('PAR', 'Júnior Alonso', 'DF', 'Atlético Mineiro'),
('PAR', 'Fabián Balbuena', 'DF', 'Grêmio'),
('PAR', 'Omar Alderete', 'DF', 'Sunderland AFC'),
('PAR', 'Juan José Cáceres', 'DF', 'Dynamo Moscow'),
('PAR', 'Gustavo Velázquez', 'DF', 'Cerro Porteño'),
('PAR', 'José Canale', 'DF', 'Lanús'),
('PAR', 'Alexandro Maidana', 'DF', 'Talleres'),
('PAR', 'Miguel Almirón', 'MF', 'Atlanta United FC'),
('PAR', 'Kaku', 'MF', 'Al-Ain'),
('PAR', 'Andrés Cubas', 'MF', 'Vancouver Whitecaps FC'),
('PAR', 'Ramón Sosa', 'MF', 'SE Palmeiras'),
('PAR', 'Diego Gómez', 'MF', 'Brighton & Hove Albion FC'),
('PAR', 'Damián Bobadilla', 'MF', 'São Paulo'),
('PAR', 'Braian Ojeda', 'MF', 'Orlando City SC'),
('PAR', 'Matías Galarza', 'MF', 'Atlanta United FC'),
('PAR', 'Maurício', 'MF', 'SE Palmeiras'),
('PAR', 'Antonio Sanabria', 'FW', 'Cremonese'),
('PAR', 'Julio Enciso', 'FW', 'RC Strasbourg'),
('PAR', 'Gabriel Ávalos', 'FW', 'Independiente'),
('PAR', 'Álex Arce', 'FW', 'Independiente Rivadavia'),
('PAR', 'Isidro Pitta', 'FW', 'Red Bull Bragantino'),
('PAR', 'Gustavo Caballero', 'FW', 'Portsmouth');

-- ---------------------------
-- United States (Group D) - 26 players
-- ---------------------------
INSERT INTO players (team_id, name, position, club) VALUES
('USA', 'Matt Turner', 'GK', 'New England Revolution'),
('USA', 'Sergiño Dest', 'DF', 'PSV Eindhoven'),
('USA', 'Chris Richards', 'DF', 'Crystal Palace FC'),
('USA', 'Tyler Adams', 'MF', 'Bournemouth'),
('USA', 'Antonee Robinson', 'DF', 'Fulham FC'),
('USA', 'Auston Trusty', 'DF', 'Celtic FC'),
('USA', 'Giovanni Reyna', 'MF', 'Borussia Mönchengladbach'),
('USA', 'Weston McKennie', 'MF', 'Juventus FC'),
('USA', 'Ricardo Pepi', 'FW', 'PSV Eindhoven'),
('USA', 'Christian Pulisic', 'FW', 'AC Milan'),
('USA', 'Brenden Aaronson', 'FW', 'Leeds United'),
('USA', 'Miles Robinson', 'DF', 'FC Cincinnati'),
('USA', 'Tim Ream', 'DF', 'Charlotte FC'),
('USA', 'Sebastian Berhalter', 'MF', 'Vancouver Whitecaps FC'),
('USA', 'Cristian Roldan', 'MF', 'Seattle Sounders FC'),
('USA', 'Alex Freeman', 'DF', 'Villarreal CF'),
('USA', 'Malik Tillman', 'MF', 'Bayer 04 Leverkusen'),
('USA', 'Maximilian Arfsten', 'DF', 'Columbus Crew'),
('USA', 'Haji Wright', 'FW', 'Coventry City FC'),
('USA', 'Folarin Balogun', 'FW', 'AS Monaco'),
('USA', 'Timothy Weah', 'FW', 'Olympique Marseille'),
('USA', 'Mark McKenzie', 'DF', 'Toulouse'),
('USA', 'Joe Scally', 'DF', 'Borussia Mönchengladbach'),
('USA', 'Matt Freese', 'GK', 'New York City FC'),
('USA', 'Chris Brady', 'GK', 'Chicago Fire FC'),
('USA', 'Alejandro Zendejas', 'FW', 'América');

-- ---------------------------
-- Japan (Group F) - 26 players
-- ---------------------------
INSERT INTO players (team_id, name, position, club) VALUES
('JPN', 'Zion Suzuki', 'GK', 'Parma'),
('JPN', 'Yukinari Sugawara', 'DF', 'SV Werder Bremen'),
('JPN', 'Shōgo Taniguchi', 'DF', 'Sint-Truiden'),
('JPN', 'Kō Itakura', 'DF', 'AFC Ajax'),
('JPN', 'Yūto Nagatomo', 'DF', 'FC Tokyo'),
('JPN', 'Wataru Endo', 'MF', 'Liverpool FC'),
('JPN', 'Ao Tanaka', 'MF', 'Leeds United'),
('JPN', 'Takefusa Kubo', 'MF', 'Real Sociedad'),
('JPN', 'Keisuke Gotō', 'FW', 'Sint-Truiden'),
('JPN', 'Ritsu Dōan', 'MF', 'Eintracht Frankfurt'),
('JPN', 'Daizen Maeda', 'FW', 'Celtic FC'),
('JPN', 'Keisuke Ōsako', 'GK', 'Sanfrecce Hiroshima'),
('JPN', 'Keito Nakamura', 'MF', 'Reims'),
('JPN', 'Junya Itō', 'MF', 'KRC Genk'),
('JPN', 'Daichi Kamada', 'MF', 'Crystal Palace FC'),
('JPN', 'Tsuyoshi Watanabe', 'DF', 'Feyenoord'),
('JPN', 'Yuito Suzuki', 'FW', 'SC Freiburg'),
('JPN', 'Ayase Ueda', 'FW', 'Feyenoord'),
('JPN', 'Kōki Ogawa', 'FW', 'NEC'),
('JPN', 'Ayumu Seko', 'DF', 'Le Havre AC'),
('JPN', 'Hiroki Itō', 'DF', 'FC Bayern München'),
('JPN', 'Takehiro Tomiyasu', 'DF', 'AFC Ajax'),
('JPN', 'Tomoki Hayakawa', 'GK', 'Kashima Antlers'),
('JPN', 'Kaishū Sano', 'MF', 'Mainz 05'),
('JPN', 'Junnosuke Suzuki', 'DF', 'Copenhagen'),
('JPN', 'Kento Shiogai', 'FW', 'VfL Wolfsburg');

-- ---------------------------
-- Netherlands (Group F) - 26 players
-- ---------------------------
INSERT INTO players (team_id, name, position, club) VALUES
('NED', 'Bart Verbruggen', 'GK', 'Brighton & Hove Albion FC'),
('NED', 'Mark Flekken', 'GK', 'Bayer 04 Leverkusen'),
('NED', 'Robin Roefs', 'GK', 'Sunderland AFC'),
('NED', 'Virgil van Dijk', 'DF', 'Liverpool FC'),
('NED', 'Denzel Dumfries', 'DF', 'Inter Milan'),
('NED', 'Nathan Aké', 'DF', 'Manchester City FC'),
('NED', 'Jurriën Timber', 'DF', 'Arsenal FC'),
('NED', 'Micky van de Ven', 'DF', 'Tottenham Hotspur FC'),
('NED', 'Mats Wieffer', 'DF', 'Brighton & Hove Albion FC'),
('NED', 'Jan Paul van Hecke', 'DF', 'Brighton & Hove Albion FC'),
('NED', 'Jorrel Hato', 'DF', 'Chelsea FC'),
('NED', 'Frenkie de Jong', 'MF', 'FC Barcelona'),
('NED', 'Marten de Roon', 'MF', 'Atalanta'),
('NED', 'Tijjani Reijnders', 'MF', 'Manchester City FC'),
('NED', 'Teun Koopmeiners', 'MF', 'Juventus FC'),
('NED', 'Ryan Gravenberch', 'MF', 'Liverpool FC'),
('NED', 'Justin Kluivert', 'MF', 'Bournemouth'),
('NED', 'Quinten Timber', 'MF', 'Olympique Marseille'),
('NED', 'Guus Til', 'MF', 'PSV Eindhoven'),
('NED', 'Memphis Depay', 'FW', 'Corinthians'),
('NED', 'Wout Weghorst', 'FW', 'AFC Ajax'),
('NED', 'Donyell Malen', 'FW', 'AS Roma'),
('NED', 'Cody Gakpo', 'FW', 'Liverpool FC'),
('NED', 'Noa Lang', 'FW', 'Galatasaray SK'),
('NED', 'Brian Brobbey', 'FW', 'Sunderland AFC'),
('NED', 'Crysencio Summerville', 'FW', 'West Ham United FC');

-- ---------------------------
-- Sweden (Group F) - 26 players
-- ---------------------------
INSERT INTO players (team_id, name, position, club) VALUES
('SWE', 'Jacob Widell Zetterström', 'GK', 'Derby County'),
('SWE', 'Gustaf Lagerbielke', 'DF', 'SC Braga'),
('SWE', 'Victor Lindelöf', 'DF', 'Aston Villa FC'),
('SWE', 'Isak Hien', 'DF', 'Atalanta'),
('SWE', 'Gabriel Gudmundsson', 'DF', 'Leeds United'),
('SWE', 'Herman Johansson', 'DF', 'FC Dallas'),
('SWE', 'Lucas Bergvall', 'MF', 'Tottenham Hotspur FC'),
('SWE', 'Daniel Svensson', 'DF', 'Borussia Dortmund'),
('SWE', 'Alexander Isak', 'FW', 'Liverpool FC'),
('SWE', 'Benjamin Nygren', 'FW', 'Celtic FC'),
('SWE', 'Anthony Elanga', 'FW', 'Newcastle United FC'),
('SWE', 'Viktor Johansson', 'GK', 'Stoke City'),
('SWE', 'Ken Sema', 'FW', 'Pafos FC'),
('SWE', 'Hjalmar Ekdal', 'DF', 'Burnley FC'),
('SWE', 'Carl Starfelt', 'DF', 'Celta Vigo'),
('SWE', 'Jesper Karlström', 'MF', 'Udinese'),
('SWE', 'Viktor Gyökeres', 'FW', 'Arsenal FC'),
('SWE', 'Yasin Ayari', 'MF', 'Brighton & Hove Albion FC'),
('SWE', 'Mattias Svanberg', 'MF', 'VfL Wolfsburg'),
('SWE', 'Eric Smith', 'DF', 'FC St. Pauli'),
('SWE', 'Alexander Bernhardsson', 'FW', 'Holstein Kiel'),
('SWE', 'Besfort Zeneli', 'MF', 'Union Saint-Gilloise'),
('SWE', 'Kristoffer Nordfeldt', 'GK', 'AIK'),
('SWE', 'Elliot Stroud', 'DF', 'Mjällby AIF'),
('SWE', 'Gustaf Nilsson', 'FW', 'Club Brugge'),
('SWE', 'Taha Ali', 'FW', 'Malmö FF');

-- ---------------------------
-- Tunisia (Group F) - 26 players
-- ---------------------------
INSERT INTO players (team_id, name, position, club) VALUES
('TUN', 'Aymen Dahmen', 'GK', 'CS Sfaxien'),
('TUN', 'Sabri Ben Hessen', 'GK', 'Étoile du Sahel'),
('TUN', 'Mouhib Chamakh', 'GK', 'Club Africain'),
('TUN', 'Montassar Talbi', 'DF', 'Lorient'),
('TUN', 'Dylan Bronn', 'DF', 'Servette'),
('TUN', 'Ali Abdi', 'DF', 'Nice'),
('TUN', 'Yan Valery', 'DF', 'BSC Young Boys'),
('TUN', 'Mohamed Amine Ben Hamida', 'DF', 'Espérance de Tunis'),
('TUN', 'Moutaz Neffati', 'DF', 'IFK Norrköping'),
('TUN', 'Omar Rekik', 'DF', 'NK Maribor'),
('TUN', 'Adem Arous', 'DF', 'Kasımpaşa'),
('TUN', 'Raed Chikhaoui', 'DF', 'US Monastir'),
('TUN', 'Ellyes Skhiri', 'MF', 'Eintracht Frankfurt'),
('TUN', 'Hannibal Mejbri', 'MF', 'Burnley FC'),
('TUN', 'Anis Ben Slimane', 'MF', 'Norwich City FC'),
('TUN', 'Mortadha Ben Ouanes', 'MF', 'Kasımpaşa'),
('TUN', 'Ismaël Gharbi', 'MF', 'FC Augsburg'),
('TUN', 'Hadj Mahmoud', 'MF', 'FC Lugano'),
('TUN', 'Rani Khedira', 'MF', 'Union Berlin'),
('TUN', 'Elias Achouri', 'FW', 'Copenhagen'),
('TUN', 'Firas Chaouat', 'FW', 'Club Africain'),
('TUN', 'Hazem Mastouri', 'FW', 'Dynamo Makhachkala'),
('TUN', 'Elias Saad', 'FW', 'Hannover 96'),
('TUN', 'Sebastian Tounekti', 'FW', 'Celtic FC'),
('TUN', 'Khalil Ayari', 'FW', 'Paris Saint-Germain'),
('TUN', 'Rayan Elloumi', 'FW', 'Vancouver Whitecaps FC');


-- worldcuppass.com squads: 11 teams
-- TUR to be added after separate fetch

-- Iran (Group G) - 26 players (worldcuppass.com)
INSERT INTO players (team_id, name, position, club) VALUES
('IRN', 'Alireza Beiranvand', 'GK', 'Tractor'),
('IRN', 'Payam Niazmand', 'GK', 'Persepolis'),
('IRN', 'Hossein Hosseini', 'GK', 'Sepahan'),
('IRN', 'Ehsan Hajsafi', 'DF', 'Sepahan'),
('IRN', 'Milad Mohammadi', 'DF', 'Persepolis'),
('IRN', 'Ramin Rezaeian', 'DF', 'Foolad'),
('IRN', 'Hossein Kanaanizadegan', 'DF', 'Persepolis'),
('IRN', 'Shojae Khalilzadeh', 'DF', 'Tractor'),
('IRN', 'Saleh Hardani', 'DF', 'Esteghlal'),
('IRN', 'Ali Nemati', 'DF', 'Foolad'),
('IRN', 'Danial Eiri', 'DF', 'Malavan'),
('IRN', 'Alireza Jahanbakhsh', 'MF', 'Dender'),
('IRN', 'Saeid Ezatolahi', 'MF', 'Shabab Al-Ahli'),
('IRN', 'Saman Ghoddos', 'MF', 'Ittihad Kalba'),
('IRN', 'Mehdi Torabi', 'MF', 'Tractor'),
('IRN', 'Rouzbeh Cheshmi', 'MF', 'Esteghlal'),
('IRN', 'Mohammad Mohebi', 'MF', 'Rostov'),
('IRN', 'Mehdi Ghayedi', 'MF', 'Al-Nassr'),
('IRN', 'Mohammad Ghorbani', 'MF', 'Al Wahda'),
('IRN', 'Aria Yousefi', 'MF', 'Sepahan'),
('IRN', 'Amirmohammad Razzaghinia', 'MF', 'Esteghlal'),
('IRN', 'Mehdi Taremi', 'FW', 'Olympiacos'),
('IRN', 'Shahriyar Moghanlou', 'FW', 'Ittihad Kalba'),
('IRN', 'Amirhossein Hosseinzadeh', 'FW', 'Tractor'),
('IRN', 'Ali Alipour', 'FW', 'Persepolis'),
('IRN', 'Dennis Dargahi', 'FW', 'Standard Liège');

-- New Zealand (Group G) - 26 players (worldcuppass.com)
INSERT INTO players (team_id, name, position, club) VALUES
('NZL', 'Max Crocombe', 'GK', 'Millwall'),
('NZL', 'Alex Paulsen', 'GK', 'Lechia Gdansk'),
('NZL', 'Michael Woud', 'GK', 'Auckland FC'),
('NZL', 'Tim Payne', 'DF', 'Wellington Phoenix'),
('NZL', 'Francis De Vries', 'DF', 'Auckland FC'),
('NZL', 'Tyler Bindon', 'DF', 'Nottingham Forest FC'),
('NZL', 'Michael Boxall', 'DF', 'Minnesota United FC'),
('NZL', 'Liberato Cacace', 'DF', 'Wrexham AFC'),
('NZL', 'Nando Pijnaker', 'DF', 'Auckland FC'),
('NZL', 'Finn Surman', 'DF', 'Portland Timbers'),
('NZL', 'Callan Elliot', 'DF', 'Auckland FC'),
('NZL', 'Tommy Smith', 'DF', 'Braintree Town'),
('NZL', 'Lachlan Bayliss', 'MF', 'Newcastle Jets'),
('NZL', 'Joe Bell', 'MF', 'Viking FK'),
('NZL', 'Matt Garbett', 'MF', 'Peterborough United'),
('NZL', 'Ben Old', 'MF', 'AS Saint-Etienne'),
('NZL', 'Alex Rufer', 'MF', 'Wellington Phoenix'),
('NZL', 'Sarpreet Singh', 'MF', 'Wellington Phoenix'),
('NZL', 'Marko Stamenic', 'MF', 'Swansea City AFC'),
('NZL', 'Ryan Thomas', 'MF', 'PEC Zwolle'),
('NZL', 'Kosta Barbarouses', 'FW', 'Western Sydney Wanderers'),
('NZL', 'Eli Just', 'FW', 'Motherwell'),
('NZL', 'Callum McCowatt', 'FW', 'Silkeborg'),
('NZL', 'Jesse Randall', 'FW', 'Auckland FC'),
('NZL', 'Ben Waine', 'FW', 'Port Vale'),
('NZL', 'Chris Wood', 'FW', 'Nottingham Forest FC');

-- Saudi Arabia (Group H) - 26 players (worldcuppass.com)
INSERT INTO players (team_id, name, position, club) VALUES
('KSA', 'Mohammed Al Owais', 'GK', 'Al Ula'),
('KSA', 'Nawaf Al Aqidi', 'GK', 'Al-Nassr'),
('KSA', 'Ahmed Al Kassar', 'GK', 'Al-Qadsiah'),
('KSA', 'Abdulelah Al Amri', 'DF', 'Al-Nassr'),
('KSA', 'Hassan Tambakti', 'DF', 'Al-Hilal'),
('KSA', 'Jehad Thikri', 'DF', 'Al-Qadsiah'),
('KSA', 'Ali Lajami', 'DF', 'Al-Hilal'),
('KSA', 'Hassan Kadesh', 'DF', 'Al Ittihad'),
('KSA', 'Saud Abdulhamid', 'DF', 'RC Lens'),
('KSA', 'Mohammed Abu Al Shamat', 'DF', 'Al-Qadsiah'),
('KSA', 'Ali Majrashi', 'DF', 'Al Ahli'),
('KSA', 'Moteb Al Harbi', 'DF', 'Al-Hilal'),
('KSA', 'Nawaf Boushal', 'DF', 'Al-Nassr'),
('KSA', 'Mohammed Kanno', 'MF', 'Al-Hilal'),
('KSA', 'Abdullah Al Khaibari', 'MF', 'Al-Nassr'),
('KSA', 'Ziyad Al Johani', 'MF', 'Al Ahli'),
('KSA', 'Nasser Al Dawsari', 'MF', 'Al-Hilal'),
('KSA', 'Musab Al Juwayr', 'MF', 'Al-Qadsiah'),
('KSA', 'Sultan Mandash', 'MF', 'Al-Hilal'),
('KSA', 'Alaa Al Hajji', 'MF', 'Neom SC'),
('KSA', 'Salem Al-Dawsari', 'FW', 'Al-Hilal'),
('KSA', 'Firas Al-Buraikan', 'FW', 'Al Ahli'),
('KSA', 'Saleh Al Shehri', 'FW', 'Al Ittihad'),
('KSA', 'Abdullah Al Hamdan', 'FW', 'Al-Nassr'),
('KSA', 'Khalid Al Ghannam', 'FW', 'Al-Ettifaq'),
('KSA', 'Ayman Yahya', 'FW', 'Al-Nassr');

-- Uruguay (Group H) - 26 players (worldcuppass.com)
INSERT INTO players (team_id, name, position, club) VALUES
('URU', 'Sergio Rochet', 'GK', 'SC Internacional'),
('URU', 'Fernando Muslera', 'GK', 'Estudiantes'),
('URU', 'Santiago Mele', 'GK', 'Monterrey'),
('URU', 'Guillermo Varela', 'DF', 'CR Flamengo'),
('URU', 'Ronald Araujo', 'DF', 'FC Barcelona'),
('URU', 'Jose Maria Gimenez', 'DF', 'Atlético Madrid'),
('URU', 'Santiago Bueno', 'DF', 'Wolverhampton Wanderers FC'),
('URU', 'Sebastian Caceres', 'DF', 'Club America'),
('URU', 'Mathias Olivera', 'DF', 'SSC Napoli'),
('URU', 'Matias Vina', 'DF', 'River Plate'),
('URU', 'Joaquin Piquerez', 'DF', 'SE Palmeiras'),
('URU', 'Manuel Ugarte', 'MF', 'Manchester United FC'),
('URU', 'Emiliano Martinez', 'MF', 'SE Palmeiras'),
('URU', 'Rodrigo Bentancur', 'MF', 'Tottenham Hotspur FC'),
('URU', 'Federico Valverde', 'MF', 'Real Madrid'),
('URU', 'Agustin Canobbio', 'MF', 'Fluminense'),
('URU', 'Juan Manuel Sanabria', 'MF', 'Real Salt Lake'),
('URU', 'Giorgian de Arrascaeta', 'MF', 'CR Flamengo'),
('URU', 'Nicolas de la Cruz', 'MF', 'CR Flamengo'),
('URU', 'Rodrigo Zalazar', 'MF', 'SC Braga'),
('URU', 'Facundo Pellistri', 'MF', 'Panathinaikos FC'),
('URU', 'Maximiliano Araujo', 'MF', 'Sporting CP'),
('URU', 'Brian Rodriguez', 'MF', 'Club America'),
('URU', 'Rodrigo Aguirre', 'FW', 'Tigres UANL'),
('URU', 'Federico Vinas', 'FW', 'Real Oviedo'),
('URU', 'Darwin Nunez', 'FW', 'Al-Hilal');

-- Senegal (Group I) - 26 players (worldcuppass.com)
INSERT INTO players (team_id, name, position, club) VALUES
('SEN', 'Edouard Mendy', 'GK', 'Al Ahli'),
('SEN', 'Mory Diaw', 'GK', 'Le Havre AC'),
('SEN', 'Yehvann Diouf', 'GK', 'Nice'),
('SEN', 'Kalidou Koulibaly', 'DF', 'Al-Hilal'),
('SEN', 'Krepin Diatta', 'DF', 'AS Monaco'),
('SEN', 'Moussa Niakhate', 'DF', 'Olympique Lyonnais'),
('SEN', 'Ismail Jakobs', 'DF', 'Galatasaray SK'),
('SEN', 'Abdoulaye Seck', 'DF', 'Maccabi Haifa FC'),
('SEN', 'El Hadji Malick Diouf', 'DF', 'West Ham United FC'),
('SEN', 'Mamadou Sarr', 'DF', 'Chelsea FC'),
('SEN', 'Antoine Mendy', 'DF', 'Nice'),
('SEN', 'Idrissa Gana Gueye', 'MF', 'Everton FC'),
('SEN', 'Pape Gueye', 'MF', 'Villarreal CF'),
('SEN', 'Pape Matar Sarr', 'MF', 'Tottenham Hotspur FC'),
('SEN', 'Lamine Camara', 'MF', 'AS Monaco'),
('SEN', 'Pathe Ciss', 'MF', 'Rayo Vallecano'),
('SEN', 'Habib Diarra', 'MF', 'Sunderland AFC'),
('SEN', 'Bara Ndiaye', 'MF', 'FC Bayern München'),
('SEN', 'Sadio Mane', 'FW', 'Al-Nassr'),
('SEN', 'Ismaila Sarr', 'FW', 'Crystal Palace FC'),
('SEN', 'Iliman Ndiaye', 'FW', 'Everton FC'),
('SEN', 'Nicolas Jackson', 'FW', 'FC Bayern München'),
('SEN', 'Bamba Dieng', 'FW', 'Lorient'),
('SEN', 'Cherif Ndiaye', 'FW', 'Samsunspor'),
('SEN', 'Ibrahim Mbaye', 'FW', 'Paris Saint-Germain'),
('SEN', 'Assane Diao', 'FW', 'Como');

-- Iraq (Group I) - 26 players (worldcuppass.com)
INSERT INTO players (team_id, name, position, club) VALUES
('IRQ', 'Fahad Talib', 'GK', 'Al-Talaba'),
('IRQ', 'Jalal Hassan', 'GK', 'Al-Zawraa'),
('IRQ', 'Ahmed Basil', 'GK', 'Al-Shorta'),
('IRQ', 'Hussein Ali', 'DF', 'Pogon Szczecin'),
('IRQ', 'Manaf Younis', 'DF', 'Al-Shorta'),
('IRQ', 'Zaid Tahseen', 'DF', 'Pakhtakor'),
('IRQ', 'Rebin Sulaka', 'DF', 'Port FC'),
('IRQ', 'Akam Hashem', 'DF', 'Al-Zawraa'),
('IRQ', 'Merchas Doski', 'DF', 'FC Viktoria Plzeň'),
('IRQ', 'Ahmed Yahya', 'DF', 'Al-Shorta'),
('IRQ', 'Zaid Ismail', 'DF', 'Al-Talaba'),
('IRQ', 'Frans Putros', 'DF', 'Persib'),
('IRQ', 'Mustafa Saadoon', 'DF', 'Al-Shorta'),
('IRQ', 'Amir Al-Ammari', 'MF', 'Cracovia'),
('IRQ', 'Kevin Yakob', 'MF', 'AGF'),
('IRQ', 'Zidane Iqbal', 'MF', 'Utrecht'),
('IRQ', 'Aimar Sher', 'MF', 'Sarpsborg 08'),
('IRQ', 'Ibrahim Bayesh', 'MF', 'Al-Dhafra'),
('IRQ', 'Ahmed Qasim', 'MF', 'Nashville SC'),
('IRQ', 'Youssef Amyn', 'MF', 'AEK Larnaca'),
('IRQ', 'Marko Farji', 'MF', 'Venezia FC'),
('IRQ', 'Ali Jassim', 'FW', 'Al-Najma'),
('IRQ', 'Ali Al-Hamadi', 'FW', 'Luton Town'),
('IRQ', 'Ali Yousef', 'FW', 'Al-Talaba'),
('IRQ', 'Aymen Hussein', 'FW', 'Al-Karma'),
('IRQ', 'Mohanad Ali', 'FW', 'Dibba Al-Fujairah');

-- Norway (Group I) - 26 players (worldcuppass.com)
INSERT INTO players (team_id, name, position, club) VALUES
('NOR', 'Orjan Nyland', 'GK', 'Sevilla'),
('NOR', 'Egil Selvik', 'GK', 'Watford FC'),
('NOR', 'Sander Tangvik', 'GK', 'Hamburger SV'),
('NOR', 'Kristoffer Ajer', 'DF', 'Brentford FC'),
('NOR', 'Julian Ryerson', 'DF', 'Borussia Dortmund'),
('NOR', 'Leo Ostigard', 'DF', 'Genoa'),
('NOR', 'Marcus Holmgren Pedersen', 'DF', 'Torino FC'),
('NOR', 'David Moller Wolfe', 'DF', 'Wolverhampton Wanderers FC'),
('NOR', 'Fredrik Bjorkan', 'DF', 'Bodo/Glimt'),
('NOR', 'Torbjorn Heggem', 'DF', 'Bologna FC'),
('NOR', 'Sondre Langas', 'DF', 'Derby County'),
('NOR', 'Henrik Falchener', 'DF', 'Viking FK'),
('NOR', 'Martin Odegaard', 'MF', 'Arsenal FC'),
('NOR', 'Sander Berge', 'MF', 'Fulham FC'),
('NOR', 'Patrick Berg', 'MF', 'Bodo/Glimt'),
('NOR', 'Kristian Thorstvedt', 'MF', 'US Sassuolo'),
('NOR', 'Morten Thorsby', 'MF', 'Cremonese'),
('NOR', 'Antonio Nusa', 'MF', 'RB Leipzig'),
('NOR', 'Fredrik Aursnes', 'MF', 'Benfica'),
('NOR', 'Oscar Bobb', 'MF', 'Fulham FC'),
('NOR', 'Jens Petter Hauge', 'MF', 'Bodo/Glimt'),
('NOR', 'Andreas Schjelderup', 'MF', 'Benfica'),
('NOR', 'Thelo Aasgaard', 'MF', 'Rangers FC'),
('NOR', 'Alexander Sorloth', 'FW', 'Atlético Madrid'),
('NOR', 'Erling Haaland', 'FW', 'Manchester City FC'),
('NOR', 'Jorgen Strand Larsen', 'FW', 'Crystal Palace FC');

-- Jordan (Group J) - 26 players (worldcuppass.com)
INSERT INTO players (team_id, name, position, club) VALUES
('JOR', 'Yazeed Abulaila', 'GK', 'Al-Hussein'),
('JOR', 'Nour Bani Attiah', 'GK', 'Al-Faisaly'),
('JOR', 'Abdallah Al-Fakhouri', 'GK', 'Al-Wehdat'),
('JOR', 'Mohammad Abu Hashish', 'DF', 'Al-Karma'),
('JOR', 'Abdallah Nasib', 'DF', 'Al-Zawraa'),
('JOR', 'Husam Abu Dahab', 'DF', 'Al-Faisaly'),
('JOR', 'Yazan Al-Arab', 'DF', 'FC Seoul'),
('JOR', 'Mohammad Abualnadi', 'DF', 'Selangor'),
('JOR', 'Salim Obaid', 'DF', 'Al-Hussein'),
('JOR', 'Saed Al-Rosan', 'DF', 'Al-Hussein'),
('JOR', 'Ihsan Haddad', 'DF', 'Al-Hussein'),
('JOR', 'Anas Badawi', 'DF', 'Al-Faisaly'),
('JOR', 'Mohannad Abu Taha', 'DF', 'Al-Quwa Al-Jawiya'),
('JOR', 'Noor Al-Rawabdeh', 'MF', 'Selangor'),
('JOR', 'Nizar Al-Rashdan', 'MF', 'Qatar SC'),
('JOR', 'Ibrahim Sadeh', 'MF', 'Al-Karma'),
('JOR', 'Rajaei Ayed', 'MF', 'Al-Hussein'),
('JOR', 'Amer Jamous', 'MF', 'Al-Zawraa'),
('JOR', 'Mohammad Al-Dawoud', 'MF', 'Al-Wehdat'),
('JOR', 'Mahmoud Al-Mardi', 'FW', 'Al-Hussein'),
('JOR', 'Odeh Al-Fakhouri', 'FW', 'Pyramids FC'),
('JOR', 'Musa Al-Tamari', 'FW', 'Rennes'),
('JOR', 'Mohammad Abu Zrayq', 'FW', 'Raja Casablanca'),
('JOR', 'Ali Azaizeh', 'FW', 'Al-Shabab'),
('JOR', 'Ibrahim Sabra', 'FW', 'Lokomotiva Zagreb'),
('JOR', 'Ali Olwan', 'FW', 'Al-Sailiya');

-- Portugal (Group K) - 26 players (worldcuppass.com)
INSERT INTO players (team_id, name, position, club) VALUES
('POR', 'Diogo Costa', 'GK', 'FC Porto'),
('POR', 'Jose Sa', 'GK', 'Wolverhampton Wanderers FC'),
('POR', 'Rui Silva', 'GK', 'Sporting CP'),
('POR', 'Ruben Dias', 'DF', 'Manchester City FC'),
('POR', 'Joao Cancelo', 'DF', 'FC Barcelona'),
('POR', 'Nelson Semedo', 'DF', 'Fenerbahçe'),
('POR', 'Nuno Mendes', 'DF', 'Paris Saint-Germain'),
('POR', 'Diogo Dalot', 'DF', 'Manchester United FC'),
('POR', 'Goncalo Inacio', 'DF', 'Sporting CP'),
('POR', 'Renato Veiga', 'DF', 'Villarreal CF'),
('POR', 'Tomas Araujo', 'DF', 'Benfica'),
('POR', 'Bernardo Silva', 'MF', 'Manchester City FC'),
('POR', 'Bruno Fernandes', 'MF', 'Manchester United FC'),
('POR', 'Ruben Neves', 'MF', 'Al-Hilal'),
('POR', 'Vitinha', 'MF', 'Paris Saint-Germain'),
('POR', 'Joao Neves', 'MF', 'Paris Saint-Germain'),
('POR', 'Matheus Nunes', 'MF', 'Manchester City FC'),
('POR', 'Samu Costa', 'MF', 'RCD Mallorca'),
('POR', 'Cristiano Ronaldo', 'FW', 'Al-Nassr'),
('POR', 'Francisco Trincao', 'FW', 'Sporting CP'),
('POR', 'Joao Felix', 'FW', 'Al-Nassr'),
('POR', 'Rafael Leao', 'FW', 'AC Milan'),
('POR', 'Goncalo Guedes', 'FW', 'Real Sociedad'),
('POR', 'Goncalo Ramos', 'FW', 'Paris Saint-Germain'),
('POR', 'Pedro Neto', 'FW', 'Chelsea FC'),
('POR', 'Francisco Conceicao', 'FW', 'Juventus FC');

-- Uzbekistan (Group K) - 26 players (worldcuppass.com)
INSERT INTO players (team_id, name, position, club) VALUES
('UZB', 'Utkir Yusupov', 'GK', 'Navbahor'),
('UZB', 'Abduvohid Nematov', 'GK', 'Nasaf'),
('UZB', 'Botirali Ergashev', 'GK', 'Neftchi'),
('UZB', 'Abdukodir Khusanov', 'DF', 'Manchester City FC'),
('UZB', 'Khojiakbar Alijonov', 'DF', 'Pakhtakor'),
('UZB', 'Farrukh Sayfiev', 'DF', 'Neftchi'),
('UZB', 'Rustam Ashurmatov', 'DF', 'Esteghlal'),
('UZB', 'Umar Eshmurodov', 'DF', 'Nasaf'),
('UZB', 'Sherzod Nasrullaev', 'DF', 'Pakhtakor'),
('UZB', 'Abdulla Abdullaev', 'DF', 'Dibba'),
('UZB', 'Avazbek Ulmasaliev', 'DF', 'AGMK'),
('UZB', 'Jakhongir Urozov', 'DF', 'Dinamo Tashkent'),
('UZB', 'Behruz Karimov', 'DF', 'Surkhon'),
('UZB', 'Akmal Mozgovoy', 'MF', 'Pakhtakor'),
('UZB', 'Otabek Shukurov', 'MF', 'Baniyas'),
('UZB', 'Jamshid Iskanderov', 'MF', 'Neftchi'),
('UZB', 'Odiljon Hamrobekov', 'MF', 'Tractor'),
('UZB', 'Jaloliddin Masharipov', 'MF', 'Esteghlal'),
('UZB', 'Oston Urunov', 'MF', 'Persepolis'),
('UZB', 'Dostonbek Khamdamov', 'MF', 'Pakhtakor'),
('UZB', 'Azizjon Ganiev', 'MF', 'Al Bataeh'),
('UZB', 'Abbosbek Fayzullayev', 'MF', 'Başakşehir FK'),
('UZB', 'Sherzod Esanov', 'MF', 'Bukhara'),
('UZB', 'Eldor Shomurodov', 'FW', 'Başakşehir FK'),
('UZB', 'Igor Sergeev', 'FW', 'Persepolis'),
('UZB', 'Azizbek Amonov', 'FW', 'Dinamo Tashkent');

-- Panama (Group L) - 26 players (worldcuppass.com)
INSERT INTO players (team_id, name, position, club) VALUES
('PAN', 'Luis Mejia', 'GK', 'Nacional'),
('PAN', 'Orlando Mosquera', 'GK', 'Al-Fayha'),
('PAN', 'Cesar Samudio', 'GK', 'Marathon'),
('PAN', 'Amir Murillo', 'DF', 'Beşiktaş JK'),
('PAN', 'Jose Cordoba', 'DF', 'Norwich City FC'),
('PAN', 'Cesar Blackman', 'DF', 'Slovan Bratislava'),
('PAN', 'Andres Andrade', 'DF', 'LASK Linz'),
('PAN', 'Eric Davis', 'DF', 'Plaza Amador'),
('PAN', 'Roderick Miller', 'DF', 'Turan Tovuz'),
('PAN', 'Jiovany Ramos', 'DF', 'Puerto Cabello'),
('PAN', 'Jorge Gutierrez', 'DF', 'Deportivo La Guaira'),
('PAN', 'Fidel Escobar', 'DF', 'Saprissa'),
('PAN', 'Edgardo Farina', 'DF', 'Pari Nizhny Novgorod'),
('PAN', 'Anibal Godoy', 'MF', 'San Diego FC'),
('PAN', 'Adalberto Carrasquilla', 'MF', 'UNAM'),
('PAN', 'Cristian Martinez', 'MF', 'Ironi Kiryat Shmona'),
('PAN', 'Carlos Harvey', 'MF', 'Minnesota United FC'),
('PAN', 'Jose Luis Rodriguez', 'MF', 'Juarez'),
('PAN', 'Cesar Yanis', 'MF', 'Cobresal'),
('PAN', 'Yoel Barcenas', 'MF', 'Unattached'),
('PAN', 'Alberto Quintero', 'MF', 'Plaza Amador'),
('PAN', 'Azarias Londono', 'MF', 'Universidad Catolica'),
('PAN', 'Ismael Diaz', 'FW', 'Leon'),
('PAN', 'Jose Fajardo', 'FW', 'Universidad Catolica'),
('PAN', 'Tomas Rodriguez', 'FW', 'Saprissa'),
('PAN', 'Cecilio Waterman', 'FW', 'Universidad de Concepcion');


-- Turkey (Group D) - 26 players (worldcuppass.com)
INSERT INTO players (team_id, name, position, club) VALUES
('TUR', 'Ugurcan Cakir', 'GK', 'Galatasaray SK'),
('TUR', 'Mert Gunok', 'GK', 'Beşiktaş JK'),
('TUR', 'Altay Bayindir', 'GK', 'Manchester United FC'),
('TUR', 'Zeki Celik', 'DF', 'AS Roma'),
('TUR', 'Merih Demiral', 'DF', 'Al Ahli'),
('TUR', 'Caglar Soyuncu', 'DF', 'Fenerbahçe'),
('TUR', 'Ozan Kabak', 'DF', 'TSG Hoffenheim'),
('TUR', 'Abdulkerim Bardakci', 'DF', 'Galatasaray SK'),
('TUR', 'Mert Muldur', 'DF', 'Fenerbahçe'),
('TUR', 'Ferdi Kadioglu', 'DF', 'Brighton & Hove Albion FC'),
('TUR', 'Eren Elmali', 'DF', 'Galatasaray SK'),
('TUR', 'Samet Akaydin', 'DF', 'Çaykur Rizespor'),
('TUR', 'Hakan Calhanoglu', 'MF', 'Inter Milan'),
('TUR', 'Kaan Ayhan', 'MF', 'Galatasaray SK'),
('TUR', 'Salih Ozcan', 'MF', 'Borussia Dortmund'),
('TUR', 'Ismail Yuksek', 'MF', 'Fenerbahçe'),
('TUR', 'Orkun Kokcu', 'MF', 'Beşiktaş JK'),
('TUR', 'Arda Guler', 'FW', 'Real Madrid'),
('TUR', 'Kenan Yildiz', 'FW', 'Juventus FC'),
('TUR', 'Kerem Akturkoglu', 'FW', 'Fenerbahçe'),
('TUR', 'Baris Alper Yilmaz', 'FW', 'Galatasaray SK'),
('TUR', 'Irfan Can Kahveci', 'FW', 'Fenerbahçe'),
('TUR', 'Yunus Akgun', 'FW', 'Galatasaray SK'),
('TUR', 'Oguz Aydin', 'FW', 'Fenerbahçe'),
('TUR', 'Can Uzun', 'FW', 'Eintracht Frankfurt'),
('TUR', 'Deniz Gul', 'FW', 'FC Porto');


-- ============================================================
-- GROUP STAGE MATCHES (72 total, goals NULL until played)
-- Dates verified against Wikipedia schedule 2026-06-17
-- MD1: A→Jun11 | B→Jun12/13 | C→Jun13 | D→Jun12/13 | E/F→Jun14 | G/H→Jun15 | I/J→Jun16 | K/L→Jun17
-- MD2: A/B→Jun18 | C/D→Jun19 | E/F→Jun20 | G/H→Jun21 | I/J→Jun22 | K/L→Jun23
-- MD3: A/B/C→Jun24 | D/E/F→Jun25 | G/H/I→Jun26 | J/K/L→Jun27 (simultaneous per group)
-- ============================================================
INSERT INTO matches (match_id, fifa_match_no, team_home, team_away, goals_home, goals_away, stage, group_name, match_date, stadium, city) VALUES
-- Group A: MD1 Jun 11 | MD2 Jun 18 | MD3 Jun 24
(1,  1,  'MEX', 'RSA', NULL, NULL, 'group', 'A', '2026-06-11', 'Estadio Azteca',       'Mexico City'),
(2,  2,  'KOR', 'CZE', NULL, NULL, 'group', 'A', '2026-06-11', 'Estadio Akron',        'Guadalajara'),
(3,  28, 'MEX', 'KOR', NULL, NULL, 'group', 'A', '2026-06-18', 'Estadio Akron',        'Guadalajara'),
(4,  25, 'RSA', 'CZE', NULL, NULL, 'group', 'A', '2026-06-18', 'Mercedes-Benz Stadium','Atlanta'),
(5,  53, 'MEX', 'CZE', NULL, NULL, 'group', 'A', '2026-06-24', 'Estadio Azteca',       'Mexico City'),
(6,  54, 'RSA', 'KOR', NULL, NULL, 'group', 'A', '2026-06-24', 'Estadio BBVA',         'Monterrey'),
-- Group B: MD1 Jun 12 (CAN) / Jun 13 (QAT) | MD2 Jun 18 | MD3 Jun 24
(7,  3,  'CAN', 'BIH', NULL, NULL, 'group', 'B', '2026-06-12', 'BMO Field',            'Toronto'),
(8,  5,  'QAT', 'SUI', NULL, NULL, 'group', 'B', '2026-06-13', 'Levi''s Stadium',      'San Francisco Bay Area'),
(9,  27, 'CAN', 'QAT', NULL, NULL, 'group', 'B', '2026-06-18', 'BC Place',             'Vancouver'),
(10, 26, 'BIH', 'SUI', NULL, NULL, 'group', 'B', '2026-06-18', 'SoFi Stadium',         'Los Angeles'),
(11, 49, 'CAN', 'SUI', NULL, NULL, 'group', 'B', '2026-06-24', 'BC Place',             'Vancouver'),
(12, 50, 'BIH', 'QAT', NULL, NULL, 'group', 'B', '2026-06-24', 'Lumen Field',          'Seattle'),
-- Group C: MD1 Jun 13 | MD2 Jun 19 | MD3 Jun 24
(13, 6,  'BRA', 'MAR', NULL, NULL, 'group', 'C', '2026-06-13', 'MetLife Stadium',      'New York/New Jersey'),
(14, 7,  'HAI', 'SCO', NULL, NULL, 'group', 'C', '2026-06-13', 'Gillette Stadium',     'Boston'),
(15, 31, 'BRA', 'HAI', NULL, NULL, 'group', 'C', '2026-06-19', 'Lincoln Financial Field','Philadelphia'),
(16, 30, 'MAR', 'SCO', NULL, NULL, 'group', 'C', '2026-06-19', 'Gillette Stadium',     'Boston'),
(17, 51, 'BRA', 'SCO', NULL, NULL, 'group', 'C', '2026-06-24', 'Hard Rock Stadium',    'Miami'),
(18, 52, 'MAR', 'HAI', NULL, NULL, 'group', 'C', '2026-06-24', 'Mercedes-Benz Stadium','Atlanta'),
-- Group D: MD1 Jun 12 (USA) / Jun 13 (AUS) | MD2 Jun 19 | MD3 Jun 25
(19, 4,  'USA', 'PAR', NULL, NULL, 'group', 'D', '2026-06-12', 'SoFi Stadium',         'Los Angeles'),
(20, 8,  'AUS', 'TUR', NULL, NULL, 'group', 'D', '2026-06-13', 'BC Place',             'Vancouver'),
(21, 29, 'USA', 'AUS', NULL, NULL, 'group', 'D', '2026-06-19', 'Lumen Field',          'Seattle'),
(22, 32, 'PAR', 'TUR', NULL, NULL, 'group', 'D', '2026-06-19', 'Levi''s Stadium',      'San Francisco Bay Area'),
(23, 59, 'USA', 'TUR', NULL, NULL, 'group', 'D', '2026-06-25', 'SoFi Stadium',         'Los Angeles'),
(24, 60, 'PAR', 'AUS', NULL, NULL, 'group', 'D', '2026-06-25', 'Levi''s Stadium',      'San Francisco Bay Area'),
-- Group E: MD1 Jun 14 | MD2 Jun 20 | MD3 Jun 25
(25, 9,  'GER', 'CUW', NULL, NULL, 'group', 'E', '2026-06-14', 'NRG Stadium',          'Houston'),
(26, 11, 'CIV', 'ECU', NULL, NULL, 'group', 'E', '2026-06-14', 'Lincoln Financial Field','Philadelphia'),
(27, 34, 'GER', 'CIV', NULL, NULL, 'group', 'E', '2026-06-20', 'BMO Field',            'Toronto'),
(28, 35, 'CUW', 'ECU', NULL, NULL, 'group', 'E', '2026-06-20', 'Arrowhead Stadium',    'Kansas City'),
(29, 56, 'GER', 'ECU', NULL, NULL, 'group', 'E', '2026-06-25', 'MetLife Stadium',      'New York/New Jersey'),
(30, 55, 'CUW', 'CIV', NULL, NULL, 'group', 'E', '2026-06-25', 'Lincoln Financial Field','Philadelphia'),
-- Group F: MD1 Jun 14 | MD2 Jun 20 | MD3 Jun 25
(31, 10, 'NED', 'JPN', NULL, NULL, 'group', 'F', '2026-06-14', 'AT&T Stadium',         'Dallas'),
(32, 12, 'SWE', 'TUN', NULL, NULL, 'group', 'F', '2026-06-14', 'Estadio BBVA',         'Monterrey'),
(33, 33, 'NED', 'SWE', NULL, NULL, 'group', 'F', '2026-06-20', 'NRG Stadium',          'Houston'),
(34, 36, 'JPN', 'TUN', NULL, NULL, 'group', 'F', '2026-06-20', 'Estadio BBVA',         'Monterrey'),
(35, 58, 'NED', 'TUN', NULL, NULL, 'group', 'F', '2026-06-25', 'Arrowhead Stadium',    'Kansas City'),
(36, 57, 'JPN', 'SWE', NULL, NULL, 'group', 'F', '2026-06-25', 'AT&T Stadium',         'Dallas'),
-- Group G: MD1 Jun 15 | MD2 Jun 21 | MD3 Jun 26
(37, 14, 'BEL', 'EGY', NULL, NULL, 'group', 'G', '2026-06-15', 'Lumen Field',          'Seattle'),
(38, 16, 'IRN', 'NZL', NULL, NULL, 'group', 'G', '2026-06-15', 'SoFi Stadium',         'Los Angeles'),
(39, 38, 'BEL', 'IRN', NULL, NULL, 'group', 'G', '2026-06-21', 'SoFi Stadium',         'Los Angeles'),
(40, 40, 'EGY', 'NZL', NULL, NULL, 'group', 'G', '2026-06-21', 'BC Place',             'Vancouver'),
(41, 66, 'BEL', 'NZL', NULL, NULL, 'group', 'G', '2026-06-26', 'BC Place',             'Vancouver'),
(42, 65, 'EGY', 'IRN', NULL, NULL, 'group', 'G', '2026-06-26', 'Lumen Field',          'Seattle'),
-- Group H: MD1 Jun 15 | MD2 Jun 21 | MD3 Jun 26
(43, 13, 'ESP', 'CPV', NULL, NULL, 'group', 'H', '2026-06-15', 'Mercedes-Benz Stadium','Atlanta'),
(44, 15, 'KSA', 'URU', NULL, NULL, 'group', 'H', '2026-06-15', 'Hard Rock Stadium',    'Miami'),
(45, 37, 'ESP', 'KSA', NULL, NULL, 'group', 'H', '2026-06-21', 'Mercedes-Benz Stadium','Atlanta'),
(46, 39, 'CPV', 'URU', NULL, NULL, 'group', 'H', '2026-06-21', 'Hard Rock Stadium',    'Miami'),
(47, 64, 'ESP', 'URU', NULL, NULL, 'group', 'H', '2026-06-26', 'Estadio Akron',        'Guadalajara'),
(48, 63, 'CPV', 'KSA', NULL, NULL, 'group', 'H', '2026-06-26', 'NRG Stadium',          'Houston'),
-- Group I: MD1 Jun 16 | MD2 Jun 22 | MD3 Jun 26
(49, 17, 'FRA', 'SEN', NULL, NULL, 'group', 'I', '2026-06-16', 'MetLife Stadium',      'New York/New Jersey'),
(50, 18, 'IRQ', 'NOR', NULL, NULL, 'group', 'I', '2026-06-16', 'Gillette Stadium',     'Boston'),
(51, 42, 'FRA', 'IRQ', NULL, NULL, 'group', 'I', '2026-06-22', 'Lincoln Financial Field','Philadelphia'),
(52, 43, 'SEN', 'NOR', NULL, NULL, 'group', 'I', '2026-06-22', 'MetLife Stadium',      'New York/New Jersey'),
(53, 61, 'FRA', 'NOR', NULL, NULL, 'group', 'I', '2026-06-26', 'Gillette Stadium',     'Boston'),
(54, 62, 'SEN', 'IRQ', NULL, NULL, 'group', 'I', '2026-06-26', 'BMO Field',            'Toronto'),
-- Group J: MD1 Jun 16 | MD2 Jun 22 | MD3 Jun 27
(55, 19, 'ARG', 'ALG', NULL, NULL, 'group', 'J', '2026-06-16', 'Arrowhead Stadium',    'Kansas City'),
(56, 20, 'AUT', 'JOR', NULL, NULL, 'group', 'J', '2026-06-16', 'Levi''s Stadium',      'San Francisco Bay Area'),
(57, 41, 'ARG', 'AUT', NULL, NULL, 'group', 'J', '2026-06-22', 'AT&T Stadium',         'Dallas'),
(58, 44, 'ALG', 'JOR', NULL, NULL, 'group', 'J', '2026-06-22', 'Levi''s Stadium',      'San Francisco Bay Area'),
(59, 72, 'ARG', 'JOR', NULL, NULL, 'group', 'J', '2026-06-27', 'AT&T Stadium',         'Dallas'),
(60, 71, 'ALG', 'AUT', NULL, NULL, 'group', 'J', '2026-06-27', 'Arrowhead Stadium',    'Kansas City'),
-- Group K: MD1 Jun 17 | MD2 Jun 23 | MD3 Jun 27
(61, 21, 'POR', 'COD', NULL, NULL, 'group', 'K', '2026-06-17', 'NRG Stadium',          'Houston'),
(62, 24, 'UZB', 'COL', NULL, NULL, 'group', 'K', '2026-06-17', 'Estadio Azteca',       'Mexico City'),
(63, 45, 'POR', 'UZB', NULL, NULL, 'group', 'K', '2026-06-23', 'NRG Stadium',          'Houston'),
(64, 48, 'COD', 'COL', NULL, NULL, 'group', 'K', '2026-06-23', 'Estadio Akron',        'Guadalajara'),
(65, 69, 'POR', 'COL', NULL, NULL, 'group', 'K', '2026-06-27', 'Hard Rock Stadium',    'Miami'),
(66, 70, 'COD', 'UZB', NULL, NULL, 'group', 'K', '2026-06-27', 'Mercedes-Benz Stadium','Atlanta'),
-- Group L: MD1 Jun 17 | MD2 Jun 23 | MD3 Jun 27
(67, 22, 'ENG', 'CRO', NULL, NULL, 'group', 'L', '2026-06-17', 'AT&T Stadium',         'Dallas'),
(68, 23, 'GHA', 'PAN', NULL, NULL, 'group', 'L', '2026-06-17', 'BMO Field',            'Toronto'),
(69, 46, 'ENG', 'GHA', NULL, NULL, 'group', 'L', '2026-06-23', 'Gillette Stadium',     'Boston'),
(70, 47, 'CRO', 'PAN', NULL, NULL, 'group', 'L', '2026-06-23', 'BMO Field',            'Toronto'),
(71, 67, 'ENG', 'PAN', NULL, NULL, 'group', 'L', '2026-06-27', 'MetLife Stadium',      'New York/New Jersey'),
(72, 68, 'CRO', 'GHA', NULL, NULL, 'group', 'L', '2026-06-27', 'Lincoln Financial Field','Philadelphia');

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
INSERT INTO matches (match_id, fifa_match_no, team_home, team_away, goals_home, goals_away, stage, group_name, match_date, stadium, city) VALUES
(73,  73,  NULL, NULL, NULL, NULL, 'r32', 'knock-out', NULL, NULL, NULL),
(74,  74,  NULL, NULL, NULL, NULL, 'r32', 'knock-out', NULL, NULL, NULL),
(75,  75,  NULL, NULL, NULL, NULL, 'r32', 'knock-out', NULL, NULL, NULL),
(76,  76,  NULL, NULL, NULL, NULL, 'r32', 'knock-out', NULL, NULL, NULL),
(77,  77,  NULL, NULL, NULL, NULL, 'r32', 'knock-out', NULL, NULL, NULL),
(78,  78,  NULL, NULL, NULL, NULL, 'r32', 'knock-out', NULL, NULL, NULL),
(79,  79,  NULL, NULL, NULL, NULL, 'r32', 'knock-out', NULL, NULL, NULL),
(80,  80,  NULL, NULL, NULL, NULL, 'r32', 'knock-out', NULL, NULL, NULL),
(81,  81,  NULL, NULL, NULL, NULL, 'r32', 'knock-out', NULL, NULL, NULL),
(82,  82,  NULL, NULL, NULL, NULL, 'r32', 'knock-out', NULL, NULL, NULL),
(83,  83,  NULL, NULL, NULL, NULL, 'r32', 'knock-out', NULL, NULL, NULL),
(84,  84,  NULL, NULL, NULL, NULL, 'r32', 'knock-out', NULL, NULL, NULL),
(85,  85,  NULL, NULL, NULL, NULL, 'r32', 'knock-out', NULL, NULL, NULL),
(86,  86,  NULL, NULL, NULL, NULL, 'r32', 'knock-out', NULL, NULL, NULL),
(87,  87,  NULL, NULL, NULL, NULL, 'r32', 'knock-out', NULL, NULL, NULL),
(88,  88,  NULL, NULL, NULL, NULL, 'r32', 'knock-out', NULL, NULL, NULL);

-- ROUND OF 16 (Jul 4–7)
-- 89: W74 vs W77 | 90: W73 vs W75 | 91: W76 vs W78 | 92: W79 vs W80
-- 93: W83 vs W84 | 94: W81 vs W82 | 95: W86 vs W88 | 96: W85 vs W87
INSERT INTO matches (match_id, fifa_match_no, team_home, team_away, goals_home, goals_away, stage, group_name, match_date, stadium, city) VALUES
(89,  89,  NULL, NULL, NULL, NULL, 'r16', 'knock-out', NULL, NULL, NULL),
(90,  90,  NULL, NULL, NULL, NULL, 'r16', 'knock-out', NULL, NULL, NULL),
(91,  91,  NULL, NULL, NULL, NULL, 'r16', 'knock-out', NULL, NULL, NULL),
(92,  92,  NULL, NULL, NULL, NULL, 'r16', 'knock-out', NULL, NULL, NULL),
(93,  93,  NULL, NULL, NULL, NULL, 'r16', 'knock-out', NULL, NULL, NULL),
(94,  94,  NULL, NULL, NULL, NULL, 'r16', 'knock-out', NULL, NULL, NULL),
(95,  95,  NULL, NULL, NULL, NULL, 'r16', 'knock-out', NULL, NULL, NULL),
(96,  96,  NULL, NULL, NULL, NULL, 'r16', 'knock-out', NULL, NULL, NULL);

-- QUARTERFINALS (Jul 9–11)
-- 97: W89 vs W90 | 98: W91 vs W92 | 99: W93 vs W94 | 100: W95 vs W96
INSERT INTO matches (match_id, fifa_match_no, team_home, team_away, goals_home, goals_away, stage, group_name, match_date, stadium, city) VALUES
(97,  97,  NULL, NULL, NULL, NULL, 'qf', 'knock-out', NULL, NULL, NULL),
(98,  98,  NULL, NULL, NULL, NULL, 'qf', 'knock-out', NULL, NULL, NULL),
(99,  99,  NULL, NULL, NULL, NULL, 'qf', 'knock-out', NULL, NULL, NULL),
(100, 100, NULL, NULL, NULL, NULL, 'qf', 'knock-out', NULL, NULL, NULL);

-- SEMIFINALS (Jul 14–15)
-- 101: W97 vs W98 | 102: W99 vs W100
INSERT INTO matches (match_id, fifa_match_no, team_home, team_away, goals_home, goals_away, stage, group_name, match_date, stadium, city) VALUES
(101, 101, NULL, NULL, NULL, NULL, 'sf', 'knock-out', NULL, NULL, NULL),
(102, 102, NULL, NULL, NULL, NULL, 'sf', 'knock-out', NULL, NULL, NULL);

-- THIRD PLACE (Jul 18)
INSERT INTO matches (match_id, fifa_match_no, team_home, team_away, goals_home, goals_away, stage, group_name, match_date, stadium, city) VALUES
(103, 103, NULL, NULL, NULL, NULL, 'third_place', 'knock-out', '2026-07-18', NULL, NULL);

-- FINAL (Jul 19 — MetLife Stadium confirmed)
INSERT INTO matches (match_id, fifa_match_no, team_home, team_away, goals_home, goals_away, stage, group_name, match_date, stadium, city) VALUES
(104, 104, NULL, NULL, NULL, NULL, 'final', 'knock-out', '2026-07-19', 'MetLife Stadium', 'New York/New Jersey');

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