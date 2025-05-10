-- =============================================================================================
-- Script de Creación de Base de Datos: Sistema de Gestión de Eventos Culturales y Asistencia
-- =============================================================================================

-- Tipos ENUM personalizados
CREATE TYPE estado_evento AS ENUM ('programado', 'en_curso', 'finalizado', 'cancelado', 'pospuesto');
CREATE TYPE tipo_usuario AS ENUM ('administrador', 'organizador', 'artista', 'cliente');
CREATE TYPE estado_entrada AS ENUM ('reservada', 'pagada', 'cancelada', 'utilizada');
CREATE TYPE tipo_archivo AS ENUM ('imagen', 'video', 'audio', 'documento', 'otro');
CREATE TYPE tipo_recurso AS ENUM ('equipo_sonido', 'equipo_iluminacion', 'mobiliario', 'decoracion', 'seguridad', 'personal');
CREATE TYPE tipo_patrocinador AS ENUM ('gubernamental', 'privado', 'ong', 'educativo', 'medios');
CREATE TYPE tipo_recordatorio AS ENUM ('email', 'sms', 'app');

-- Tabla de Usuarios
CREATE TABLE usuarios (
    usuario_id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    telefono VARCHAR(20),
    fecha_nacimiento DATE,
    password VARCHAR(255) NOT NULL,
    tipo_usuario tipo_usuario NOT NULL DEFAULT 'cliente',
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- Tabla de Intereses de Usuarios (Atributo multivaluado)
CREATE TABLE intereses_usuarios (
    usuario_id INTEGER REFERENCES usuarios(usuario_id) ON DELETE CASCADE,
    interes VARCHAR(100) NOT NULL,
    fecha_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (usuario_id, interes)
);

-- Tabla de Sedes
CREATE TABLE sedes (
    sede_id SERIAL PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    direccion VARCHAR(255) NOT NULL,
    capacidad_maxima INTEGER NOT NULL CHECK (capacidad_maxima > 0),
    ubicacion_gps POINT,
    descripcion TEXT,
    accesibilidad BOOLEAN NOT NULL DEFAULT FALSE,
    telefono VARCHAR(20),
    horario_apertura TIME NOT NULL,
    horario_cierre TIME NOT NULL,
    CONSTRAINT chk_horario CHECK (horario_apertura < horario_cierre)
);

-- Tabla de Salas en Sedes (Atributo multivaluado)
CREATE TABLE salas_sedes (
    sede_id INTEGER REFERENCES sedes(sede_id) ON DELETE CASCADE,
    nombre_sala VARCHAR(100) NOT NULL,
    capacidad INTEGER NOT NULL CHECK (capacidad > 0),
    descripcion TEXT,
    PRIMARY KEY (sede_id, nombre_sala)
);

-- Tabla de Categorías
CREATE TABLE categorias (
    categoria_id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT,
    color VARCHAR(7) CHECK (color ~* '^#[0-9A-F]{6}$')
);

-- Tabla de Artistas
CREATE TABLE artistas (
    artista_id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    biografia TEXT,
    nacionalidad VARCHAR(100),
    fecha_inicio_carrera DATE,
    sitio_web VARCHAR(255),
    redes_sociales JSONB
);

-- Tabla de Especialidades de Artistas (Atributo multivaluado)
CREATE TABLE especialidades_artistas (
    artista_id INTEGER REFERENCES artistas(artista_id) ON DELETE CASCADE,
    especialidad VARCHAR(100) NOT NULL,
    fecha_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (artista_id, especialidad)
);

-- Tabla de Patrocinadores
CREATE TABLE patrocinadores (
    patrocinador_id SERIAL PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    tipo tipo_patrocinador NOT NULL,
    contacto_nombre VARCHAR(200),
    contacto_email VARCHAR(150),
    contacto_telefono VARCHAR(20),
    descripcion TEXT
);

-- Tabla de Recursos
CREATE TABLE recursos (
    recurso_id SERIAL PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    tipo tipo_recurso NOT NULL,
    descripcion TEXT,
    cantidad_disponible INTEGER NOT NULL DEFAULT 0 CHECK (cantidad_disponible >= 0),
    requiere_reserva BOOLEAN NOT NULL DEFAULT TRUE
);

-- Tabla de Eventos
CREATE TABLE eventos (
    evento_id SERIAL PRIMARY KEY,
    sede_id INTEGER NOT NULL REFERENCES sedes(sede_id) ON DELETE RESTRICT,
    organizador_id INTEGER NOT NULL REFERENCES usuarios(usuario_id) ON DELETE RESTRICT,
    titulo VARCHAR(200) NOT NULL,
    descripcion TEXT,
    fecha_inicio TIMESTAMP NOT NULL,
    fecha_fin TIMESTAMP NOT NULL,
    capacidad_maxima INTEGER NOT NULL CHECK (capacidad_maxima > 0),
    precio_entrada DECIMAL(10,2) NOT NULL DEFAULT 0.00 CHECK (precio_entrada >= 0),
    publicado BOOLEAN NOT NULL DEFAULT FALSE,
    estado estado_evento NOT NULL DEFAULT 'programado',
    fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_publicacion TIMESTAMP,
    CONSTRAINT chk_fechas CHECK (fecha_inicio < fecha_fin),
    CONSTRAINT chk_fecha_publicacion CHECK (fecha_publicacion IS NULL OR (fecha_publicacion <= fecha_inicio))
);

-- Tabla de Relación Eventos - Categorías
CREATE TABLE evento_categorias (
    evento_id INTEGER REFERENCES eventos(evento_id) ON DELETE CASCADE,
    categoria_id INTEGER REFERENCES categorias(categoria_id) ON DELETE RESTRICT,
    PRIMARY KEY (evento_id, categoria_id)
);

-- Tabla de Relación Eventos - Artistas
CREATE TABLE evento_artistas (
    evento_id INTEGER REFERENCES eventos(evento_id) ON DELETE CASCADE,
    artista_id INTEGER REFERENCES artistas(artista_id) ON DELETE RESTRICT,
    rol VARCHAR(100) NOT NULL,
    hora_inicio_participacion TIMESTAMP NOT NULL,
    hora_fin_participacion TIMESTAMP NOT NULL,
    PRIMARY KEY (evento_id, artista_id),
    CONSTRAINT chk_horas_participacion CHECK (hora_inicio_participacion < hora_fin_participacion)
);

-- Tabla de Relación Eventos - Patrocinadores
CREATE TABLE evento_patrocinadores (
    evento_id INTEGER REFERENCES eventos(evento_id) ON DELETE CASCADE,
    patrocinador_id INTEGER REFERENCES patrocinadores(patrocinador_id) ON DELETE RESTRICT,
    monto_patrocinio DECIMAL(12,2) CHECK (monto_patrocinio >= 0),
    beneficios TEXT,
    acuerdos TEXT,
    PRIMARY KEY (evento_id, patrocinador_id)
);

-- Tabla de Relación Eventos - Recursos
CREATE TABLE evento_recursos (
    evento_id INTEGER REFERENCES eventos(evento_id) ON DELETE CASCADE,
    recurso_id INTEGER REFERENCES recursos(recurso_id) ON DELETE RESTRICT,
    cantidad_asignada INTEGER NOT NULL CHECK (cantidad_asignada > 0),
    fecha_asignacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (evento_id, recurso_id)
);

-- Tabla de Entradas
CREATE TABLE entradas (
    entrada_id SERIAL PRIMARY KEY,
    evento_id INTEGER NOT NULL REFERENCES eventos(evento_id) ON DELETE CASCADE,
    usuario_id INTEGER NOT NULL REFERENCES usuarios(usuario_id) ON DELETE RESTRICT,
    codigo_entrada VARCHAR(20) NOT NULL UNIQUE,
    fecha_compra TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    precio_pagado DECIMAL(10,2) NOT NULL CHECK (precio_pagado >= 0),
    metodo_pago VARCHAR(50),
    estado estado_entrada NOT NULL DEFAULT 'reservada',
    check_in BOOLEAN NOT NULL DEFAULT FALSE,
    fecha_check_in TIMESTAMP
);

-- Tabla de Comentarios
CREATE TABLE comentarios (
    comentario_id SERIAL PRIMARY KEY,
    evento_id INTEGER NOT NULL REFERENCES eventos(evento_id) ON DELETE CASCADE,
    usuario_id INTEGER NOT NULL REFERENCES usuarios(usuario_id) ON DELETE CASCADE,
    contenido TEXT NOT NULL,
    calificacion INTEGER CHECK (calificacion BETWEEN 1 AND 5),
    fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    aprobado BOOLEAN NOT NULL DEFAULT FALSE
);

-- Tabla de Recordatorios
CREATE TABLE recordatorios (
    recordatorio_id SERIAL PRIMARY KEY,
    evento_id INTEGER NOT NULL REFERENCES eventos(evento_id) ON DELETE CASCADE,
    usuario_id INTEGER NOT NULL REFERENCES usuarios(usuario_id) ON DELETE CASCADE,
    tipo tipo_recordatorio NOT NULL DEFAULT 'email',
    fecha_envio TIMESTAMP,
    enviado BOOLEAN NOT NULL DEFAULT FALSE,
    fecha_programada TIMESTAMP NOT NULL
);

-- Tabla de Archivos de Eventos
CREATE TABLE archivos_eventos (
    archivo_id SERIAL PRIMARY KEY,
    evento_id INTEGER NOT NULL REFERENCES eventos(evento_id) ON DELETE CASCADE,
    tipo tipo_archivo NOT NULL,
    url VARCHAR(255) NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    fecha_subida TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    formato VARCHAR(10),
    tamano_kb INTEGER CHECK (tamano_kb > 0)
);

-- =============================================================================================
-- VISTAS
-- =============================================================================================

-- Vista de próximos eventos
CREATE OR REPLACE VIEW v_proximos_eventos AS
SELECT e.evento_id, e.titulo, e.descripcion, e.fecha_inicio, e.fecha_fin, 
       e.capacidad_maxima, e.precio_entrada, s.nombre AS sede_nombre, s.direccion,
       ARRAY_AGG(DISTINCT c.nombre) AS categorias,
       COUNT(DISTINCT en.entrada_id) AS entradas_vendidas,
       (e.capacidad_maxima - COUNT(DISTINCT en.entrada_id)) AS entradas_disponibles
FROM eventos e
JOIN sedes s ON e.sede_id = s.sede_id
LEFT JOIN evento_categorias ec ON e.evento_id = ec.evento_id
LEFT JOIN categorias c ON ec.categoria_id = c.categoria_id
LEFT JOIN entradas en ON e.evento_id = en.evento_id AND en.estado != 'cancelada'
WHERE e.fecha_inicio > CURRENT_TIMESTAMP
  AND e.estado NOT IN ('cancelado', 'pospuesto')
  AND e.publicado = TRUE
GROUP BY e.evento_id, s.sede_id;

-- Vista de asistencia por evento
CREATE OR REPLACE VIEW v_asistencia_eventos AS
SELECT e.evento_id, e.titulo, e.fecha_inicio, s.nombre AS sede_nombre,
       COUNT(DISTINCT en.entrada_id) AS total_entradas_vendidas,
       SUM(CASE WHEN en.check_in = TRUE THEN 1 ELSE 0 END) AS total_asistentes,
       ROUND((SUM(CASE WHEN en.check_in = TRUE THEN 1 ELSE 0 END)::numeric / 
             NULLIF(COUNT(DISTINCT en.entrada_id), 0)::numeric) * 100, 2) AS porcentaje_asistencia,
       SUM(en.precio_pagado) AS ingresos_totales
FROM eventos e
JOIN sedes s ON e.sede_id = s.sede_id
LEFT JOIN entradas en ON e.evento_id = en.evento_id AND en.estado != 'cancelada'
GROUP BY e.evento_id, s.nombre;

-- Vista de eventos por categoría
CREATE OR REPLACE VIEW v_eventos_por_categoria AS
SELECT c.categoria_id, c.nombre, COUNT(DISTINCT ec.evento_id) AS total_eventos,
       COUNT(DISTINCT CASE WHEN e.fecha_inicio > CURRENT_TIMESTAMP THEN e.evento_id END) AS eventos_futuros,
       COUNT(DISTINCT CASE WHEN e.fecha_inicio <= CURRENT_TIMESTAMP AND e.fecha_fin >= CURRENT_TIMESTAMP THEN e.evento_id END) AS eventos_en_curso,
       COUNT(DISTINCT CASE WHEN e.fecha_fin < CURRENT_TIMESTAMP THEN e.evento_id END) AS eventos_finalizados,
       ROUND(AVG(COALESCE(co.calificacion, 0)), 2) AS calificacion_promedio
FROM categorias c
LEFT JOIN evento_categorias ec ON c.categoria_id = ec.categoria_id
LEFT JOIN eventos e ON ec.evento_id = e.evento_id
LEFT JOIN comentarios co ON e.evento_id = co.evento_id
GROUP BY c.categoria_id;

-- =============================================================================================
-- FUNCIONES
-- =============================================================================================

-- Función para calcular el total de entradas disponibles (Atributo derivado)
CREATE OR REPLACE FUNCTION calcular_entradas_disponibles(p_evento_id INTEGER)
RETURNS INTEGER AS $$
DECLARE
    v_capacidad INTEGER;
    v_entradas_vendidas INTEGER;
BEGIN
    -- Obtener la capacidad máxima del evento
    SELECT capacidad_maxima INTO v_capacidad
    FROM eventos
    WHERE evento_id = p_evento_id;
    
    -- Obtener el número de entradas vendidas no canceladas
    SELECT COUNT(*) INTO v_entradas_vendidas
    FROM entradas
    WHERE evento_id = p_evento_id
    AND estado != 'cancelada';
    
    -- Retornar el número de entradas disponibles
    RETURN v_capacidad - v_entradas_vendidas;
END;
$$ LANGUAGE plpgsql;

-- Función para calcular ingresos por evento (Atributo derivado)
CREATE OR REPLACE FUNCTION calcular_ingresos_evento(p_evento_id INTEGER)
RETURNS DECIMAL AS $$
DECLARE
    v_ingresos DECIMAL(12,2);
BEGIN
    -- Sumar el precio pagado de todas las entradas no canceladas
    SELECT COALESCE(SUM(precio_pagado), 0) INTO v_ingresos
    FROM entradas
    WHERE evento_id = p_evento_id
    AND estado != 'cancelada';
    
    RETURN v_ingresos;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================================
-- TRIGGERS
-- =============================================================================================

-- Trigger 1: Verificar disponibilidad de recursos al asignarlos a un evento
CREATE OR REPLACE FUNCTION verificar_disponibilidad_recursos()
RETURNS TRIGGER AS $$
DECLARE
    v_disponible INTEGER;
    v_total_asignado INTEGER;
BEGIN
    -- Obtener cantidad disponible del recurso
    SELECT cantidad_disponible INTO v_disponible
    FROM recursos
    WHERE recurso_id = NEW.recurso_id;
    
    -- Calcular el total asignado a otros eventos en fechas superpuestas
    SELECT COALESCE(SUM(er.cantidad_asignada), 0) INTO v_total_asignado
    FROM evento_recursos er
    JOIN eventos e ON er.evento_id = e.evento_id
    WHERE er.recurso_id = NEW.recurso_id
    AND er.evento_id != NEW.evento_id
    AND e.fecha_inicio <= (SELECT fecha_fin FROM eventos WHERE evento_id = NEW.evento_id)
    AND e.fecha_fin >= (SELECT fecha_inicio FROM eventos WHERE evento_id = NEW.evento_id);
    
    -- Verificar si hay suficientes recursos disponibles
    IF (v_disponible - v_total_asignado) < NEW.cantidad_asignada THEN
        RAISE EXCEPTION 'No hay suficientes recursos disponibles para la fecha del evento. Disponible: %, Solicitado: %', 
                        (v_disponible - v_total_asignado), NEW.cantidad_asignada;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_verificar_recursos
BEFORE INSERT OR UPDATE ON evento_recursos
FOR EACH ROW
EXECUTE FUNCTION verificar_disponibilidad_recursos();

-- Trigger 2: Actualizar estado del evento automáticamente según las fechas
CREATE OR REPLACE FUNCTION actualizar_estado_evento()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.fecha_inicio <= CURRENT_TIMESTAMP AND NEW.fecha_fin >= CURRENT_TIMESTAMP THEN
        NEW.estado = 'en_curso';
    ELSIF NEW.fecha_fin < CURRENT_TIMESTAMP THEN
        NEW.estado = 'finalizado';
    ELSE
        NEW.estado = 'programado';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_actualizar_estado_evento
BEFORE INSERT OR UPDATE OF fecha_inicio, fecha_fin ON eventos
FOR EACH ROW
EXECUTE FUNCTION actualizar_estado_evento();

-- Trigger 3: Validar y generar código único para entradas
CREATE OR REPLACE FUNCTION generar_codigo_entrada()
RETURNS TRIGGER AS $$
DECLARE
    v_evento_info RECORD;
    v_codigo VARCHAR(20);
    v_disponibilidad INTEGER;
BEGIN
    -- Obtener información del evento
    SELECT evento_id, capacidad_maxima INTO v_evento_info
    FROM eventos
    WHERE evento_id = NEW.evento_id;
    
    -- Calcular disponibilidad actual
    SELECT capacidad_maxima - COUNT(*)
    INTO v_disponibilidad
    FROM entradas
    WHERE evento_id = NEW.evento_id
    AND estado != 'cancelada'
    GROUP BY evento_id;
    
    -- Si es NULL, significa que no hay entradas vendidas aún
    IF v_disponibilidad IS NULL THEN
        v_disponibilidad := v_evento_info.capacidad_maxima;
    END IF;
    
    -- Verificar si hay entradas disponibles
    IF v_disponibilidad <= 0 THEN
        RAISE EXCEPTION 'No hay entradas disponibles para este evento';
    END IF;
    
    -- Generar código único para la entrada (prefijo del evento + número aleatorio)
    v_codigo := 'E' || v_evento_info.evento_id || '-' || 
                TO_CHAR(CURRENT_DATE, 'YYMMDD') || '-' ||
                LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0');
                
    -- Asignar el código generado
    NEW.codigo_entrada := v_codigo;
    
    -- Si no se ha especificado un precio, usar el precio del evento
    IF NEW.precio_pagado IS NULL OR NEW.precio_pagado = 0 THEN
        SELECT precio_entrada INTO NEW.precio_pagado
        FROM eventos
        WHERE evento_id = NEW.evento_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_generar_codigo_entrada
BEFORE INSERT ON entradas
FOR EACH ROW
EXECUTE FUNCTION generar_codigo_entrada();

-- Trigger 4: Registrar la fecha de check-in
CREATE OR REPLACE FUNCTION registrar_fecha_check_in()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.check_in = TRUE AND OLD.check_in = FALSE THEN
        NEW.fecha_check_in := CURRENT_TIMESTAMP;
        
        -- Cambiar el estado a 'utilizada'
        NEW.estado := 'utilizada';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_registrar_fecha_check_in
BEFORE UPDATE OF check_in ON entradas
FOR EACH ROW
EXECUTE FUNCTION registrar_fecha_check_in();

-- Trigger 5: Verificar fechas de participación de artistas
CREATE OR REPLACE FUNCTION verificar_fechas_participacion_artistas()
RETURNS TRIGGER AS $$
DECLARE
    v_fecha_inicio TIMESTAMP;
    v_fecha_fin TIMESTAMP;
BEGIN
    -- Obtener fechas de inicio y fin del evento
    SELECT fecha_inicio, fecha_fin INTO v_fecha_inicio, v_fecha_fin
    FROM eventos
    WHERE evento_id = NEW.evento_id;
    
    -- Verificar que las horas de participación estén dentro de las fechas del evento
    IF NEW.hora_inicio_participacion < v_fecha_inicio OR NEW.hora_fin_participacion > v_fecha_fin THEN
        RAISE EXCEPTION 'Las horas de participación del artista deben estar dentro del período del evento (% a %)', 
                        v_fecha_inicio, v_fecha_fin;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_verificar_fechas_participacion
BEFORE INSERT OR UPDATE ON evento_artistas
FOR EACH ROW
EXECUTE FUNCTION verificar_fechas_participacion_artistas();