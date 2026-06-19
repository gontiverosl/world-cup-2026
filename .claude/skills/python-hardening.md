# Python Hardening Patterns

Every script and API endpoint in this repo follows these templates exactly.
Do not deviate without a documented reason.

---

## Script Template (non-API scripts)

```python
import os
import sqlite3
import logging
import pandas as pd

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE_DIR, "novapay.db")
LOG_PATH = os.path.join(BASE_DIR, "novapay.log")

logging.basicConfig(
    filename=LOG_PATH,
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)

def load_data():
    conn = None
    try:
        conn = sqlite3.connect(DB_PATH)
        df = pd.read_sql(query, conn)   # query FIRST, conn SECOND
        logging.info(f"{len(df)} rows loaded.")
        return df
    finally:
        if conn:
            conn.close()

def main():
    df = load_data()
    # orchestration only — main() opens no connection

if __name__ == "__main__":
    main()
```

---

## API Template (FastAPI endpoints)

```python
def get_something(param: str):
    conn = None
    try:
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        cursor.execute(query, (param,))   # ? placeholder, never f-string
        rows = cursor.fetchall()
        if cursor.rowcount == 0:
            logging.warning(f"No rows found for {param}")
        return rows
    except Exception as e:
        logging.error(f"DB error: {e}")
        return {"error": str(e)}
    finally:
        if conn:
            conn.close()
```

Key difference from script template: `except Exception as e` catches and handles instead of letting the crash surface. Scripts crash visibly (good). APIs return errors (required).

---

## Function Separation Rule

One function per responsibility. `main()` orchestrates only — it opens no connections, reads no files, calls no SQL.

```
load_data()       → owns its own try/finally, returns DataFrame
process_data(df)  → pure transformation, no I/O
export_data(df)   → owns its own file open/close
main()            → calls the above in order, nothing else
```

---

## CSV Read/Write Pattern

```python
import csv

# Write — pandas handles newline internally
df.to_csv(OUTPUT_PATH, index=False)

# Read — always newline="" to prevent phantom blank rows on Windows
with open(OUTPUT_PATH, "r", newline="") as f:
    reader = csv.DictReader(f)
    for row in reader:
        print(row["col"])   # row is a dict — use row, not reader
    # log len() AFTER loop, not before — DictReader has no len()
    logging.info(f"{len(results)} rows loaded.")
```

---

## Bugs Burned In

| Bug | Rule |
|-----|------|
| `%(asctime)s` written as `%{asctime}s` | Logging format uses `%(...)s` — parentheses, not curly braces. |
| `len(reader)` on a DictReader | DictReader is an iterator — no `len()`. Collect into a list first. |
| `newline=""` omitted in `open()` | Always required for CSV on Windows. |
| Loop variable shadowed by list name | `for row in rows: print(rows["col"])` → must be `row["col"]`. |
| `pd.read_sql(conn, query)` | Argument order is query first, conn second — always. |
| `SUM() OVER (PARTITION BY)` in a CTE | Causes duplicate rows in SQLite. Use `SUM() + GROUP BY` in CTEs instead. |
| Window function alias in `WHERE` | WHERE runs before SELECT. Filter window aliases in outer query only. |
