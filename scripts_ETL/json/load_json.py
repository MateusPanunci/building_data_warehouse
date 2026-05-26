import json
import oracledb
import os
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()

# Take the root folder of the project based on the current file layer (each parent back one layer)
root_path = Path(__file__).parent.parent.parent
wallet_folder = os.getenv("ORACLE_WALLET_FOLDER", "")

WALLET_PATH = str(root_path / ".secrets" / wallet_folder) 
WALLET_PASSWORD = os.getenv("WALLET_PASSWORD")

DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_DSN = os.getenv("WALLET_DSN")

# Path to save the json file
data_dir_path = root_path / "data"

# Grouped into a list for easy iteration, with the corrected file name
# Change the path acording to your local machine
JSON_FILES = [
    data_dir_path / "worldbankAirQualityCountries.json",
    data_dir_path / "worldbankPrecipitationCountries.json",
    data_dir_path / "worldbankAreaCountries.json"
]

# SQL to create the staging table
DDL_STG_WORLD_BANK = """
CREATE TABLE STG_WORLD_BANK (
    id           NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source       VARCHAR2(100),         
    json_data    CLOB,                  
    load_date    DATE DEFAULT SYSDATE
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

# Create table
try:
    cursor.execute(DDL_STG_WORLD_BANK)
    conn.commit()
    print("Table STG_WORLD_BANK created.")
except oracledb.DatabaseError as e:
    if "ORA-00955" in str(e):
        print("Table STG_WORLD_BANK already exists, continuing...")
    else:
        raise

# Clear staging table
cursor.execute("DELETE FROM STG_WORLD_BANK")
conn.commit()

# Updated INSERT statement to accept the dynamic file name
INSERT_SQL = """
    INSERT INTO STG_WORLD_BANK
     (source, json_data)
      VALUES
       (:1, :2)
"""

# Iterate through all files and insert data
for filepath in JSON_FILES:
    filename = os.path.basename(filepath) # Gets just the file name (e.g., 'worldbankPopulation.json')

    with open(filepath, 'r', encoding='utf-8') as file:
        json_content = json.load(file)

        rows_to_insert = []

        # If the JSON is a list of objects, prepare each object as a separate row
        if isinstance(json_content, list):
            for item in json_content:
                json_string = json.dumps(item)
                rows_to_insert.append((filename, json_string))
        else:
            # If it's a single large object, prepare it entirely
            json_string = json.dumps(json_content)
            rows_to_insert.append((filename, json_string))

        # Bulk insert for much faster performance
        if rows_to_insert:
            cursor.executemany(INSERT_SQL, rows_to_insert)

conn.commit()
print("All JSONs inserted into STG_WORLD_BANK.")

cursor.close()
conn.close()
print("Connection closed.")