import os
import requests
import logging
import time

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
OUTPUT_PATH = os.path.join(BASE_DIR, "results", "raw")
LOG_PATH = os.path.join(BASE_DIR, "worldcup26.log")

logging.basicConfig(
    filename=LOG_PATH,
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)

def main():
    try:
        response = requests.get('https://fbref.com/en/matches/a2c54ed9/Germany-Curacao-June-14-2026-World-Cup', headers={"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"})
        response.raise_for_status()
        logging.info(f"Request status code: {response.status_code}")
        os.makedirs(OUTPUT_PATH, exist_ok=True)
        path = os.path.join(OUTPUT_PATH, "a2c54ed9.html")
        with open(path, "w", encoding="utf-8") as f:
            f.write(response.text)
        time.sleep(3)
    except requests.exceptions.RequestException as e:
        logging.error(f"Fetch failed: {e}")

if __name__ == "__main__":
    main()