from database import execute_query, execute_query_pandas
import json

# --------------------------------
# REPORTE 1: Análisis de Asistencia por Evento
# --------------------------------
def get_attendance_analysis(fecha_inicio=None, fecha_fin=None, categoria_id=None, 
                          sede_id=None, estado_evento=None, precio_min=None, precio_max=None):
    """
    Análisis de asistencia, ingresos y satisfacción por evento.
    
    Filtros:
        fecha_inicio: Fecha de inicio del rango a consultar
        fecha_fin: Fecha de fin del rango a consultar
        categoria_id: ID de la categoría de evento
        sede_id: ID de la sede donde se realiza el evento
        estado_evento: Estado del evento ('programado', 'en_curso', 'finalizado', etc.)
        precio_min: Precio mínimo de entrada
        precio_max: Precio máximo de entrada
    """
    params = []
    conditions = []
    
    # Construir condiciones según los filtros proporcionados
    if fecha_inicio:
        conditions.append("e.fecha_inicio >= %s")
        params.append(fecha_inicio)
    
    if fecha_fin:
        conditions.append("e.fecha_fin <= %s")
        params.append(fecha_fin)
    
    if categoria_id:
        conditions.append("EXISTS (SELECT 1 FROM evento_categorias ec WHERE ec.evento_id = e.evento_id AND ec.categoria_id = %s)")
        params.append(categoria_id)
    
    if sede_id:
        conditions.append("e.sede_id = %s")
        params.append(sede_id)
    
    if estado_evento:
        conditions.append("e.estado = %s")
        params.append(estado_evento)
    
    if precio_min is not None:
        conditions.append("e.precio_entrada >= %s")
        params.append(precio_min)
    
    if precio_max is not None:
        conditions.append("e.precio_entrada <= %s")
        params.append(precio_max)
    
    # Construir la cláusula WHERE
    where_clause = " AND ".join(conditions) if conditions else "1=1"
    
    # Consulta SQL
    query = f"""
    SELECT 
        e.evento_id, 
        e.titulo,
        e.fecha_inicio,
        e.fecha_fin,
        s.nombre AS sede_nombre,
        e.capacidad_maxima,
        COUNT(en.entrada_id) AS entradas_vendidas,
        SUM(CASE WHEN en.check_in = TRUE THEN 1 ELSE 0 END) AS asistentes,
        ROUND((SUM(CASE WHEN en.check_in = TRUE THEN 1 ELSE 0 END)::numeric / 
               NULLIF(COUNT(en.entrada_id), 0)::numeric) * 100, 2) AS porcentaje_asistencia,
        SUM(en.precio_pagado) AS ingresos_totales,
        ROUND(AVG(CASE WHEN c.calificacion IS NOT NULL THEN c.calificacion ELSE NULL END), 2) AS calificacion_promedio,
        COUNT(DISTINCT c.comentario_id) AS num_comentarios,
        ARRAY_AGG(DISTINCT cat.nombre) FILTER (WHERE cat.nombre IS NOT NULL) AS categorias
    FROM 
        eventos e
    LEFT JOIN 
        entradas en ON e.evento_id = en.evento_id
    LEFT JOIN 
        sedes s ON e.sede_id = s.sede_id
    LEFT JOIN 
        comentarios c ON e.evento_id = c.evento_id
    LEFT JOIN 
        evento_categorias ec ON e.evento_id = ec.evento_id
    LEFT JOIN 
        categorias cat ON ec.categoria_id = cat.categoria_id
    WHERE 
        {where_clause}
    GROUP BY 
        e.evento_id, s.nombre
    ORDER BY 
        e.fecha_inicio DESC
    """
    
    return execute_query(query, params)

# --------------------------------
# REPORTE 2: Popularidad de Categorías
# --------------------------------
def get_category_popularity(fecha_inicio=None, fecha_fin=None, calificacion_min=None, 
                          calificacion_max=None, sede_id=None, precio_min=None, precio_max=None):
    """
    Análisis de qué categorías culturales atraen más público.
    
    Filtros:
        fecha_inicio: Fecha de inicio del rango a consultar
        fecha_fin: Fecha de fin del rango a consultar
        calificacion_min: Calificación mínima de los eventos
        calificacion_max: Calificación máxima de los eventos
        sede_id: ID de la sede donde se realizan los eventos
        precio_min: Precio mínimo de entrada
        precio_max: Precio máximo de entrada
    """
    params = []
    conditions = []
    
    # Construir condiciones según los filtros proporcionados
    if fecha_inicio:
        conditions.append("e.fecha_inicio >= %s")
        params.append(fecha_inicio)
    
    if fecha_fin:
        conditions.append("e.fecha_fin <= %s")
        params.append(fecha_fin)
    
    if calificacion_min is not None:
        conditions.append("COALESCE(AVG(co.calificacion), 0) >= %s")
        params.append(calificacion_min)
    
    if calificacion_max is not None:
        conditions.append("COALESCE(AVG(co.calificacion), 0) <= %s")
        params.append(calificacion_max)
    
    if sede_id:
        conditions.append("e.sede_id = %s")
        params.append(sede_id)
    
    if precio_min is not None:
        conditions.append("e.precio_entrada >= %s")
        params.append(precio_min)
    
    if precio_max is not None:
        conditions.append("e.precio_entrada <= %s")
        params.append(precio_max)
    
    # Construir la cláusula WHERE
    where_clause = " AND ".join(conditions) if conditions else "1=1"
    
    # Consulta SQL
    query = f"""
    SELECT 
        c.categoria_id,
        c.nombre AS categoria_nombre,
        c.color,
        COUNT(DISTINCT e.evento_id) AS total_eventos,
        COUNT(DISTINCT en.usuario_id) AS total_asistentes,
        SUM(en.precio_pagado) AS ingresos_totales,
        ROUND(AVG(COALESCE(co.calificacion, 0)), 2) AS calificacion_promedio,
        COUNT(DISTINCT CASE WHEN e.fecha_inicio > CURRENT_TIMESTAMP THEN e.evento_id END) AS eventos_futuros,
        COUNT(DISTINCT CASE WHEN e.fecha_fin < CURRENT_TIMESTAMP THEN e.evento_id END) AS eventos_pasados
    FROM 
        categorias c
    JOIN 
        evento_categorias ec ON c.categoria_id = ec.categoria_id
    JOIN 
        eventos e ON ec.evento_id = e.evento_id
    LEFT JOIN 
        entradas en ON e.evento_id = en.evento_id AND en.estado != 'cancelada'
    LEFT JOIN 
        comentarios co ON e.evento_id = co.evento_id
    WHERE 
        {where_clause}
    GROUP BY 
        c.categoria_id
    ORDER BY 
        total_asistentes DESC
    """
    
    return execute_query(query, params)

# --------------------------------
# REPORTE 3: Rendimiento de Sedes
# --------------------------------
def get_venue_performance(fecha_inicio=None, fecha_fin=None, categoria_id=None, 
                        capacidad_min=None, capacidad_max=None, accesibilidad=None, 
                        tasa_ocupacion_min=None):
    """
    Comparación de ocupación, ingresos y eventos por sede.
    
    Filtros:
        fecha_inicio: Fecha de inicio del rango a consultar
        fecha_fin: Fecha de fin del rango a consultar
        categoria_id: ID de la categoría de eventos
        capacidad_min: Capacidad mínima de la sede
        capacidad_max: Capacidad máxima de la sede
        accesibilidad: Filtrar por sedes con accesibilidad (True/False)
        tasa_ocupacion_min: Tasa de ocupación mínima
    """
    params = []
    event_conditions = []
    venue_conditions = []
    
    # Construir condiciones según los filtros proporcionados
    if fecha_inicio:
        event_conditions.append("e.fecha_inicio >= %s")
        params.append(fecha_inicio)
    
    if fecha_fin:
        event_conditions.append("e.fecha_fin <= %s")
        params.append(fecha_fin)
    
    if categoria_id:
        event_conditions.append("EXISTS (SELECT 1 FROM evento_categorias ec WHERE ec.evento_id = e.evento_id AND ec.categoria_id = %s)")
        params.append(categoria_id)
    
    if capacidad_min is not None:
        venue_conditions.append("s.capacidad_maxima >= %s")
        params.append(capacidad_min)
    
    if capacidad_max is not None:
        venue_conditions.append("s.capacidad_maxima <= %s")
        params.append(capacidad_max)
    
    if accesibilidad is not None:
        venue_conditions.append("s.accesibilidad = %s")
        params.append(accesibilidad)
    
    # Construir las cláusulas WHERE
    event_where_clause = " AND ".join(event_conditions) if event_conditions else "1=1"
    venue_where_clause = " AND ".join(venue_conditions) if venue_conditions else "1=1"
    
    # Consulta SQL
    query = f"""
    WITH event_stats AS (
        SELECT 
            e.sede_id,
            COUNT(DISTINCT e.evento_id) AS total_eventos,
            COUNT(DISTINCT CASE WHEN e.fecha_inicio > CURRENT_TIMESTAMP THEN e.evento_id END) AS eventos_futuros,
            COUNT(DISTINCT CASE WHEN e.fecha_fin < CURRENT_TIMESTAMP THEN e.evento_id END) AS eventos_pasados,
            COUNT(DISTINCT en.entrada_id) AS entradas_vendidas,
            SUM(CASE WHEN en.check_in = TRUE THEN 1 ELSE 0 END) AS asistentes,
            SUM(en.precio_pagado) AS ingresos_totales,
            ROUND(AVG(COALESCE(co.calificacion, 0)), 2) AS calificacion_promedio
        FROM 
            eventos e
        LEFT JOIN 
            entradas en ON e.evento_id = en.evento_id AND en.estado != 'cancelada'
        LEFT JOIN 
            comentarios co ON e.evento_id = co.evento_id
        WHERE 
            {event_where_clause}
        GROUP BY 
            e.sede_id
    )
    SELECT 
        s.sede_id,
        s.nombre AS sede_nombre,
        s.direccion,
        s.capacidad_maxima,
        s.accesibilidad,
        s.horario_apertura,
        s.horario_cierre,
        COALESCE(es.total_eventos, 0) AS total_eventos,
        COALESCE(es.eventos_futuros, 0) AS eventos_futuros,
        COALESCE(es.eventos_pasados, 0) AS eventos_pasados,
        COALESCE(es.entradas_vendidas, 0) AS entradas_vendidas,
        COALESCE(es.asistentes, 0) AS asistentes,
        COALESCE(es.ingresos_totales, 0) AS ingresos_totales,
        es.calificacion_promedio,
        ROUND((COALESCE(es.asistentes, 0)::numeric / NULLIF(COALESCE(es.entradas_vendidas, 0), 0)::numeric) * 100, 2) AS tasa_asistencia,
        ss.salas_info
    FROM 
        sedes s
    LEFT JOIN 
        event_stats es ON s.sede_id = es.sede_id
    LEFT JOIN LATERAL (
        SELECT 
            json_agg(json_build_object('nombre_sala', ss.nombre_sala, 'capacidad', ss.capacidad)) AS salas_info
        FROM 
            salas_sedes ss
        WHERE 
            ss.sede_id = s.sede_id
    ) ss ON true
    WHERE 
        {venue_where_clause}
    """
    
    result = execute_query(query, params)
    
    # Filtrar por tasa de ocupación mínima si se especificó
    if tasa_ocupacion_min is not None:
        result = [r for r in result if r['tasa_asistencia'] is not None and r['tasa_asistencia'] >= float(tasa_ocupacion_min)]
    
    return result

# --------------------------------
# REPORTE 4: Análisis Temporal de Eventos
# --------------------------------
def get_temporal_analysis(periodo='mensual', fecha_inicio=None, fecha_fin=None, 
                        categoria_id=None, sede_id=None, tipo_usuario=None, precio_min=None, precio_max=None):
    """
    Tendencias de asistencia, precio y satisfacción en el tiempo.
    
    Filtros:
        periodo: 'diario', 'semanal', 'mensual', 'trimestral' o 'anual'
        fecha_inicio: Fecha de inicio del rango a consultar
        fecha_fin: Fecha de fin del rango a consultar
        categoria_id: ID de la categoría de eventos
        sede_id: ID de la sede donde se realizan los eventos
        tipo_usuario: Tipo de usuario ('cliente', 'organizador', etc.)
        precio_min: Precio mínimo de entrada
        precio_max: Precio máximo de entrada
    """
    # Definir el formato de agrupación según el periodo
    if periodo == 'diario':
        date_format = "DATE_TRUNC('day', e.fecha_inicio)"
        label_format = "TO_CHAR(DATE_TRUNC('day', e.fecha_inicio), 'YYYY-MM-DD')"
    elif periodo == 'semanal':
        date_format = "DATE_TRUNC('week', e.fecha_inicio)"
        label_format = "TO_CHAR(DATE_TRUNC('week', e.fecha_inicio), 'YYYY-\"W\"IW')"
    elif periodo == 'trimestral':
        date_format = "DATE_TRUNC('quarter', e.fecha_inicio)"
        label_format = "TO_CHAR(DATE_TRUNC('quarter', e.fecha_inicio), 'YYYY-\"Q\"Q')"
    elif periodo == 'anual':
        date_format = "DATE_TRUNC('year', e.fecha_inicio)"
        label_format = "TO_CHAR(DATE_TRUNC('year', e.fecha_inicio), 'YYYY')"
    else:  # mensual por defecto
        date_format = "DATE_TRUNC('month', e.fecha_inicio)"
        label_format = "TO_CHAR(DATE_TRUNC('month', e.fecha_inicio), 'YYYY-MM')"
    
    params = []
    conditions = []
    
    # Construir condiciones según los filtros proporcionados
    if fecha_inicio:
        conditions.append("e.fecha_inicio >= %s")
        params.append(fecha_inicio)
    
    if fecha_fin:
        conditions.append("e.fecha_fin <= %s")
        params.append(fecha_fin)
    
    if categoria_id:
        conditions.append("EXISTS (SELECT 1 FROM evento_categorias ec WHERE ec.evento_id = e.evento_id AND ec.categoria_id = %s)")
        params.append(categoria_id)
    
    if sede_id:
        conditions.append("e.sede_id = %s")
        params.append(sede_id)
    
    if precio_min is not None:
        conditions.append("e.precio_entrada >= %s")
        params.append(precio_min)
    
    if precio_max is not None:
        conditions.append("e.precio_entrada <= %s")
        params.append(precio_max)
    
    if tipo_usuario:
        conditions.append("u.tipo_usuario = %s")
        params.append(tipo_usuario)
    
    # Construir la cláusula WHERE
    where_clause = " AND ".join(conditions) if conditions else "1=1"
    
    # Consulta SQL
    query = f"""
    SELECT 
        {date_format} AS periodo_fecha,
        {label_format} AS periodo_label,
        COUNT(DISTINCT e.evento_id) AS total_eventos,
        COUNT(DISTINCT en.entrada_id) AS entradas_vendidas,
        SUM(CASE WHEN en.check_in = TRUE THEN 1 ELSE 0 END) AS asistentes,
        ROUND((SUM(CASE WHEN en.check_in = TRUE THEN 1 ELSE 0 END)::numeric / 
               NULLIF(COUNT(DISTINCT en.entrada_id), 0)::numeric) * 100, 2) AS porcentaje_asistencia,
        SUM(en.precio_pagado) AS ingresos_totales,
        ROUND(AVG(e.precio_entrada), 2) AS precio_promedio,
        ROUND(AVG(COALESCE(co.calificacion, 0)), 2) AS calificacion_promedio,
        COUNT(DISTINCT u.usuario_id) AS usuarios_unicos
    FROM 
        eventos e
    LEFT JOIN 
        entradas en ON e.evento_id = en.evento_id AND en.estado != 'cancelada'
    LEFT JOIN 
        usuarios u ON en.usuario_id = u.usuario_id
    LEFT JOIN 
        comentarios co ON e.evento_id = co.evento_id
    WHERE 
        {where_clause}
    GROUP BY 
        periodo_fecha, periodo_label
    ORDER BY 
        periodo_fecha
    """
    
    return execute_query(query, params)

# --------------------------------
# REPORTE 5: Perfil de Usuarios y Preferencias
# --------------------------------
def get_user_preferences(edad_min=None, edad_max=None, fecha_registro_min=None, 
                       fecha_registro_max=None, interes=None, num_eventos_min=None, 
                       categoria_id=None, sede_id=None):
    """
    Segmentación de usuarios por intereses y asistencia.
    
    Filtros:
        edad_min: Edad mínima de los usuarios
        edad_max: Edad máxima de los usuarios
        fecha_registro_min: Fecha mínima de registro de usuarios
        fecha_registro_max: Fecha máxima de registro de usuarios
        interes: Interés específico de los usuarios
        num_eventos_min: Número mínimo de eventos asistidos
        categoria_id: ID de la categoría de eventos
        sede_id: ID de la sede donde se realizan los eventos
    """
    params = []
    conditions = []
    
    # Construir condiciones según los filtros proporcionados
    if edad_min is not None:
        conditions.append("DATE_PART('year', AGE(CURRENT_DATE, u.fecha_nacimiento)) >= %s")
        params.append(edad_min)
    
    if edad_max is not None:
        conditions.append("DATE_PART('year', AGE(CURRENT_DATE, u.fecha_nacimiento)) <= %s")
        params.append(edad_max)
    
    if fecha_registro_min:
        conditions.append("u.fecha_creacion >= %s")
        params.append(fecha_registro_min)
    
    if fecha_registro_max:
        conditions.append("u.fecha_creacion <= %s")
        params.append(fecha_registro_max)
    
    if interes:
        conditions.append("EXISTS (SELECT 1 FROM intereses_usuarios iu WHERE iu.usuario_id = u.usuario_id AND iu.interes ILIKE %s)")
        params.append(f"%{interes}%")
    
    if categoria_id:
        conditions.append("""
            EXISTS (
                SELECT 1 
                FROM entradas en 
                JOIN eventos ev ON en.evento_id = ev.evento_id
                JOIN evento_categorias ec ON ev.evento_id = ec.evento_id
                WHERE en.usuario_id = u.usuario_id AND ec.categoria_id = %s
            )
        """)
        params.append(categoria_id)
    
    if sede_id:
        conditions.append("""
            EXISTS (
                SELECT 1 
                FROM entradas en 
                JOIN eventos ev ON en.evento_id = ev.evento_id
                WHERE en.usuario_id = u.usuario_id AND ev.sede_id = %s
            )
        """)
        params.append(sede_id)
    
    # Construir la cláusula WHERE
    where_clause = " AND ".join(conditions) if conditions else "1=1"
    
    # Consulta SQL para obtener datos de usuarios
    query = f"""
    WITH user_event_stats AS (
        SELECT 
            u.usuario_id,
            COUNT(DISTINCT en.entrada_id) AS total_entradas,
            COUNT(DISTINCT CASE WHEN en.check_in = TRUE THEN en.entrada_id END) AS eventos_asistidos,
            SUM(en.precio_pagado) AS gasto_total,
            STRING_AGG(DISTINCT c.nombre, ', ') AS categorias_favoritas
        FROM 
            usuarios u
        LEFT JOIN 
            entradas en ON u.usuario_id = en.usuario_id
        LEFT JOIN 
            eventos e ON en.evento_id = e.evento_id
        LEFT JOIN 
            evento_categorias ec ON e.evento_id = ec.evento_id
        LEFT JOIN 
            categorias c ON ec.categoria_id = c.categoria_id
        GROUP BY 
            u.usuario_id
    )
    SELECT 
        u.usuario_id,
        u.nombre,
        u.apellido,
        u.email,
        u.fecha_nacimiento,
        DATE_PART('year', AGE(CURRENT_DATE, u.fecha_nacimiento)) AS edad,
        u.fecha_creacion,
        ues.total_entradas,
        ues.eventos_asistidos,
        ues.gasto_total,
        ues.categorias_favoritas,
        ui.intereses,
        ROUND((ues.eventos_asistidos::numeric / NULLIF(ues.total_entradas, 0)::numeric) * 100, 2) AS tasa_asistencia
    FROM 
        usuarios u
    LEFT JOIN 
        user_event_stats ues ON u.usuario_id = ues.usuario_id
    LEFT JOIN LATERAL (
        SELECT 
            array_agg(iu.interes) AS intereses
        FROM 
            intereses_usuarios iu
        WHERE 
            iu.usuario_id = u.usuario_id
    ) ui ON true
    WHERE 
        u.tipo_usuario = 'cliente'
        AND {where_clause}
    """
    
    result = execute_query(query, params)
    
    # Filtrar por número mínimo de eventos asistidos si se especificó
    if num_eventos_min is not None:
        result = [r for r in result if r['eventos_asistidos'] is not None and r['eventos_asistidos'] >= int(num_eventos_min)]
    
    return result

# --------------------------------
# Funciones auxiliares para obtener datos de filtros
# --------------------------------
def get_filter_options():
    """Obtiene las opciones disponibles para los filtros de los reportes."""
    options = {}
    
    # Categorías
    query_categorias = "SELECT categoria_id, nombre FROM categorias ORDER BY nombre"
    options['categorias'] = execute_query(query_categorias)
    
    # Sedes
    query_sedes = "SELECT sede_id, nombre FROM sedes ORDER BY nombre"
    options['sedes'] = execute_query(query_sedes)
    
    # Estados de eventos
    query_estados = "SELECT unnest(enum_range(NULL::estado_evento)) AS estado"
    options['estados_eventos'] = execute_query(query_estados)
    
    # Tipos de usuario
    query_tipos_usuario = "SELECT unnest(enum_range(NULL::tipo_usuario)) AS tipo"
    options['tipos_usuario'] = execute_query(query_tipos_usuario)
    
    # Intereses
    query_intereses = "SELECT DISTINCT interes FROM intereses_usuarios ORDER BY interes"
    options['intereses'] = execute_query(query_intereses)
    
    return options

def get_dashboard_stats():
    """Obtiene estadísticas generales para el dashboard."""
    stats = {}
    
    # Total de eventos
    query_eventos = """
    SELECT 
        COUNT(*) AS total_eventos,
        COUNT(CASE WHEN estado = 'programado' THEN 1 END) AS eventos_programados,
        COUNT(CASE WHEN estado = 'en_curso' THEN 1 END) AS eventos_en_curso,
        COUNT(CASE WHEN estado = 'finalizado' THEN 1 END) AS eventos_finalizados
    FROM eventos
    """
    eventos_stats = execute_query(query_eventos)[0]
    stats['eventos'] = eventos_stats
    
    # Total de entradas y asistencias
    query_entradas = """
    SELECT 
        COUNT(*) AS total_entradas,
        COUNT(CASE WHEN check_in = TRUE THEN 1 END) AS total_asistencias,
        SUM(precio_pagado) AS ingresos_totales
    FROM entradas
    """
    entradas_stats = execute_query(query_entradas)[0]
    stats['entradas'] = entradas_stats
    
    # Categorías más populares
    query_categorias = """
    SELECT 
        c.nombre AS categoria,
        c.color,
        COUNT(DISTINCT en.entrada_id) AS total_entradas
    FROM 
        categorias c
    JOIN 
        evento_categorias ec ON c.categoria_id = ec.categoria_id
    JOIN 
        eventos e ON ec.evento_id = e.evento_id
    JOIN 
        entradas en ON e.evento_id = en.evento_id
    GROUP BY 
        c.categoria_id
    ORDER BY 
        total_entradas DESC
    LIMIT 5
    """
    stats['categorias_populares'] = execute_query(query_categorias)
    
    # Próximos eventos
    query_proximos = """
    SELECT 
        evento_id,
        titulo,
        fecha_inicio,
        (SELECT nombre FROM sedes WHERE sede_id = eventos.sede_id) AS sede_nombre,
        capacidad_maxima,
        precio_entrada,
        (
            SELECT COUNT(*) 
            FROM entradas 
            WHERE evento_id = eventos.evento_id AND estado != 'cancelada'
        ) AS entradas_vendidas
    FROM 
        eventos
    WHERE 
        fecha_inicio > CURRENT_TIMESTAMP AND
        estado = 'programado' AND
        publicado = TRUE
    ORDER BY 
        fecha_inicio
    LIMIT 5
    """
    stats['proximos_eventos'] = execute_query(query_proximos)
    
    return stats