#!/bin/bash
set -e

host="db"
port="5432"
user="postgres"
password="postgres"
dbname="eventos_culturales"

# Función para verificar si PostgreSQL está listo
pg_ready() {
    PGPASSWORD=$password psql -h "$host" -p "$port" -U "$user" -d "$dbname" -c "SELECT 1" >/dev/null 2>&1
}

# Esperar hasta que PostgreSQL esté listo
echo "Esperando a PostgreSQL..."
until pg_ready; do
    echo "PostgreSQL no está disponible todavía... esperando"
    sleep 2
done

echo "PostgreSQL está listo, comprobando datos..."

# Verificar si hay tablas en la base de datos
tables=$(PGPASSWORD=$password psql -h "$host" -p "$port" -U "$user" -d "$dbname" -t -c "\dt" | wc -l)

if [ "$tables" -lt 5 ]; then
    echo "ADVERTENCIA: La base de datos parece no estar inicializada correctamente."
    echo "Solo se encontraron $tables tablas."
    echo "Verifica los scripts de inicialización."
else
    echo "Base de datos inicializada correctamente con $tables tablas."
    # Verificar algunos conteos básicos
    PGPASSWORD=$password psql -h "$host" -p "$port" -U "$user" -d "$dbname" -c "SELECT 'usuarios' AS tabla, COUNT(*) FROM usuarios UNION ALL SELECT 'eventos', COUNT(*) FROM eventos UNION ALL SELECT 'sedes', COUNT(*) FROM sedes"
fi

# Ejecutar el comando pasado a este script
exec "$@"