import json
import requests
import os
from pathlib import Path

class JsonExtract:
  def  __init__(self):
     pass

  def extract_json_from_api(self, url, file_name):
    print(" Extracting data from World Bank API...")
    response = requests.get(url)

    # Path to save the json file
    new_json_path = Path(__file__).parent.parent.parent / "data" / file_name
    
    # Ensures the data directory exists
    new_json_path.parent.mkdir(parents=True, exist_ok=True)
    
    # Saving the response in a json file
    with open(f"{new_json_path}", 'w', encoding='utf-8') as file:
      json.dump(response.json(), file, indent=4)
    
    if response.status_code == 200:
        return response.json()
    else:
        raise Exception(f"Failed to fetch data. Status code: {response.status_code}")

  
  def explore_json(self, data):
    for index, item in enumerate(data):
      print(f"\n\n--- Index {index} ---\n\n")
      
      if index > 0: # The first element of the list is just metadata
        actual_records = data[index] 
        
        for index, item in enumerate(actual_records):
          print(f"--- Record {index} ---")
          
          if isinstance(item, dict):
              for key, value in item.items():
                  print(f"{key}: {value}")


def main():
   json_extractor = JsonExtract()

   API_BASE_URL = "https://api.worldbank.org/v2"

   # POP_INDICATOR= "country/all/indicator/SP.POP.TOTL?date=1995:2015&format=json&per_page=30000"
   # GRP_INDICATOR= "indicator/NY.GDP.MKTP.CD?date=2006&format=json"
   # GERAL_INDICATORS = "indicator?format=json&per_page=1000"
   AREA_INDICATOR = "country/all/indicator/AG.SRF.TOTL.K2?date=2015&format=json&per_page=30000"
   AIR_QUALITY_INDICATOR = "country/all/indicator/EN.ATM.PM25.MC.M3?date=1995:2015&format=json&per_page=30000&source=2"
   PRECIPITATION_INDICATOR = "country/all/indicator/AG.LND.PRCP.MM?date=1995:2015&format=json&per_page=30000"

   # URL_GDP = os.path.join(API_BASE_URL, GRP_INDICATOR)
   # URL_GERAL = os.path.join(API_BASE_URL, GERAL_INDICATORS)
   # URL_POP = os.path.join(API_BASE_URL, POP_INDICATOR)  
   URL_AREA = os.path.join(API_BASE_URL, AREA_INDICATOR)
   URL_AIR_QUALITY = os.path.join(API_BASE_URL, AIR_QUALITY_INDICATOR)
   URL_PRECIPITATION = os.path.join(API_BASE_URL, PRECIPITATION_INDICATOR)

   # POP_FILE =  "worldbankPopCountries.json"
   AREA_FILE =  "worldbankAreaCountries.json"
   AIR_QUALITY_FILE = "worldbankAirQualityCountries.json"
   PRECIPITION_FILE = "worldbankPrecipitationCountries.json"

   # List to iterate over the files defined above
   files_to_terate = [(URL_AREA, AREA_FILE), (URL_AIR_QUALITY, AIR_QUALITY_FILE), (URL_PRECIPITATION, PRECIPITION_FILE)]

   # Extracting the data from the API and saving it in a json file
   for url, file_name in files_to_terate:
       json_extractor.extract_json_from_api(url, file_name)
  
if __name__ == "__main__":
   main()
