import oracledb
import sys
import os
from pathlib import Path
from dotenv import load_dotenv


class OracleConnectionT1:
    def __init__(self):
        load_dotenv()

        wallet_folder = os.getenv("ORACLE_WALLET_FOLDER"," ")
        
        # Take the root folder of the project based on the current file layer (each parent back one layer)
        root_path = Path(__file__).parent.parent
        wallet_path = str(root_path / ".secrets" / wallet_folder) 
        
        db_user = os.getenv("DB_USER")
        db_password = os.getenv("DB_PASSWORD")
        db_dsn = os.getenv("WALLET_DSN")
        wallet_path = str(root_path / ".secrets" / wallet_folder) 

        
        wallet_password = os.getenv("WALLET_PASSWORD")

        print(db_dsn)
        print(wallet_path)
        self.conn = oracledb.connect(
            user=db_user,
            password=db_password,
            dsn=db_dsn,
            config_dir=wallet_path,
            wallet_location=wallet_path,
            wallet_password=wallet_password
        )
        
        self.cursor = self.conn.cursor()

        print("Conectado:", self.conn.version)

    def execute_query(self, query):
        resultado = self.cursor.execute(query)
        print(resultado.fetchall())

    def close_conn(self):
        if self.cursor:
            self.cursor.close()
        if self.conn:
            self.conn.close()
        print("Connection finished successfully!")


def main():
     conn = OracleConnectionT1()

     sql_1 = "SELECT * FROM STG_HAPPINESS ORDER BY RANK_GERAL"
     conn.execute_query(sql_1)


     conn.close_conn()

main()