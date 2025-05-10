#!/bin/bash
set -e

# Esperar a que PostgreSQL esté completamente inicializado
sleep 10

# Ejecutar los scripts SQL en orden
echo "Ejecutando ddl.sql..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -f /docker-entrypoint-initdb.d/ddl.sql
echo "ddl.sql ejecutado correctamente"

echo "Ejecutando dml.sql..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -f /docker-entrypoint-initdb.d/dml.sql
echo "dml.sql ejecutado correctamente"

echo "Base de datos inicializada con éxito!"