# Multi-Source ETL Pipeline to Oracle Cloud DB (T1 - Data Integration and Preparation Subject)

This repository contains an end-to-end Python ETL (Extract, Transform, Load) pipeline that orchestrates the extraction of diverse data formats (**CSV, JSON, and XML**) from local files and public APIs, transforms them, and stages them into an **Oracle Cloud Autonomous Database** utilizing `oracledb` thick-client configuration.

---



## 📊 Data Sources & File Descriptions

This project integrates data from three distinct public domains, processing different file structures (CSV, JSON, and XML) to build a unified analytical data warehouse.

### 1. World Happiness Report (`.csv`)
* **File:** `data/happiness2015.csv`
* **Source:** [Git Hub](https://github.com/turdubars/World-Happiness/raw/master/2015.csv)
* **Description:** Contains global geodemographic scores and rankings evaluating factors such as economic production (GDP per capita), social support, life expectancy, freedom, absence of corruption, and generosity across more than 150 nations. 
* **ETL Target:** Maps explicitly structured columns directly into the `STG_HAPPINESS` staging table.

### 2. World Bank Development Indicators (`.json`)
* **Files:**
  * `data/worldbankAirQuality.json`
  * `data/worldbankPrecipitationCountries.json`
* **Source:** [World Bank Open Data API](https://data.worldbank.org/)
* **Description:** Provides essential macroeconomic and environmental baseline metrics for world countries, specifically capturing surface area dimensions and mean annual precipitation rates.
* **ETL Target:** These multi-layered JSON payloads are streamed and safely nested as raw text inside the `STG_WORLD_BANK` CLOB columns before being parsed relationally.

### 3. Mondial Geography Database (`.xml`)
* **File:** `data/mondial.xml`
* **Source:** [Mondial Database (Universität Göttingen)](https://raw.githubusercontent.com/ullenboom/mondial-database/main/mondial.xml)
* **Temporal Coverage:** Socioeconomic and demographic metrics scale from **1998 to 2015** (sourced primarily from the CIA World Factbook updates).
* **Description:** A comprehensive geographical compilation mapping relationships between global political regimes, continents, major water bodies (seas), national coordinates, languages, religions, and international airports.
* **ETL Target:** The script strips out conflicting inline `<!DOCTYPE>` declarations, extracts and filters target nodes (`country`, `organization`, `sea`, `airport`), and streams the compressed structure cleanly into the `STG_MONDIAL_XML` database `XMLTYPE` column.

---



## 📁 Repository Structure

```text
├── .secrets/
│   └── wallet_oracle_T1/          # Unzipped Oracle Wallet credentials
├── data/                          # Target folder for extracted data files
│   ├── happiness2015.csv
│   ├── mondial.xml
│   └── worldbank*.json
├── scripts_ETL/
│   ├── csv/
│   │   ├── extract_csv.py         # Pulls World Happiness data
│   │   └── load_csv.py            # Loads transformed CSV to STG_HAPPINESS
│   ├── json/
│   │   ├── extract_json.py        # Pulls World Bank economic indicators
│   │   └── load_json.py           # Bulk loads raw JSON rows into STG_WORLD_BANK
│   └── xml/
│       ├── extract.py             # Downloads public XML source
│       └── load_xml.py            # Filters elements and loads into STG_MONDIAL_XML
├── scripts_tests/
│   └── test_connection.py         # Sandbox to test connection parameters
├── sql/
│   ├── queries/
│   │   ├── dw_tests.sql           # Data validation verification scripts
│   │   └── queries.sql            # Core analytics query scripts
│   ├── schema_creation/
│   └── staged_to_schema/
├── .env                           # Local environment secrets (ignored by git)
├── .env.example                   # Template configuration file
├── .gitignore
├── requirements.txt               # App dependencies 
└── README.md

```

---

## 🛠️ Step 1: Setting up Oracle Cloud Infrastructure (OCI)

Before executing any script, you must configure a cloud database instance and download the client credentials securely.

1. **Create an Oracle Cloud Account**: Sign up at [Oracle Cloud Free Tier](https://www.oracle.com/cloud/free/).
2. **Provision an Autonomous Database**:
* Navigate to the OCI Console menu: **Oracle Database** -> **Autonomous Database**.
* Click **Create Autonomous Database**.
* Provide a display name and choose **Transaction Processing** (ATP) or **Data Warehouse** (ADW).
* Choose **Shared Infrastructure** (Free Tier eligible).
* Create an administrative password (keep track of your `ADMIN` credentials).


3. **Download Client Credentials (Wallet)**:
* Once your database status shows **Available**, click on its name to enter the details page.
* Click on **Database Connection**.
* Under Wallet Type, select **Instance Wallet** and click **Download Wallet**.
* Secure the wallet zip file with a wallet password.


4. **Deploying the Wallet in Your Workspace**:
* Create a folder named `.secrets/wallet_oracle_T1` in your project root workspace.
* Extract **all files** from your downloaded wallet zip file directly into this folder.



---

## ⚙️ Step 2: Environment Requirements & Dependency Installation

### 1. Installation

Install the required application packages listed in the packager file via pip:

```bash
pip install -r requirements.txt

```

### 2. Environment Configurations (`.env`)

The database configurations and path layers must be hidden from version control.

1. Duplicate `.env.example` and rename it to `.env`:
```bash
cp .env.example .env

```


2. Populate the parameters inside `.env` matching your configuration:

```ini
# Oracle Database Core Configs
DB_USER="ADMIN"
DB_PASSWORD="your_strong_cloud_password"

# DSN should match one of the aliases defined inside your unzipped wallet's 'tnsnames.ora' file
# e.g., yourdbname_high, yourdbname_medium, or yourdbname_low
WALLET_DSN="yourdbname_medium"

# Folder directory name located within project_root/.secrets/
ORACLE_WALLET_FOLDER="wallet_oracle_T1"
WALLET_PASSWORD="your_wallet_zip_download_password"

```

---

## 🚀 Step 3: Run Validation & Execution Guide

### 🧪 Step 3.1: Test DB Infrastructure Connection

Verify that your Python application layer can communicate seamlessly with your Oracle Cloud instance before running full operations:

```bash
python scripts_tests/test_connection.py

```

---

### 📥 Step 3.2: Execute Data Extraction Pipelines

Extract data files from internet registries or local endpoints to build the system data directory layer. Run all extraction tasks:

```bash
# Extract World Happiness CSV data
python scripts_ETL/csv/extract_csv.py

# Extract World Bank Development Indicator JSON files
python scripts_ETL/json/extract_json.py

# Download World Geography XML data
python scripts_ETL/xml/extract.py

```

---

### 📤 Step 3.3: Execute Database Ingestion Pipelines

Process, convert data types, filter out namespaces/doctypes, and stage the data utilizing bulk matrix streaming capabilities (`executemany`):

```bash
# Load mapped columns into STG_HAPPINESS
python scripts_ETL/csv/load_csv.py

# Load un-nested iterations into STG_WORLD_BANK CLOB columns
python scripts_ETL/json/load_json.py

# Clean DOCTYPE, parse and isolate nodes, load into STG_MONDIAL_XML XMLTYPE
python scripts_ETL/xml/load_xml.py

```

---

## 📊 Step 4: Analytical Verification & Execution

Once ingestion succeeds, run your transformation queries to build metrics or test structures.

1. **Verify Integrity Staging States**: Run `sql/queries/dw_tests.sql` via an IDE (such as DBeaver, SQL Developer, or VS Code Oracle Developer Tools extension) to look for row matching validations.
2. **Execute Schema
3. **Execute Analytical Reporting Queries**: Run `sql/queries/queries.sql` to pull metrics relating country distributions to geographic matrices or development profiles.

---

## ⚠️ Important Architectural Observations

> 💡 **Path Traversal Best Practices (`pathlib.Path`)**
> * **Do not mix** native `pathlib.Path` objects directly into older string operators like `os.path.join()`. This mismatch will result in a runtime crash error: `No overload of function matching arguments`.
> * This repository computes runtime coordinates cleanly using the modern division operator notation: `root_path / ".secrets" / wallet_folder`.
> * Always check your directory depth relative parent loops (`.parent.parent.parent`). If you change script directory depth layout, verify the mapping logic matches.