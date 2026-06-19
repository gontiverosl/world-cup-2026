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
DROP TABLE IF EXISTS player_stats;
DROP TABLE IF EXISTS players;
DROP TABLE IF EXISTS matches;
DROP TABLE IF EXISTS teams;

CREATE TABLE teams (
    team_id        TEXT PRIMARY KEY,   -- 3-letter FIFA code
    country        TEXT NOT NULL,
    confederation  TEXT NOT NULL,       -- UEFA / CONMEBOL / AFC / CAF / CONCACAF / OFC
    group_name     TEXT NOT NULL,       -- 'A' through 'L'
    fifa_ranking   INTEGER,
    coach          TEXT,
    host           INTEGER DEFAULT 0,   -- 1 if co-host (MEX, USA, CAN)
    squad_size     INTEGER,             -- Transfermarkt snapshot 2026-06-16
    avg_age        REAL,                -- years
    market_value_m REAL,                -- total squad market value, EUR millions
    base_camp      TEXT                 -- base camp city, State/Province (Wikipedia, 2026-06-17)
);

-- ============================================================
-- TABLE: players
-- ============================================================
CREATE TABLE players (
    player_id   INTEGER PRIMARY KEY AUTOINCREMENT,
    team_id     TEXT NOT NULL REFERENCES teams(team_id),
    name        TEXT NOT NULL,
    position    TEXT NOT NULL,         -- GK / DF / MF / FW
    age         INTEGER,               -- age as of June 11, 2026
    club        TEXT,
    caps        INTEGER DEFAULT 0,     -- career international appearances
    intl_goals  INTEGER DEFAULT 0      -- career international goals
);

-- ============================================================
-- TABLE: matches
-- ============================================================
CREATE TABLE matches (
    match_id      INTEGER PRIMARY KEY AUTOINCREMENT,
    fifa_match_no INTEGER UNIQUE,        -- FIFA official match number (1-104) — validation
    team_home     TEXT REFERENCES teams(team_id),  -- NULL for unresolved knockout fixtures
    team_away     TEXT REFERENCES teams(team_id),
    goals_home    INTEGER,               -- NULL = not yet played
    goals_away    INTEGER,
    stage         TEXT NOT NULL,         -- 'Group' / 'R32' / 'R16' / 'QF' / 'SF' / 'F'
    group_name    TEXT,                  -- NULL for knockout stage
    match_date    TEXT,                  -- ISO format: '2026-06-11'
    stadium       TEXT,
    city          TEXT
);

-- ============================================================
-- TABLE: player_stats
-- ============================================================
CREATE TABLE player_stats (
    stat_id        INTEGER PRIMARY KEY AUTOINCREMENT,
    player_id      INTEGER NOT NULL REFERENCES players(player_id),
    match_id       INTEGER NOT NULL REFERENCES matches(match_id),
    goals          INTEGER DEFAULT 0,
    assists        INTEGER DEFAULT 0,
    minutes_played INTEGER DEFAULT 0,
    yellow_cards   INTEGER DEFAULT 0,
    red_cards      INTEGER DEFAULT 0,
    shots          INTEGER DEFAULT 0,
    shots_on_goal  INTEGER DEFAULT 0,
    fouls          INTEGER DEFAULT 0,
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
UPDATE teams SET squad_size=26, avg_age=27.0, market_value_m=1520.0 WHERE team_id='FRA';
UPDATE teams SET squad_size=26, avg_age=27.2, market_value_m=1360.0 WHERE team_id='ENG';
UPDATE teams SET squad_size=26, avg_age=26.8, market_value_m=1220.0 WHERE team_id='ESP';
UPDATE teams SET squad_size=26, avg_age=28.1, market_value_m=1010.0 WHERE team_id='POR';
UPDATE teams SET squad_size=26, avg_age=28.1, market_value_m=947.0 WHERE team_id='GER';
UPDATE teams SET squad_size=26, avg_age=29.4, market_value_m=928.2 WHERE team_id='BRA';
UPDATE teams SET squad_size=26, avg_age=29.2, market_value_m=807.5 WHERE team_id='ARG';
UPDATE teams SET squad_size=26, avg_age=27.8, market_value_m=754.2 WHERE team_id='NED';
UPDATE teams SET squad_size=26, avg_age=26.8, market_value_m=589.9 WHERE team_id='NOR';
UPDATE teams SET squad_size=26, avg_age=27.7, market_value_m=547.5 WHERE team_id='BEL';
UPDATE teams SET squad_size=26, avg_age=25.9, market_value_m=522.1 WHERE team_id='CIV';
UPDATE teams SET squad_size=26, avg_age=27.1, market_value_m=478.1 WHERE team_id='SEN';
UPDATE teams SET squad_size=26, avg_age=27.7, market_value_m=473.7 WHERE team_id='TUR';
UPDATE teams SET squad_size=26, avg_age=26.6, market_value_m=447.7 WHERE team_id='MAR';
UPDATE teams SET squad_size=26, avg_age=27.6, market_value_m=406.08 WHERE team_id='SWE';
UPDATE teams SET squad_size=26, avg_age=28.4, market_value_m=387.3 WHERE team_id='CRO';
UPDATE teams SET squad_size=26, avg_age=26.9, market_value_m=385.65 WHERE team_id='USA';
UPDATE teams SET squad_size=26, avg_age=26.1, market_value_m=368.7 WHERE team_id='ECU';
UPDATE teams SET squad_size=26, avg_age=28.8, market_value_m=359.3 WHERE team_id='URU';
UPDATE teams SET squad_size=26, avg_age=28.3, market_value_m=332.5 WHERE team_id='SUI';
UPDATE teams SET squad_size=26, avg_age=30.1, market_value_m=302.35 WHERE team_id='COL';
UPDATE teams SET squad_size=26, avg_age=27.5, market_value_m=270.85 WHERE team_id='JPN';
UPDATE teams SET squad_size=26, avg_age=26.9, market_value_m=256.9 WHERE team_id='ALG';
UPDATE teams SET squad_size=26, avg_age=28.6, market_value_m=245.2 WHERE team_id='AUT';
UPDATE teams SET squad_size=26, avg_age=27.0, market_value_m=234.35 WHERE team_id='GHA';
UPDATE teams SET squad_size=26, avg_age=27.0, market_value_m=198.65 WHERE team_id='CAN';
UPDATE teams SET squad_size=26, avg_age=27.9, market_value_m=191.85 WHERE team_id='MEX';
UPDATE teams SET squad_size=26, avg_age=27.7, market_value_m=188.18 WHERE team_id='CZE';
UPDATE teams SET squad_size=26, avg_age=29.2, market_value_m=170.25 WHERE team_id='SCO';
UPDATE teams SET squad_size=26, avg_age=29.1, market_value_m=153.65 WHERE team_id='PAR';
UPDATE teams SET squad_size=26, avg_age=26.5, market_value_m=146.4 WHERE team_id='BIH';
UPDATE teams SET squad_size=26, avg_age=29.1, market_value_m=143.9 WHERE team_id='COD';
UPDATE teams SET squad_size=26, avg_age=28.1, market_value_m=139.05 WHERE team_id='KOR';
UPDATE teams SET squad_size=26, avg_age=29.1, market_value_m=116.48 WHERE team_id='EGY';
UPDATE teams SET squad_size=26, avg_age=28.5, market_value_m=85.33 WHERE team_id='UZB';
UPDATE teams SET squad_size=26, avg_age=27.4, market_value_m=77.45 WHERE team_id='AUS';
UPDATE teams SET squad_size=26, avg_age=26.7, market_value_m=69.95 WHERE team_id='TUN';
UPDATE teams SET squad_size=26, avg_age=27.6, market_value_m=55.9 WHERE team_id='HAI';
UPDATE teams SET squad_size=26, avg_age=29.7, market_value_m=54.5 WHERE team_id='CPV';
UPDATE teams SET squad_size=26, avg_age=26.8, market_value_m=49.25 WHERE team_id='RSA';
UPDATE teams SET squad_size=26, avg_age=28.6, market_value_m=40.68 WHERE team_id='KSA';
UPDATE teams SET squad_size=26, avg_age=30.5, market_value_m=34.55 WHERE team_id='PAN';
UPDATE teams SET squad_size=26, avg_age=28.3, market_value_m=34.3 WHERE team_id='NZL';
UPDATE teams SET squad_size=26, avg_age=30.4, market_value_m=32.05 WHERE team_id='IRN';
UPDATE teams SET squad_size=26, avg_age=28.1, market_value_m=25.78 WHERE team_id='CUW';
UPDATE teams SET squad_size=26, avg_age=27.0, market_value_m=21.2 WHERE team_id='IRQ';
UPDATE teams SET squad_size=26, avg_age=28.5, market_value_m=20.3 WHERE team_id='JOR';
UPDATE teams SET squad_size=26, avg_age=29.5, market_value_m=19.93 WHERE team_id='QAT';

-- ============================================================
-- SEED: players
-- Full 26-man squads for 6 teams (real data from FIFA).
-- Remaining 42 teams: placeholder GKs only — enough to run
-- confederation-level queries. Expand per session.
-- ============================================================

-- ---------------------------
-- MEXICO (Group A) — full 26
-- ---------------------------
INSERT INTO players (team_id, name, position, age, club, caps, intl_goals) VALUES
('MEX', 'Guillermo Ochoa',    'GK', 40, 'AEL Limassol',     152, 0),
('MEX', 'Raúl Rangel',        'GK', 26, 'Guadalajara',       13, 0),
('MEX', 'Carlos Acevedo',     'GK', 30, 'Santos Laguna',      7, 0),
('MEX', 'Jesús Gallardo',     'DF', 31, 'Toluca',            120, 3),
('MEX', 'César Montes',       'DF', 29, 'Lokomotiv Moscow',   66, 4),
('MEX', 'Jorge Sánchez',      'DF', 28, 'PAOK',               58, 3),
('MEX', 'Johan Vásquez',      'DF', 27, 'Genoa',              45, 2),
('MEX', 'Israel Reyes',       'DF', 26, 'América',            33, 2),
('MEX', 'Mateo Chávez',       'DF', 22, 'AZ',                  9, 0),
('MEX', 'Edson Álvarez',      'MF', 28, 'Fenerbahçe',         97, 7),
('MEX', 'Orbelín Pineda',     'MF', 30, 'AEK Athens',         91, 12),
('MEX', 'Roberto Alvarado',   'MF', 27, 'Guadalajara',        66, 5),
('MEX', 'Luis Romo',          'MF', 31, 'Guadalajara',        62, 4),
('MEX', 'Luis Chávez',        'MF', 30, 'Dynamo Moscow',      44, 4),
('MEX', 'Érik Lira',          'MF', 26, 'Cruz Azul',          24, 0),
('MEX', 'Gilberto Mora',      'MF', 17, 'Tijuana',             7, 0),
('MEX', 'Brian Gutiérrez',    'MF', 22, 'Guadalajara',         6, 2),
('MEX', 'Obed Vargas',        'MF', 20, 'Atlético Madrid',     6, 0),
('MEX', 'Álvaro Fidalgo',     'MF', 29, 'Real Betis',          3, 0),
('MEX', 'Raúl Jiménez',       'FW', 35, 'Fulham FC',            123, 44),
('MEX', 'Alexis Vega',        'FW', 28, 'Toluca',             51, 7),
('MEX', 'Santiago Giménez',   'FW', 25, 'AC Milan',           47, 6),
('MEX', 'César Huerta',       'FW', 25, 'RSC Anderlecht',         26, 3),
('MEX', 'Julián Quiñones',    'FW', 29, 'Al-Qadsiah',         21, 2),
('MEX', 'Guillermo Martínez', 'FW', 31, 'UNAM',               11, 3),
('MEX', 'Armando González',   'FW', 23, 'Guadalajara',         7, 1);

-- ---------------------------
-- ARGENTINA (Group J) — full 26
-- ---------------------------
INSERT INTO players (team_id, name, position, age, club, caps, intl_goals) VALUES
('ARG', 'Emiliano Martínez',  'GK', 33, 'Aston Villa FC',        58, 0),
('ARG', 'Gerónimo Rulli',     'GK', 33, 'Olympique Marseille',          34, 0),
('ARG', 'Juan Musso',         'GK', 31, 'Atlético Madrid',    30, 0),
('ARG', 'Cristian Romero',    'DF', 26, 'Tottenham Hotspur FC',          56, 5),
('ARG', 'Lisandro Martínez',  'DF', 26, 'Manchester United FC',  40, 3),
('ARG', 'Nicolás Otamendi',   'DF', 37, 'Benfica',           119, 10),
('ARG', 'Nahuel Molina',      'DF', 26, 'Atlético Madrid',    54, 7),
('ARG', 'Gonzalo Montiel',    'DF', 27, 'Nottingham Forest FC',  46, 4),
('ARG', 'Nicolás Tagliafico', 'DF', 32, 'Olympique Lyonnais',               84, 3),
('ARG', 'Germán Pezzella',    'DF', 33, 'Real Betis',         44, 2),
('ARG', 'Rodrigo De Paul',    'MF', 31, 'Atlético Madrid',    77, 12),
('ARG', 'Enzo Fernández',     'MF', 25, 'Chelsea FC',            56, 6),
('ARG', 'Alexis Mac Allister','MF', 25, 'Liverpool FC',          52, 8),
('ARG', 'Leandro Paredes',    'MF', 31, 'AS Roma',               78, 9),
('ARG', 'Giovani Lo Celso',   'MF', 28, 'Villarreal CF',         62, 8),
('ARG', 'Thiago Almada',      'MF', 23, 'Botafogo',           17, 2),
('ARG', 'Exequiel Palacios',  'MF', 26, 'Bayer 04 Leverkusen',   28, 3),
('ARG', 'Lionel Messi',       'FW', 38, 'Inter Miami CF',       191, 112),
('ARG', 'Lautaro Martínez',   'FW', 27, 'Inter Milan',        86, 33),
('ARG', 'Julián Álvarez',     'FW', 24, 'Atlético Madrid',    51, 20),
('ARG', 'Paulo Dybala',       'FW', 32, 'AS Roma',               42, 9),
('ARG', 'Ángel Correa',       'FW', 30, 'Atlético Madrid',    52, 9),
('ARG', 'Alejandro Garnacho', 'FW', 21, 'Manchester United FC',  20, 5),
('ARG', 'Valentín Castellanos','FW', 26, 'Lazio',             18, 3),
('ARG', 'Nicolás González',   'FW', 27, 'Juventus FC',           30, 8),
('ARG', 'Facundo Buonanotte', 'MF', 20, 'Leicester City FC',     10, 1);

-- ---------------------------
-- BRAZIL (Group C) — full 26
-- ---------------------------
INSERT INTO players (team_id, name, position, age, club, caps, intl_goals) VALUES
('BRA', 'Ederson',           'GK', 32, 'Manchester City FC',    57, 0),
('BRA', 'Alisson',           'GK', 33, 'Liverpool FC',          87, 0),
('BRA', 'Bento',             'GK', 25, 'Al-Qadsiah',         20, 0),
('BRA', 'Marquinhos',        'DF', 31, 'Paris Saint-Germain', 108, 9),
('BRA', 'Gabriel Magalhães', 'DF', 27, 'Arsenal FC',            43, 4),
('BRA', 'Éder Militão',      'DF', 26, 'Real Madrid',        47, 4),
('BRA', 'Danilo',            'DF', 33, 'Juventus FC',          102, 7),
('BRA', 'Alex Sandro',       'DF', 33, 'São Paulo',          77, 3),
('BRA', 'Vanderson',         'DF', 24, 'AS Monaco',             24, 1),
('BRA', 'Guilherme Arana',   'DF', 27, 'Atlético Mineiro',   27, 1),
('BRA', 'Casemiro',          'MF', 34, 'Manchester United FC',  79, 9),
('BRA', 'Bruno Guimarães',   'MF', 27, 'Newcastle United FC',   47, 5),
('BRA', 'Lucas Paquetá',     'MF', 27, 'West Ham United FC',           62, 11),
('BRA', 'Gerson',            'MF', 27, 'CR Flamengo',           32, 3),
('BRA', 'Andreas Pereira',   'MF', 29, 'Fulham FC',             22, 2),
('BRA', 'Rodrygo',           'FW', 24, 'Real Madrid',        52, 16),
('BRA', 'Vinicius Jr.',      'FW', 25, 'Real Madrid',        72, 25),
('BRA', 'Neymar',            'FW', 34, 'Santos',            134, 79),
('BRA', 'Raphinha',          'FW', 29, 'FC Barcelona',          60, 20),
('BRA', 'Gabriel Martinelli','FW', 23, 'Arsenal FC',            28, 8),
('BRA', 'Endrick',           'FW', 18, 'Real Madrid',        24, 6),
('BRA', 'Gabriel Barbosa',   'FW', 29, 'CR Flamengo',           20, 7),
('BRA', 'Savinho',           'FW', 21, 'Manchester City FC',    16, 3),
('BRA', 'Yan Couto',         'DF', 23, 'Manchester City FC',    18, 1),
('BRA', 'André',             'MF', 23, 'Wolverhampton Wanderers FC',      14, 0),
('BRA', 'Igor Jesus',        'FW', 23, 'Botafogo',            9, 3);

-- ---------------------------
-- SPAIN (Group H) — full 26
-- ---------------------------
INSERT INTO players (team_id, name, position, age, club, caps, intl_goals) VALUES
('ESP', 'Unai Simón',        'GK', 27, 'Athletic Bilbao',    44, 0),
('ESP', 'David Raya',        'GK', 29, 'Arsenal FC',            18, 0),
('ESP', 'Álex Remiro',       'GK', 30, 'Real Sociedad',      14, 0),
('ESP', 'Dani Carvajal',     'DF', 32, 'Real Madrid',        101, 4),
('ESP', 'Alejandro Balde',   'DF', 21, 'FC Barcelona',           32, 3),
('ESP', 'Aymeric Laporte',   'DF', 30, 'Al-Nassr',            55, 3),
('ESP', 'Robin Le Normand',  'DF', 28, 'Atlético Madrid',     24, 2),
('ESP', 'Pau Cubarsí',       'DF', 18, 'FC Barcelona',           14, 1),
('ESP', 'Pedro Porro',       'DF', 25, 'Tottenham Hotspur FC',           28, 3),
('ESP', 'Marc Cucurella',    'DF', 26, 'Chelsea FC',             37, 1),
('ESP', 'Rodri',             'MF', 29, 'Manchester City FC',     72, 8),
('ESP', 'Pedri',             'MF', 23, 'FC Barcelona',           57, 8),
('ESP', 'Fabian Ruiz',       'MF', 28, 'Paris Saint-Germain',  53, 10),
('ESP', 'Dani Olmo',         'MF', 27, 'FC Barcelona',           46, 12),
('ESP', 'Martín Zubimendi',  'MF', 26, 'Arsenal FC',             23, 0),
('ESP', 'Mikel Merino',      'MF', 28, 'Arsenal FC',             42, 9),
('ESP', 'Álex Baena',        'MF', 24, 'Villarreal CF',          18, 3),
('ESP', 'Lamine Yamal',      'FW', 18, 'FC Barcelona',           37, 12),
('ESP', 'Álvaro Morata',     'FW', 32, 'AC Milan',           100, 38),
('ESP', 'Mikel Oyarzabal',   'FW', 27, 'Real Sociedad',       56, 22),
('ESP', 'Ferran Torres',     'FW', 25, 'FC Barcelona',           54, 18),
('ESP', 'Nico Williams',     'FW', 22, 'Athletic Bilbao',     29, 7),
('ESP', 'Bryan Gil',         'FW', 24, 'Sevilla',             20, 3),
('ESP', 'Joselu',            'FW', 34, 'RCD Espanyol',            17, 10),
('ESP', 'Yeremy Pino',       'FW', 22, 'Villarreal CF',          19, 3),
('ESP', 'Aitor Paredes',     'DF', 25, 'Athletic Bilbao',      8, 0);

-- ---------------------------
-- FRANCE (Group I) — full 26
-- ---------------------------
INSERT INTO players (team_id, name, position, age, club, caps, intl_goals) VALUES
('FRA', 'Mike Maignan',       'GK', 29, 'AC Milan',           32, 0),
('FRA', 'Alphonse Areola',    'GK', 32, 'West Ham United FC',           24, 0),
('FRA', 'Brice Samba',        'GK', 30, 'RC Lens',               10, 0),
('FRA', 'William Saliba',     'DF', 25, 'Arsenal FC',            33, 2),
('FRA', 'Dayot Upamecano',    'DF', 26, 'FC Bayern München',      47, 2),
('FRA', 'Ibrahima Konaté',    'DF', 26, 'Liverpool FC',          29, 0),
('FRA', 'Jules Koundé',       'DF', 26, 'FC Barcelona',          44, 2),
('FRA', 'Theo Hernández',     'DF', 27, 'AC Milan',           41, 6),
('FRA', 'Benjamin Pavard',    'DF', 29, 'Inter Milan',        62, 6),
('FRA', 'Lucas Hernandez',    'DF', 28, 'Paris Saint-Germain', 56, 0),
('FRA', 'N''Golo Kanté',      'MF', 35, 'Al-Ittihad',         63, 2),
('FRA', 'Aurélien Tchouaméni','MF', 25, 'Real Madrid',        42, 3),
('FRA', 'Adrien Rabiot',      'MF', 31, 'Olympique Marseille',          54, 12),
('FRA', 'Eduardo Camavinga',  'MF', 23, 'Real Madrid',        28, 3),
('FRA', 'Warren Zaïre-Emery', 'MF', 19, 'Paris Saint-Germain', 17, 2),
('FRA', 'Ousmane Dembélé',    'FW', 27, 'Paris Saint-Germain', 73, 16),
('FRA', 'Kylian Mbappé',      'FW', 27, 'Real Madrid',       100, 54),
('FRA', 'Antoine Griezmann',  'FW', 35, 'Atlético Madrid',   142, 55),
('FRA', 'Marcus Thuram',      'FW', 27, 'Inter Milan',        43, 16),
('FRA', 'Randal Kolo Muani',  'FW', 26, 'Paris Saint-Germain', 38, 8),
('FRA', 'Bradley Barcola',    'FW', 22, 'Paris Saint-Germain', 18, 5),
('FRA', 'Kingsley Coman',     'FW', 29, 'FC Bayern München',      72, 14),
('FRA', 'Christopher Nkunku', 'FW', 27, 'Chelsea FC',            23, 6),
('FRA', 'Youssouf Fofana',    'MF', 26, 'AC Milan',           24, 3),
('FRA', 'Matteo Guendouzi',   'MF', 26, 'Lazio',              26, 2),
('FRA', 'Jonathan Clauss',    'DF', 33, 'Nice',               21, 2);

-- ---------------------------
-- MOROCCO (Group C) — full 26
-- ---------------------------
INSERT INTO players (team_id, name, position, age, club, caps, intl_goals) VALUES
('MAR', 'Yassine Bounou',     'GK', 33, 'Al-Hilal',           63, 0),
('MAR', 'Munir Mohamedi',     'GK', 34, 'Villarreal CF',         28, 0),
('MAR', 'Ahmed Reda Tagnaouti','GK',29, 'Wydad AC',           20, 0),
('MAR', 'Achraf Hakimi',      'DF', 27, 'Paris Saint-Germain', 89, 16),
('MAR', 'Nayef Aguerd',       'DF', 28, 'West Ham United FC',           49, 5),
('MAR', 'Romain Saiss',       'DF', 34, 'Beşiktaş JK',           98, 6),
('MAR', 'Jawad El Yamiq',     'DF', 31, 'Real Valladolid',    30, 3),
('MAR', 'Noussair Mazraoui',  'DF', 27, 'Manchester United FC',  42, 3),
('MAR', 'Adam Masina',        'DF', 30, 'Udinese',            30, 1),
('MAR', 'Yahia Attiyat Allah','DF', 29, 'Wydad AC',           29, 2),
('MAR', 'Sofiane Boufal',     'MF', 31, 'Southampton FC',        65, 8),
('MAR', 'Selim Amallah',      'MF', 28, 'Standard Liège',     35, 5),
('MAR', 'Azzedine Ounahi',    'MF', 24, 'Olympique Marseille',          37, 2),
('MAR', 'Bilal El Khannous',  'MF', 21, 'KRC Genk',              29, 3),
('MAR', 'Abdessamad Ezzalzouli','MF',24,'Barcelona B',        18, 4),
('MAR', 'Ilias Chair',        'MF', 27, 'QPR',               22, 3),
('MAR', 'Hamza Mendyl',       'DF', 27, 'Kasimpasa',         14, 0),
('MAR', 'Youssef En-Nesyri',  'FW', 27, 'Fenerbahçe',        66, 22),
('MAR', 'Sofiane Chakib Ahannach','FW',26,'Moroccan',         12, 3),
('MAR', 'Hakim Ziyech',       'FW', 33, 'Galatasaray SK',        75, 27),
('MAR', 'Munir El Haddadi',   'FW', 29, 'Angers',            28, 8),
('MAR', 'Zakaria Aboukhlal',  'FW', 24, 'Toulouse',          31, 6),
('MAR', 'Ibrahim Salah Ezzaki','FW', 22,'Raja Casablanca',    8, 2),
('MAR', 'Ryan Mmaee',         'FW', 27, 'AC Sparta Praha',     22, 4),
('MAR', 'Walid Cheddira',     'FW', 26, 'Parma',             21, 6),
('MAR', 'Amine Harit',        'MF', 27, 'Olympique Marseille',         34, 5);


-- ============================================================
-- FULL 26-PLAYER SQUADS — 42 teams
-- Sources: FIFA PDF (19) | Wikipedia (11) | worldcuppass (11) | compiled (TUR)
-- ============================================================

-- ---------------------------
-- Czechia (Group A) - 26 players (FIFA official)
-- ---------------------------
INSERT INTO players (team_id, name, position, age, club, caps, intl_goals) VALUES
('CZE', 'Matej Kovar', 'GK', 26, 'PSV Eindhoven', 21, 0),
('CZE', 'David Zima', 'DF', 25, 'SK Slavia Praha', 25, 1),
('CZE', 'Tomas Holes', 'DF', 33, 'SK Slavia Praha', 41, 2),
('CZE', 'Robin Hranac', 'DF', 26, 'TSG Hoffenheim', 15, 1),
('CZE', 'Vladimir Coufal', 'DF', 33, 'TSG Hoffenheim', 63, 2),
('CZE', 'Stepan Chaloupek', 'DF', 23, 'SK Slavia Praha', 6, 0),
('CZE', 'Ladislav Krejci', 'DF', 27, 'Wolverhampton Wanderers FC', 28, 6),
('CZE', 'Vladimir Darida', 'MF', 35, 'FC Hradec Králové', 79, 8),
('CZE', 'Adam Hlozek', 'FW', 23, 'TSG Hoffenheim', 44, 5),
('CZE', 'Patrik Schick', 'FW', 30, 'Bayer 04 Leverkusen', 54, 26),
('CZE', 'Jan Kuchta', 'FW', 29, 'AC Sparta Praha', 31, 3),
('CZE', 'Lukas Cerv', 'MF', 25, 'FC Viktoria Plzeň', 17, 2),
('CZE', 'Mojmir Chytil', 'FW', 27, 'SK Slavia Praha', 23, 6),
('CZE', 'David Jurasek', 'DF', 25, 'SK Slavia Praha', 18, 1),
('CZE', 'Pavel Sulc', 'FW', 25, 'Olympique Lyonnais', 22, 5),
('CZE', 'Jindrich Stanek', 'GK', 30, 'SK Slavia Praha', 14, 0),
('CZE', 'Lukas Provod', 'MF', 29, 'SK Slavia Praha', 39, 3),
('CZE', 'Michal Sadilek', 'MF', 27, 'SK Slavia Praha', 36, 1),
('CZE', 'Tomas Chory', 'FW', 31, 'SK Slavia Praha', 23, 7),
('CZE', 'Jaroslav Zeleny', 'DF', 33, 'AC Sparta Praha', 24, 0),
('CZE', 'David Doudera', 'DF', 28, 'SK Slavia Praha', 17, 2),
('CZE', 'Tomas Soucek', 'MF', 31, 'West Ham United FC', 91, 17),
('CZE', 'Lukas Hornicek', 'GK', 23, 'SC Braga', 1, 0),
('CZE', 'Alexandr Sojka', 'MF', 23, 'FC Viktoria Plzeň', 3, 0),
('CZE', 'Hugo Sochurek', 'MF', 18, 'AC Sparta Praha', 1, 0),
('CZE', 'Denis Visinsky', 'FW', 23, 'FC Viktoria Plzeň', 2, 1);

-- ---------------------------
-- Bosnia & Herz. (Group B) - 26 players (FIFA official)
-- ---------------------------
INSERT INTO players (team_id, name, position, age, club, caps, intl_goals) VALUES
('BIH', 'Nikola Vasilj', 'GK', 30, 'FC St. Pauli', 27, 0),
('BIH', 'Nihad Mujakic', 'DF', 28, 'Gaziantep FK', 12, 1),
('BIH', 'Dennis Hadzikadunic', 'DF', 27, 'UC Sampdoria', 32, 0),
('BIH', 'Tarik Muharemovic', 'DF', 23, 'US Sassuolo', 15, 1),
('BIH', 'Sead Kolasinac', 'DF', 32, 'Atalanta Bergamo', 66, 0),
('BIH', 'Benjamin Tahirovic', 'MF', 23, 'Brøndby IF', 29, 2),
('BIH', 'Amar Dedic', 'DF', 23, 'Benfica', 29, 1),
('BIH', 'Armin Gigovic', 'MF', 24, 'BSC Young Boys', 21, 1),
('BIH', 'Samed Bazdar', 'FW', 22, 'Jagiellonia Białystok', 14, 1),
('BIH', 'Ermedin Demirovic', 'FW', 28, 'VfB Stuttgart', 41, 4),
('BIH', 'Edin Dzeko', 'FW', 40, 'FC Schalke 04', 148, 73),
('BIH', 'Mladen Jurkas', 'GK', 18, 'FK Borac Banja Luka', 0, 0),
('BIH', 'Ivan Basic', 'MF', 24, 'FC Astana', 18, 0),
('BIH', 'Ivan Sunjic', 'MF', 29, 'Pafos FC', 12, 0),
('BIH', 'Amar Memic', 'MF', 25, 'FC Viktoria Plzeň', 14, 1),
('BIH', 'Amir Hadziahmetovic', 'MF', 29, 'Hull City FC', 36, 0),
('BIH', 'Dzenis Burnic', 'MF', 28, 'Karlsruher SC', 21, 0),
('BIH', 'Nikola Katic', 'DF', 29, 'FC Schalke 04', 18, 2),
('BIH', 'Kerim Alajbegovic', 'FW', 18, 'FC Red Bull Salzburg', 11, 1),
('BIH', 'Esmir Bajraktarevic', 'FW', 21, 'PSV Eindhoven', 17, 1),
('BIH', 'Stjepan Radeljic', 'DF', 28, 'HNK Rijeka', 5, 0),
('BIH', 'Martin Zlomislic', 'GK', 27, 'HNK Rijeka', 3, 0),
('BIH', 'Haris Tabakovic', 'FW', 31, 'Borussia Mönchengladbach', 10, 4),
('BIH', 'Arjan Malic', 'DF', 20, 'SK Sturm Graz', 8, 0),
('BIH', 'Jovo Lukic', 'FW', 27, 'Universitatea Cluj', 4, 1),
('BIH', 'Ermin Mahmic', 'MF', 21, 'FC Slovan Liberec', 2, 0);

-- ---------------------------
-- Canada (Group B) - 26 players (FIFA official)
-- ---------------------------
INSERT INTO players (team_id, name, position, age, club, caps, intl_goals) VALUES
('CAN', 'ST.', 'GK', 29, 'Inter Miami CF', 20, 0),
('CAN', 'Alistair Johnston', 'DF', 27, 'Celtic FC', 59, 1),
('CAN', 'Ale Jones', 'DF', 28, 'Middlesbrough FC', 2, 0),
('CAN', 'Luc De Fougerolles', 'DF', 20, 'FCV Dender EH', 14, 0),
('CAN', 'Joel Waterman', 'DF', 30, 'Chicago Fire FC', 17, 0),
('CAN', 'Mathieu Choiniere', 'MF', 27, 'LAFC', 24, 0),
('CAN', 'Stephen Eustaquio', 'MF', 29, 'LAFC', 57, 4),
('CAN', 'Ismael Kone', 'MF', 23, 'US Sassuolo', 41, 4),
('CAN', 'Cyle Larin', 'FW', 31, 'Southampton FC', 91, 31),
('CAN', 'Jonathan David', 'FW', 26, 'Juventus FC', 78, 39),
('CAN', 'Liam Millar', 'MF', 26, 'Hull City FC', 42, 1),
('CAN', 'Tani Oluwaseyi', 'FW', 26, 'Villarreal CF', 25, 2),
('CAN', 'Derek Cornelius', 'DF', 28, 'Rangers FC', 45, 1),
('CAN', 'Jacob Shaffelburg', 'MF', 26, 'LAFC', 32, 6),
('CAN', 'Moise Bombito', 'DF', 26, 'OGC Nice', 20, 0),
('CAN', 'Maxime Crepeau', 'GK', 32, 'Orlando City SC', 33, 0),
('CAN', 'Tajon Buchanan', 'FW', 27, 'Villarreal CF', 61, 8),
('CAN', 'Owen Goodman', 'GK', 22, 'Barnsley', 0, 0),
('CAN', 'Alphonso Davies', 'DF', 25, 'FC Bayern München', 58, 15),
('CAN', 'Ali Ahmed', 'FW', 25, 'Norwich City FC', 25, 1),
('CAN', 'Jonathan Osorio', 'MF', 33, 'Toronto FC', 92, 10),
('CAN', 'Richie Laryea', 'DF', 31, 'Toronto FC', 77, 1),
('CAN', 'Niko Sigur', 'DF', 22, 'HNK Hajduk Split', 19, 2),
('CAN', 'Promise David', 'FW', 24, 'Royale Union Saint-Gilloise', 11, 3),
('CAN', 'Nathan Saliba', 'MF', 22, 'RSC Anderlecht', 15, 2),
('CAN', 'Jayden Nelson', 'FW', 23, 'Austin FC', 15, 3);

-- ---------------------------
-- Haiti (Group C) - 26 players (FIFA official)
-- ---------------------------
INSERT INTO players (team_id, name, position, age, club, caps, intl_goals) VALUES
('HAI', 'Johny Placide', 'GK', 38, 'SC Bastia', 84, 0),
('HAI', 'Carlens Arcus', 'DF', 29, 'Angers SCO', 57, 1),
('HAI', 'Keeto Thermoncy', 'DF', 20, 'BSC Young Boys', 1, 0),
('HAI', 'Ricardo Ade', 'DF', 36, 'LDU Quito', 62, 2),
('HAI', 'Hannes Delcroix', 'DF', 27, 'FC Lugano', 8, 0),
('HAI', 'Carl Sainte', 'MF', 23, 'El Paso Locomotive FC', 26, 0),
('HAI', 'Derrick Etienne', 'FW', 29, 'Toronto FC', 50, 8),
('HAI', 'Martin Experience', 'DF', 27, 'AS Nancy', 22, 0),
('HAI', 'Duckens Nazon', 'FW', 32, 'Esteghlal', 83, 44),
('HAI', 'Jean-Ricner Bellegarde', 'MF', 27, 'Wolverhampton Wanderers FC', 11, 0),
('HAI', 'Louicius Deedson', 'FW', 25, 'FC Dallas', 33, 10),
('HAI', 'Alexandre Pierre', 'GK', 25, 'FC Sochaux-Montbéliard', 17, 0),
('HAI', 'Markhus Lacroix', 'DF', 32, 'Colorado Springs Switchbacks FC', 16, 3),
('HAI', 'Garven Metusala', 'DF', 26, 'Colorado Springs Switchbacks FC', 15, 0),
('HAI', 'Ruben Providence', 'FW', 24, 'Almere City FC', 16, 3),
('HAI', 'Lenny Joseph', 'FW', 25, 'Ferencvárosi TC', 3, 1),
('HAI', 'Danley Jean Jacques', 'MF', 26, 'Philadelphia Union', 32, 6),
('HAI', 'Wilson Isidor', 'FW', 25, 'Sunderland AFC', 5, 2),
('HAI', 'Yassin Fortune', 'FW', 27, 'FC Vizela', 5, 0),
('HAI', 'Frantzdy Pierrot', 'FW', 31, 'Çaykur Rizespor', 54, 34),
('HAI', 'Josue Casimir', 'FW', 24, 'AJ Auxerre', 8, 0),
('HAI', 'Jean-Kevin Duverne', 'DF', 28, 'KAA Gent', 17, 1),
('HAI', 'Josue Duverger', 'GK', 26, 'FC Cosmos Koblenz', 7, 0),
('HAI', 'Wilguens Paugain', 'DF', 24, 'SV Zulte Waregem', 8, 0),
('HAI', 'Dominique Simon', 'MF', 25, 'FC Tatran Prešov', 2, 0),
('HAI', 'Woodensky Pierre', 'MF', 21, 'Violette AC', 1, 0);

-- ---------------------------
-- Australia (Group D) - 26 players (FIFA official)
-- ---------------------------
INSERT INTO players (team_id, name, position, age, club, caps, intl_goals) VALUES
('AUS', 'Mathew Ryan', 'GK', 34, 'Levante UD', 104, 0),
('AUS', 'Milos Degenek', 'DF', 32, 'APOEL FC', 57, 1),
('AUS', 'Alessandro Circati', 'DF', 22, 'Parma', 14, 1),
('AUS', 'Jacob Italiano', 'DF', 24, 'Grazer AK', 6, 0),
('AUS', 'Jordan Bos', 'DF', 23, 'Feyenoord Rotterdam', 28, 4),
('AUS', 'Jason Geria', 'DF', 33, 'Albirex Niigata', 15, 0),
('AUS', 'Mathew Leckie', 'FW', 35, 'Melbourne City FC', 81, 14),
('AUS', 'Connor Metcalfe', 'MF', 26, 'FC St. Pauli', 37, 2),
('AUS', 'Mohamed Toure', 'FW', 22, 'Norwich City FC', 11, 2),
('AUS', 'Ajdin Hrustic', 'FW', 29, 'SC Heracles Almelo', 37, 3),
('AUS', 'Awer Mabil', 'FW', 30, 'CD Castellón', 38, 10),
('AUS', 'Paul Izzo', 'GK', 31, 'Randers FC', 4, 0),
('AUS', 'Aiden Oneill', 'MF', 27, 'New York City FC', 32, 0),
('AUS', 'Cameron Devlin', 'MF', 28, 'Heart Of Midlothian FC', 5, 0),
('AUS', 'Kai Trewin', 'DF', 25, 'New York City FC', 6, 0),
('AUS', 'Aziz Behich', 'DF', 35, 'Melbourne City FC', 85, 3),
('AUS', 'Nestory Irankunda', 'FW', 20, 'Watford FC', 16, 6),
('AUS', 'Patrick Beach', 'GK', 22, 'Melbourne City FC', 3, 0),
('AUS', 'Harry Souttar', 'DF', 27, 'Leicester City FC', 39, 11),
('AUS', 'Cristian Volpato', 'FW', 22, 'US Sassuolo', 1, 0),
('AUS', 'Cameron Burgess', 'DF', 30, 'Swansea City AFC', 28, 0),
('AUS', 'Jackson Irvine', 'MF', 33, 'FC St. Pauli', 83, 14),
('AUS', 'Nishan Velupillay', 'FW', 25, 'Melbourne Victory FC', 8, 3),
('AUS', 'Paul Okon-engstler', 'MF', 21, 'Sydney FC', 7, 0),
('AUS', 'Lucas Herrington', 'DF', 18, 'Colorado Rapids', 4, 0),
('AUS', 'Tete Yengi', 'FW', 25, 'FC Machida Zelvia', 2, 1);

-- ---------------------------
-- Cote d'Ivoire (Group E) - 26 players (FIFA official)
-- ---------------------------
INSERT INTO players (team_id, name, position, age, club, caps, intl_goals) VALUES
('CIV', 'Yahia Fofana', 'GK', 25, 'Çaykur Rizespor', 37, 0),
('CIV', 'Ousmane Diomande', 'DF', 22, 'Sporting CP', 16, 1),
('CIV', 'Ghislain Konan', 'DF', 30, 'Gil Vicente FC', 55, 0),
('CIV', 'Jean Seri', 'MF', 34, 'NK Maribor', 65, 4),
('CIV', 'Wilfried Singo', 'DF', 25, 'Galatasaray SK', 36, 1),
('CIV', 'Seko Fofana', 'MF', 31, 'FC Porto', 33, 7),
('CIV', 'Odilon Kossounou', 'DF', 25, 'Atalanta Bergamo', 37, 0),
('CIV', 'Franck Kessie', 'MF', 29, 'Al Ahli', 105, 15),
('CIV', 'Ange-Yoan Bonny', 'FW', 22, 'Inter Milan', 2, 0),
('CIV', 'Simon Adingra', 'FW', 24, 'AS Monaco', 29, 5),
('CIV', 'Yan Diomande', 'FW', 19, 'RB Leipzig', 11, 3),
('CIV', 'Elye Wahi', 'FW', 23, 'OGC Nice', 3, 0),
('CIV', 'Christopher Operi', 'DF', 29, 'Başakşehir FK', 12, 0),
('CIV', 'Oumar Diakite', 'FW', 22, 'Cercle Brugge', 29, 6),
('CIV', 'Amad Diallo', 'FW', 23, 'Manchester United FC', 20, 7),
('CIV', 'Mohamed Kone', 'GK', 24, 'Sporting Charleroi', 0, 0),
('CIV', 'Guela Doue', 'DF', 23, 'RC Strasbourg', 21, 3),
('CIV', 'Ibrahim Sangare', 'MF', 28, 'Nottingham Forest FC', 56, 11),
('CIV', 'Nicolas Pepe', 'FW', 31, 'Villarreal CF', 57, 12),
('CIV', 'Emmanuel Agbadou', 'DF', 28, 'Beşiktaş JK', 22, 2),
('CIV', 'Evan Ndicka', 'DF', 26, 'AS Roma', 29, 0),
('CIV', 'Evann Guessand', 'FW', 24, 'Crystal Palace FC', 21, 4),
('CIV', 'Alban Lafont', 'GK', 27, 'Panathinaikos FC', 4, 0),
('CIV', 'Bazoumana Toure', 'FW', 20, 'TSG Hoffenheim', 7, 2),
('CIV', 'Parfait Guiagon', 'MF', 25, 'Sporting Charleroi', 5, 0),
('CIV', 'Christ Oulai', 'MF', 20, 'Trabzonspor', 10, 0);

-- ---------------------------
-- Curacao (Group E) - 26 players (FIFA official)
-- ---------------------------
INSERT INTO players (team_id, name, position, age, club, caps, intl_goals) VALUES
('CUW', 'Eloy Room', 'GK', 37, 'Miami FC', 73, 0),
('CUW', 'Shurandy Sambo', 'DF', 24, 'Sparta Rotterdam', 8, 0),
('CUW', 'Jurien Gaari', 'DF', 32, 'Abha Club', 60, 1),
('CUW', 'Roshon Van Eijma', 'DF', 28, 'RKC Waalwijk', 28, 1),
('CUW', 'Sherel Floranus', 'DF', 27, 'PEC Zwolle', 28, 0),
('CUW', 'Godfried Roemeratoe', 'MF', 26, 'RKC Waalwijk', 29, 1),
('CUW', 'Juninho Bacuna', 'MF', 28, 'FC Volendam', 51, 14),
('CUW', 'Livano Comenencia', 'MF', 22, 'FC Zürich', 21, 3),
('CUW', 'Juergen Locadia', 'FW', 32, 'Miami FC', 14, 1),
('CUW', 'Leandro Bacuna', 'MF', 34, 'Iğdır FK', 73, 16),
('CUW', 'Jeremy Antonisse', 'FW', 24, 'AE Kisia FC', 28, 4),
('CUW', 'Sontje Hansen', 'FW', 24, 'Middlesbrough FC', 7, 1),
('CUW', 'Tyrese Noslin', 'FW', 23, 'SC Telstar', 7, 1),
('CUW', 'Kenji Gorre', 'FW', 31, 'Maccabi Haifa FC', 38, 6),
('CUW', 'Arjany Martha', 'MF', 22, 'Rotherham United FC', 9, 2),
('CUW', 'Jearl Margaritha', 'FW', 26, 'SK Beveren', 23, 5),
('CUW', 'Brandley Kuwas', 'FW', 33, 'FC Volendam', 36, 2),
('CUW', 'Armando Obispo', 'DF', 27, 'PSV Eindhoven', 7, 0),
('CUW', 'Gervane Kastaneer', 'FW', 30, 'Terengganu FC', 30, 9),
('CUW', 'Joshua Brenet', 'DF', 32, 'Kayserispor', 18, 2),
('CUW', 'Tahith Chong', 'MF', 26, 'Sheeld United FC', 7, 3),
('CUW', 'Kevin Felida', 'MF', 26, 'FC Den Bosch', 19, 1),
('CUW', 'Riechedly Bazoer', 'DF', 29, 'Konyaspor', 6, 0),
('CUW', 'Deveron Fonville', 'DF', 23, 'NEC Nijmegen', 3, 0),
('CUW', 'Tyrick Bodak', 'GK', 24, 'SC Telstar', 4, 0),
('CUW', 'Trevor Doornbusch', 'GK', 26, 'VVV Venlo', 8, 0);

-- ---------------------------
-- Ecuador (Group E) - 26 players (FIFA official)
-- ---------------------------
INSERT INTO players (team_id, name, position, age, club, caps, intl_goals) VALUES
('ECU', 'Hernan Galindez', 'GK', 39, 'CA Huracán', 36, 0),
('ECU', 'Felix Torres', 'DF', 29, 'SC Internacional', 49, 5),
('ECU', 'Piero Hincapie', 'DF', 24, 'Arsenal FC', 53, 2),
('ECU', 'Joel Ordonez', 'DF', 22, 'Club Brugge', 18, 0),
('ECU', 'Jordy Alcivar', 'MF', 26, 'Independiente Del Valle', 11, 1),
('ECU', 'Willian Pacho', 'DF', 24, 'Paris Saint-Germain', 35, 2),
('ECU', 'Pervis Estupinan', 'DF', 28, 'AC Milan', 54, 5),
('ECU', 'Anthony Valencia', 'MF', 22, 'Royal Antwerp FC', 3, 1),
('ECU', 'John Yeboah', 'FW', 25, 'Venezia FC', 23, 3),
('ECU', 'Kendry Paez', 'MF', 19, 'CA River Plate', 26, 2),
('ECU', 'Kevin Rodriguez', 'FW', 26, 'Royale Union Saint-Gilloise', 32, 2),
('ECU', 'Moises Ramirez', 'GK', 25, 'AE Kisia FC', 7, 0),
('ECU', 'Enner Valencia', 'FW', 36, 'CF Pachuca', 106, 49),
('ECU', 'Alan Minda', 'MF', 23, 'Atlético Mineiro', 21, 2),
('ECU', 'Pedro Vite', 'MF', 24, 'Pumas UNAM', 18, 1),
('ECU', 'Jordy Caicedo', 'FW', 28, 'CA Huracán', 20, 4),
('ECU', 'Angelo Preciado', 'DF', 28, 'Atlético Mineiro', 57, 0),
('ECU', 'Denil Castillo', 'MF', 22, 'FC Midtjylland', 5, 0),
('ECU', 'Gonzalo Plata', 'FW', 25, 'CR Flamengo', 51, 8),
('ECU', 'Nilson Angulo', 'FW', 22, 'Sunderland AFC', 15, 2),
('ECU', 'Alan Franco', 'MF', 27, 'Atlético Mineiro', 59, 1),
('ECU', 'Gonzalo Valle', 'GK', 30, 'LDU Quito', 4, 0),
('ECU', 'Moises Caicedo', 'MF', 24, 'Chelsea FC', 62, 3),
('ECU', 'Jeremy Arevalo', 'FW', 21, 'VfB Stuttgart', 4, 0),
('ECU', 'Jackson Porozo', 'DF', 25, 'Club Tijuana', 10, 1),
('ECU', 'Yaimar Medina', 'DF', 21, 'KRC Genk', 6, 0);

-- ---------------------------
-- Germany (Group E) - 26 players (FIFA official)
-- ---------------------------
INSERT INTO players (team_id, name, position, age, club, caps, intl_goals) VALUES
('GER', 'Manuel Neuer', 'GK', 40, 'FC Bayern München', 125, 0),
('GER', 'Antonio Ruediger', 'DF', 33, 'Real Madrid', 83, 3),
('GER', 'Waldemar Anton', 'DF', 29, 'Borussia Dortmund', 14, 0),
('GER', 'Jonathan Tah', 'DF', 30, 'FC Bayern München', 48, 1),
('GER', 'Aleksandar Pavlovic', 'MF', 22, 'FC Bayern München', 12, 1),
('GER', 'Joshua Kimmich', 'DF', 31, 'FC Bayern München', 111, 10),
('GER', 'Kai Havertz', 'FW', 27, 'Arsenal FC', 59, 24),
('GER', 'Leon Goretzka', 'MF', 31, 'FC Bayern München', 71, 15),
('GER', 'Jamie Leweling', 'MF', 25, 'VfB Stuttgart', 5, 1),
('GER', 'Jamal Musiala', 'MF', 23, 'FC Bayern München', 43, 10),
('GER', 'Nick Woltemade', 'FW', 24, 'Newcastle United FC', 11, 4),
('GER', 'Oliver Baumann', 'GK', 36, 'TSG Hoffenheim', 13, 0),
('GER', 'Pascal Gross', 'MF', 34, 'Brighton & Hove Albion FC', 18, 1),
('GER', 'Maximilian Beier', 'FW', 23, 'Borussia Dortmund', 9, 0),
('GER', 'Nico Schlotterbeck', 'DF', 26, 'Borussia Dortmund', 28, 1),
('GER', 'Angelo Stiller', 'MF', 25, 'VfB Stuttgart', 8, 0),
('GER', 'Florian Wirtz', 'MF', 23, 'Liverpool FC', 42, 11),
('GER', 'Nathaniel Brown', 'DF', 22, 'Eintracht Frankfurt', 6, 1),
('GER', 'Leroy Sane', 'MF', 30, 'Galatasaray SK', 77, 17),
('GER', 'Nadiem Amiri', 'MF', 29, '1. FSV Mainz 05', 11, 1),
('GER', 'Alexander Nuebel', 'GK', 29, 'VfB Stuttgart', 3, 0),
('GER', 'David Raum', 'DF', 28, 'RB Leipzig', 38, 1),
('GER', 'Felix Nmecha', 'MF', 25, 'Borussia Dortmund', 9, 2),
('GER', 'Malick Thiaw', 'DF', 24, 'Newcastle United FC', 5, 0),
('GER', 'Assan Ouedraogo', 'MF', 20, 'RB Leipzig', 1, 1),
('GER', 'Deniz Undav', 'FW', 29, 'VfB Stuttgart', 10, 7);

-- ---------------------------
-- Belgium (Group G) - 26 players (FIFA official)
-- ---------------------------
INSERT INTO players (team_id, name, position, age, club, caps, intl_goals) VALUES
('BEL', 'Thibaut Courtois', 'GK', 34, 'Real Madrid', 109, 0),
('BEL', 'Zeno Debast', 'DF', 22, 'Sporting CP', 26, 1),
('BEL', 'Arthur Theate', 'DF', 26, 'Eintracht Frankfurt', 33, 1),
('BEL', 'Brandon Mechele', 'DF', 33, 'Club Brugge', 9, 1),
('BEL', 'Maxim De Cuyper', 'DF', 25, 'Brighton & Hove Albion FC', 19, 4),
('BEL', 'Axel Witsel', 'MF', 37, 'Girona FC', 138, 12),
('BEL', 'Kevin De Bruyne', 'MF', 34, 'SSC Napoli', 119, 37),
('BEL', 'Youri Tielemans', 'MF', 29, 'Aston Villa FC', 85, 13),
('BEL', 'Romelu Lukaku', 'FW', 33, 'SSC Napoli', 126, 90),
('BEL', 'Leandro Trossard', 'FW', 31, 'Arsenal FC', 51, 12),
('BEL', 'Jeremy Doku', 'FW', 24, 'Manchester City FC', 43, 7),
('BEL', 'Senne Lammens', 'GK', 23, 'Manchester United FC', 2, 0),
('BEL', 'Mike Penders', 'GK', 20, 'RC Strasbourg', 0, 0),
('BEL', 'Dodi Lukebakio', 'FW', 28, 'Benfica', 30, 6),
('BEL', 'Thomas Meunier', 'DF', 34, 'Lille OSC', 80, 10),
('BEL', 'Koni De Winter', 'DF', 23, 'AC Milan', 8, 0),
('BEL', 'Charles De Ketelaere', 'FW', 25, 'Atalanta Bergamo', 30, 6),
('BEL', 'Joaquin Seys', 'DF', 21, 'Club Brugge', 5, 0),
('BEL', 'Diego Moreira', 'MF', 21, 'RC Strasbourg', 3, 0),
('BEL', 'Hans Vanaken', 'MF', 33, 'Club Brugge', 34, 7),
('BEL', 'Timothy Castagne', 'DF', 30, 'Fulham FC', 63, 2),
('BEL', 'Alexis Saelemaekers', 'MF', 26, 'AC Milan', 24, 2),
('BEL', 'Nicolas Raskin', 'MF', 25, 'Rangers FC', 13, 2),
('BEL', 'Amadou Onana', 'MF', 24, 'Aston Villa FC', 29, 1),
('BEL', 'Nathan Ngoy', 'DF', 23, 'Lille OSC', 4, 0),
('BEL', 'Matias Fernandez-pardo', 'FW', 21, 'Lille OSC', 2, 0);

-- ---------------------------
-- Egypt (Group G) - 26 players (FIFA official)
-- ---------------------------
INSERT INTO players (team_id, name, position, age, club, caps, intl_goals) VALUES
('EGY', 'Mohamed Mohamed Elshenawy', 'GK', 37, 'Al Ahly FC', 77, 0),
('EGY', 'Yasser Yasser Ibrahim', 'DF', 33, 'Al Ahly FC', 18, 1),
('EGY', 'Mohamed Mohamed Hany', 'DF', 30, 'Al Ahly FC', 43, 0),
('EGY', 'Hossam Hossam Abdelmaguid', 'DF', 25, 'Zamalek SC', 13, 0),
('EGY', 'Ramy Ramy Rabia', 'DF', 33, 'Al-Ain', 47, 6),
('EGY', 'Mohamed Mohamed Abdelmoneim', 'DF', 27, 'OGC Nice', 36, 3),
('EGY', 'Mahmoud Trezeguet', 'FW', 31, 'Al Ahly FC', 96, 23),
('EGY', 'Emam Emam Ashour', 'MF', 28, 'Al Ahly FC', 29, 0),
('EGY', 'Hamza Hamza Abdelkarim', 'FW', 18, 'FC Barcelona', 2, 0),
('EGY', 'Mohamed Mohamed Salah', 'FW', 33, 'Liverpool FC', 116, 67),
('EGY', 'Mostafa Mostafa Zico', 'MF', 29, 'Pyramids FC', 2, 2),
('EGY', 'Haissem Haissem Hassan', 'FW', 24, 'Real Oviedo', 4, 0),
('EGY', 'Ahmed Ahmed Fatouh', 'DF', 28, 'Zamalek SC', 39, 1),
('EGY', 'Hamdy Hamdy Fathy', 'MF', 31, 'Al-Wakrah', 64, 4),
('EGY', 'Karim Karim Hafez', 'DF', 30, 'Pyramids FC', 9, 0),
('EGY', 'Mahdy Mahdy Soliman', 'GK', 39, 'Zamalek SC', 0, 0),
('EGY', 'Mohanad Mohanad Lashin', 'MF', 30, 'Pyramids FC', 23, 0),
('EGY', 'Nabil Nabil Donga', 'MF', 30, 'Al Najmah SC', 12, 0),
('EGY', 'Marawan Marawan Attia', 'MF', 27, 'Al Ahly FC', 35, 1),
('EGY', 'Ibrahim Ibrahim Adel', 'FW', 25, 'FC Nordsjælland', 24, 3),
('EGY', 'Mahmoud Mahmoud Saber', 'MF', 24, 'ZED FC', 15, 1),
('EGY', 'Omar Omar Marmoush', 'FW', 27, 'Manchester City FC', 50, 11),
('EGY', 'Mostafa Mostafa Shoubir', 'GK', 26, 'Al Ahly FC', 10, 0),
('EGY', 'Tarek Tarek Alaa', 'DF', 24, 'ZED FC', 3, 0),
('EGY', 'Ahmed Zizo', 'FW', 30, 'Al Ahly FC', 64, 5),
('EGY', 'Mohamed Mohamed Alaa', 'GK', 27, 'El Gouna FC', 0, 0);

-- ---------------------------
-- Cabo Verde (Group H) - 26 players (FIFA official)
-- ---------------------------
INSERT INTO players (team_id, name, position, age, club, caps, intl_goals) VALUES
('CPV', 'Josimar Vozinha', 'GK', 40, 'GD Chaves', 90, 0),
('CPV', 'Ianique Stopira', 'DF', 38, 'SCU Torreense', 61, 4),
('CPV', 'Edilson Diney Borges', 'DF', 31, 'Al Bataeh', 32, 2),
('CPV', 'Roberto Pico Lopes', 'DF', 33, 'Shamrock Rovers FC', 45, 0),
('CPV', 'Logan Logan Costa', 'DF', 25, 'Villarreal CF', 28, 0),
('CPV', 'Kevin Kevin Pina', 'MF', 29, 'FC Krasnodar', 31, 3),
('CPV', 'Jovane Jovane Cabral', 'MF', 27, 'CF Estrela Da Amadora', 29, 3),
('CPV', 'João Joao Paulo', 'MF', 28, 'FC FCSB', 41, 1),
('CPV', 'Gilson Gilson Benchimol', 'FW', 24, 'FC Akron Tolyatti', 21, 6),
('CPV', 'Jamiro Jamiro Monteiro', 'MF', 32, 'PEC Zwolle', 55, 5),
('CPV', 'Garry Garry Rodrigues', 'MF', 35, 'Apollon Limassol', 61, 10),
('CPV', 'Márcio Marcio Rosa', 'GK', 29, 'PFC Montana', 11, 0),
('CPV', 'Sidny Sidny Lopes Cabral', 'DF', 23, 'Benfica', 11, 3),
('CPV', 'Deroy Deroy Duarte', 'MF', 26, 'PFC Ludogorets Razgrad', 33, 0),
('CPV', 'Laros Laros Duarte', 'MF', 29, 'Puskás Akadémia FC', 20, 1),
('CPV', 'Jair Yannick Semedo', 'MF', 30, 'SC Farense', 11, 1),
('CPV', 'Willy Willy Semedo', 'MF', 32, 'AC Omonia', 38, 3),
('CPV', 'Telmo Telmo Arcanjo', 'MF', 24, 'Vitória SC', 16, 1),
('CPV', 'Dailon Dailon Livramento', 'FW', 25, 'Casa Pia AC', 22, 7),
('CPV', 'Ryan Ryan Mendes', 'FW', 36, 'Iğdır FK', 98, 22),
('CPV', 'Nuno Nuno Da Costa', 'MF', 35, 'Başakşehir FK', 9, 2),
('CPV', 'Steven Steven Moreira', 'DF', 31, 'Columbus Crew', 20, 0),
('CPV', 'Carlos Cj Dos Santos', 'GK', 25, 'San Diego FC', 1, 0),
('CPV', 'Wagner Wagner Pina', 'DF', 23, 'Trabzonspor', 14, 0),
('CPV', 'Kelvin Kelvin Pires', 'DF', 26, 'SJK', 6, 1),
('CPV', 'Hélio Helio Varela', 'MF', 24, 'Maccabi Tel-Aviv FC', 21, 0);

-- ---------------------------
-- Algeria (Group J) - 26 players (FIFA official)
-- ---------------------------
INSERT INTO players (team_id, name, position, age, club, caps, intl_goals) VALUES
('ALG', 'Melvin Mastil', 'GK', 26, 'FC Stade Nyonnais', 2, 0),
('ALG', 'Aissa Mandi', 'DF', 34, 'Lille OSC', 119, 8),
('ALG', 'Achref Abada', 'DF', 26, 'USM Alger', 10, 1),
('ALG', 'Mohamed Tougai', 'DF', 26, 'Espérance de Tunis', 30, 2),
('ALG', 'Zineddine Belaid', 'DF', 27, 'JS Kabylie', 18, 1),
('ALG', 'Ramiz Zerrouki', 'MF', 28, 'FC Twente', 53, 3),
('ALG', 'Riyad Mahrez', 'FW', 35, 'Al Ahli', 116, 38),
('ALG', 'Houssem Aouar', 'MF', 27, 'Al Ittihad', 23, 6),
('ALG', 'Amine Gouiri', 'FW', 26, 'Olympique Marseille', 23, 10),
('ALG', 'Fares Chaibi', 'MF', 23, 'Eintracht Frankfurt', 31, 3),
('ALG', 'Anis Hadj Moussa', 'FW', 24, 'Feyenoord Rotterdam', 15, 2),
('ALG', 'Nadhir Benbouali', 'FW', 26, 'Györi ETO FC', 4, 1),
('ALG', 'Jaouen Hadjam', 'DF', 23, 'BSC Young Boys', 18, 3),
('ALG', 'Hicham Boudaoui', 'MF', 26, 'OGC Nice', 34, 0),
('ALG', 'Rayan Ait-nouri', 'DF', 25, 'Manchester City FC', 30, 0),
('ALG', 'Oussama Benbot', 'GK', 31, 'USM Alger', 3, 0),
('ALG', 'Rak Belghali', 'DF', 24, 'Hellas Verona FC', 13, 1),
('ALG', 'Mohamed Amoura', 'FW', 26, 'VfL Wolfsburg', 47, 19),
('ALG', 'Nabil Bentaleb', 'MF', 31, 'Lille OSC', 60, 6),
('ALG', 'Adil Boulbina', 'FW', 23, 'Al-Duhail', 11, 5),
('ALG', 'Ramy Bensebaini', 'DF', 31, 'Borussia Dortmund', 82, 9),
('ALG', 'Ibrahim Maza', 'MF', 20, 'Bayer 04 Leverkusen', 17, 2),
('ALG', 'Luca Zidane', 'GK', 28, 'Granada CF', 7, 0),
('ALG', 'Yassine Titraoui', 'MF', 22, 'Sporting Charleroi', 5, 0),
('ALG', 'Fares Ghedjemis', 'FW', 23, 'Frosinone', 1, 1),
('ALG', 'Samir Chergui', 'DF', 27, 'Paris FC', 5, 0);

-- ---------------------------
-- Austria (Group J) - 26 players (FIFA official)
-- ---------------------------
INSERT INTO players (team_id, name, position, age, club, caps, intl_goals) VALUES
('AUT', 'Alexander Schlager', 'GK', 30, 'FC Red Bull Salzburg', 26, 0),
('AUT', 'David Affengruber', 'DF', 25, 'Elche CF', 1, 0),
('AUT', 'Kevin Danso', 'DF', 27, 'Tottenham Hotspur FC', 32, 0),
('AUT', 'Xaver Schlager', 'MF', 28, 'RB Leipzig', 51, 4),
('AUT', 'Stefan Posch', 'DF', 29, '1. FSV Mainz 05', 52, 5),
('AUT', 'Nicolas Seiwald', 'MF', 25, 'RB Leipzig', 47, 1),
('AUT', 'Marko Arnautovic', 'FW', 37, 'FK Crvena Zvezda', 133, 47),
('AUT', 'David Alaba', 'DF', 33, 'Real Madrid', 113, 15),
('AUT', 'Marcel Sabitzer', 'MF', 32, 'Borussia Dortmund', 98, 26),
('AUT', 'Florian Grillitsch', 'MF', 30, 'SC Braga', 59, 1),
('AUT', 'Michael Gregoritsch', 'FW', 32, 'FC Augsburg', 75, 24),
('AUT', 'Florian Wiegele', 'GK', 25, 'FC Viktoria Plzeň', 1, 0),
('AUT', 'Patrick Pentz', 'GK', 29, 'Brøndby IF', 18, 0),
('AUT', 'Sasa Kalajdzic', 'FW', 28, 'LASK Linz', 22, 4),
('AUT', 'Philipp Lienhart', 'DF', 29, 'SC Freiburg', 41, 3),
('AUT', 'Phillip Mwene', 'DF', 32, '1. FSV Mainz 05', 30, 0),
('AUT', 'Carney Chukwuemeka', 'MF', 22, 'Borussia Dortmund', 3, 1),
('AUT', 'Romano Schmid', 'MF', 26, 'SV Werder Bremen', 34, 3),
('AUT', 'Dejan Ljubicic', 'MF', 28, 'FC Schalke 04', 9, 1),
('AUT', 'Konrad Laimer', 'MF', 29, 'FC Bayern München', 57, 7),
('AUT', 'Patrick Wimmer', 'FW', 25, 'VfL Wolfsburg', 30, 1),
('AUT', 'Alexander Prass', 'MF', 25, 'TSG Hoffenheim', 19, 0),
('AUT', 'Marco Friedl', 'DF', 28, 'SV Werder Bremen', 11, 0),
('AUT', 'Paul Wanner', 'MF', 20, 'PSV Eindhoven', 3, 0),
('AUT', 'Michael Svoboda', 'DF', 27, 'Venezia FC', 4, 0),
('AUT', 'Alessandro Schoepf', 'MF', 32, 'Wolfsberger AC', 35, 6);

-- ---------------------------
-- DR Congo (Group K) - 26 players (FIFA official)
-- ---------------------------
INSERT INTO players (team_id, name, position, age, club, caps, intl_goals) VALUES
('COD', 'Lionel Mpasi', 'GK', 31, 'Le Havre AC', 28, 0),
('COD', 'Aaron Wan-bissaka', 'DF', 28, 'West Ham United FC', 12, 0),
('COD', 'Steve Kapuadi', 'DF', 28, 'Widzew Łódź', 3, 0),
('COD', 'Axel Tuanzebe', 'DF', 28, 'Burnley FC', 13, 1),
('COD', 'Dylan Batubinsika', 'DF', 30, 'AEL FC', 15, 1),
('COD', 'Ngalayel Mukau', 'MF', 21, 'Lille OSC', 14, 0),
('COD', 'Nathanael Mbuku', 'MF', 24, 'Montpellier HSC', 19, 2),
('COD', 'Samuel Moutoussamy', 'MF', 29, 'Atromitos FC', 58, 0),
('COD', 'Brian Cipenga', 'FW', 28, 'CD Castellón', 8, 0),
('COD', 'Theo Bongonda', 'MF', 30, 'FC Spartak Moscow', 38, 7),
('COD', 'Gael Kakuta', 'FW', 34, 'AEL FC', 31, 5),
('COD', 'Joris Kayembe', 'DF', 31, 'KRC Genk', 26, 1),
('COD', 'Meschack Elia', 'FW', 28, 'Alanyaspor', 68, 12),
('COD', 'Noah Sadiki', 'MF', 21, 'Sunderland AFC', 20, 0),
('COD', 'Aaron Tshibola', 'MF', 31, 'Kilmarnock FC', 17, 1),
('COD', 'Timothy Fayulu', 'GK', 26, 'FC Noah', 3, 0),
('COD', 'Cedric Bakambu', 'FW', 35, 'Real Betis', 70, 21),
('COD', 'Charles Pickel', 'MF', 29, 'RCD Espanyol', 34, 1),
('COD', 'Fiston Mayele', 'FW', 31, 'Pyramids FC', 36, 5),
('COD', 'Yoane Wissa', 'FW', 29, 'Newcastle United FC', 38, 8),
('COD', 'Matthieu Epolo', 'GK', 21, 'Standard Liège', 1, 0),
('COD', 'Chancel Mbemba', 'DF', 31, 'Lille OSC', 109, 7),
('COD', 'Simon Banza', 'FW', 29, 'Al Jazira', 15, 2),
('COD', 'Gedeon Kalulu', 'DF', 28, 'Aris Limassol FC', 28, 0),
('COD', 'Edo Kayembe', 'MF', 28, 'Watford FC', 42, 2),
('COD', 'Arthur Masuaku', 'DF', 32, 'RC Lens', 44, 4);

-- ---------------------------
-- Colombia (Group K) - 26 players (FIFA official)
-- ---------------------------
INSERT INTO players (team_id, name, position, age, club, caps, intl_goals) VALUES
('COL', 'David Ospina', 'GK', 37, 'Atlético Nacional', 130, 0),
('COL', 'Daniel Munoz', 'DF', 30, 'Crystal Palace FC', 46, 3),
('COL', 'Jhon Lucumi', 'DF', 27, 'Bologna FC', 37, 1),
('COL', 'Santiago Arias', 'DF', 34, 'CA Independiente', 68, 0),
('COL', 'Kevin Castano', 'MF', 25, 'CA River Plate', 25, 0),
('COL', 'Richard Rios', 'MF', 26, 'Benfica', 32, 2),
('COL', 'Luis Diaz', 'FW', 29, 'FC Bayern München', 74, 22),
('COL', 'Jorge Carrascal', 'MF', 28, 'CR Flamengo', 25, 2),
('COL', 'Jhon Cordoba', 'FW', 33, 'FC Krasnodar', 21, 6),
('COL', 'James Rodriguez', 'MF', 34, 'Minnesota United FC', 126, 31),
('COL', 'Jhon Arias', 'MF', 28, 'SE Palmeiras', 38, 6),
('COL', 'Camilo Vargas', 'GK', 37, 'Atlas FC', 42, 0),
('COL', 'Yerry Mina', 'DF', 31, 'Cagliari', 54, 8),
('COL', 'Gustavo Puerta', 'DF', 22, 'Racing Santander', 6, 1),
('COL', 'Juan Portilla', 'MF', 27, 'Athletico Paranaense', 10, 0),
('COL', 'Jefferson Lerma', 'MF', 31, 'Crystal Palace FC', 65, 5),
('COL', 'Johan Mojica', 'DF', 33, 'RCD Mallorca', 45, 1),
('COL', 'Willer Ditta', 'DF', 28, 'Cruz Azul', 5, 0),
('COL', 'Cucho Hernandez', 'FW', 27, 'Real Betis', 9, 2),
('COL', 'Juan Quintero', 'MF', 33, 'CA River Plate', 49, 6),
('COL', 'Jaminton Campaz', 'FW', 26, 'CA Rosario Central', 10, 1),
('COL', 'Deiver Machado', 'DF', 32, 'FC Nantes', 15, 0),
('COL', 'Davinson Sanchez', 'DF', 29, 'Galatasaray SK', 79, 4),
('COL', 'Alvaro Montero', 'GK', 31, 'CA Vélez Sarseld', 12, 0),
('COL', 'Luis Suarez', 'FW', 28, 'Sporting CP', 12, 5),
('COL', 'Andres Gomez', 'FW', 23, 'CR Vasco Da Gama', 8, 2);

-- ---------------------------
-- Croatia (Group L) - 26 players (FIFA official)
-- ---------------------------
INSERT INTO players (team_id, name, position, age, club, caps, intl_goals) VALUES
('CRO', 'Dominik Livakovic', 'GK', 31, 'GNK Dinamo Zagreb', 75, 0),
('CRO', 'Josip Stanisic', 'DF', 26, 'FC Bayern München', 31, 0),
('CRO', 'Marin Pongracic', 'DF', 28, 'ACF Fiorentina', 20, 0),
('CRO', 'Josko Gvardiol', 'DF', 24, 'Manchester City FC', 48, 4),
('CRO', 'Duje Caleta-car', 'DF', 29, 'Real Sociedad', 38, 1),
('CRO', 'Josip Sutalo', 'DF', 26, 'AFC Ajax', 33, 0),
('CRO', 'Nikola Moro', 'MF', 28, 'Bologna FC', 10, 0),
('CRO', 'Mateo Kovacic', 'MF', 32, 'Manchester City FC', 113, 5),
('CRO', 'Andrej Kramaric', 'FW', 34, 'TSG Hoffenheim', 116, 36),
('CRO', 'Luka Modric', 'MF', 40, 'AC Milan', 198, 29),
('CRO', 'Ante Budimir', 'FW', 34, 'CA Osasuna', 38, 6),
('CRO', 'Ivor Pandur', 'GK', 26, 'Hull City FC', 0, 0),
('CRO', 'Nikola Vlasic', 'MF', 28, 'Torino FC', 63, 10),
('CRO', 'Ivan Perisic', 'FW', 37, 'PSV Eindhoven', 154, 38),
('CRO', 'Mario Pasalic', 'MF', 31, 'Atalanta Bergamo', 85, 12),
('CRO', 'Martin Baturina', 'MF', 23, 'Como', 19, 1),
('CRO', 'Petar Sucic', 'MF', 22, 'Inter Milan', 17, 1),
('CRO', 'Kristijan Jakic', 'DF', 29, 'FC Augsburg', 17, 2),
('CRO', 'Toni Fruk', 'MF', 25, 'HNK Rijeka', 7, 1),
('CRO', 'Igor Matanovic', 'FW', 23, 'SC Freiburg', 9, 2),
('CRO', 'Luka Sucic', 'MF', 23, 'Real Sociedad', 21, 1),
('CRO', 'Luka Vuskovic', 'DF', 19, 'Hamburger SV', 5, 1),
('CRO', 'Dominik Kotarski', 'GK', 26, 'FC København', 4, 0),
('CRO', 'Marco Pasalic', 'FW', 25, 'Orlando City SC', 15, 1),
('CRO', 'Martin Erlic', 'DF', 28, 'FC Midtjylland', 13, 1),
('CRO', 'Petar Musa', 'FW', 28, 'FC Dallas', 11, 1);

-- ---------------------------
-- England (Group L) - 26 players (FIFA official)
-- ---------------------------
INSERT INTO players (team_id, name, position, age, club, caps, intl_goals) VALUES
('ENG', 'Jordan Pickford', 'GK', 32, 'Everton FC', 84, 0),
('ENG', 'Ezri Konsa', 'DF', 28, 'Aston Villa FC', 20, 1),
('ENG', 'Nico Oreilly', 'DF', 21, 'Manchester City FC', 5, 0),
('ENG', 'Declan Rice', 'MF', 27, 'Arsenal FC', 73, 7),
('ENG', 'John Stones', 'DF', 32, 'Manchester City FC', 89, 3),
('ENG', 'Marc Guehi', 'DF', 25, 'Manchester City FC', 29, 1),
('ENG', 'Bukayo Saka', 'FW', 24, 'Arsenal FC', 49, 14),
('ENG', 'Elliot Anderson', 'MF', 23, 'Nottingham Forest FC', 9, 0),
('ENG', 'Harry Kane', 'FW', 32, 'FC Bayern München', 114, 79),
('ENG', 'Jude Bellingham', 'MF', 22, 'Real Madrid', 48, 6),
('ENG', 'Marcus Rashford', 'FW', 28, 'FC Barcelona', 72, 18),
('ENG', 'Tino Livramento', 'DF', 23, 'Newcastle United FC', 6, 0),
('ENG', 'Dean Henderson', 'GK', 29, 'Crystal Palace FC', 4, 0),
('ENG', 'Jordan Henderson', 'MF', 35, 'Brentford FC', 91, 3),
('ENG', 'Dan Burn', 'DF', 34, 'Newcastle United FC', 8, 0),
('ENG', 'Kobbie Mainoo', 'MF', 21, 'Manchester United FC', 14, 0),
('ENG', 'Morgan Rogers', 'MF', 23, 'Aston Villa FC', 15, 1),
('ENG', 'Anthony Gordon', 'FW', 25, 'Newcastle United FC', 19, 3),
('ENG', 'Ollie Watkins', 'FW', 30, 'Aston Villa FC', 22, 7),
('ENG', 'Noni Madueke', 'FW', 24, 'Arsenal FC', 11, 1),
('ENG', 'Eberechi Eze', 'MF', 27, 'Arsenal FC', 17, 3),
('ENG', 'Ivan Toney', 'FW', 30, 'Al Ahli', 8, 1),
('ENG', 'James Trafford', 'GK', 23, 'Manchester City FC', 2, 0),
('ENG', 'Reece James', 'DF', 26, 'Chelsea FC', 24, 1),
('ENG', 'Djed Spence', 'DF', 25, 'Tottenham Hotspur FC', 6, 0),
('ENG', 'Jarell Quansah', 'DF', 23, 'Bayer 04 Leverkusen', 3, 0);

-- ---------------------------
-- Ghana (Group L) - 26 players (FIFA official)
-- ---------------------------
INSERT INTO players (team_id, name, position, age, club, caps, intl_goals) VALUES
('GHA', 'Lawrence Zigi', 'GK', 29, 'FC St. Gallen', 30, 0),
('GHA', 'Alidu Seidu', 'DF', 26, 'Stade Rennais FC', 24, 1),
('GHA', 'Caleb Yirenkyi', 'MF', 20, 'FC Nordsjælland', 11, 1),
('GHA', 'Jonas Adjetey', 'DF', 22, 'VfL Wolfsburg', 10, 0),
('GHA', 'Thomas Partey', 'MF', 32, 'Villarreal CF', 59, 16),
('GHA', 'Abdul Mumin', 'DF', 28, 'Rayo Vallecano', 5, 0),
('GHA', 'Abdul Fatawu', 'FW', 22, 'Leicester City FC', 28, 3),
('GHA', 'Kwasi Sibo', 'MF', 27, 'Real Oviedo', 8, 0),
('GHA', 'Jordan Ayew', 'FW', 34, 'Leicester City FC', 120, 34),
('GHA', 'Brandon Thomas-asante', 'FW', 27, 'Coventry City FC', 8, 1),
('GHA', 'Antoine Semenyo', 'MF', 26, 'Manchester City FC', 34, 3),
('GHA', 'Joseph Anang', 'GK', 26, 'St Patrick''s Athletic FC', 1, 0),
('GHA', 'Christopher Bonsu Baah', 'FW', 21, 'Al-Qadsiah', 9, 0),
('GHA', 'Gideon Mensah', 'DF', 27, 'AJ Auxerre', 40, 0),
('GHA', 'Elisha Owusu', 'MF', 28, 'AJ Auxerre', 20, 0),
('GHA', 'Benjamin Asare', 'GK', 33, 'Hearts Of Oak SC', 13, 0),
('GHA', 'Baba Rahman', 'DF', 31, 'PAOK Saloniki', 53, 1),
('GHA', 'Jerome Opoku', 'DF', 27, 'Başakşehir FK', 11, 1),
('GHA', 'Inaki Williams', 'FW', 31, 'Athletic Club', 26, 2),
('GHA', 'Augustine Boakye', 'MF', 25, 'AS Saint-Etienne', 0, 0),
('GHA', 'Kojo Oppong', 'DF', 22, 'OGC Nice', 4, 0),
('GHA', 'Kamaldeen Sulemana', 'FW', 24, 'Atalanta Bergamo', 28, 1),
('GHA', 'Derrick Luckassen', 'DF', 30, 'Pafos FC', 1, 0),
('GHA', 'Ernest Nuamah', 'FW', 22, 'Olympique Lyonnais', 19, 4),
('GHA', 'Prince Adu', 'FW', 22, 'FC Viktoria Plzeň', 5, 0),
('GHA', 'Marvin Senaya', 'DF', 25, 'AJ Auxerre', 2, 0);


-- ---------------------------
-- South Korea (Group A) - 26 players
-- ---------------------------
INSERT INTO players (team_id, name, position, age, club, caps, intl_goals) VALUES
('KOR', 'Kim Seung-gyu', 'GK', 35, 'FC Tokyo', 86, 0),
('KOR', 'Jo Hyeon-woo', 'GK', 34, 'Ulsan HD', 48, 0),
('KOR', 'Song Bum-keun', 'GK', 28, 'Jeonbuk Hyundai Motors', 2, 0),
('KOR', 'Kim Min-jae', 'DF', 29, 'FC Bayern München', 78, 4),
('KOR', 'Kim Moon-hwan', 'DF', 30, 'Daejeon Hana Citizen', 35, 0),
('KOR', 'Seol Young-woo', 'DF', 27, 'Red Star Belgrade', 33, 0),
('KOR', 'Lee Tae-seok', 'DF', 23, 'Austria Wien', 14, 1),
('KOR', 'Park Jin-seob', 'DF', 30, 'Zhejiang', 13, 1),
('KOR', 'Kim Tae-hyeon', 'DF', 25, 'Kashima Antlers', 7, 0),
('KOR', 'Lee Han-beom', 'DF', 23, 'FC Midtjylland', 7, 0),
('KOR', 'Jens Castrop', 'DF', 22, 'Borussia Mönchengladbach', 6, 0),
('KOR', 'Lee Ki-hyuk', 'DF', 25, 'Gangwon FC', 2, 0),
('KOR', 'Cho Wi-je', 'DF', 24, 'Jeonbuk Hyundai Motors', 0, 0),
('KOR', 'Lee Jae-sung', 'MF', 33, 'Mainz 05', 104, 15),
('KOR', 'Hwang Hee-chan', 'MF', 30, 'Wolverhampton Wanderers FC', 78, 17),
('KOR', 'Hwang In-beom', 'MF', 29, 'Feyenoord', 72, 6),
('KOR', 'Lee Kang-in', 'MF', 25, 'Paris Saint-Germain', 46, 11),
('KOR', 'Paik Seung-ho', 'MF', 29, 'Birmingham City', 26, 3),
('KOR', 'Kim Jin-gyu', 'MF', 29, 'Jeonbuk Hyundai Motors', 21, 3),
('KOR', 'Lee Dong-gyeong', 'MF', 28, 'Ulsan HD', 17, 3),
('KOR', 'Bae Jun-ho', 'MF', 22, 'Stoke City', 13, 2),
('KOR', 'Eom Ji-sung', 'MF', 24, 'Swansea City AFC', 9, 2),
('KOR', 'Yang Hyun-jun', 'MF', 24, 'Celtic FC', 8, 0),
('KOR', 'Son Heung-min', 'FW', 33, 'LAFC', 143, 56),
('KOR', 'Cho Gue-sung', 'FW', 28, 'FC Midtjylland', 43, 12),
('KOR', 'Oh Hyeon-gyu', 'FW', 25, 'Beşiktaş JK', 26, 6);

-- ---------------------------
-- South Africa (Group A) - 26 players
-- ---------------------------
INSERT INTO players (team_id, name, position, age, club, caps, intl_goals) VALUES
('RSA', 'Ronwen Williams', 'GK', 34, 'Mamelodi Sundowns', 62, 0),
('RSA', 'Ricardo Goss', 'GK', 32, 'Siwelele', 4, 0),
('RSA', 'Sipho Chaine', 'GK', 29, 'Orlando Pirates', 3, 0),
('RSA', 'Aubrey Modiba', 'DF', 30, 'Mamelodi Sundowns', 44, 3),
('RSA', 'Khuliso Mudau', 'DF', 31, 'Mamelodi Sundowns', 32, 1),
('RSA', 'Nkosinathi Sibisi', 'DF', 30, 'Orlando Pirates', 19, 0),
('RSA', 'Mbekezeli Mbokazi', 'DF', 20, 'Chicago Fire FC', 10, 1),
('RSA', 'Ime Okon', 'DF', 22, 'Hannover 96', 7, 1),
('RSA', 'Samukele Kabini', 'DF', 22, 'Molde', 5, 0),
('RSA', 'Khulumani Ndamane', 'DF', 22, 'Mamelodi Sundowns', 5, 0),
('RSA', 'Thabang Matuludi', 'DF', 27, 'Polokwane City', 2, 0),
('RSA', 'Kamogelo Sebelebele', 'DF', 23, 'Orlando Pirates', 2, 0),
('RSA', 'Bradley Cross', 'DF', 25, 'Kaizer Chiefs', 0, 0),
('RSA', 'Olwethu Makhanya', 'DF', 22, 'Philadelphia Union', 0, 0),
('RSA', 'Teboho Mokoena', 'MF', 29, 'Mamelodi Sundowns', 51, 9),
('RSA', 'Sphephelo Sithole', 'MF', 27, 'Tondela', 27, 1),
('RSA', 'Thalente Mbatha', 'MF', 26, 'Orlando Pirates', 14, 3),
('RSA', 'Jayden Adams', 'MF', 25, 'Mamelodi Sundowns', 4, 0),
('RSA', 'Themba Zwane', 'FW', 36, 'Mamelodi Sundowns', 53, 12),
('RSA', 'Lyle Foster', 'FW', 26, 'Burnley FC', 26, 10),
('RSA', 'Evidence Makgopa', 'FW', 26, 'Orlando Pirates', 26, 6),
('RSA', 'Oswin Appollis', 'FW', 24, 'Orlando Pirates', 25, 8),
('RSA', 'Iqraam Rayners', 'FW', 30, 'Mamelodi Sundowns', 13, 4),
('RSA', 'Relebohile Mofokeng', 'FW', 21, 'Orlando Pirates', 12, 0),
('RSA', 'Thapelo Maseko', 'FW', 22, 'AEL Limassol', 9, 1),
('RSA', 'Tshepang Moremi', 'FW', 25, 'Orlando Pirates', 9, 1);

-- ---------------------------
-- Qatar (Group B) - 26 players
-- ---------------------------
INSERT INTO players (team_id, name, position, age, club, caps, intl_goals) VALUES
('QAT', 'Mahmud Abunada', 'GK', 26, 'Al-Rayyan', 4, 0),
('QAT', 'Pedro Miguel', 'DF', 35, 'Al-Sadd', 98, 3),
('QAT', 'Lucas Mendes', 'DF', 35, 'Al-Wakrah', 25, 1),
('QAT', 'Issa Laye', 'DF', 28, 'Al-Arabi', 3, 0),
('QAT', 'Jassem Gaber', 'MF', 24, 'Al-Rayyan', 31, 1),
('QAT', 'Abdulaziz Hatem', 'MF', 35, 'Al-Rayyan', 117, 11),
('QAT', 'Ahmed Alaaeldin', 'FW', 33, 'Al-Rayyan', 67, 9),
('QAT', 'Edmilson Junior', 'FW', 31, 'Al-Duhail', 15, 0),
('QAT', 'Mohammed Muntari', 'FW', 32, 'Al-Gharafa', 67, 16),
('QAT', 'Hassan Al-Haydos', 'FW', 35, 'Al-Sadd', 185, 41),
('QAT', 'Akram Afif', 'FW', 29, 'Al-Sadd', 124, 39),
('QAT', 'Karim Boudiaf', 'MF', 35, 'Al-Duhail', 117, 5),
('QAT', 'Ayoub Al-Oui', 'DF', 21, 'Al-Gharafa', 5, 0),
('QAT', 'Homam Ahmed', 'DF', 26, 'Cultural Leonesa', 67, 3),
('QAT', 'Yusuf Abdurisag', 'FW', 26, 'Al-Wakrah', 38, 3),
('QAT', 'Boualem Khoukhi', 'DF', 35, 'Al-Sadd', 115, 20),
('QAT', 'Ahmed Al-Ganehi', 'FW', 25, 'Al-Gharafa', 13, 1),
('QAT', 'Sultan Al-Brake', 'DF', 30, 'Al-Duhail', 16, 0),
('QAT', 'Almoez Ali', 'FW', 29, 'Al-Duhail', 115, 55),
('QAT', 'Ahmed Fathy', 'MF', 33, 'Al-Arabi', 47, 0),
('QAT', 'Salah Zakaria', 'GK', 27, 'Al-Duhail', 8, 0),
('QAT', 'Meshaal Barsham', 'GK', 28, 'Al-Sadd', 52, 0),
('QAT', 'Assim Madibo', 'MF', 29, 'Al-Wakrah', 50, 0),
('QAT', 'Tahsin Jamshid', 'FW', 19, 'Al-Duhail', 2, 0),
('QAT', 'Al-Hashmi Al-Hussain', 'DF', 22, 'Al-Arabi', 7, 0),
('QAT', 'Mohamed Al-Mannai', 'MF', 22, 'Al-Shamal', 9, 0);

-- ---------------------------
-- Switzerland (Group B) - 26 players
-- ---------------------------
INSERT INTO players (team_id, name, position, age, club, caps, intl_goals) VALUES
('SUI', 'Gregor Kobel', 'GK', 28, 'Borussia Dortmund', 20, 0),
('SUI', 'Miro Muheim', 'DF', 28, 'Hamburger SV', 9, 0),
('SUI', 'Silvan Widmer', 'DF', 33, 'Mainz 05', 59, 5),
('SUI', 'Nico Elvedi', 'DF', 29, 'Borussia Mönchengladbach', 66, 3),
('SUI', 'Manuel Akanji', 'DF', 30, 'Inter Milan', 80, 4),
('SUI', 'Denis Zakaria', 'MF', 29, 'AS Monaco', 64, 3),
('SUI', 'Breel Embolo', 'FW', 29, 'Rennes', 86, 24),
('SUI', 'Remo Freuler', 'MF', 34, 'Bologna FC', 87, 11),
('SUI', 'Johan Manzambi', 'MF', 20, 'SC Freiburg', 11, 3),
('SUI', 'Granit Xhaka', 'MF', 33, 'Sunderland AFC', 145, 17),
('SUI', 'Dan Ndoye', 'FW', 25, 'Nottingham Forest FC', 30, 7),
('SUI', 'Yvon Mvogo', 'GK', 32, 'Lorient', 13, 0),
('SUI', 'Ricardo Rodriguez', 'DF', 33, 'Real Betis', 137, 9),
('SUI', 'Ardon Jashari', 'MF', 23, 'AC Milan', 7, 0),
('SUI', 'Djibril Sow', 'MF', 29, 'Sevilla', 51, 0),
('SUI', 'Christian Fassnacht', 'MF', 32, 'BSC Young Boys', 22, 5),
('SUI', 'Rubén Vargas', 'FW', 27, 'Sevilla', 61, 11),
('SUI', 'Eray Cömert', 'DF', 28, 'Valencia', 21, 0),
('SUI', 'Noah Okafor', 'FW', 26, 'Leeds United', 24, 2),
('SUI', 'Michel Aebischer', 'MF', 29, 'Pisa', 39, 2),
('SUI', 'Marvin Keller', 'GK', 23, 'BSC Young Boys', 1, 0),
('SUI', 'Fabian Rieder', 'MF', 24, 'FC Augsburg', 27, 1),
('SUI', 'Zeki Amdouni', 'FW', 25, 'Burnley FC', 28, 11),
('SUI', 'Aurèle Amenda', 'DF', 22, 'Eintracht Frankfurt', 6, 0),
('SUI', 'Luca Jaquez', 'DF', 23, 'VfB Stuttgart', 3, 0),
('SUI', 'Cedric Itten', 'FW', 29, 'Fortuna Düsseldorf', 14, 5);

-- ---------------------------
-- Scotland (Group C) - 26 players
-- ---------------------------
INSERT INTO players (team_id, name, position, age, club, caps, intl_goals) VALUES
('SCO', 'Craig Gordon', 'GK', 43, 'Heart Of Midlothian FC', 84, 0),
('SCO', 'Angus Gunn', 'GK', 30, 'Nottingham Forest FC', 21, 0),
('SCO', 'Liam Kelly', 'GK', 30, 'Rangers FC', 3, 0),
('SCO', 'Andy Robertson', 'DF', 32, 'Liverpool FC', 93, 4),
('SCO', 'Grant Hanley', 'DF', 34, 'Hibernian', 67, 2),
('SCO', 'Kieran Tierney', 'DF', 29, 'Celtic FC', 55, 2),
('SCO', 'Scott McKenna', 'DF', 29, 'GNK Dinamo Zagreb', 50, 1),
('SCO', 'Jack Hendry', 'DF', 31, 'Al-Ettifaq', 37, 3),
('SCO', 'Nathan Patterson', 'DF', 24, 'Everton FC', 26, 1),
('SCO', 'Anthony Ralston', 'DF', 27, 'Celtic FC', 26, 1),
('SCO', 'John Souttar', 'DF', 29, 'Rangers FC', 23, 2),
('SCO', 'Aaron Hickey', 'DF', 24, 'Brentford FC', 20, 0),
('SCO', 'Dominic Hyam', 'DF', 30, 'Wrexham AFC', 3, 0),
('SCO', 'John McGinn', 'MF', 31, 'Aston Villa FC', 85, 20),
('SCO', 'Scott McTominay', 'MF', 29, 'SSC Napoli', 69, 14),
('SCO', 'Ryan Christie', 'MF', 31, 'Bournemouth', 67, 10),
('SCO', 'Kenny McLean', 'MF', 34, 'Norwich City FC', 57, 3),
('SCO', 'Lewis Ferguson', 'MF', 26, 'Bologna FC', 23, 1),
('SCO', 'Ben Gannon-Doak', 'MF', 20, 'Bournemouth', 13, 1),
('SCO', 'Findlay Curtis', 'MF', 20, 'Kilmarnock FC', 2, 1),
('SCO', 'Tyler Fletcher', 'MF', 19, 'Manchester United FC', 1, 0),
('SCO', 'Lyndon Dykes', 'FW', 30, 'Charlton Athletic', 51, 10),
('SCO', 'Ché Adams', 'FW', 29, 'Torino FC', 46, 11),
('SCO', 'Lawrence Shankland', 'FW', 30, 'Heart Of Midlothian FC', 19, 6),
('SCO', 'George Hirst', 'FW', 27, 'Ipswich Town', 9, 1),
('SCO', 'Ross Stewart', 'FW', 29, 'Southampton FC', 2, 0);

-- ---------------------------
-- Paraguay (Group D) - 26 players
-- ---------------------------
INSERT INTO players (team_id, name, position, age, club, caps, intl_goals) VALUES
('PAR', 'Gatito Fernández', 'GK', 38, 'Cerro Porteño', 30, 0),
('PAR', 'Orlando Gill', 'GK', 26, 'San Lorenzo', 5, 0),
('PAR', 'Gastón Olveira', 'GK', 33, 'Olimpia', 1, 0),
('PAR', 'Gustavo Gómez', 'DF', 33, 'SE Palmeiras', 88, 4),
('PAR', 'Júnior Alonso', 'DF', 33, 'Atlético Mineiro', 70, 3),
('PAR', 'Fabián Balbuena', 'DF', 34, 'Grêmio', 47, 2),
('PAR', 'Omar Alderete', 'DF', 29, 'Sunderland AFC', 35, 3),
('PAR', 'Juan José Cáceres', 'DF', 26, 'Dynamo Moscow', 16, 0),
('PAR', 'Gustavo Velázquez', 'DF', 35, 'Cerro Porteño', 12, 1),
('PAR', 'José Canale', 'DF', 29, 'Lanús', 1, 0),
('PAR', 'Alexandro Maidana', 'DF', 20, 'Talleres', 1, 0),
('PAR', 'Miguel Almirón', 'MF', 32, 'Atlanta United FC', 75, 9),
('PAR', 'Kaku', 'MF', 31, 'Al-Ain', 32, 5),
('PAR', 'Andrés Cubas', 'MF', 30, 'Vancouver Whitecaps FC', 32, 0),
('PAR', 'Ramón Sosa', 'MF', 26, 'SE Palmeiras', 28, 1),
('PAR', 'Diego Gómez', 'MF', 23, 'Brighton & Hove Albion FC', 23, 3),
('PAR', 'Damián Bobadilla', 'MF', 24, 'São Paulo', 19, 1),
('PAR', 'Braian Ojeda', 'MF', 25, 'Orlando City SC', 16, 0),
('PAR', 'Matías Galarza', 'MF', 24, 'Atlanta United FC', 14, 2),
('PAR', 'Maurício', 'MF', 24, 'SE Palmeiras', 2, 0),
('PAR', 'Antonio Sanabria', 'FW', 30, 'Cremonese', 47, 7),
('PAR', 'Julio Enciso', 'FW', 22, 'RC Strasbourg', 31, 4),
('PAR', 'Gabriel Ávalos', 'FW', 34, 'Independiente', 22, 2),
('PAR', 'Álex Arce', 'FW', 30, 'Independiente Rivadavia', 14, 1),
('PAR', 'Isidro Pitta', 'FW', 26, 'Red Bull Bragantino', 5, 0),
('PAR', 'Gustavo Caballero', 'FW', 24, 'Portsmouth', 2, 1);

-- ---------------------------
-- United States (Group D) - 26 players
-- ---------------------------
INSERT INTO players (team_id, name, position, age, club, caps, intl_goals) VALUES
('USA', 'Matt Turner', 'GK', 31, 'New England Revolution', 54, 0),
('USA', 'Sergiño Dest', 'DF', 25, 'PSV Eindhoven', 38, 3),
('USA', 'Chris Richards', 'DF', 26, 'Crystal Palace FC', 36, 3),
('USA', 'Tyler Adams', 'MF', 27, 'Bournemouth', 53, 2),
('USA', 'Antonee Robinson', 'DF', 28, 'Fulham FC', 53, 4),
('USA', 'Auston Trusty', 'DF', 27, 'Celtic FC', 7, 0),
('USA', 'Giovanni Reyna', 'MF', 23, 'Borussia Mönchengladbach', 37, 9),
('USA', 'Weston McKennie', 'MF', 27, 'Juventus FC', 65, 12),
('USA', 'Ricardo Pepi', 'FW', 23, 'PSV Eindhoven', 36, 13),
('USA', 'Christian Pulisic', 'FW', 27, 'AC Milan', 85, 33),
('USA', 'Brenden Aaronson', 'FW', 25, 'Leeds United', 57, 9),
('USA', 'Miles Robinson', 'DF', 29, 'FC Cincinnati', 39, 3),
('USA', 'Tim Ream', 'DF', 38, 'Charlotte FC', 81, 1),
('USA', 'Sebastian Berhalter', 'MF', 25, 'Vancouver Whitecaps FC', 12, 1),
('USA', 'Cristian Roldan', 'MF', 31, 'Seattle Sounders FC', 46, 0),
('USA', 'Alex Freeman', 'DF', 21, 'Villarreal CF', 16, 2),
('USA', 'Malik Tillman', 'MF', 24, 'Bayer 04 Leverkusen', 29, 3),
('USA', 'Maximilian Arfsten', 'DF', 25, 'Columbus Crew', 19, 1),
('USA', 'Haji Wright', 'FW', 28, 'Coventry City FC', 20, 7),
('USA', 'Folarin Balogun', 'FW', 24, 'AS Monaco', 26, 9),
('USA', 'Timothy Weah', 'FW', 26, 'Olympique Marseille', 50, 7),
('USA', 'Mark McKenzie', 'DF', 27, 'Toulouse', 28, 0),
('USA', 'Joe Scally', 'DF', 23, 'Borussia Mönchengladbach', 25, 0),
('USA', 'Matt Freese', 'GK', 27, 'New York City FC', 14, 0),
('USA', 'Chris Brady', 'GK', 22, 'Chicago Fire FC', 1, 0),
('USA', 'Alejandro Zendejas', 'FW', 28, 'América', 14, 2);

-- ---------------------------
-- Japan (Group F) - 26 players
-- ---------------------------
INSERT INTO players (team_id, name, position, age, club, caps, intl_goals) VALUES
('JPN', 'Zion Suzuki', 'GK', 23, 'Parma', 24, 0),
('JPN', 'Yukinari Sugawara', 'DF', 25, 'SV Werder Bremen', 21, 2),
('JPN', 'Shōgo Taniguchi', 'DF', 34, 'Sint-Truiden', 38, 1),
('JPN', 'Kō Itakura', 'DF', 29, 'AFC Ajax', 40, 2),
('JPN', 'Yūto Nagatomo', 'DF', 39, 'FC Tokyo', 145, 4),
('JPN', 'Wataru Endo', 'MF', 33, 'Liverpool FC', 73, 4),
('JPN', 'Ao Tanaka', 'MF', 27, 'Leeds United', 38, 8),
('JPN', 'Takefusa Kubo', 'MF', 25, 'Real Sociedad', 49, 7),
('JPN', 'Keisuke Gotō', 'FW', 21, 'Sint-Truiden', 4, 0),
('JPN', 'Ritsu Dōan', 'MF', 27, 'Eintracht Frankfurt', 65, 11),
('JPN', 'Daizen Maeda', 'FW', 28, 'Celtic FC', 27, 4),
('JPN', 'Keisuke Ōsako', 'GK', 26, 'Sanfrecce Hiroshima', 11, 0),
('JPN', 'Keito Nakamura', 'MF', 25, 'Reims', 25, 10),
('JPN', 'Junya Itō', 'MF', 33, 'KRC Genk', 69, 15),
('JPN', 'Daichi Kamada', 'MF', 29, 'Crystal Palace FC', 49, 12),
('JPN', 'Tsuyoshi Watanabe', 'DF', 29, 'Feyenoord', 11, 0),
('JPN', 'Yuito Suzuki', 'FW', 24, 'SC Freiburg', 6, 0),
('JPN', 'Ayase Ueda', 'FW', 27, 'Feyenoord', 39, 16),
('JPN', 'Kōki Ogawa', 'FW', 28, 'NEC', 15, 11),
('JPN', 'Ayumu Seko', 'DF', 26, 'Le Havre AC', 14, 0),
('JPN', 'Hiroki Itō', 'DF', 27, 'FC Bayern München', 24, 1),
('JPN', 'Takehiro Tomiyasu', 'DF', 27, 'AFC Ajax', 43, 1),
('JPN', 'Tomoki Hayakawa', 'GK', 27, 'Kashima Antlers', 4, 0),
('JPN', 'Kaishū Sano', 'MF', 25, 'Mainz 05', 13, 0),
('JPN', 'Junnosuke Suzuki', 'DF', 22, 'Copenhagen', 6, 0),
('JPN', 'Kento Shiogai', 'FW', 21, 'VfL Wolfsburg', 2, 0);

-- ---------------------------
-- Netherlands (Group F) - 26 players
-- ---------------------------
INSERT INTO players (team_id, name, position, age, club, caps, intl_goals) VALUES
('NED', 'Bart Verbruggen', 'GK', 23, 'Brighton & Hove Albion FC', 27, 0),
('NED', 'Mark Flekken', 'GK', 32, 'Bayer 04 Leverkusen', 11, 0),
('NED', 'Robin Roefs', 'GK', 23, 'Sunderland AFC', 0, 0),
('NED', 'Virgil van Dijk', 'DF', 34, 'Liverpool FC', 90, 12),
('NED', 'Denzel Dumfries', 'DF', 30, 'Inter Milan', 71, 11),
('NED', 'Nathan Aké', 'DF', 31, 'Manchester City FC', 58, 5),
('NED', 'Jurriën Timber', 'DF', 24, 'Arsenal FC', 23, 0),
('NED', 'Micky van de Ven', 'DF', 25, 'Tottenham Hotspur FC', 19, 1),
('NED', 'Mats Wieffer', 'DF', 26, 'Brighton & Hove Albion FC', 14, 1),
('NED', 'Jan Paul van Hecke', 'DF', 26, 'Brighton & Hove Albion FC', 10, 0),
('NED', 'Jorrel Hato', 'DF', 20, 'Chelsea FC', 7, 0),
('NED', 'Frenkie de Jong', 'MF', 29, 'FC Barcelona', 64, 2),
('NED', 'Marten de Roon', 'MF', 35, 'Atalanta', 42, 1),
('NED', 'Tijjani Reijnders', 'MF', 27, 'Manchester City FC', 30, 7),
('NED', 'Teun Koopmeiners', 'MF', 28, 'Juventus FC', 27, 3),
('NED', 'Ryan Gravenberch', 'MF', 24, 'Liverpool FC', 25, 1),
('NED', 'Justin Kluivert', 'MF', 27, 'Bournemouth', 11, 0),
('NED', 'Quinten Timber', 'MF', 24, 'Olympique Marseille', 10, 1),
('NED', 'Guus Til', 'MF', 28, 'PSV Eindhoven', 6, 1),
('NED', 'Memphis Depay', 'FW', 32, 'Corinthians', 108, 55),
('NED', 'Wout Weghorst', 'FW', 33, 'AFC Ajax', 51, 14),
('NED', 'Donyell Malen', 'FW', 27, 'AS Roma', 51, 13),
('NED', 'Cody Gakpo', 'FW', 27, 'Liverpool FC', 48, 19),
('NED', 'Noa Lang', 'FW', 26, 'Galatasaray SK', 15, 3),
('NED', 'Brian Brobbey', 'FW', 24, 'Sunderland AFC', 10, 1),
('NED', 'Crysencio Summerville', 'FW', 24, 'West Ham United FC', 0, 0);

-- ---------------------------
-- Sweden (Group F) - 26 players
-- ---------------------------
INSERT INTO players (team_id, name, position, age, club, caps, intl_goals) VALUES
('SWE', 'Jacob Widell Zetterström', 'GK', 27, 'Derby County', 3, 0),
('SWE', 'Gustaf Lagerbielke', 'DF', 26, 'SC Braga', 10, 2),
('SWE', 'Victor Lindelöf', 'DF', 31, 'Aston Villa FC', 76, 3),
('SWE', 'Isak Hien', 'DF', 27, 'Atalanta', 28, 0),
('SWE', 'Gabriel Gudmundsson', 'DF', 27, 'Leeds United', 23, 0),
('SWE', 'Herman Johansson', 'DF', 28, 'FC Dallas', 3, 0),
('SWE', 'Lucas Bergvall', 'MF', 20, 'Tottenham Hotspur FC', 9, 0),
('SWE', 'Daniel Svensson', 'DF', 24, 'Borussia Dortmund', 12, 0),
('SWE', 'Alexander Isak', 'FW', 26, 'Liverpool FC', 57, 17),
('SWE', 'Benjamin Nygren', 'FW', 24, 'Celtic FC', 10, 3),
('SWE', 'Anthony Elanga', 'FW', 24, 'Newcastle United FC', 29, 6),
('SWE', 'Viktor Johansson', 'GK', 27, 'Stoke City', 12, 0),
('SWE', 'Ken Sema', 'FW', 32, 'Pafos FC', 33, 5),
('SWE', 'Hjalmar Ekdal', 'DF', 27, 'Burnley FC', 12, 0),
('SWE', 'Carl Starfelt', 'DF', 31, 'Celta Vigo', 17, 0),
('SWE', 'Jesper Karlström', 'MF', 30, 'Udinese', 24, 0),
('SWE', 'Viktor Gyökeres', 'FW', 28, 'Arsenal FC', 32, 19),
('SWE', 'Yasin Ayari', 'MF', 22, 'Brighton & Hove Albion FC', 20, 3),
('SWE', 'Mattias Svanberg', 'MF', 27, 'VfL Wolfsburg', 40, 2),
('SWE', 'Eric Smith', 'DF', 29, 'FC St. Pauli', 1, 0),
('SWE', 'Alexander Bernhardsson', 'FW', 27, 'Holstein Kiel', 10, 0),
('SWE', 'Besfort Zeneli', 'MF', 23, 'Union Saint-Gilloise', 7, 0),
('SWE', 'Kristoffer Nordfeldt', 'GK', 36, 'AIK', 20, 0),
('SWE', 'Elliot Stroud', 'DF', 23, 'Mjällby AIF', 0, 0),
('SWE', 'Gustaf Nilsson', 'FW', 29, 'Club Brugge', 9, 3),
('SWE', 'Taha Ali', 'FW', 27, 'Malmö FF', 1, 0);

-- ---------------------------
-- Tunisia (Group F) - 26 players
-- ---------------------------
INSERT INTO players (team_id, name, position, age, club, caps, intl_goals) VALUES
('TUN', 'Aymen Dahmen', 'GK', 29, 'CS Sfaxien', 37, 0),
('TUN', 'Sabri Ben Hessen', 'GK', 29, 'Étoile du Sahel', 2, 0),
('TUN', 'Mouhib Chamakh', 'GK', 24, 'Club Africain', 1, 0),
('TUN', 'Montassar Talbi', 'DF', 28, 'Lorient', 62, 4),
('TUN', 'Dylan Bronn', 'DF', 30, 'Servette', 52, 2),
('TUN', 'Ali Abdi', 'DF', 32, 'Nice', 45, 7),
('TUN', 'Yan Valery', 'DF', 27, 'BSC Young Boys', 21, 0),
('TUN', 'Mohamed Amine Ben Hamida', 'DF', 30, 'Espérance de Tunis', 12, 0),
('TUN', 'Moutaz Neffati', 'DF', 21, 'IFK Norrköping', 5, 0),
('TUN', 'Omar Rekik', 'DF', 24, 'NK Maribor', 4, 0),
('TUN', 'Adem Arous', 'DF', 21, 'Kasımpaşa', 1, 0),
('TUN', 'Raed Chikhaoui', 'DF', 22, 'US Monastir', 0, 0),
('TUN', 'Ellyes Skhiri', 'MF', 31, 'Eintracht Frankfurt', 81, 4),
('TUN', 'Hannibal Mejbri', 'MF', 23, 'Burnley FC', 44, 1),
('TUN', 'Anis Ben Slimane', 'MF', 25, 'Norwich City FC', 39, 4),
('TUN', 'Mortadha Ben Ouanes', 'MF', 31, 'Kasımpaşa', 17, 0),
('TUN', 'Ismaël Gharbi', 'MF', 22, 'FC Augsburg', 15, 2),
('TUN', 'Hadj Mahmoud', 'MF', 26, 'FC Lugano', 7, 0),
('TUN', 'Rani Khedira', 'MF', 32, 'Union Berlin', 2, 0),
('TUN', 'Elias Achouri', 'FW', 27, 'Copenhagen', 29, 4),
('TUN', 'Firas Chaouat', 'FW', 30, 'Club Africain', 28, 6),
('TUN', 'Hazem Mastouri', 'FW', 28, 'Dynamo Makhachkala', 18, 4),
('TUN', 'Elias Saad', 'FW', 26, 'Hannover 96', 14, 4),
('TUN', 'Sebastian Tounekti', 'FW', 23, 'Celtic FC', 10, 1),
('TUN', 'Khalil Ayari', 'FW', 21, 'Paris Saint-Germain', 2, 0),
('TUN', 'Rayan Elloumi', 'FW', 18, 'Vancouver Whitecaps FC', 2, 0);


-- worldcuppass.com squads: 11 teams
-- TUR to be added after separate fetch

-- Iran (Group G) - 26 players (worldcuppass.com)
INSERT INTO players (team_id, name, position, age, club, caps, intl_goals) VALUES
('IRN', 'Alireza Beiranvand', 'GK', 33, 'Tractor', 85, 0),
('IRN', 'Payam Niazmand', 'GK', 31, 'Persepolis', 15, 0),
('IRN', 'Hossein Hosseini', 'GK', 33, 'Sepahan', 13, 0),
('IRN', 'Ehsan Hajsafi', 'DF', 36, 'Sepahan', 145, 7),
('IRN', 'Milad Mohammadi', 'DF', 32, 'Persepolis', 75, 1),
('IRN', 'Ramin Rezaeian', 'DF', 36, 'Foolad', 73, 7),
('IRN', 'Hossein Kanaanizadegan', 'DF', 32, 'Persepolis', 64, 6),
('IRN', 'Shojae Khalilzadeh', 'DF', 37, 'Tractor', 57, 2),
('IRN', 'Saleh Hardani', 'DF', 27, 'Esteghlal', 17, 1),
('IRN', 'Ali Nemati', 'DF', 30, 'Foolad', 16, 0),
('IRN', 'Danial Eiri', 'DF', 22, 'Malavan', 0, 0),
('IRN', 'Alireza Jahanbakhsh', 'MF', 32, 'Dender', 98, 17),
('IRN', 'Saeid Ezatolahi', 'MF', 29, 'Shabab Al-Ahli', 82, 1),
('IRN', 'Saman Ghoddos', 'MF', 32, 'Ittihad Kalba', 67, 3),
('IRN', 'Mehdi Torabi', 'MF', 31, 'Tractor', 52, 7),
('IRN', 'Rouzbeh Cheshmi', 'MF', 32, 'Esteghlal', 40, 3),
('IRN', 'Mohammad Mohebi', 'MF', 27, 'Rostov', 36, 14),
('IRN', 'Mehdi Ghayedi', 'MF', 27, 'Al-Nassr', 29, 10),
('IRN', 'Mohammad Ghorbani', 'MF', 25, 'Al Wahda', 15, 0),
('IRN', 'Aria Yousefi', 'MF', 24, 'Sepahan', 13, 1),
('IRN', 'Amirmohammad Razzaghinia', 'MF', 20, 'Esteghlal', 3, 0),
('IRN', 'Mehdi Taremi', 'FW', 33, 'Olympiacos', 104, 60),
('IRN', 'Shahriyar Moghanlou', 'FW', 31, 'Ittihad Kalba', 20, 2),
('IRN', 'Amirhossein Hosseinzadeh', 'FW', 25, 'Tractor', 17, 5),
('IRN', 'Ali Alipour', 'FW', 30, 'Persepolis', 13, 1),
('IRN', 'Dennis Dargahi', 'FW', 29, 'Standard Liège', 0, 0);

-- New Zealand (Group G) - 26 players (worldcuppass.com)
INSERT INTO players (team_id, name, position, age, club, caps, intl_goals) VALUES
('NZL', 'Max Crocombe', 'GK', 33, 'Millwall', 22, 0),
('NZL', 'Alex Paulsen', 'GK', 23, 'Lechia Gdansk', 6, 0),
('NZL', 'Michael Woud', 'GK', 27, 'Auckland FC', 6, 0),
('NZL', 'Tim Payne', 'DF', 31, 'Wellington Phoenix', 50, 3),
('NZL', 'Francis De Vries', 'DF', 33, 'Auckland FC', 18, 1),
('NZL', 'Tyler Bindon', 'DF', 21, 'Nottingham Forest FC', 23, 3),
('NZL', 'Michael Boxall', 'DF', 37, 'Minnesota United FC', 61, 1),
('NZL', 'Liberato Cacace', 'DF', 25, 'Wrexham AFC', 35, 1),
('NZL', 'Nando Pijnaker', 'DF', 26, 'Auckland FC', 23, 0),
('NZL', 'Finn Surman', 'DF', 23, 'Portland Timbers', 17, 2),
('NZL', 'Callan Elliot', 'DF', 26, 'Auckland FC', 9, 0),
('NZL', 'Tommy Smith', 'DF', 36, 'Braintree Town', 56, 2),
('NZL', 'Lachlan Bayliss', 'MF', 23, 'Newcastle Jets', 2, 0),
('NZL', 'Joe Bell', 'MF', 27, 'Viking FK', 31, 1),
('NZL', 'Matt Garbett', 'MF', 24, 'Peterborough United', 36, 5),
('NZL', 'Ben Old', 'MF', 23, 'AS Saint-Etienne', 22, 2),
('NZL', 'Alex Rufer', 'MF', 29, 'Wellington Phoenix', 24, 0),
('NZL', 'Sarpreet Singh', 'MF', 27, 'Wellington Phoenix', 26, 3),
('NZL', 'Marko Stamenic', 'MF', 24, 'Swansea City AFC', 37, 3),
('NZL', 'Ryan Thomas', 'MF', 31, 'PEC Zwolle', 25, 3),
('NZL', 'Kosta Barbarouses', 'FW', 36, 'Western Sydney Wanderers', 74, 10),
('NZL', 'Eli Just', 'FW', 25, 'Motherwell', 42, 9),
('NZL', 'Callum McCowatt', 'FW', 26, 'Silkeborg', 30, 4),
('NZL', 'Jesse Randall', 'FW', 25, 'Auckland FC', 9, 2),
('NZL', 'Ben Waine', 'FW', 24, 'Port Vale', 30, 9),
('NZL', 'Chris Wood', 'FW', 34, 'Nottingham Forest FC', 88, 45);

-- Saudi Arabia (Group H) - 26 players (worldcuppass.com)
INSERT INTO players (team_id, name, position, age, club, caps, intl_goals) VALUES
('KSA', 'Mohammed Al Owais', 'GK', 34, 'Al Ula', 0, 0),
('KSA', 'Nawaf Al Aqidi', 'GK', 26, 'Al-Nassr', 0, 0),
('KSA', 'Ahmed Al Kassar', 'GK', 35, 'Al-Qadsiah', 0, 0),
('KSA', 'Abdulelah Al Amri', 'DF', 29, 'Al-Nassr', 0, 0),
('KSA', 'Hassan Tambakti', 'DF', 27, 'Al-Hilal', 0, 0),
('KSA', 'Jehad Thikri', 'DF', 24, 'Al-Qadsiah', 0, 0),
('KSA', 'Ali Lajami', 'DF', 30, 'Al-Hilal', 0, 0),
('KSA', 'Hassan Kadesh', 'DF', 33, 'Al Ittihad', 0, 0),
('KSA', 'Saud Abdulhamid', 'DF', 26, 'RC Lens', 0, 0),
('KSA', 'Mohammed Abu Al Shamat', 'DF', 23, 'Al-Qadsiah', 0, 0),
('KSA', 'Ali Majrashi', 'DF', 26, 'Al Ahli', 0, 0),
('KSA', 'Moteb Al Harbi', 'DF', 26, 'Al-Hilal', 0, 0),
('KSA', 'Nawaf Boushal', 'DF', 26, 'Al-Nassr', 0, 0),
('KSA', 'Mohammed Kanno', 'MF', 31, 'Al-Hilal', 0, 0),
('KSA', 'Abdullah Al Khaibari', 'MF', 29, 'Al-Nassr', 0, 0),
('KSA', 'Ziyad Al Johani', 'MF', 24, 'Al Ahli', 0, 0),
('KSA', 'Nasser Al Dawsari', 'MF', 27, 'Al-Hilal', 0, 0),
('KSA', 'Musab Al Juwayr', 'MF', 22, 'Al-Qadsiah', 0, 0),
('KSA', 'Sultan Mandash', 'MF', 31, 'Al-Hilal', 0, 0),
('KSA', 'Alaa Al Hajji', 'MF', 30, 'Neom SC', 0, 0),
('KSA', 'Salem Al-Dawsari', 'FW', 34, 'Al-Hilal', 0, 0),
('KSA', 'Firas Al-Buraikan', 'FW', 26, 'Al Ahli', 0, 0),
('KSA', 'Saleh Al Shehri', 'FW', 32, 'Al Ittihad', 0, 0),
('KSA', 'Abdullah Al Hamdan', 'FW', 26, 'Al-Nassr', 0, 0),
('KSA', 'Khalid Al Ghannam', 'FW', 25, 'Al-Ettifaq', 0, 0),
('KSA', 'Ayman Yahya', 'FW', 25, 'Al-Nassr', 0, 0);

-- Uruguay (Group H) - 26 players (worldcuppass.com)
INSERT INTO players (team_id, name, position, age, club, caps, intl_goals) VALUES
('URU', 'Sergio Rochet', 'GK', 33, 'SC Internacional', 0, 0),
('URU', 'Fernando Muslera', 'GK', 39, 'Estudiantes', 0, 0),
('URU', 'Santiago Mele', 'GK', 28, 'Monterrey', 0, 0),
('URU', 'Guillermo Varela', 'DF', 33, 'CR Flamengo', 0, 0),
('URU', 'Ronald Araujo', 'DF', 27, 'FC Barcelona', 0, 0),
('URU', 'Jose Maria Gimenez', 'DF', 31, 'Atlético Madrid', 0, 0),
('URU', 'Santiago Bueno', 'DF', 27, 'Wolverhampton Wanderers FC', 0, 0),
('URU', 'Sebastian Caceres', 'DF', 26, 'Club America', 0, 0),
('URU', 'Mathias Olivera', 'DF', 28, 'SSC Napoli', 0, 0),
('URU', 'Matias Vina', 'DF', 28, 'River Plate', 0, 0),
('URU', 'Joaquin Piquerez', 'DF', 27, 'SE Palmeiras', 0, 0),
('URU', 'Manuel Ugarte', 'MF', 24, 'Manchester United FC', 0, 0),
('URU', 'Emiliano Martinez', 'MF', 26, 'SE Palmeiras', 0, 0),
('URU', 'Rodrigo Bentancur', 'MF', 28, 'Tottenham Hotspur FC', 0, 0),
('URU', 'Federico Valverde', 'MF', 27, 'Real Madrid', 0, 0),
('URU', 'Agustin Canobbio', 'MF', 26, 'Fluminense', 0, 0),
('URU', 'Juan Manuel Sanabria', 'MF', 26, 'Real Salt Lake', 0, 0),
('URU', 'Giorgian de Arrascaeta', 'MF', 32, 'CR Flamengo', 0, 0),
('URU', 'Nicolas de la Cruz', 'MF', 29, 'CR Flamengo', 0, 0),
('URU', 'Rodrigo Zalazar', 'MF', 26, 'SC Braga', 0, 0),
('URU', 'Facundo Pellistri', 'MF', 24, 'Panathinaikos FC', 0, 0),
('URU', 'Maximiliano Araujo', 'MF', 26, 'Sporting CP', 0, 0),
('URU', 'Brian Rodriguez', 'MF', 25, 'Club America', 0, 0),
('URU', 'Rodrigo Aguirre', 'FW', 31, 'Tigres UANL', 0, 0),
('URU', 'Federico Vinas', 'FW', 27, 'Real Oviedo', 0, 0),
('URU', 'Darwin Nunez', 'FW', 26, 'Al-Hilal', 0, 0);

-- Senegal (Group I) - 26 players (worldcuppass.com)
INSERT INTO players (team_id, name, position, age, club, caps, intl_goals) VALUES
('SEN', 'Edouard Mendy', 'GK', 34, 'Al Ahli', 56, 0),
('SEN', 'Mory Diaw', 'GK', 32, 'Le Havre AC', 5, 0),
('SEN', 'Yehvann Diouf', 'GK', 26, 'Nice', 2, 0),
('SEN', 'Kalidou Koulibaly', 'DF', 34, 'Al-Hilal', 102, 2),
('SEN', 'Krepin Diatta', 'DF', 27, 'AS Monaco', 60, 2),
('SEN', 'Moussa Niakhate', 'DF', 30, 'Olympique Lyonnais', 30, 0),
('SEN', 'Ismail Jakobs', 'DF', 26, 'Galatasaray SK', 29, 0),
('SEN', 'Abdoulaye Seck', 'DF', 34, 'Maccabi Haifa FC', 22, 4),
('SEN', 'El Hadji Malick Diouf', 'DF', 21, 'West Ham United FC', 19, 1),
('SEN', 'Mamadou Sarr', 'DF', 20, 'Chelsea FC', 7, 0),
('SEN', 'Antoine Mendy', 'DF', 22, 'Nice', 6, 0),
('SEN', 'Idrissa Gana Gueye', 'MF', 36, 'Everton FC', 130, 7),
('SEN', 'Pape Gueye', 'MF', 27, 'Villarreal CF', 41, 5),
('SEN', 'Pape Matar Sarr', 'MF', 23, 'Tottenham Hotspur FC', 39, 4),
('SEN', 'Lamine Camara', 'MF', 22, 'AS Monaco', 32, 7),
('SEN', 'Pathe Ciss', 'MF', 32, 'Rayo Vallecano', 29, 0),
('SEN', 'Habib Diarra', 'MF', 22, 'Sunderland AFC', 20, 4),
('SEN', 'Bara Ndiaye', 'MF', 18, 'FC Bayern München', 1, 0),
('SEN', 'Sadio Mane', 'FW', 34, 'Al-Nassr', 127, 55),
('SEN', 'Ismaila Sarr', 'FW', 28, 'Crystal Palace FC', 82, 19),
('SEN', 'Iliman Ndiaye', 'FW', 26, 'Everton FC', 39, 4),
('SEN', 'Nicolas Jackson', 'FW', 24, 'FC Bayern München', 32, 8),
('SEN', 'Bamba Dieng', 'FW', 26, 'Lorient', 22, 2),
('SEN', 'Cherif Ndiaye', 'FW', 30, 'Samsunspor', 18, 4),
('SEN', 'Ibrahim Mbaye', 'FW', 18, 'Paris Saint-Germain', 10, 3),
('SEN', 'Assane Diao', 'FW', 20, 'Como', 5, 0);

-- Iraq (Group I) - 26 players (worldcuppass.com)
INSERT INTO players (team_id, name, position, age, club, caps, intl_goals) VALUES
('IRQ', 'Fahad Talib', 'GK', 31, 'Al-Talaba', 0, 0),
('IRQ', 'Jalal Hassan', 'GK', 35, 'Al-Zawraa', 0, 0),
('IRQ', 'Ahmed Basil', 'GK', 29, 'Al-Shorta', 0, 0),
('IRQ', 'Hussein Ali', 'DF', 24, 'Pogon Szczecin', 0, 0),
('IRQ', 'Manaf Younis', 'DF', 29, 'Al-Shorta', 0, 0),
('IRQ', 'Zaid Tahseen', 'DF', 25, 'Pakhtakor', 0, 0),
('IRQ', 'Rebin Sulaka', 'DF', 33, 'Port FC', 0, 0),
('IRQ', 'Akam Hashem', 'DF', 27, 'Al-Zawraa', 0, 0),
('IRQ', 'Merchas Doski', 'DF', 26, 'FC Viktoria Plzeň', 0, 0),
('IRQ', 'Ahmed Yahya', 'DF', 30, 'Al-Shorta', 0, 0),
('IRQ', 'Zaid Ismail', 'DF', 24, 'Al-Talaba', 0, 0),
('IRQ', 'Frans Putros', 'DF', 32, 'Persib', 0, 0),
('IRQ', 'Mustafa Saadoon', 'DF', 25, 'Al-Shorta', 0, 0),
('IRQ', 'Amir Al-Ammari', 'MF', 28, 'Cracovia', 0, 0),
('IRQ', 'Kevin Yakob', 'MF', 25, 'AGF', 0, 0),
('IRQ', 'Zidane Iqbal', 'MF', 22, 'Utrecht', 0, 0),
('IRQ', 'Aimar Sher', 'MF', 23, 'Sarpsborg 08', 0, 0),
('IRQ', 'Ibrahim Bayesh', 'MF', 25, 'Al-Dhafra', 0, 0),
('IRQ', 'Ahmed Qasim', 'MF', 22, 'Nashville SC', 0, 0),
('IRQ', 'Youssef Amyn', 'MF', 22, 'AEK Larnaca', 0, 0),
('IRQ', 'Marko Farji', 'MF', 22, 'Venezia FC', 0, 0),
('IRQ', 'Ali Jassim', 'FW', 22, 'Al-Najma', 0, 0),
('IRQ', 'Ali Al-Hamadi', 'FW', 24, 'Luton Town', 0, 0),
('IRQ', 'Ali Yousef', 'FW', 30, 'Al-Talaba', 0, 0),
('IRQ', 'Aymen Hussein', 'FW', 30, 'Al-Karma', 0, 0),
('IRQ', 'Mohanad Ali', 'FW', 25, 'Dibba Al-Fujairah', 0, 0);

-- Norway (Group I) - 26 players (worldcuppass.com)
INSERT INTO players (team_id, name, position, age, club, caps, intl_goals) VALUES
('NOR', 'Orjan Nyland', 'GK', 35, 'Sevilla', 0, 0),
('NOR', 'Egil Selvik', 'GK', 28, 'Watford FC', 0, 0),
('NOR', 'Sander Tangvik', 'GK', 23, 'Hamburger SV', 0, 0),
('NOR', 'Kristoffer Ajer', 'DF', 28, 'Brentford FC', 0, 0),
('NOR', 'Julian Ryerson', 'DF', 28, 'Borussia Dortmund', 0, 0),
('NOR', 'Leo Ostigard', 'DF', 26, 'Genoa', 0, 0),
('NOR', 'Marcus Holmgren Pedersen', 'DF', 27, 'Torino FC', 0, 0),
('NOR', 'David Moller Wolfe', 'DF', 25, 'Wolverhampton Wanderers FC', 0, 0),
('NOR', 'Fredrik Bjorkan', 'DF', 26, 'Bodo/Glimt', 0, 0),
('NOR', 'Torbjorn Heggem', 'DF', 27, 'Bologna FC', 0, 0),
('NOR', 'Sondre Langas', 'DF', 25, 'Derby County', 0, 0),
('NOR', 'Henrik Falchener', 'DF', 23, 'Viking FK', 0, 0),
('NOR', 'Martin Odegaard', 'MF', 27, 'Arsenal FC', 0, 0),
('NOR', 'Sander Berge', 'MF', 28, 'Fulham FC', 0, 0),
('NOR', 'Patrick Berg', 'MF', 28, 'Bodo/Glimt', 0, 0),
('NOR', 'Kristian Thorstvedt', 'MF', 27, 'US Sassuolo', 0, 0),
('NOR', 'Morten Thorsby', 'MF', 30, 'Cremonese', 0, 0),
('NOR', 'Antonio Nusa', 'MF', 21, 'RB Leipzig', 0, 0),
('NOR', 'Fredrik Aursnes', 'MF', 30, 'Benfica', 0, 0),
('NOR', 'Oscar Bobb', 'MF', 22, 'Fulham FC', 0, 0),
('NOR', 'Jens Petter Hauge', 'MF', 27, 'Bodo/Glimt', 0, 0),
('NOR', 'Andreas Schjelderup', 'MF', 22, 'Benfica', 0, 0),
('NOR', 'Thelo Aasgaard', 'MF', 23, 'Rangers FC', 0, 0),
('NOR', 'Alexander Sorloth', 'FW', 30, 'Atlético Madrid', 0, 0),
('NOR', 'Erling Haaland', 'FW', 25, 'Manchester City FC', 0, 0),
('NOR', 'Jorgen Strand Larsen', 'FW', 26, 'Crystal Palace FC', 0, 0);

-- Jordan (Group J) - 26 players (worldcuppass.com)
INSERT INTO players (team_id, name, position, age, club, caps, intl_goals) VALUES
('JOR', 'Yazeed Abulaila', 'GK', 33, 'Al-Hussein', 74, 0),
('JOR', 'Nour Bani Attiah', 'GK', 33, 'Al-Faisaly', 4, 0),
('JOR', 'Abdallah Al-Fakhouri', 'GK', 26, 'Al-Wehdat', 11, 0),
('JOR', 'Mohammad Abu Hashish', 'DF', 31, 'Al-Karma', 54, 1),
('JOR', 'Abdallah Nasib', 'DF', 32, 'Al-Zawraa', 64, 3),
('JOR', 'Husam Abu Dahab', 'DF', 26, 'Al-Faisaly', 16, 0),
('JOR', 'Yazan Al-Arab', 'DF', 30, 'FC Seoul', 78, 3),
('JOR', 'Mohammad Abualnadi', 'DF', 25, 'Selangor', 16, 0),
('JOR', 'Salim Obaid', 'DF', 34, 'Al-Hussein', 9, 0),
('JOR', 'Saed Al-Rosan', 'DF', 29, 'Al-Hussein', 19, 2),
('JOR', 'Ihsan Haddad', 'DF', 32, 'Al-Hussein', 90, 2),
('JOR', 'Anas Badawi', 'DF', 28, 'Al-Faisaly', 0, 0),
('JOR', 'Mohannad Abu Taha', 'DF', 23, 'Al-Quwa Al-Jawiya', 27, 1),
('JOR', 'Noor Al-Rawabdeh', 'MF', 29, 'Selangor', 66, 3),
('JOR', 'Nizar Al-Rashdan', 'MF', 27, 'Qatar SC', 45, 4),
('JOR', 'Ibrahim Sadeh', 'MF', 26, 'Al-Karma', 55, 3),
('JOR', 'Rajaei Ayed', 'MF', 32, 'Al-Hussein', 72, 0),
('JOR', 'Amer Jamous', 'MF', 23, 'Al-Zawraa', 18, 1),
('JOR', 'Mohammad Al-Dawoud', 'MF', 33, 'Al-Wehdat', 11, 1),
('JOR', 'Mahmoud Al-Mardi', 'FW', 32, 'Al-Hussein', 87, 9),
('JOR', 'Odeh Al-Fakhouri', 'FW', 20, 'Pyramids FC', 8, 0),
('JOR', 'Musa Al-Tamari', 'FW', 29, 'Rennes', 90, 24),
('JOR', 'Mohammad Abu Zrayq', 'FW', 28, 'Raja Casablanca', 39, 5),
('JOR', 'Ali Azaizeh', 'FW', 22, 'Al-Shabab', 2, 0),
('JOR', 'Ibrahim Sabra', 'FW', 20, 'Lokomotiva Zagreb', 9, 1),
('JOR', 'Ali Olwan', 'FW', 26, 'Al-Sailiya', 64, 29);

-- Portugal (Group K) - 26 players (worldcuppass.com)
INSERT INTO players (team_id, name, position, age, club, caps, intl_goals) VALUES
('POR', 'Diogo Costa', 'GK', 26, 'FC Porto', 0, 0),
('POR', 'Jose Sa', 'GK', 33, 'Wolverhampton Wanderers FC', 0, 0),
('POR', 'Rui Silva', 'GK', 32, 'Sporting CP', 0, 0),
('POR', 'Ruben Dias', 'DF', 29, 'Manchester City FC', 0, 0),
('POR', 'Joao Cancelo', 'DF', 32, 'FC Barcelona', 0, 0),
('POR', 'Nelson Semedo', 'DF', 32, 'Fenerbahçe', 0, 0),
('POR', 'Nuno Mendes', 'DF', 23, 'Paris Saint-Germain', 0, 0),
('POR', 'Diogo Dalot', 'DF', 27, 'Manchester United FC', 0, 0),
('POR', 'Goncalo Inacio', 'DF', 24, 'Sporting CP', 0, 0),
('POR', 'Renato Veiga', 'DF', 22, 'Villarreal CF', 0, 0),
('POR', 'Tomas Araujo', 'DF', 24, 'Benfica', 0, 0),
('POR', 'Bernardo Silva', 'MF', 31, 'Manchester City FC', 0, 0),
('POR', 'Bruno Fernandes', 'MF', 31, 'Manchester United FC', 0, 0),
('POR', 'Ruben Neves', 'MF', 29, 'Al-Hilal', 0, 0),
('POR', 'Vitinha', 'MF', 26, 'Paris Saint-Germain', 0, 0),
('POR', 'Joao Neves', 'MF', 21, 'Paris Saint-Germain', 0, 0),
('POR', 'Matheus Nunes', 'MF', 27, 'Manchester City FC', 0, 0),
('POR', 'Samu Costa', 'MF', 25, 'RCD Mallorca', 0, 0),
('POR', 'Cristiano Ronaldo', 'FW', 41, 'Al-Nassr', 0, 0),
('POR', 'Francisco Trincao', 'FW', 26, 'Sporting CP', 0, 0),
('POR', 'Joao Felix', 'FW', 26, 'Al-Nassr', 0, 0),
('POR', 'Rafael Leao', 'FW', 27, 'AC Milan', 0, 0),
('POR', 'Goncalo Guedes', 'FW', 29, 'Real Sociedad', 0, 0),
('POR', 'Goncalo Ramos', 'FW', 24, 'Paris Saint-Germain', 0, 0),
('POR', 'Pedro Neto', 'FW', 26, 'Chelsea FC', 0, 0),
('POR', 'Francisco Conceicao', 'FW', 23, 'Juventus FC', 0, 0);

-- Uzbekistan (Group K) - 26 players (worldcuppass.com)
INSERT INTO players (team_id, name, position, age, club, caps, intl_goals) VALUES
('UZB', 'Utkir Yusupov', 'GK', 35, 'Navbahor', 39, 0),
('UZB', 'Abduvohid Nematov', 'GK', 25, 'Nasaf', 13, 0),
('UZB', 'Botirali Ergashev', 'GK', 30, 'Neftchi', 3, 0),
('UZB', 'Abdukodir Khusanov', 'DF', 22, 'Manchester City FC', 25, 0),
('UZB', 'Khojiakbar Alijonov', 'DF', 29, 'Pakhtakor', 51, 3),
('UZB', 'Farrukh Sayfiev', 'DF', 35, 'Neftchi', 64, 1),
('UZB', 'Rustam Ashurmatov', 'DF', 29, 'Esteghlal', 47, 1),
('UZB', 'Umar Eshmurodov', 'DF', 33, 'Nasaf', 39, 0),
('UZB', 'Sherzod Nasrullaev', 'DF', 27, 'Pakhtakor', 35, 2),
('UZB', 'Abdulla Abdullaev', 'DF', 28, 'Dibba', 27, 0),
('UZB', 'Avazbek Ulmasaliev', 'DF', 26, 'AGMK', 0, 0),
('UZB', 'Jakhongir Urozov', 'DF', 22, 'Dinamo Tashkent', 2, 1),
('UZB', 'Behruz Karimov', 'DF', 18, 'Surkhon', 2, 0),
('UZB', 'Akmal Mozgovoy', 'MF', 26, 'Pakhtakor', 23, 1),
('UZB', 'Otabek Shukurov', 'MF', 29, 'Baniyas', 86, 9),
('UZB', 'Jamshid Iskanderov', 'MF', 32, 'Neftchi', 42, 4),
('UZB', 'Odiljon Hamrobekov', 'MF', 30, 'Tractor', 71, 1),
('UZB', 'Jaloliddin Masharipov', 'MF', 32, 'Esteghlal', 73, 12),
('UZB', 'Oston Urunov', 'MF', 25, 'Persepolis', 42, 10),
('UZB', 'Dostonbek Khamdamov', 'MF', 29, 'Pakhtakor', 35, 5),
('UZB', 'Azizjon Ganiev', 'MF', 28, 'Al Bataeh', 22, 0),
('UZB', 'Abbosbek Fayzullayev', 'MF', 22, 'Başakşehir FK', 30, 8),
('UZB', 'Sherzod Esanov', 'MF', 23, 'Bukhara', 0, 0),
('UZB', 'Eldor Shomurodov', 'FW', 30, 'Başakşehir FK', 90, 44),
('UZB', 'Igor Sergeev', 'FW', 33, 'Persepolis', 81, 24),
('UZB', 'Azizbek Amonov', 'FW', 28, 'Dinamo Tashkent', 11, 2);

-- Panama (Group L) - 26 players (worldcuppass.com)
INSERT INTO players (team_id, name, position, age, club, caps, intl_goals) VALUES
('PAN', 'Luis Mejia', 'GK', 35, 'Nacional', 0, 0),
('PAN', 'Orlando Mosquera', 'GK', 31, 'Al-Fayha', 0, 0),
('PAN', 'Cesar Samudio', 'GK', 32, 'Marathon', 0, 0),
('PAN', 'Amir Murillo', 'DF', 30, 'Beşiktaş JK', 0, 0),
('PAN', 'Jose Cordoba', 'DF', 25, 'Norwich City FC', 0, 0),
('PAN', 'Cesar Blackman', 'DF', 28, 'Slovan Bratislava', 0, 0),
('PAN', 'Andres Andrade', 'DF', 27, 'LASK Linz', 0, 0),
('PAN', 'Eric Davis', 'DF', 35, 'Plaza Amador', 0, 0),
('PAN', 'Roderick Miller', 'DF', 34, 'Turan Tovuz', 0, 0),
('PAN', 'Jiovany Ramos', 'DF', 29, 'Puerto Cabello', 0, 0),
('PAN', 'Jorge Gutierrez', 'DF', 27, 'Deportivo La Guaira', 0, 0),
('PAN', 'Fidel Escobar', 'DF', 31, 'Saprissa', 0, 0),
('PAN', 'Edgardo Farina', 'DF', 24, 'Pari Nizhny Novgorod', 0, 0),
('PAN', 'Anibal Godoy', 'MF', 36, 'San Diego FC', 0, 0),
('PAN', 'Adalberto Carrasquilla', 'MF', 27, 'UNAM', 0, 0),
('PAN', 'Cristian Martinez', 'MF', 29, 'Ironi Kiryat Shmona', 0, 0),
('PAN', 'Carlos Harvey', 'MF', 26, 'Minnesota United FC', 0, 0),
('PAN', 'Jose Luis Rodriguez', 'MF', 27, 'Juarez', 0, 0),
('PAN', 'Cesar Yanis', 'MF', 30, 'Cobresal', 0, 0),
('PAN', 'Yoel Barcenas', 'MF', 32, 'Unattached', 0, 0),
('PAN', 'Alberto Quintero', 'MF', 38, 'Plaza Amador', 0, 0),
('PAN', 'Azarias Londono', 'MF', 24, 'Universidad Catolica', 0, 0),
('PAN', 'Ismael Diaz', 'FW', 29, 'Leon', 0, 0),
('PAN', 'Jose Fajardo', 'FW', 32, 'Universidad Catolica', 0, 0),
('PAN', 'Tomas Rodriguez', 'FW', 27, 'Saprissa', 0, 0),
('PAN', 'Cecilio Waterman', 'FW', 35, 'Universidad de Concepcion', 0, 0);


-- Turkey (Group D) - 26 players (worldcuppass.com)
INSERT INTO players (team_id, name, position, age, club, caps, intl_goals) VALUES
('TUR', 'Ugurcan Cakir', 'GK', 30, 'Galatasaray SK', 0, 0),
('TUR', 'Mert Gunok', 'GK', 37, 'Beşiktaş JK', 0, 0),
('TUR', 'Altay Bayindir', 'GK', 28, 'Manchester United FC', 0, 0),
('TUR', 'Zeki Celik', 'DF', 29, 'AS Roma', 0, 0),
('TUR', 'Merih Demiral', 'DF', 28, 'Al Ahli', 0, 0),
('TUR', 'Caglar Soyuncu', 'DF', 30, 'Fenerbahçe', 0, 0),
('TUR', 'Ozan Kabak', 'DF', 26, 'TSG Hoffenheim', 0, 0),
('TUR', 'Abdulkerim Bardakci', 'DF', 31, 'Galatasaray SK', 0, 0),
('TUR', 'Mert Muldur', 'DF', 27, 'Fenerbahçe', 0, 0),
('TUR', 'Ferdi Kadioglu', 'DF', 26, 'Brighton & Hove Albion FC', 0, 0),
('TUR', 'Eren Elmali', 'DF', 25, 'Galatasaray SK', 0, 0),
('TUR', 'Samet Akaydin', 'DF', 32, 'Çaykur Rizespor', 0, 0),
('TUR', 'Hakan Calhanoglu', 'MF', 32, 'Inter Milan', 0, 0),
('TUR', 'Kaan Ayhan', 'MF', 31, 'Galatasaray SK', 0, 0),
('TUR', 'Salih Ozcan', 'MF', 28, 'Borussia Dortmund', 0, 0),
('TUR', 'Ismail Yuksek', 'MF', 27, 'Fenerbahçe', 0, 0),
('TUR', 'Orkun Kokcu', 'MF', 25, 'Beşiktaş JK', 0, 0),
('TUR', 'Arda Guler', 'FW', 21, 'Real Madrid', 0, 0),
('TUR', 'Kenan Yildiz', 'FW', 21, 'Juventus FC', 0, 0),
('TUR', 'Kerem Akturkoglu', 'FW', 27, 'Fenerbahçe', 0, 0),
('TUR', 'Baris Alper Yilmaz', 'FW', 26, 'Galatasaray SK', 0, 0),
('TUR', 'Irfan Can Kahveci', 'FW', 30, 'Fenerbahçe', 0, 0),
('TUR', 'Yunus Akgun', 'FW', 25, 'Galatasaray SK', 0, 0),
('TUR', 'Oguz Aydin', 'FW', 25, 'Fenerbahçe', 0, 0),
('TUR', 'Can Uzun', 'FW', 20, 'Eintracht Frankfurt', 0, 0),
('TUR', 'Deniz Gul', 'FW', 21, 'FC Porto', 0, 0);


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
(73,  73,  NULL, NULL, NULL, NULL, 'r32', NULL, NULL, NULL, NULL),
(74,  74,  NULL, NULL, NULL, NULL, 'r32', NULL, NULL, NULL, NULL),
(75,  75,  NULL, NULL, NULL, NULL, 'r32', NULL, NULL, NULL, NULL),
(76,  76,  NULL, NULL, NULL, NULL, 'r32', NULL, NULL, NULL, NULL),
(77,  77,  NULL, NULL, NULL, NULL, 'r32', NULL, NULL, NULL, NULL),
(78,  78,  NULL, NULL, NULL, NULL, 'r32', NULL, NULL, NULL, NULL),
(79,  79,  NULL, NULL, NULL, NULL, 'r32', NULL, NULL, NULL, NULL),
(80,  80,  NULL, NULL, NULL, NULL, 'r32', NULL, NULL, NULL, NULL),
(81,  81,  NULL, NULL, NULL, NULL, 'r32', NULL, NULL, NULL, NULL),
(82,  82,  NULL, NULL, NULL, NULL, 'r32', NULL, NULL, NULL, NULL),
(83,  83,  NULL, NULL, NULL, NULL, 'r32', NULL, NULL, NULL, NULL),
(84,  84,  NULL, NULL, NULL, NULL, 'r32', NULL, NULL, NULL, NULL),
(85,  85,  NULL, NULL, NULL, NULL, 'r32', NULL, NULL, NULL, NULL),
(86,  86,  NULL, NULL, NULL, NULL, 'r32', NULL, NULL, NULL, NULL),
(87,  87,  NULL, NULL, NULL, NULL, 'r32', NULL, NULL, NULL, NULL),
(88,  88,  NULL, NULL, NULL, NULL, 'r32', NULL, NULL, NULL, NULL);

-- ROUND OF 16 (Jul 4–7)
-- 89: W74 vs W77 | 90: W73 vs W75 | 91: W76 vs W78 | 92: W79 vs W80
-- 93: W83 vs W84 | 94: W81 vs W82 | 95: W86 vs W88 | 96: W85 vs W87
INSERT INTO matches (match_id, fifa_match_no, team_home, team_away, goals_home, goals_away, stage, group_name, match_date, stadium, city) VALUES
(89,  89,  NULL, NULL, NULL, NULL, 'r16', NULL, NULL, NULL, NULL),
(90,  90,  NULL, NULL, NULL, NULL, 'r16', NULL, NULL, NULL, NULL),
(91,  91,  NULL, NULL, NULL, NULL, 'r16', NULL, NULL, NULL, NULL),
(92,  92,  NULL, NULL, NULL, NULL, 'r16', NULL, NULL, NULL, NULL),
(93,  93,  NULL, NULL, NULL, NULL, 'r16', NULL, NULL, NULL, NULL),
(94,  94,  NULL, NULL, NULL, NULL, 'r16', NULL, NULL, NULL, NULL),
(95,  95,  NULL, NULL, NULL, NULL, 'r16', NULL, NULL, NULL, NULL),
(96,  96,  NULL, NULL, NULL, NULL, 'r16', NULL, NULL, NULL, NULL);

-- QUARTERFINALS (Jul 9–11)
-- 97: W89 vs W90 | 98: W91 vs W92 | 99: W93 vs W94 | 100: W95 vs W96
INSERT INTO matches (match_id, fifa_match_no, team_home, team_away, goals_home, goals_away, stage, group_name, match_date, stadium, city) VALUES
(97,  97,  NULL, NULL, NULL, NULL, 'qf', NULL, NULL, NULL, NULL),
(98,  98,  NULL, NULL, NULL, NULL, 'qf', NULL, NULL, NULL, NULL),
(99,  99,  NULL, NULL, NULL, NULL, 'qf', NULL, NULL, NULL, NULL),
(100, 100, NULL, NULL, NULL, NULL, 'qf', NULL, NULL, NULL, NULL);

-- SEMIFINALS (Jul 14–15)
-- 101: W97 vs W98 | 102: W99 vs W100
INSERT INTO matches (match_id, fifa_match_no, team_home, team_away, goals_home, goals_away, stage, group_name, match_date, stadium, city) VALUES
(101, 101, NULL, NULL, NULL, NULL, 'sf', NULL, NULL, NULL, NULL),
(102, 102, NULL, NULL, NULL, NULL, 'sf', NULL, NULL, NULL, NULL);

-- THIRD PLACE (Jul 18)
INSERT INTO matches (match_id, fifa_match_no, team_home, team_away, goals_home, goals_away, stage, group_name, match_date, stadium, city) VALUES
(103, 103, NULL, NULL, NULL, NULL, 'third_place', NULL, '2026-07-18', NULL, NULL);

-- FINAL (Jul 19 — MetLife Stadium confirmed)
INSERT INTO matches (match_id, fifa_match_no, team_home, team_away, goals_home, goals_away, stage, group_name, match_date, stadium, city) VALUES
(104, 104, NULL, NULL, NULL, NULL, 'final', NULL, '2026-07-19', 'MetLife Stadium', 'New York/New Jersey');

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

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    