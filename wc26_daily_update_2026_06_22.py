"""
WC26 Daily Update — 2026-06-22
Updates goals, corners, possession, attendance, referee
for all 36 played matches (June 11–20) with NULL goals.
Source: FBref match report pages (verified via Claude-in-Chrome).
"""

import sqlite3
import os
import logging

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s %(levelname)s %(message)s'
)

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE_DIR, 'worldcup26.db')
SQL_PATH = os.path.join(BASE_DIR, 'worldcup26_results.sql')

# Tuple order: goals_home, goals_away, corners_home, corners_away,
#              possession_home, possession_away, attendance, referee, match_id
#
# NOTE: matches where FBref home != DB home_team have been SWAPPED:
#   match_id=4  (RSA home in DB, CZE home on FBref)
#   match_id=10 (BIH home in DB, SUI home on FBref)
#   match_id=16 (MAR home in DB, SCO home on FBref)
#   match_id=22 (PAR home in DB, TUR home on FBref)
#   match_id=28 (CUW home in DB, ECU home on FBref)
#   match_id=34 (JPN home in DB, TUN home on FBref)

UPDATES = [
    # June 11
    (2, 0, 3,  1,  61.0, 40.0, 80824, 'Wilton Sampaio',                    1),   # MEX-RSA
    (2, 1, 4,  5,  62.0, 38.0, 44985, 'Amin Omar',                          2),   # KOR-CZE
    # June 12
    (1, 1, 9,  4,  61.0, 39.0, 43002, 'Facundo Tello',                      7),   # CAN-BIH
    (4, 1, 3,  1,  65.0, 35.0, 70492, 'Danny Makkelie',                    19),   # USA-PAR
    # June 13
    (1, 1, 3, 10,  32.0, 68.0, 67966, 'Said Martínez',                      8),   # QAT-SUI
    (2, 0, 5,  8,  28.0, 72.0, 52497, 'Jesús Valenzuela',                  20),   # AUS-TUR
    # June 14
    (1, 1, 6,  2,  51.0, 49.0, 80663, 'Slavko Vinčič',                     13),   # BRA-MAR
    (0, 1, 4,  3,  54.0, 46.0, 64146, 'Mustapha Ghorbal',                  14),   # HAI-SCO
    # June 15
    (7, 1, 8,  1,  65.0, 35.0, 68021, 'Jalal Jiyed',                       25),   # GER-CUW
    (1, 0, 3,  5,  48.0, 52.0, 68274, 'François Letexier',                 26),   # CIV-ECU
    (2, 2, 5,  4,  60.0, 40.0, 69285, 'Ismail Elfath',                     31),   # NED-JPN
    (5, 1, 4,  2,  49.0, 51.0, 50987, 'Yael Falcón',                       32),   # SWE-TUN
    # June 16
    (1, 1, 2,  7,  54.0, 46.0, 66775, 'Ramon Abatti',                      37),   # BEL-EGY
    (0, 0, 11, 1,  74.0, 26.0, 67640, 'Adham Makhadmeh',                   43),   # ESP-CPV
    (2, 2, 4,  1,  48.0, 52.0, 70108, 'César Arturo Ramos',                38),   # IRN-NZL
    (1, 1, 4, 14,  33.0, 67.0, 62764, 'Maurizio Mariani',                  44),   # KSA-URU
    # June 17
    (3, 1, 6,  4,  54.0, 46.0, 80545, 'Alireza Faghani',                   49),   # FRA-SEN
    (1, 4, 2,  5,  39.0, 61.0, 63106, 'Pierre Ghislain Atcho',             50),   # IRQ-NOR
    (3, 0, 2,  2,  48.0, 52.0, 69045, 'Szymon Marciniak',                  55),   # ARG-ALG
    (3, 1, 4,  3,  63.0, 37.0, 68527, 'Dahane Beida',                      56),   # AUT-JOR
    (1, 1, 5,  4,  75.0, 25.0, 68777, 'Abdulrahman Ibrahim Al Jassim',     61),   # POR-COD
    (4, 2, 8,  2,  52.0, 48.0, 70389, 'Clément Turpin',                    67),   # ENG-CRO
    (1, 0, 2,  2,  38.0, 62.0, 42942, 'Glenn Nyberg',                      68),   # GHA-PAN
    (1, 3, 3,  4,  39.0, 62.0, 80824, 'Anthony Taylor',                    62),   # UZB-COL
    # June 18
    (1, 1, 5,  5,  62.0, 38.0, 67442, 'Tori Penso',                         4),   # RSA-CZE (SWAPPED)
    (1, 4, 3,  7,  38.0, 62.0, 70026, 'João Pinheiro',                     10),   # BIH-SUI (SWAPPED)
    (6, 0, 19, 1,  79.0, 21.0, 52497, 'Cristián Garay',                     9),   # CAN-QAT
    (1, 0, 0,  2,  42.0, 58.0, 45522, 'Gustavo Tejera',                     3),   # MEX-KOR
    # June 19
    (2, 0, 7,  4,  62.0, 38.0, 66925, 'Felix Zwayer',                      21),   # USA-AUS
    (1, 0, 5,  2,  59.0, 41.0, 64146, 'Ilgiz Tantashev',                   16),   # MAR-SCO (SWAPPED)
    (1, 0, 0, 12,  22.0, 79.0, 68827, 'Iván Barton',                       22),   # PAR-TUR (SWAPPED)
    (3, 0, 4,  4,  57.0, 43.0, 68324, 'Alejandro Hernández',               15),   # BRA-HAI
    # June 20
    (5, 1, 2,  5,  51.0, 49.0, 68777, 'Michael Oliver',                    33),   # NED-SWE
    (2, 1, 8,  3,  59.0, 41.0, 43036, 'Juan Gabriel Benítez',              27),   # GER-CIV
    (0, 0, 0,  9,  25.0, 75.0, 68598, 'Ma Ning',                           28),   # CUW-ECU (SWAPPED)
    (4, 0, 5,  3,  62.0, 38.0, 51243, 'István Kovács',                     34),   # JPN-TUN (SWAPPED)
]

UPDATE_SQL = """UPDATE matches SET
    goals_home=?, goals_away=?,
    corners_home=?, corners_away=?,
    possession_home=?, possession_away=?,
    attendance=?, referee=?
WHERE match_id=?;"""


def apply_updates(updates):
    conn = None
    try:
        conn = sqlite3.connect(DB_PATH)
        conn.execute('PRAGMA journal_mode=MEMORY')
        cursor = conn.cursor()
        count = 0
        for row in updates:
            cursor.execute(UPDATE_SQL, row)
            if cursor.rowcount != 1:
                logging.warning('match_id=%d: expected 1 row affected, got %d', row[-1], cursor.rowcount)
            else:
                count += 1
        conn.commit()
        logging.info('DB updated: %d rows committed', count)
        return count
    finally:
        if conn:
            conn.close()


def append_sql_file(updates):
    lines = [
        '-- WC26 daily update 2026-06-22: match scores June 11-20\n'
    ]
    for row in updates:
        gh, ga, ch, ca, ph, pa, att, ref, mid = row
        stmt = (
            f"UPDATE matches SET\n"
            f"    goals_home={gh}, goals_away={ga},\n"
            f"    corners_home={ch}, corners_away={ca},\n"
            f"    possession_home={ph}, possession_away={pa},\n"
            f"    attendance={att}, referee='{ref}'\n"
            f"WHERE match_id={mid};\n"
        )
        lines.append(stmt)
    block = '\n'.join(lines) + '\n'

    with open(SQL_PATH, 'a', encoding='utf-8') as f:
        f.write(block)
    logging.info('Appended %d UPDATE statements to %s', len(updates), SQL_PATH)


if __name__ == '__main__':
    logging.info('Starting WC26 daily update — 2026-06-22')
    n = apply_updates(UPDATES)
    append_sql_file(UPDATES)
    logging.info('Done. %d matches updated.', n)
