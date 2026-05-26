import csv
import oracledb
import os
import sys
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()

root_path = Path(__file__).parent.parent.parent
wallet_folder = os.getenv("ORACLE_WALLET_FOLDER", "")

WALLET_PATH = str(root_path / ".secrets" / wallet_folder) 
WALLET_PASSWORD = os.getenv("WALLET_PASSWORD")

DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_DSN = os.getenv("WALLET_DSN")

data_file_path = root_path / "data" / "happiness2015.csv"


DDL_STG_HAPPINESS = """
CREATE TABLE STG_HAPPINESS (
    rank_geral          NUMBER(3),
    country_name        VARCHAR2(100),
    region              VARCHAR2(100),
    happiness_score     NUMBER(6,3),
    standard_error      NUMBER(8,5),
    gdp_per_capita      NUMBER(6,3),
    social_support      NUMBER(6,3),
    life_expectancy     NUMBER(6,3),
    freedom             NUMBER(6,3),
    generosity          NUMBER(6,3),
    corruption_percept  NUMBER(6,3),
    dystopia_residual   NUMBER(6,5)
)
"""

print("Connecting to Oracle...")
conn = oracledb.connect(
    user=DB_USER,
    password=DB_PASSWORD,
    dsn=DB_DSN,
    config_dir=WALLET_PATH,
    wallet_location=WALLET_PATH,
    wallet_password=WALLET_PASSWORD,
)

cursor = conn.cursor()
print("Connected!")

try:
    cursor.execute(DDL_STG_HAPPINESS)
    conn.commit()
    print("Table STG_HAPPINESS created.")
except oracledb.DatabaseError as e:
    if "ORA-00955" in str(e):
        print("Table STG_HAPPINESS already exists, continuing code...")
    else:
        raise

cursor.execute("DELETE FROM STG_HAPPINESS")
conn.commit()
print("Table cleared")

INSERT_SQL = """
    INSERT INTO STG_HAPPINESS (
        rank_geral, country_name, region, happiness_score,
        standard_error, gdp_per_capita, social_support,
        life_expectancy, freedom, generosity,
        corruption_percept, dystopia_residual
    ) VALUES (
        :1, :2, :3, :4, :5, :6, :7, :8, :9, :10, :11, :12
    )
"""


def parse_float(val):
    val = val.strip()
    return float(val) if val else None


rows_to_insert = []

try:
    with open(f"{data_file_path}", newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            row_data = (
                int(row["Happiness Rank"]),
                row["Country"].strip(),
                row["Region"].strip(),
                parse_float(row["Happiness Score"]),
                parse_float(row["Standard Error"]),
                parse_float(row["Economy (GDP per Capita)"]),
                parse_float(row["Family"]),
                parse_float(row["Health (Life Expectancy)"]),
                parse_float(row["Freedom"]),
                parse_float(row["Generosity"]),
                parse_float(row["Trust (Government Corruption)"]),
                parse_float(row["Dystopia Residual"]),
            )
            rows_to_insert.append(row_data)
except FileNotFoundError:
    print(f"Error: The file {data_file_path.name} was not found in the data folder!")
    print("Please run the extraction script (extract.py) first.")
    sys.exit(1)

#bulk insert all parsed rows at once
if rows_to_insert:
    cursor.executemany(INSERT_SQL, rows_to_insert)

conn.commit()
print(f"{len(rows_to_insert)} countries successfully inserted into STG_HAPPINESS")

cursor.close()
conn.close()
print("Connection closed")