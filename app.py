from flask import Flask, render_template, request, jsonify
import json
from datetime import datetime
import reports

app = Flask(__name__)

@app.route('/')
def index():
    """Página principal con dashboard."""
    stats = reports.get_dashboard_stats()
    filter_options = reports.get_filter_options()
    return render_template('index.html', stats=stats, filter_options=filter_options)

@app.route('/report/attendance')
def attendance_report():
    """Reporte 1: Análisis de Asistencia por Evento."""
    filter_options = reports.get_filter_options()
    return render_template('report_1.html', filter_options=filter_options)

@app.route('/api/attendance')
def api_attendance():
    """API para obtener datos del reporte de asistencia."""
    fecha_inicio = request.args.get('fecha_inicio')
    fecha_fin = request.args.get('fecha_fin')
    categoria_id = request.args.get('categoria_id')
    sede_id = request.args.get('sede_id')
    estado_evento = request.args.get('estado_evento')
    precio_min = request.args.get('precio_min')
    precio_max = request.args.get('precio_max')
    
    data = reports.get_attendance_analysis(
        fecha_inicio=fecha_inicio, 
        fecha_fin=fecha_fin,
        categoria_id=categoria_id, 
        sede_id=sede_id,
        estado_evento=estado_evento,
        precio_min=precio_min, 
        precio_max=precio_max
    )
    
    # Convertir datos para JSON
    result = []
    for row in data:
        item = dict(row)
        
        # Formatear fechas para JSON
        if 'fecha_inicio' in item and item['fecha_inicio']:
            item['fecha_inicio'] = item['fecha_inicio'].strftime('%Y-%m-%d %H:%M')
        if 'fecha_fin' in item and item['fecha_fin']:
            item['fecha_fin'] = item['fecha_fin'].strftime('%Y-%m-%d %H:%M')
            
        # Manejar campos especiales
        if 'categorias' in item and item['categorias']:
            # Convertir array de PostgreSQL a lista de Python
            if isinstance(item['categorias'], str) and item['categorias'].startswith('{') and item['categorias'].endswith('}'):
                item['categorias'] = item['categorias'][1:-1].split(',')
            
        result.append(item)
    
    return jsonify(result)

@app.route('/report/categories')
def categories_report():
    """Reporte 2: Popularidad de Categorías."""
    filter_options = reports.get_filter_options()
    return render_template('report_2.html', filter_options=filter_options)

@app.route('/api/categories')
def api_categories():
    """API para obtener datos del reporte de categorías."""
    fecha_inicio = request.args.get('fecha_inicio')
    fecha_fin = request.args.get('fecha_fin')
    calificacion_min = request.args.get('calificacion_min')
    calificacion_max = request.args.get('calificacion_max')
    sede_id = request.args.get('sede_id')
    precio_min = request.args.get('precio_min')
    precio_max = request.args.get('precio_max')
    
    data = reports.get_category_popularity(
        fecha_inicio=fecha_inicio, 
        fecha_fin=fecha_fin,
        calificacion_min=calificacion_min, 
        calificacion_max=calificacion_max,
        sede_id=sede_id,
        precio_min=precio_min, 
        precio_max=precio_max
    )
    
    return jsonify([dict(row) for row in data])

@app.route('/report/venues')
def venues_report():
    """Reporte 3: Rendimiento de Sedes."""
    filter_options = reports.get_filter_options()
    return render_template('report_3.html', filter_options=filter_options)

@app.route('/api/venues')
def api_venues():
    """API para obtener datos del reporte de sedes."""
    fecha_inicio = request.args.get('fecha_inicio')
    fecha_fin = request.args.get('fecha_fin')
    categoria_id = request.args.get('categoria_id')
    capacidad_min = request.args.get('capacidad_min')
    capacidad_max = request.args.get('capacidad_max')
    accesibilidad = request.args.get('accesibilidad')
    tasa_ocupacion_min = request.args.get('tasa_ocupacion_min')
    
    # Convertir parámetros
    if accesibilidad is not None:
        accesibilidad = accesibilidad.lower() == 'true'
    
    data = reports.get_venue_performance(
        fecha_inicio=fecha_inicio, 
        fecha_fin=fecha_fin,
        categoria_id=categoria_id, 
        capacidad_min=capacidad_min,
        capacidad_max=capacidad_max,
        accesibilidad=accesibilidad,
        tasa_ocupacion_min=tasa_ocupacion_min
    )
    
    # Convertir salas_info a objetos JSON
    result = []
    for row in data:
        item = dict(row)
        
        # Formatear horarios
        if 'horario_apertura' in item and item['horario_apertura']:
            item['horario_apertura'] = item['horario_apertura'].strftime('%H:%M')
        if 'horario_cierre' in item and item['horario_cierre']:
            item['horario_cierre'] = item['horario_cierre'].strftime('%H:%M')
            
        # Convertir JSON string a objeto Python
        if 'salas_info' in item and item['salas_info']:
            if isinstance(item['salas_info'], str):
                try:
                    item['salas_info'] = json.loads(item['salas_info'])
                except:
                    item['salas_info'] = []
        
        result.append(item)
    
    return jsonify(result)

@app.route('/report/temporal')
def temporal_report():
    """Reporte 4: Análisis Temporal de Eventos."""
    filter_options = reports.get_filter_options()
    return render_template('report_4.html', filter_options=filter_options)

@app.route('/api/temporal')
def api_temporal():
    """API para obtener datos del reporte temporal."""
    periodo = request.args.get('periodo', 'mensual')
    fecha_inicio = request.args.get('fecha_inicio')
    fecha_fin = request.args.get('fecha_fin')
    categoria_id = request.args.get('categoria_id')
    sede_id = request.args.get('sede_id')
    tipo_usuario = request.args.get('tipo_usuario')
    precio_min = request.args.get('precio_min')
    precio_max = request.args.get('precio_max')
    
    data = reports.get_temporal_analysis(
        periodo=periodo,
        fecha_inicio=fecha_inicio, 
        fecha_fin=fecha_fin,
        categoria_id=categoria_id, 
        sede_id=sede_id,
        tipo_usuario=tipo_usuario,
        precio_min=precio_min, 
        precio_max=precio_max
    )
    
    # Formatear fechas
    result = []
    for row in data:
        item = dict(row)
        if 'periodo_fecha' in item and item['periodo_fecha']:
            item['periodo_fecha'] = item['periodo_fecha'].strftime('%Y-%m-%d')
        result.append(item)
    
    return jsonify(result)

@app.route('/report/users')
def users_report():
    """Reporte 5: Perfil de Usuarios y Preferencias."""
    filter_options = reports.get_filter_options()
    return render_template('report_5.html', filter_options=filter_options)

@app.route('/api/users')
def api_users():
    """API para obtener datos del reporte de usuarios."""
    edad_min = request.args.get('edad_min')
    edad_max = request.args.get('edad_max')
    fecha_registro_min = request.args.get('fecha_registro_min')
    fecha_registro_max = request.args.get('fecha_registro_max')
    interes = request.args.get('interes')
    num_eventos_min = request.args.get('num_eventos_min')
    categoria_id = request.args.get('categoria_id')
    sede_id = request.args.get('sede_id')
    
    data = reports.get_user_preferences(
        edad_min=edad_min, 
        edad_max=edad_max,
        fecha_registro_min=fecha_registro_min, 
        fecha_registro_max=fecha_registro_max,
        interes=interes,
        num_eventos_min=num_eventos_min,
        categoria_id=categoria_id,
        sede_id=sede_id
    )
    
    # Formatear fechas y manejar arrays
    result = []
    for row in data:
        item = dict(row)
        if 'fecha_nacimiento' in item and item['fecha_nacimiento']:
            item['fecha_nacimiento'] = item['fecha_nacimiento'].strftime('%Y-%m-%d')
        if 'fecha_creacion' in item and item['fecha_creacion']:
            item['fecha_creacion'] = item['fecha_creacion'].strftime('%Y-%m-%d %H:%M')
        
        # Convertir arrays de PostgreSQL a listas de Python
        if 'intereses' in item and item['intereses']:
            if isinstance(item['intereses'], str) and item['intereses'].startswith('{') and item['intereses'].endswith('}'):
                item['intereses'] = item['intereses'][1:-1].split(',')
        
        result.append(item)
    
    return jsonify(result)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)