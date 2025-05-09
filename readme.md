# Sistema de Gestión de Eventos Culturales y Asistencia

Un sistema completo para la gestión de eventos culturales, con generación de reportes en tiempo real que permiten analizar asistencia, preferencias de usuarios, rendimiento de sedes y más.

![Dashboard](screenshot.png)

## Características

- **Dashboard interactivo** con estadísticas generales y principales métricas
- **5 reportes detallados** con visualizaciones dinámicas:
  1. Análisis de Asistencia por Evento
  2. Popularidad de Categorías
  3. Rendimiento de Sedes
  4. Análisis Temporal de Eventos
  5. Perfil de Usuarios y Preferencias
- **Filtros personalizables** en cada reporte (más de 4 por reporte)
- **Visualizaciones gráficas** con Chart.js para una mejor interpretación de datos
- **Exportación a múltiples formatos** (PDF, Excel, CSV)
- **Diseño responsivo** para usar en cualquier dispositivo

## Tecnologías utilizadas

- **Backend**: Python con Flask
- **Base de datos**: PostgreSQL
- **Frontend**: HTML5, CSS3, JavaScript
- **Visualizaciones**: Chart.js
- **Exportaciones**: jsPDF, SheetJS
- **Estilos**: Bootstrap 5
- **Iconos**: Font Awesome

## Requisitos

- Python 3.7 o superior
- PostgreSQL 12 o superior
- Conexión a internet (para cargar bibliotecas CDN)

## Instalación

1. **Clonar el repositorio:**

   ```bash
   git clone https://github.com/lfmendoza/event-sttendance.git
   cd event-sttendance
   ```

2. **Crear un entorno virtual e instalar dependencias:**

```bash
python -m venv venv
source venv/bin/activate  # En Windows: venv\Scripts\activate
pip install -r requirements.txt
```

3. **Configurar la base de datos:**

- Crear una base de datos PostgreSQL llamada `eventos_culturales`
- Ejecutar el script DDL: `psql -d eventos_culturales -f ddl.sql`
- Cargar datos de prueba: `psql -d eventos_culturales -f dml.sql`

4. **Configurar variables de entorno: Crear un archivo .env en la raíz del proyecto con:**

```bash
DB_NAME=eventos_culturales
DB_USER=tu_usuario
DB_PASSWORD=tu_contraseña
DB_HOST=localhost
DB_PORT=5432
```

5. **Iniciar la aplicación:**

```bash
python app.py
```

6. **Acceder a la aplicación: Abrir en el navegador: `http://localhost:5000`**

```bash
proyecto_eventos_culturales/
├── static/            # Archivos estáticos
│   ├── css/           # Estilos CSS
│   ├── js/            # Scripts JavaScript
│   └── img/           # Imágenes
├── templates/         # Plantillas HTML
├── app.py             # Aplicación principal
├── database.py        # Configuración de la base de datos
├── reports.py         # Lógica de los reportes
├── requirements.txt   # Dependencias del proyecto
├── ddl.sql            # Script de estructura de la base de datos
├── dml.sql            # Script de datos de prueba
└── README.md          # Documentación
```

## Reportes disponibles

### 1. Análisis de Asistencia por Evento

Analiza la tasa de asistencia, ingresos y satisfacción por evento.
Filtros:

- Rango de fechas
- Categoría
- Sede
- Estado del evento
- Rango de precios

### 2. Popularidad de Categorías

Muestra qué categorías culturales atraen más público.
Filtros:

- Rango de fechas
- Rango de calificaciones
- Sede
- Rango de precios

### 3. Rendimiento de Sedes

Compara ocupación, ingresos y eventos por sede.
Filtros:

- Rango de fechas
- Categoría
- Capacidad
- Accesibilidad
- Tasa de ocupación mínima

### 4. Análisis Temporal de Eventos

Tendencias de asistencia, precio y satisfacción en el tiempo.
Filtros:

- Período (diario, semanal, mensual, trimestral, anual)
- Rango de fechas
- Categoría
- Sede
- Tipo de usuario
- Rango de precios

### 5. Perfil de Usuarios y Preferencias

Segmentación de usuarios por intereses y asistencia.
Filtros:

- Rango de edad
- Fecha de registro
- Interés específico
- Número mínimo de eventos asistidos
- Categoría de interés
- Sede frecuentada

## Funcionalidades adicionales

- Exportación a PDF: Todos los reportes pueden exportarse a PDF para su documentación y compartición.
- Exportación a Excel: Facilita el análisis avanzado de los datos en herramientas como Excel.
- Exportación a CSV: Permite integración con otros sistemas de análisis de datos.
- Visualizaciones gráficas: Gráficos interactivos que facilitan la interpretación de resultados.

## Contribuir

- Hacer un fork del repositorio
- Crear una rama para tu funcionalidad (git checkout -b feature/nueva-funcionalidad)
- Hacer commit a tus cambios (git commit -am 'Añadir nueva funcionalidad')
- Hacer push a la rama (git push origin feature/nueva-funcionalidad)
- Crear un Pull Request

### Autores

Fernando Mendoza
