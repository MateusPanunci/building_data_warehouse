import urllib.request
import sys
from pathlib import Path

# 1. URL na versão "RAW" (Crua) do GitHub
CSV_URL = "https://github.com/turdubars/World-Happiness/raw/master/2015.csv"

# Path to save the csv file
root_path = Path(__file__).parent.parent.parent
csv_path = root_path / "data" / "happiness2015.csv"

# Ensures the data directory exists
csv_path.parent.mkdir(parents=True, exist_ok=True)

print("Downloading 2015.csv from GitHub...")

# Download the file 
with urllib.request.urlopen(CSV_URL) as response:
    csv_bytes = response.read()

print(f"Download done !)")

# Save the file
with open(csv_path, "wb") as file:
    file.write(csv_bytes)

print(f"File saved in: {csv_path}")