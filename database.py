import psycopg2
import psycopg2.extras
import os
from dotenv import load_dotenv

# Cargar variables de entorno si existe un archivo .env
load_dotenv()

# Configuración de la base de datos
DB_CONFIG = {
    'dbname': os.getenv('DB_NAME', 'eventos_culturales'),
    'user': os.getenv('DB_USER', 'postgres'),
    'password': os.getenv('DB_PASSWORD', 'postgres'),
    'host': os.getenv('DB_HOST', 'localhost'),
    'port': os.getenv('DB_PORT', '5432')
}

def get_db_connection():
    """Establece una conexión a la base de datos PostgreSQL."""
    conn = psycopg2.connect(**DB_CONFIG)
    conn.autocommit = True
    return conn

def execute_query(query, params=None, fetch=True):
    """
    Ejecuta una consulta SQL y opcionalmente recupera los resultados.
    """
    conn = None
    try:
        conn = get_db_connection()
        with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
            print(f"Ejecutando consulta: {query}")
            print(f"Parámetros: {params}")
            cur.execute(query, params)
            if fetch:
                results = cur.fetchall()
                print(f"Resultados: {len(results)} filas")
                return results
    except Exception as e:
        print(f"Error en la consulta: {e}")
        print(f"Query: {query}")
        print(f"Params: {params}")
        if conn:
            conn.rollback()
        return [] if fetch else None
    finally:
        if conn:
            conn.close()

def execute_query_pandas(query, params=None):
    """
    Ejecuta una consulta SQL y devuelve los resultados como un DataFrame de pandas.
    Útil para análisis de datos y manipulación.
    
    Args:
        query (str): Consulta SQL a ejecutar
        params (tuple, optional): Parámetros para la consulta
        
    Returns:
        pandas.DataFrame: DataFrame con los resultados de la consulta
    """
    import pandas as pd
    conn = None
    try:
        conn = get_db_connection()
        return pd.read_sql_query(query, conn, params=params)
    except Exception as e:
        print(f"Error en la consulta pandas: {e}")
        return pd.DataFrame()
    finally:
        if conn:
            conn.close()