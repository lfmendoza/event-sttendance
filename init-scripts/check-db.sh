#!/bin/bash

# Esperar a que PostgreSQL esté listo
echo "Esperando a PostgreSQL..."
sleep 10

# Verificar si hay tablas en la base de datos
tables=$(psql -U postgres -d eventos_culturales -c "\dt" | grep -c "public")

echo "Número de tablas encontradas: $tables"

if [ "$tables" -eq 0 ]; then
    echo "La base de datos está vacía. Ejecutando scripts de inicialización..."
    psql -U postgres -d eventos_culturales -f /docker-entrypoint-initdb.d/ddl.sql
    psql -U postgres -d eventos_culturales -f /docker-entrypoint-initdb.d/dml.sql
    echo "Inicialización completada."
else
    echo "La base de datos ya está inicializada."
fi

# Verificar el número de registros en algunas tablas clave
psql -U postgres -d eventos_culturales -c "SELECT 'usuarios' AS tabla, COUNT(*) FROM usuarios UNION ALL SELECT 'eventos', COUNT(*) FROM eventos UNION ALL SELECT 'categorias', COUNT(*) FROM categorias"