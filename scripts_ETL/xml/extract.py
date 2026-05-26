import urllib.request
import sys
from pathlib import Path

XML_URL = "https://raw.githubusercontent.com/ullenboom/mondial-database/main/mondial.xml"

# Path to save the csv file
root_path = Path(__file__).parent.parent.parent
xml_path = root_path / "data" / "mondial.xml"

# Ensures the data directory exists
xml_path.parent.mkdir(parents=True, exist_ok=True)

print("Downloading mondial.xml...")
with urllib.request.urlopen(XML_URL) as response:
    xml_bytes = response.read()

print(f"Download done !)")

# Save the file
with open(xml_path, "wb") as file:
    file.write(xml_bytes)

print(f"File saved in: {xml_path}")


