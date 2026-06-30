"""
fbref_move.py — move Chrome-downloaded stat table HTMLs to results/raw/

Chrome saves downloads to C:\\Users\\gonti\\Downloads (Windows default).
Each file is named {hex}.html — downloaded via the JS blob trigger.

After running this, run fbref_batch.py to parse + load all.

Usage (from WSL):
    python3 fbref_move.py
"""
import os
import shutil
import logging

BASE_DIR    = os.path.dirname(os.path.abspath(__file__))
RAW_DIR     = os.path.join(BASE_DIR, "results", "raw")
LOG_PATH    = os.path.join(BASE_DIR, "worldcup26.log")

# Windows Downloads folder mounted in WSL
WIN_DOWNLOADS = "/mnt/c/Users/gonti/Downloads"

logging.basicConfig(
    filename=LOG_PATH,
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)


def main():
    os.makedirs(RAW_DIR, exist_ok=True)

    moved = 0
    skipped = 0

    for fname in os.listdir(WIN_DOWNLOADS):
        # Accept both {hex}.html and {hex}_tables.html
        if not fname.endswith(".html"):
            continue
        hex_id = fname.replace("_tables.html", "").replace(".html", "")
        if len(hex_id) != 8 or not all(c in "0123456789abcdef" for c in hex_id):
            continue  # not a match file

        src  = os.path.join(WIN_DOWNLOADS, fname)
        dest = os.path.join(RAW_DIR, f"{hex_id}.html")

        if os.path.exists(dest):
            skipped += 1
            continue

        shutil.copy2(src, dest)
        moved += 1
        logging.info(f"fbref_move: {fname} → results/raw/{hex_id}.html")

    print(f"Done — {moved} moved, {skipped} already in place.")
    logging.info(f"fbref_move: {moved} moved, {skipped} skipped.")


if __name__ == "__main__":
    main()
