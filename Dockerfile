FROM python:3.9-slim

WORKDIR /app

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    postgresql-client \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copiar y instalar requisitos
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar el código de la aplicación
COPY . .

# Script de entrada para esperar a la base de datos
COPY wait-for-db.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/wait-for-db.sh

# Comando para ejecutar la aplicación
CMD ["/usr/local/bin/wait-for-db.sh", "python", "app.py"]