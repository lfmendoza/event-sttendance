#!/bin/bash
set -e

# Función para verificar si PostgreSQL está listo
postgres_ready() {
    python << END
import sys
import psycopg2
try:
    psycopg2.connect(
        dbname="${DB_NAME}",
        user="${DB_USER}",
        password="${DB_PASSWORD}",
        host="${DB_HOST}",
        port="${DB_PORT}"
    )
except psycopg2.OperationalError:
    sys.exit(-1)
sys.exit(0)
END
}

# Esperar hasta que PostgreSQL esté listo
until postgres_ready; do
    echo "PostgreSQL no está disponible todavía... esperar 1 segundo"
    sleep 1
done

echo "PostgreSQL está listo, iniciando aplicación..."

# Ejecutar el comando pasado a este script
exec "$@"