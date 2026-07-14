import os
import csv

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
FOLDER_PATH = os.path.join(BASE_DIR, "results")

def get_csv_files(folder):
    csv_files = []
    for filename in os.listdir(folder):
        if filename.endswith(".csv"):
            csv_files.append(os.path.join(folder, filename))
    return csv_files

def load_csv(path):
    rows = []
    with open(path, newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            rows.append({
                "match_id":   int(row["match_id"]),
                "goals_home": int(row["goals_home"]),
                "goals_away": int(row["goals_away"]),
            })
    return rows

def main():
    csv_files = get_csv_files(FOLDER_PATH)
    for filename in csv_files:
        print(f"{filename} | {len(load_csv(filename))}")
        
if __name__ == "__main__":
    main()