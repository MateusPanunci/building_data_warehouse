import urllib.request
import oracledb
import os
import sys
from xml.etree import ElementTree as ET
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

data_file_path = root_path / "data" / "mondial.xml"

DDL = """
CREATE TABLE STG_MONDIAL_XML (
    id          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fonte       VARCHAR2(100),         -- 'mondial.xml'
    dados_xml   XMLTYPE,               -- raw XML filtered 
    dt_carga    DATE DEFAULT SYSDATE
)
"""

print("\nConnecting to Oracle...")
conn = oracledb.connect(
    user=DB_USER,
    password=DB_PASSWORD,
    dsn=DB_DSN,
    config_dir=WALLET_PATH,
    wallet_location=WALLET_PATH,
    wallet_password=WALLET_PASSWORD
)

cursor = conn.cursor()
print("Connected!")


#elements that we want to keep
DESIRED_ELEMENTS = {"country", "organization", "sea", "airport"}

try:
    with open(data_file_path, "r", encoding="utf-8") as file:
        xml_content = file.read()
except FileNotFoundError:
    print(f"Error: The file {data_file_path.name} was not found in the data folder!")
    print("Please run the extraction script (extract.py) first.")
    sys.exit(1)
    
#remove the Doctype from the XML
lines = xml_content.splitlines()
clean_lines = [l for l in lines if "<!DOCTYPE" not in l]
xml_str = "\n".join(clean_lines)

print("Parsing XML...")
root = ET.fromstring(xml_str)

print("Filtering elements...")
new_root = ET.Element("mondial")
for element in DESIRED_ELEMENTS:
    finded = root.findall(element)
    print(f"  {element}: {len(finded)} ")
    for item in finded:
        new_root.append(item)

xml_filtered = ET.tostring(new_root, encoding="unicode", xml_declaration=False)
xml_filtered = '<?xml version="1.0" encoding="UTF-8"?>\n' + xml_filtered

print(f"XML filtered: {len(xml_filtered)//1024} KB "
      f"({len(xml_filtered.splitlines())} lines)")

try:
    cursor.execute(DDL)
    conn.commit()
    print("STG_MONDIAL_XML table created!.")
except oracledb.DatabaseError as e:
    if "ORA-00955" in str(e):
        print("Table already exists, continuing...")
    else:
        raise

cursor.execute("DELETE FROM STG_MONDIAL_XML")
conn.commit()

clob_var = cursor.var(oracledb.DB_TYPE_CLOB) # variable of CLOB type to store the XML
clob_var.setvalue(0, xml_filtered) # sets the value of the CLOB variable
cursor.execute("""
    INSERT INTO STG_MONDIAL_XML (fonte, dados_xml)
    VALUES ('mondial.xml', XMLType(:1))
""", (clob_var,))
#(CLOB not have a size limit -> if you don't do this, it gives an error!)
#CLOB = Character Large Object
conn.commit()
print("XML inserted in STG_MONDIAL_XML.")

cursor.close()
conn.close()
print("Connection closed.")
 