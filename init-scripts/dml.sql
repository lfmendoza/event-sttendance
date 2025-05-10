-- =============================================================================================
-- Script de Inserción de Datos: Sistema de Gestión de Eventos Culturales y Asistencia
-- =============================================================================================

-- Función auxiliar para generar fechas aleatorias en un rango
CREATE OR REPLACE FUNCTION fecha_aleatoria(fecha_inicio DATE, fecha_fin DATE)
RETURNS DATE AS $$
DECLARE
    dias INTEGER;
BEGIN
    dias := fecha_fin - fecha_inicio;
    RETURN fecha_inicio + floor(random() * dias)::INTEGER;
END;
$$ LANGUAGE plpgsql;

-- Función auxiliar para generar timestamp aleatorios para los eventos
CREATE OR REPLACE FUNCTION timestamp_evento_aleatorio(
    min_dias_futuro INTEGER DEFAULT -180, 
    max_dias_futuro INTEGER DEFAULT 180, 
    min_hora INTEGER DEFAULT 8, 
    max_hora INTEGER DEFAULT 22,
    min_duracion_horas INTEGER DEFAULT 1,
    max_duracion_horas INTEGER DEFAULT 8
)
RETURNS TABLE(fecha_inicio TIMESTAMP, fecha_fin TIMESTAMP) AS $$
DECLARE
    v_fecha_base DATE;
    v_hora_inicio INTEGER;
    v_duracion_horas INTEGER;
    v_inicio TIMESTAMP;
    v_fin TIMESTAMP;
BEGIN
    -- Generar fecha base (puede ser pasada o futura)
    v_fecha_base := CURRENT_DATE + (floor(random() * (max_dias_futuro - min_dias_futuro + 1))::INTEGER + min_dias_futuro);
    
    -- Generar hora de inicio (entre 8 AM y 10 PM)
    v_hora_inicio := floor(random() * (max_hora - min_hora + 1))::INTEGER + min_hora;
    
    -- Generar duración (entre 1 y 8 horas)
    v_duracion_horas := floor(random() * (max_duracion_horas - min_duracion_horas + 1))::INTEGER + min_duracion_horas;
    
    -- Construir timestamps
    v_inicio := v_fecha_base + (v_hora_inicio * INTERVAL '1 hour');
    v_fin := v_inicio + (v_duracion_horas * INTERVAL '1 hour');
    
    fecha_inicio := v_inicio;
    fecha_fin := v_fin;
    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;

-- Limpieza de datos existentes para recargar
TRUNCATE usuarios, intereses_usuarios, sedes, salas_sedes, categorias, artistas, 
         especialidades_artistas, patrocinadores, recursos, eventos, evento_categorias, 
         evento_artistas, evento_patrocinadores, evento_recursos, entradas, comentarios, 
         recordatorios, archivos_eventos CASCADE;

-- Restablecer las secuencias
ALTER SEQUENCE usuarios_usuario_id_seq RESTART WITH 1;
ALTER SEQUENCE sedes_sede_id_seq RESTART WITH 1;
ALTER SEQUENCE categorias_categoria_id_seq RESTART WITH 1;
ALTER SEQUENCE artistas_artista_id_seq RESTART WITH 1;
ALTER SEQUENCE patrocinadores_patrocinador_id_seq RESTART WITH 1;
ALTER SEQUENCE recursos_recurso_id_seq RESTART WITH 1;
ALTER SEQUENCE eventos_evento_id_seq RESTART WITH 1;
ALTER SEQUENCE entradas_entrada_id_seq RESTART WITH 1;
ALTER SEQUENCE comentarios_comentario_id_seq RESTART WITH 1;
ALTER SEQUENCE recordatorios_recordatorio_id_seq RESTART WITH 1;
ALTER SEQUENCE archivos_eventos_archivo_id_seq RESTART WITH 1;

-- =============================================================================================
-- 1. INSERTANDO USUARIOS (100 registros)
-- =============================================================================================

INSERT INTO usuarios (nombre, apellido, email, telefono, fecha_nacimiento, password, tipo_usuario, activo)
VALUES
    ('Admin', 'Sistema', 'admin@eventosculturales.com', '+50212345678', '1985-05-15', '$2a$10$OhKhwSi6KVVx8/iXr9.uy.r02DnFqALxJQG9RK45LY3MKeVbZaeny', 'administrador', TRUE),
    ('Carlos', 'Méndez', 'carlos.mendez@gmail.com', '+50255789012', '1990-08-22', '$2a$10$nJXxM9UlpBr1KbJKydpJL.l3xUb3TqyVxCuWCq8/ZLzY42HMaXlNG', 'organizador', TRUE),
    ('María', 'Gutiérrez', 'maria.gutierrez@hotmail.com', '+50233451278', '1988-12-10', '$2a$10$Dkz5fQU4VT9IuRkKxGzzA.gEMfD98QB9KgBCxWjj4NxE7bOe3gIrC', 'organizador', TRUE);

-- Generar 97 usuarios más para completar 100
DO $
DECLARE
    v_nombre VARCHAR[];
    v_apellido VARCHAR[];
    v_dominio VARCHAR[];
    v_nombre_sel VARCHAR;
    v_apellido_sel VARCHAR;
    v_dominio_sel VARCHAR;
    v_telefono VARCHAR;
    v_fecha_nac DATE;
    v_email VARCHAR;
    v_tipo VARCHAR;
    i INTEGER;
BEGIN
    -- Arrays para generación aleatoria
    v_nombre := ARRAY['Juan', 'Pedro', 'Luis', 'Ana', 'Sofía', 'Lucía', 'Miguel', 'Diego', 'José', 
                    'Roberto', 'Alejandro', 'Claudia', 'Gabriela', 'Fernando', 'Marcela', 'Tomás', 
                    'Valeria', 'Rodrigo', 'Eduardo', 'Ximena', 'Isabel', 'Francisco', 'Patricia',
                    'Adriana', 'Ricardo', 'Manuel', 'Mónica', 'Daniela', 'Oscar', 'Natalia'];
    
    v_apellido := ARRAY['García', 'López', 'Martínez', 'Rodríguez', 'Hernández', 'González', 
                        'Pérez', 'Sánchez', 'Ramírez', 'Flores', 'Cruz', 'Ortiz', 'Morales', 
                        'Reyes', 'Díaz', 'Torres', 'Vásquez', 'Castillo', 'Santos', 'Mendoza',
                        'Rivera', 'Franco', 'Jiménez', 'Alvarado', 'Campos', 'Rivas', 'Guzmán',
                        'Vargas', 'Castro', 'Delgado'];
    
    v_dominio := ARRAY['gmail.com', 'hotmail.com', 'outlook.com', 'yahoo.com', 'icloud.com', 'me.com'];
    
    FOR i IN 1..97 LOOP
        -- Seleccionar valores aleatorios
        v_nombre_sel := v_nombre[1 + floor(random() * array_length(v_nombre, 1))];
        v_apellido_sel := v_apellido[1 + floor(random() * array_length(v_apellido, 1))];
        v_dominio_sel := v_dominio[1 + floor(random() * array_length(v_dominio, 1))];
        
        -- Generar email
        v_email := lower(v_nombre_sel) || '.' || lower(v_apellido_sel) || 
                  floor(random() * 100)::TEXT || '@' || v_dominio_sel;
        
        -- Generar teléfono
        v_telefono := '+502' || (floor(random() * 90000000) + 10000000)::TEXT;
        
        -- Generar fecha de nacimiento (entre 18 y 70 años)
        v_fecha_nac := CURRENT_DATE - ((floor(random() * (70-18+1)) + 18) * INTERVAL '1 year') - 
                     (floor(random() * 365) * INTERVAL '1 day');
        
        -- Asignar tipo de usuario (mayoría clientes)
        IF i <= 5 THEN
            v_tipo := 'artista';
        ELSIF i <= 15 THEN
            v_tipo := 'organizador';
        ELSE
            v_tipo := 'cliente';
        END IF;
        
        -- Insertar usuario
        INSERT INTO usuarios (nombre, apellido, email, telefono, fecha_nacimiento, 
                            password, tipo_usuario, activo)
        VALUES (
            v_nombre_sel,
            v_apellido_sel,
            v_email,
            v_telefono,
            v_fecha_nac,
            '$2a$10$' || md5(random()::text),-- Password hash aleatorio
            v_tipo::tipo_usuario,
            TRUE
        );
    END LOOP;
END $;

-- =============================================================================================
-- 2. INSERTANDO INTERESES DE USUARIOS (para atributo multivaluado)
-- =============================================================================================

-- Lista de posibles intereses
WITH intereses AS (
    SELECT unnest(ARRAY[
        'Música clásica', 'Jazz', 'Teatro', 'Ópera', 'Ballet', 'Danza contemporánea', 
        'Arte urbano', 'Exposiciones', 'Fotografía', 'Pintura', 'Escultura', 'Literatura', 
        'Poesía', 'Cine independiente', 'Festivales', 'Gastronomía', 'Historia', 'Patrimonio',
        'Artesanía', 'Música folklórica', 'Rock', 'Pop', 'Electrónica', 'Hip hop',
        'Comedia', 'Performance', 'Talleres', 'Charlas'
    ]) AS interes
)
-- Asignar entre 2 y 5 intereses aleatorios a cada usuario
INSERT INTO intereses_usuarios (usuario_id, interes)
SELECT 
    u.usuario_id,
    i.interes
FROM 
    usuarios u
CROSS JOIN LATERAL (
    SELECT interes FROM intereses
    ORDER BY random()
    LIMIT floor(random() * 4)::INTEGER + 2
) i
WHERE 
    u.tipo_usuario IN ('cliente', 'artista');

-- =============================================================================================
-- 3. INSERTANDO SEDES (20 registros)
-- =============================================================================================

INSERT INTO sedes (nombre, direccion, capacidad_maxima, ubicacion_gps, descripcion, accesibilidad, telefono, horario_apertura, horario_cierre)
VALUES
    ('Teatro Nacional', 'Zona 1, Centro Histórico', 1200, POINT(14.634915, -90.513384), 'Teatro principal con arquitectura neoclásica y excelente acústica', TRUE, '+50222325453', '08:00', '22:00'),
    ('Centro Cultural Miguel Ángel Asturias', '24 Calle 3-81, Zona 1', 2100, POINT(14.625238, -90.522061), 'Complejo cultural diseñado por Efraín Recinos', TRUE, '+50222325261', '09:00', '23:00'),
    ('Auditorio Juan Bautista Gutiérrez', 'Campus Central Universidad del Valle', 800, POINT(14.603834, -90.489097), 'Auditorio moderno para eventos académicos y culturales', TRUE, '+50224893269', '07:00', '21:00'),
    ('Museo Miraflores', '7 Calle 21-55, Zona 11', 300, POINT(14.613519, -90.556417), 'Museo arqueológico con exposiciones itinerantes', TRUE, '+50224733639', '09:00', '18:00'),
    ('Casa Ibargüen', '7a Avenida 11-66, Zona 1', 150, POINT(14.636298, -90.514401), 'Edificio colonial restaurado para eventos culturales', FALSE, '+50222325435', '10:00', '19:00');

-- Generar 15 sedes más
DO $
DECLARE
    v_nombres VARCHAR[];
    v_zonas INTEGER[];
    v_calles INTEGER[];
    v_direccion VARCHAR;
    v_nombre VARCHAR;
    v_capacidad INTEGER;
    v_lat FLOAT;
    v_long FLOAT;
    v_telefono VARCHAR;
    v_descripcion TEXT;
    v_apertura TIME;
    v_cierre TIME;
    i INTEGER;
BEGIN
    -- Arrays para generación aleatoria
    v_nombres := ARRAY['Centro Cultural', 'Galería', 'Auditorio', 'Teatro', 'Sala de Exposiciones', 
                      'Foro', 'Museo', 'Casa de la Cultura', 'Plaza Cultural', 'Palacio', 
                      'Centro de Arte', 'Ateneo', 'Espacio', 'Sala de Conciertos', 'Arena'];
    
    v_zonas := ARRAY[1, 2, 4, 5, 9, 10, 11, 13, 14, 15, 16];
    v_calles := ARRAY[2, 3, 5, 6, 7, 9, 10, 11, 12, 14, 15, 16, 18, 20];
    
    FOR i IN 1..15 LOOP
        -- Generar nombre aleatorio con adjetivo
        v_nombre := v_nombres[1 + floor(random() * array_length(v_nombres, 1))] || ' ' ||
                    CASE 
                        WHEN i % 3 = 0 THEN 'Municipal'
                        WHEN i % 3 = 1 THEN 'Metropolitano'
                        ELSE 'Nacional'
                    END || ' ' ||
                    chr(65 + i);
        
        -- Generar dirección
        v_direccion := v_calles[1 + floor(random() * array_length(v_calles, 1))]::TEXT || 
                      ' Calle ' ||
                      floor(random() * 20 + 1)::TEXT || '-' || 
                      floor(random() * 80 + 10)::TEXT || ', Zona ' || 
                      v_zonas[1 + floor(random() * array_length(v_zonas, 1))]::TEXT;
        
        -- Generar capacidad (entre 100 y 1500)
        v_capacidad := floor(random() * 1400 + 100)::INTEGER;
        
        -- Generar coordenadas (cercanas a Ciudad de Guatemala)
        v_lat := 14.60 + (random() * 0.07);
        v_long := -90.49 - (random() * 0.10);
        
        -- Generar teléfono
        v_telefono := '+502' || (floor(random() * 90000000) + 10000000)::TEXT;
        
        -- Generar descripción
        v_descripcion := 'Espacio cultural ubicado en zona ' || 
                      v_zonas[1 + floor(random() * array_length(v_zonas, 1))]::TEXT || 
                      ' con capacidad para ' || v_capacidad || ' personas y facilidades para diversos eventos.';
        
        -- Generar horarios (entre 7am y 11pm)
        v_apertura := (7 + floor(random() * 3))::TEXT || ':00'::TIME;
        v_cierre := (19 + floor(random() * 4))::TEXT || ':00'::TIME;
        
        -- Insertar sede
        INSERT INTO sedes (nombre, direccion, capacidad_maxima, ubicacion_gps, descripcion, 
                        accesibilidad, telefono, horario_apertura, horario_cierre)
        VALUES (
            v_nombre,
            v_direccion,
            v_capacidad,
            POINT(v_lat, v_long),
            v_descripcion,
            (random() > 0.3), -- 70% tienen accesibilidad
            v_telefono,
            v_apertura,
            v_cierre
        );
    END LOOP;
END $;

-- =============================================================================================
-- 4. INSERTANDO SALAS EN SEDES (atributo multivaluado)
-- =============================================================================================

-- Para cada sede, crear entre 1 y 4 salas
WITH sede_ids AS (
    SELECT sede_id FROM sedes
)
INSERT INTO salas_sedes (sede_id, nombre_sala, capacidad, descripcion)
SELECT 
    s.sede_id,
    CASE 
        WHEN num = 1 THEN 'Sala Principal'
        WHEN num = 2 THEN 'Sala Auxiliar'
        WHEN num = 3 THEN 'Salón VIP'
        WHEN num = 4 THEN 'Sala de Exposiciones'
    END AS nombre_sala,
    GREATEST(50, floor((random() * s.capacidad_maxima * 0.5)::INTEGER)) AS capacidad,
    'Sala ' || num || ' de la sede con capacidad para eventos de mediana escala.'
FROM 
    sede_ids s
CROSS JOIN LATERAL (
    SELECT generate_series(1, 1 + floor(random() * 3)::INTEGER) AS num
) nums;

-- =============================================================================================
-- 5. INSERTANDO CATEGORÍAS (15 registros)
-- =============================================================================================

INSERT INTO categorias (nombre, descripcion, color)
VALUES
    ('Música', 'Eventos musicales de diversos géneros', '#E91E63'),
    ('Teatro', 'Obras de teatro, monólogos y performances teatrales', '#9C27B0'),
    ('Danza', 'Espectáculos de danza clásica y contemporánea', '#673AB7'),
    ('Arte Visual', 'Exposiciones de pintura, escultura y fotografía', '#3F51B5'),
    ('Literatura', 'Presentaciones de libros, poesía y foros literarios', '#2196F3'),
    ('Cine', 'Proyecciones cinematográficas y festivales de cine', '#03A9F4'),
    ('Gastronomía', 'Eventos culinarios y degustaciones', '#00BCD4'),
    ('Talleres', 'Actividades participativas y formativas', '#009688'),
    ('Conferencias', 'Charlas, simposios y conferencias', '#4CAF50'),
    ('Patrimonio', 'Eventos relacionados con el patrimonio cultural', '#8BC34A'),
    ('Infantil', 'Actividades para público infantil y familiar', '#CDDC39'),
    ('Festivales', 'Festivales y celebraciones de diversa índole', '#FFEB3B'),
    ('Artesanía', 'Ferias y exposiciones de artesanía tradicional', '#FFC107'),
    ('Multidisciplinar', 'Eventos que combinan diversas expresiones artísticas', '#FF9800'),
    ('Folclore', 'Manifestaciones culturales tradicionales', '#FF5722');

-- =============================================================================================
-- 6. INSERTANDO ARTISTAS (50 registros)
-- =============================================================================================

INSERT INTO artistas (nombre, apellido, biografia, nacionalidad, fecha_inicio_carrera, sitio_web, redes_sociales)
VALUES
    ('Gabriela', 'Moreno', 'Pianista clásica con reconocimiento internacional', 'Guatemalteca', '2005-03-15', 'https://gabrielamoreno.com', '{"instagram": "@gabrielamoreno", "facebook": "GabrielaMorenoPiano"}'),
    ('Javier', 'Cruz', 'Director teatral con más de 20 años de experiencia', 'Mexicano', '1998-06-22', 'https://javiercruz.mx', '{"twitter": "@javiercruz", "youtube": "JavierCruzTeatro"}'),
    ('Isabel', 'Alvarado', 'Coreógrafa especializada en danza contemporánea', 'Guatemalteca', '2008-11-10', 'https://isabelalvarado.gt', '{"instagram": "@isabelladanza", "tiktok": "@isadance"}'),
    ('Roberto', 'Méndez', 'Pintor abstracto con exposiciones internacionales', 'Salvadoreño', '2001-04-05', 'https://robertomendez.art', '{"facebook": "RobertoMendezArt", "instagram": "@mendezart"}'),
    ('Carmen', 'Solís', 'Cantante lírica con formación en el Conservatorio Nacional', 'Guatemalteca', '2010-09-18', 'https://carmensolis.com', '{"youtube": "CarmenSolisSoprano", "instagram": "@carmensoliscanto"}');

-- Generar 45 artistas más
DO $
DECLARE
    v_nombre VARCHAR[];
    v_apellido VARCHAR[];
    v_especialidad VARCHAR[];
    v_nacionalidad VARCHAR[];
    v_nombre_sel VARCHAR;
    v_apellido_sel VARCHAR;
    v_espec_sel VARCHAR;
    v_nac_sel VARCHAR;
    v_bio TEXT;
    v_fecha_inicio DATE;
    v_sitio_web VARCHAR;
    v_redes JSONB;
    v_instagram VARCHAR;
    v_facebook VARCHAR;
    i INTEGER;
BEGIN
    -- Arrays para generación aleatoria
    v_nombre := ARRAY['Carlos', 'Miguel', 'Laura', 'Marina', 'Daniel', 'Pablo', 'Sofía', 'Andrea', 
                     'Jorge', 'Lucía', 'Eduardo', 'Alejandra', 'Fernando', 'Diana', 'Andrés',
                     'Valeria', 'Luis', 'Claudia', 'Rafael', 'Silvia', 'Emilio', 'Patricia'];
    
    v_apellido := ARRAY['Rodríguez', 'González', 'Herrera', 'Valdez', 'Jiménez', 'Pérez', 
                       'Morales', 'Santos', 'Mendoza', 'Vásquez', 'Estrada', 'Castillo',
                       'Fuentes', 'Ortega', 'Domínguez', 'Reyes', 'Vargas', 'Rojas',
                       'Castro', 'Flores', 'Rivas', 'Torres'];
    
    v_especialidad := ARRAY['Música', 'Pintura', 'Escultura', 'Danza', 'Teatro', 'Fotografía', 
                          'Literatura', 'Poesía', 'Dirección escénica', 'Performance', 
                          'Cine', 'Composición musical', 'Canto'];
    
    v_nacionalidad := ARRAY['Guatemalteco/a', 'Mexicano/a', 'Salvadoreño/a', 'Hondureño/a', 
                          'Nicaragüense', 'Costarricense', 'Panameño/a', 'Colombiano/a', 
                          'Argentino/a', 'Chileno/a', 'Español/a'];
    
    FOR i IN 1..45 LOOP
        -- Seleccionar valores aleatorios
        v_nombre_sel := v_nombre[1 + floor(random() * array_length(v_nombre, 1))];
        v_apellido_sel := v_apellido[1 + floor(random() * array_length(v_apellido, 1))];
        v_espec_sel := v_especialidad[1 + floor(random() * array_length(v_especialidad, 1))];
        v_nac_sel := v_nacionalidad[1 + floor(random() * array_length(v_nacionalidad, 1))];
        
        -- Generar biografía
        v_bio := 'Artista de ' || v_espec_sel || ' con trayectoria en el ámbito cultural. ';
        
        IF (random() > 0.5) THEN
            v_bio := v_bio || 'Ha participado en importantes eventos y festivales internacionales. ';
        END IF;
        
        IF (random() > 0.6) THEN
            v_bio := v_bio || 'Cuenta con formación académica especializada y múltiples reconocimientos en su carrera.';
        END IF;
        
        -- Generar fecha de inicio (entre 2 y 30 años atrás)
        v_fecha_inicio := CURRENT_DATE - ((floor(random() * (30-2+1)) + 2) * INTERVAL '1 year') - 
                         (floor(random() * 365) * INTERVAL '1 day');
        
        -- Generar sitio web
        v_sitio_web := 'https://www.' || lower(v_nombre_sel) || lower(v_apellido_sel) || '.com';
        
        -- Generar redes sociales
        v_instagram := '@' || lower(v_nombre_sel) || lower(v_apellido_sel) || floor(random() * 100)::TEXT;
        v_facebook := v_nombre_sel || v_apellido_sel || 'Oficial';
        
        v_redes := jsonb_build_object(
            'instagram', v_instagram,
            'facebook', v_facebook
        );
        
        -- Insertar artista
        INSERT INTO artistas (nombre, apellido, biografia, nacionalidad, fecha_inicio_carrera, 
                            sitio_web, redes_sociales)
        VALUES (
            v_nombre_sel,
            v_apellido_sel,
            v_bio,
            v_nac_sel,
            v_fecha_inicio,
            v_sitio_web,
            v_redes
        );
    END LOOP;
END $;

-- =============================================================================================
-- 7. INSERTANDO ESPECIALIDADES DE ARTISTAS (atributo multivaluado)
-- =============================================================================================

-- Lista de posibles especialidades detalladas
WITH especialidades AS (
    SELECT unnest(ARRAY[
        'Piano', 'Violín', 'Guitarra clásica', 'Canto lírico', 'Ópera', 'Jazz', 'Rock', 
        'Música folclórica', 'Dirección de orquesta', 'Composición musical',
        'Actuación dramática', 'Comedia', 'Dirección teatral', 'Teatro experimental',
        'Ballet clásico', 'Danza contemporánea', 'Danzas tradicionales', 'Coreografía',
        'Pintura al óleo', 'Acuarela', 'Escultura', 'Cerámica', 'Fotografía artística',
        'Fotografía documental', 'Literatura infantil', 'Novela', 'Poesía', 'Ensayo',
        'Performance', 'Videoarte', 'Arte digital', 'Grabado'
    ]) AS especialidad
)
-- Asignar entre 1 y 3 especialidades aleatorias a cada artista
INSERT INTO especialidades_artistas (artista_id, especialidad)
SELECT 
    a.artista_id,
    e.especialidad
FROM 
    artistas a
CROSS JOIN LATERAL (
    SELECT especialidad FROM especialidades
    ORDER BY random()
    LIMIT floor(random() * 3)::INTEGER + 1
) e;

-- =============================================================================================
-- 8. INSERTANDO PATROCINADORES (30 registros)
-- =============================================================================================

INSERT INTO patrocinadores (nombre, tipo, contacto_nombre, contacto_email, contacto_telefono, descripcion)
VALUES
    ('Ministerio de Cultura', 'gubernamental', 'Ana Martínez', 'contacto@cultura.gob.gt', '+50222325698', 'Entidad gubernamental que apoya programas culturales'),
    ('Banco Azteca', 'privado', 'Roberto García', 'patrocinios@bancoazteca.com.gt', '+50223456789', 'Institución financiera que patrocina eventos culturales como parte de su responsabilidad social'),
    ('Fundación Cultural Paiz', 'ong', 'Claudia Monzón', 'info@fundacionpaiz.org.gt', '+50224587963', 'Organización sin fines de lucro dedicada a la promoción cultural y artística'),
    ('Universidad Francisco Marroquín', 'educativo', 'Carlos Mendoza', 'extension@ufm.edu', '+50224387000', 'Institución educativa que promueve eventos académicos y culturales'),
    ('Radio Faro Cultural', 'medios', 'Lucía Contreras', 'programacion@faro.com.gt', '+50224598712', 'Medio de comunicación especializado en difusión cultural');

-- Generar 25 patrocinadores más
DO $
DECLARE
    v_nombres_priv VARCHAR[];
    v_nombres_gob VARCHAR[];
    v_nombres_ong VARCHAR[];
    v_nombres_edu VARCHAR[];
    v_nombres_med VARCHAR[];
    v_nombre_contacto VARCHAR[];
    v_apellido_contacto VARCHAR[];
    v_nombre VARCHAR;
    v_tipo tipo_patrocinador;
    v_contacto_nombre VARCHAR;
    v_contacto_email VARCHAR;
    v_contacto_telefono VARCHAR;
    v_descripcion TEXT;
    i INTEGER;
BEGIN
    -- Arrays para generación aleatoria
    v_nombres_priv := ARRAY['Banco ', 'Corporación ', 'Grupo ', 'Seguros ', 'Industrias ', 
                          'Comercial ', 'Distribuidora ', 'Importadora ', 'Cervecería ',
                          'Hoteles ', 'Restaurantes ', 'Inmobiliaria '];
    
    v_nombres_gob := ARRAY['Secretaría de ', 'Ministerio de ', 'Instituto Nacional de ', 
                          'Dirección de ', 'Consejo Nacional de '];
    
    v_nombres_ong := ARRAY['Fundación ', 'Asociación ', 'ONG ', 'Cooperativa ', 'Colectivo '];
    
    v_nombres_edu := ARRAY['Universidad ', 'Colegio ', 'Instituto ', 'Academia ', 'Centro Educativo '];
    
    v_nombres_med := ARRAY['Radio ', 'Televisora ', 'Canal ', 'Diario ', 'Revista ', 'Productora '];
    
    v_nombre_contacto := ARRAY['Juan', 'Pedro', 'María', 'Ana', 'Carlos', 'Laura', 'Diego', 
                             'Lucía', 'Gabriela', 'Fernando', 'Patricia', 'Roberto'];
    
    v_apellido_contacto := ARRAY['García', 'López', 'Martínez', 'Rodríguez', 'Hernández', 
                               'González', 'Pérez', 'Sánchez', 'Ramírez', 'Flores'];
    
    FOR i IN 1..25 LOOP
        -- Determinar tipo de patrocinador
        v_tipo := CASE 
            WHEN i % 5 = 0 THEN 'gubernamental'
            WHEN i % 5 = 1 THEN 'privado'
            WHEN i % 5 = 2 THEN 'ong'
            WHEN i % 5 = 3 THEN 'educativo'
            ELSE 'medios'
        END::tipo_patrocinador;
        
        -- Generar nombre según tipo
        CASE v_tipo
            WHEN 'gubernamental' THEN
                v_nombre := v_nombres_gob[1 + floor(random() * array_length(v_nombres_gob, 1))] || 
                          CASE 
                              WHEN i % 4 = 0 THEN 'Cultura'
                              WHEN i % 4 = 1 THEN 'Patrimonio'
                              WHEN i % 4 = 2 THEN 'Artes'
                              ELSE 'Desarrollo Social'
                          END;
                
            WHEN 'privado' THEN
                v_nombre := v_nombres_priv[1 + floor(random() * array_length(v_nombres_priv, 1))] || 
                          'Guatemala ' || chr(65 + i);
                
            WHEN 'ong' THEN
                v_nombre := v_nombres_ong[1 + floor(random() * array_length(v_nombres_ong, 1))] || 
                          CASE 
                              WHEN i % 3 = 0 THEN 'Cultural'
                              WHEN i % 3 = 1 THEN 'Artística'
                              ELSE 'para las Artes'
                          END || ' ' || chr(65 + i);
                
            WHEN 'educativo' THEN
                v_nombre := v_nombres_edu[1 + floor(random() * array_length(v_nombres_edu, 1))] || 
                          CASE 
                              WHEN i % 2 = 0 THEN 'de Artes'
                              ELSE 'Cultural'
                          END || ' ' || chr(65 + i);
                
            ELSE -- medios
                v_nombre := v_nombres_med[1 + floor(random() * array_length(v_nombres_med, 1))] || 
                          CASE 
                              WHEN i % 3 = 0 THEN 'Cultural'
                              WHEN i % 3 = 1 THEN 'Arte'
                              ELSE 'Metropolitana'
                          END;
        END CASE;
        
        -- Generar contacto
        v_contacto_nombre := v_nombre_contacto[1 + floor(random() * array_length(v_nombre_contacto, 1))] || ' ' ||
                           v_apellido_contacto[1 + floor(random() * array_length(v_apellido_contacto, 1))];
        
        -- Generar email según nombre de la entidad
        v_contacto_email := 'contacto@' || lower(regexp_replace(v_nombre, '[^a-zA-Z0-9]', '', 'g')) || '.com.gt';
        
        -- Generar teléfono
        v_contacto_telefono := '+502' || (floor(random() * 90000000) + 10000000)::TEXT;
        
        -- Generar descripción
        v_descripcion := CASE 
            WHEN v_tipo = 'gubernamental' THEN 'Entidad gubernamental que promueve y financia iniciativas culturales en ' || 
                                              CASE WHEN i % 2 = 0 THEN 'el ámbito nacional.' ELSE 'comunidades de todo el país.' END
                                              
            WHEN v_tipo = 'privado' THEN 'Empresa que apoya eventos culturales como parte de su programa de responsabilidad social corporativa.'
            
            WHEN v_tipo = 'ong' THEN 'Organización sin fines de lucro dedicada a ' || 
                                   CASE WHEN i % 2 = 0 THEN 'promover el arte y la cultura en comunidades vulnerables.' 
                                        ELSE 'preservar y difundir el patrimonio cultural.' END
                                        
            WHEN v_tipo = 'educativo' THEN 'Institución educativa que fomenta la formación artística y apoya eventos culturales.'
            
            ELSE 'Medio de comunicación especializado en la difusión de contenido cultural y artístico.'
        END;
        
        -- Insertar patrocinador
        INSERT INTO patrocinadores (nombre, tipo, contacto_nombre, contacto_email, 
                                  contacto_telefono, descripcion)
        VALUES (
            v_nombre,
            v_tipo,
            v_contacto_nombre,
            v_contacto_email,
            v_contacto_telefono,
            v_descripcion
        );
    END LOOP;
END $;

-- =============================================================================================
-- 9. INSERTANDO RECURSOS (40 registros)
-- =============================================================================================

INSERT INTO recursos (nombre, tipo, descripcion, cantidad_disponible, requiere_reserva)
VALUES
    ('Sistema de sonido profesional', 'equipo_sonido', 'Equipo completo con consola digital, altavoces y monitores', 5, TRUE),
    ('Micrófonos inalámbricos', 'equipo_sonido', 'Set de 8 micrófonos inalámbricos de alta calidad', 10, TRUE),
    ('Iluminación de escenario', 'equipo_iluminacion', 'Sistema completo con luces LED, móviles y controlador', 6, TRUE),
    ('Proyector 4K', 'equipo_iluminacion', 'Proyector de alta definición con pantalla retráctil', 8, TRUE),
    ('Sillas plegables', 'mobiliario', 'Sillas negras para eventos', 500, TRUE),
    ('Mesas redondas', 'mobiliario', 'Mesas para 8 personas con mantelería', 50, TRUE),
    ('Personal de seguridad', 'seguridad', 'Agentes de seguridad uniformados y capacitados', 20, TRUE),
    ('Asistentes de evento', 'personal', 'Personal para registro, acomodación y asistencia general', 30, TRUE),
    ('Escenario modular', 'mobiliario', 'Módulos de 1x1m para armar escenarios a medida', 100, TRUE),
    ('Decoración temática', 'decoracion', 'Elementos decorativos según temática del evento', 15, FALSE);

-- Generar 30 recursos más
DO $
DECLARE
    v_nombres_sonido VARCHAR[];
    v_nombres_iluminacion VARCHAR[];
    v_nombres_mobiliario VARCHAR[];
    v_nombres_decoracion VARCHAR[];
    v_nombres_seguridad VARCHAR[];
    v_nombres_personal VARCHAR[];
    v_nombre VARCHAR;
    v_tipo tipo_recurso;
    v_descripcion TEXT;
    v_cantidad INTEGER;
    i INTEGER;
BEGIN
    -- Arrays para generación aleatoria
    v_nombres_sonido := ARRAY['Altavoces profesionales', 'Monitores de escenario', 'Consola de audio', 
                             'Micrófonos de condensador', 'Micrófonos de diadema', 'Sistema de PA', 
                             'Cajas acústicas', 'Mezcladora digital', 'Amplificadores'];
    
    v_nombres_iluminacion := ARRAY['Focos LED', 'Luces robóticas', 'Consola DMX', 'Máquina de humo', 
                                 'Luces estroboscópicas', 'Pantalla LED', 'Cañón de seguimiento', 
                                 'Cortina de luz', 'Iluminación arquitectónica'];
    
    v_nombres_mobiliario := ARRAY['Estrado para conferencistas', 'Podio de presentador', 'Biombos divisorios', 
                                'Tarimas modulares', 'Carpas exteriores', 'Sillas ejecutivas', 
                                'Mesas de cóctel', 'Barras de bar', 'Gradas para público'];
    
    v_nombres_decoracion := ARRAY['Centros de mesa', 'Arreglos florales', 'Telas decorativas', 
                                'Globos temáticos', 'Backdrops personalizados', 'Señalética de evento', 
                                'Alfombra roja', 'Decoración temática', 'Plantas ornamentales'];
    
    v_nombres_seguridad := ARRAY['Vigilancia VIP', 'Control de acceso', 'Detectores de metales', 
                               'Circuito cerrado', 'Vallas de seguridad', 'Personal de evacuación', 
                               'Servicio de primeros auxilios', 'Coordinador de seguridad'];
    
    v_nombres_personal := ARRAY['Anfitriones', 'Guías', 'Traductores', 'Técnicos audiovisuales', 
                              'Coordinadores de área', 'Staff de camerinos', 'Encargados de protocolo', 
                              'Auxiliares logísticos', 'Maestros de ceremonia'];
    
    FOR i IN 1..30 LOOP
        -- Determinar tipo de recurso
        v_tipo := CASE 
            WHEN i % 6 = 0 THEN 'equipo_sonido'
            WHEN i % 6 = 1 THEN 'equipo_iluminacion'
            WHEN i % 6 = 2 THEN 'mobiliario'
            WHEN i % 6 = 3 THEN 'decoracion'
            WHEN i % 6 = 4 THEN 'seguridad'
            ELSE 'personal'
        END::tipo_recurso;
        
        -- Generar nombre según tipo
        CASE v_tipo
            WHEN 'equipo_sonido' THEN
                v_nombre := v_nombres_sonido[1 + floor(random() * array_length(v_nombres_sonido, 1))];
                v_descripcion := 'Equipo de audio profesional para eventos culturales.';
                v_cantidad := floor(random() * 10)::INTEGER + 2;
                
            WHEN 'equipo_iluminacion' THEN
                v_nombre := v_nombres_iluminacion[1 + floor(random() * array_length(v_nombres_iluminacion, 1))];
                v_descripcion := 'Sistema de iluminación para resaltar espacios y artistas en escena.';
                v_cantidad := floor(random() * 15)::INTEGER + 2;
                
            WHEN 'mobiliario' THEN
                v_nombre := v_nombres_mobiliario[1 + floor(random() * array_length(v_nombres_mobiliario, 1))];
                v_descripcion := 'Mobiliario para organización y comodidad en eventos.';
                v_cantidad := floor(random() * 50)::INTEGER + 10;
                
            WHEN 'decoracion' THEN
                v_nombre := v_nombres_decoracion[1 + floor(random() * array_length(v_nombres_decoracion, 1))];
                v_descripcion := 'Elementos decorativos para ambientación de espacios.';
                v_cantidad := floor(random() * 20)::INTEGER + 5;
                
            WHEN 'seguridad' THEN
                v_nombre := v_nombres_seguridad[1 + floor(random() * array_length(v_nombres_seguridad, 1))];
                v_descripcion := 'Servicios de seguridad para garantizar el orden durante el evento.';
                v_cantidad := floor(random() * 15)::INTEGER + 3;
                
            ELSE -- personal
                v_nombre := v_nombres_personal[1 + floor(random() * array_length(v_nombres_personal, 1))];
                v_descripcion := 'Personal capacitado para asistencia y coordinación de eventos.';
                v_cantidad := floor(random() * 25)::INTEGER + 5;
        END CASE;
        
        -- Añadir número al nombre para evitar duplicados
        v_nombre := v_nombre || ' tipo ' || i;
        
        -- Insertar recurso
        INSERT INTO recursos (nombre, tipo, descripcion, cantidad_disponible, requiere_reserva)
        VALUES (
            v_nombre,
            v_tipo,
            v_descripcion,
            v_cantidad,
            (random() > 0.3) -- 70% requieren reserva
        );
    END LOOP;
END $;

-- =============================================================================================
-- 10. INSERTANDO EVENTOS (100 registros)
-- =============================================================================================

-- Primero, insertamos algunos eventos específicos
INSERT INTO eventos (sede_id, organizador_id, titulo, descripcion, fecha_inicio, fecha_fin, 
                  capacidad_maxima, precio_entrada, publicado, estado, fecha_publicacion)
VALUES
    (1, 2, 'Festival de Música Clásica', 'Gran festival con orquestas nacionales e internacionales', 
     CURRENT_DATE + INTERVAL '30 days' + TIME '19:00', CURRENT_DATE + INTERVAL '30 days' + TIME '22:30',
     1000, 150.00, TRUE, 'programado', CURRENT_DATE - INTERVAL '20 days'),
    
    (2, 3, 'Exhibición de Arte Contemporáneo', 'Muestra de artistas emergentes de Centroamérica', 
     CURRENT_DATE + INTERVAL '15 days' + TIME '10:00', CURRENT_DATE + INTERVAL '45 days' + TIME '18:00',
     500, 75.00, TRUE, 'programado', CURRENT_DATE - INTERVAL '30 days'),
    
    (3, 2, 'Obra de Teatro: El Quijote', 'Adaptación contemporánea de la obra de Cervantes', 
     CURRENT_DATE + INTERVAL '7 days' + TIME '20:00', CURRENT_DATE + INTERVAL '7 days' + TIME '22:00',
     800, 125.00, TRUE, 'programado', CURRENT_DATE - INTERVAL '25 days'),
    
    (4, 3, 'Taller de Danza Folklórica', 'Aprende los bailes tradicionales de Guatemala', 
     CURRENT_DATE + INTERVAL '14 days' + TIME '15:00', CURRENT_DATE + INTERVAL '14 days' + TIME '18:00',
     30, 50.00, TRUE, 'programado', CURRENT_DATE - INTERVAL '10 days'),
    
    (5, 2, 'Concierto Sinfónico', 'Presentación de la Orquesta Sinfónica Nacional', 
     CURRENT_DATE - INTERVAL '10 days' + TIME '19:30', CURRENT_DATE - INTERVAL '10 days' + TIME '22:00',
     600, 200.00, TRUE, 'finalizado', CURRENT_DATE - INTERVAL '40 days');

-- Ahora generamos 95 eventos más
DO $
DECLARE
    v_titulo_prefix VARCHAR[];
    v_titulo_suffix VARCHAR[];
    v_sede_count INTEGER;
    v_organizador_count INTEGER;
    v_titulo VARCHAR;
    v_descripcion TEXT;
    v_sede_id INTEGER;
    v_organizador_id INTEGER;
    v_capacidad INTEGER;
    v_precio DECIMAL(10,2);
    v_publicado BOOLEAN;
    v_fechas RECORD;
    v_estado estado_evento;
    v_fecha_publicacion TIMESTAMP;
    i INTEGER;
BEGIN
    -- Obtener conteos
    SELECT COUNT(*) INTO v_sede_count FROM sedes;
    SELECT COUNT(*) INTO v_organizador_count FROM usuarios WHERE tipo_usuario = 'organizador';
    
    -- Arrays para generación aleatoria
    v_titulo_prefix := ARRAY['Festival de', 'Concierto de', 'Exposición de', 'Muestra de', 
                          'Exhibición de', 'Encuentro de', 'Semana de', 'Jornada de', 
                          'Taller de', 'Seminario de', 'Conferencia sobre', 'Charla de',
                          'Espectáculo de', 'Presentación de', 'Noche de'];
    
    v_titulo_suffix := ARRAY['Música Clásica', 'Jazz', 'Rock Nacional', 'Arte Contemporáneo', 
                           'Pintura', 'Escultura', 'Teatro', 'Danza Contemporánea', 
                           'Literatura', 'Poesía', 'Cine Independiente', 'Fotografía',
                           'Artesanía', 'Culturas Ancestrales', 'Gastronomía', 
                           'Patrimonio Cultural', 'Artes Visuales', 'Títeres', 
                           'Cultura Popular', 'Historia del Arte'];
    
    FOR i IN 1..95 LOOP
        -- Generar título
        v_titulo := v_titulo_prefix[1 + floor(random() * array_length(v_titulo_prefix, 1))] || ' ' ||
                   v_titulo_suffix[1 + floor(random() * array_length(v_titulo_suffix, 1))];
        
        -- Añadir número para evitar duplicados en algunos casos
        IF i % 5 = 0 THEN
            v_titulo := v_titulo || ' ' || (2020 + (i % 5))::TEXT;
        END IF;
        
        -- Generar descripción
        v_descripcion := 'Evento cultural que reúne a destacados ';
        
        CASE 
            WHEN i % 4 = 0 THEN v_descripcion := v_descripcion || 'artistas del ámbito musical.';
            WHEN i % 4 = 1 THEN v_descripcion := v_descripcion || 'exponentes de las artes visuales.';
            WHEN i % 4 = 2 THEN v_descripcion := v_descripcion || 'representantes del teatro y la danza.';
            ELSE v_descripcion := v_descripcion || 'participantes de diversas disciplinas artísticas.';
        END CASE;
        
        IF random() > 0.5 THEN
            v_descripcion := v_descripcion || ' Una oportunidad única para disfrutar y apreciar el arte y la cultura.';
        END IF;
        
        -- Seleccionar sede aleatoria
        v_sede_id := 1 + floor(random() * v_sede_count);
        
        -- Seleccionar organizador aleatorio (solo tipo organizador)
        -- Hay 15 organizadores (del 2 al 16), seleccionar uno aleatorio
        v_organizador_id := 2 + floor(random() * 15);
        
        -- Generar capacidad (entre 20 y 2000)
        v_capacidad := GREATEST(20, floor(random() * 2000)::INTEGER);
        
        -- Generar precio (entre 0 y 300, algunos son gratuitos)
        IF random() > 0.8 THEN
            v_precio := 0.00; -- 20% son gratuitos
        ELSE
            v_precio := (floor(random() * 60) * 5)::DECIMAL(10,2); -- Múltiplo de 5 entre 5 y 300
        END IF;
        
        -- Determinar si está publicado (80% sí)
        v_publicado := random() > 0.2;
        
        -- Generar fechas aleatorias
        SELECT * INTO v_fechas FROM timestamp_evento_aleatorio();
        
        -- Determinar estado según fechas
        IF v_fechas.fecha_inicio <= CURRENT_TIMESTAMP AND v_fechas.fecha_fin >= CURRENT_TIMESTAMP THEN
            v_estado := 'en_curso';
        ELSIF v_fechas.fecha_fin < CURRENT_TIMESTAMP THEN
            v_estado := 'finalizado';
        ELSE
            v_estado := 'programado';
        END IF;
        
        -- Generar fecha de publicación para eventos publicados
        IF v_publicado THEN
            -- La publicación ocurre entre 60 y 10 días antes del evento
            v_fecha_publicacion := v_fechas.fecha_inicio - ((floor(random() * 50) + 10) * INTERVAL '1 day');
        ELSE
            v_fecha_publicacion := NULL;
        END IF;
        
        -- Insertar evento
        INSERT INTO eventos (sede_id, organizador_id, titulo, descripcion, fecha_inicio, fecha_fin,
                          capacidad_maxima, precio_entrada, publicado, estado, fecha_publicacion)
        VALUES (
            v_sede_id,
            v_organizador_id,
            v_titulo,
            v_descripcion,
            v_fechas.fecha_inicio,
            v_fechas.fecha_fin,
            v_capacidad,
            v_precio,
            v_publicado,
            v_estado,
            v_fecha_publicacion
        );
    END LOOP;
END $;

-- =============================================================================================
-- 11. INSERTANDO RELACIONES EVENTO-CATEGORÍAS (Asignar categorías a eventos)
-- =============================================================================================

-- Para cada evento, asignar entre 1 y 3 categorías aleatorias
DO $
DECLARE
    v_evento_ids INTEGER[];
    v_categoria_ids INTEGER[];
    v_evento_id INTEGER;
    v_cat_count INTEGER;
    v_cat_id INTEGER;
    i INTEGER;
    j INTEGER;
BEGIN
    -- Obtener todos los IDs de eventos
    SELECT array_agg(evento_id) INTO v_evento_ids FROM eventos;
    
    -- Obtener todos los IDs de categorías
    SELECT array_agg(categoria_id) INTO v_categoria_ids FROM categorias;
    
    -- Para cada evento
    FOREACH v_evento_id IN ARRAY v_evento_ids LOOP
        -- Determinar cuántas categorías asignar (entre 1 y 3)
        v_cat_count := 1 + floor(random() * 3);
        
        -- Asignar categorías aleatorias
        FOR j IN 1..v_cat_count LOOP
            v_cat_id := v_categoria_ids[1 + floor(random() * array_length(v_categoria_ids, 1))];
            
            -- Insertar si no existe ya la relación
            BEGIN
                INSERT INTO evento_categorias (evento_id, categoria_id)
                VALUES (v_evento_id, v_cat_id);
            EXCEPTION WHEN unique_violation THEN
                -- Ya existe, intentar con otro
                CONTINUE;
            END;
        END LOOP;
    END LOOP;
END $;

-- =============================================================================================
-- 15. INSERTANDO ENTRADAS (Vendidas para eventos)
-- =============================================================================================

-- Para cada evento, generar un número de entradas vendidas
DO $
DECLARE
    v_evento_record RECORD;
    v_usuario_ids INTEGER[];
    v_usuario_id INTEGER;
    v_entradas_vender INTEGER;
    v_metodos_pago VARCHAR[];
    v_metodo VARCHAR;
    v_precio DECIMAL(10,2);
    v_codigo VARCHAR(20);
    v_estado estado_entrada;
    v_check_in BOOLEAN;
    v_fecha_check_in TIMESTAMP;
    i INTEGER;
BEGIN
    -- Obtener IDs de usuarios tipo 'cliente'
    SELECT array_agg(usuario_id) INTO v_usuario_ids 
    FROM usuarios 
    WHERE tipo_usuario = 'cliente';
    
    -- Lista de métodos de pago
    v_metodos_pago := ARRAY['Tarjeta de crédito', 'Tarjeta de débito', 'Transferencia bancaria', 
                           'PayPal', 'Efectivo', 'Depósito bancario'];
    
    -- Para cada evento publicado
    FOR v_evento_record IN 
        SELECT e.evento_id, e.capacidad_maxima, e.precio_entrada, e.fecha_inicio, e.fecha_fin, e.estado, e.fecha_publicacion 
        FROM eventos e 
        WHERE e.publicado = TRUE
    LOOP
        -- Determinar cuántas entradas vender (entre 10% y 90% de la capacidad)
        v_entradas_vender := GREATEST(1, floor(v_evento_record.capacidad_maxima * (0.1 + random() * 0.8))::INTEGER);
        
        -- Ajustar entradas según estado del evento (los finalizados tienen más entradas vendidas)
        IF v_evento_record.estado = 'finalizado' THEN
            v_entradas_vender := GREATEST(v_entradas_vender, floor(v_evento_record.capacidad_maxima * 0.4)::INTEGER);
        END IF;
        
        -- Vender entradas
        FOR i IN 1..v_entradas_vender LOOP
            -- Seleccionar usuario aleatorio
            v_usuario_id := v_usuario_ids[1 + floor(random() * array_length(v_usuario_ids, 1))];
            
            -- Seleccionar método de pago aleatorio
            v_metodo := v_metodos_pago[1 + floor(random() * array_length(v_metodos_pago, 1))];
            
            -- Precio (igual al del evento, con posible descuento aleatorio)
            IF random() > 0.8 THEN -- 20% con descuento
                v_precio := v_evento_record.precio_entrada * (0.8 + random() * 0.15); -- 5-20% descuento
                v_precio := ROUND(v_precio, 2); -- Redondear a 2 decimales
            ELSE
                v_precio := v_evento_record.precio_entrada;
            END IF;
            
            -- Determinar estado y check-in
            IF v_evento_record.estado = 'finalizado' THEN
                -- Para eventos finalizados, la mayoría de entradas fueron utilizadas
                IF random() > 0.15 THEN -- 85% fueron usadas
                    v_estado := 'utilizada';
                    v_check_in := TRUE;
                    -- Fecha de check-in entre 15 minutos antes del inicio y 1 hora después
                    v_fecha_check_in := v_evento_record.fecha_inicio - 
                                      INTERVAL '15 minutes' + 
                                      (random() * 75 * INTERVAL '1 minute');
                ELSE
                    v_estado := 'pagada';
                    v_check_in := FALSE;
                    v_fecha_check_in := NULL;
                END IF;
            ELSIF v_evento_record.estado = 'en_curso' THEN
                -- Para eventos en curso, algunas entradas ya se usaron
                IF random() > 0.6 THEN -- 40% ya se usaron
                    v_estado := 'utilizada';
                    v_check_in := TRUE;
                    v_fecha_check_in := v_evento_record.fecha_inicio + (random() * 
                                      EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - v_evento_record.fecha_inicio)) * 
                                      INTERVAL '1 second');
                ELSE
                    v_estado := 'pagada';
                    v_check_in := FALSE;
                    v_fecha_check_in := NULL;
                END IF;
            ELSE
                -- Para eventos futuros, todas las entradas están pagadas o algunas reservadas
                IF random() > 0.2 THEN -- 80% pagadas
                    v_estado := 'pagada';
                ELSE
                    v_estado := 'reservada';
                END IF;
                v_check_in := FALSE;
                v_fecha_check_in := NULL;
            END IF;
            
            -- Generar código único para la entrada
            v_codigo := 'E' || v_evento_record.evento_id || '-' || 
                      TO_CHAR(CURRENT_DATE, 'YYMMDD') || '-' ||
                      LPAD(i::TEXT, 4, '0');
            
            -- Insertar entrada
            INSERT INTO entradas (evento_id, usuario_id, codigo_entrada, fecha_compra, 
                               precio_pagado, metodo_pago, estado, check_in, fecha_check_in)
            VALUES (
                v_evento_record.evento_id,
                v_usuario_id,
                v_codigo,
                -- Fecha de compra entre la fecha de publicación y la fecha actual o de inicio
                v_evento_record.fecha_publicacion + 
                  (random() * EXTRACT(EPOCH FROM (LEAST(CURRENT_TIMESTAMP, v_evento_record.fecha_inicio) - 
                                                v_evento_record.fecha_publicacion)) * 
                   INTERVAL '1 second'),
                v_precio,
                v_metodo,
                v_estado,
                v_check_in,
                v_fecha_check_in
            );
        END LOOP;
    END LOOP;
END $;

-- =============================================================================================
-- 16. INSERTANDO COMENTARIOS (Reseñas y opiniones de eventos)
-- =============================================================================================

-- Para eventos finalizados y algunos en curso, agregar comentarios de los asistentes
DO $
DECLARE
    v_evento_entrada RECORD;
    v_contenido_pos TEXT[];
    v_contenido_neu TEXT[];
    v_contenido_neg TEXT[];
    v_contenido TEXT;
    v_calificacion INTEGER;
    v_aprobado BOOLEAN;
    v_fecha_creacion TIMESTAMP;
BEGIN
    -- Arrays de posibles comentarios positivos
    v_contenido_pos := ARRAY[
        'Excelente evento, superó mis expectativas. La organización fue impecable.',
        'Me encantó la experiencia, sin duda repetiría. Felicitaciones a los organizadores.',
        'Un evento de primer nivel. Los artistas fueron extraordinarios y el ambiente increíble.',
        'Magnífica organización y contenido. Una de las mejores experiencias culturales del año.',
        'Brillante en todos los aspectos. Volveré al próximo sin duda alguna.',
        'Los artistas demostraron un nivel excepcional. Me sentí totalmente inmerso en la experiencia.',
        'Increíble evento cultural, recomiendo a todos que no se lo pierdan en futuras ediciones.',
        'Una producción de altísima calidad, cada detalle estuvo pensado para el disfrute del público.'
    ];
    
    -- Arrays de posibles comentarios neutros
    v_contenido_neu := ARRAY[
        'El evento estuvo bien, aunque esperaba algo más impactante.',
        'Cumplió con lo prometido, ni más ni menos.',
        'Interesante propuesta cultural, aunque mejorable en algunos aspectos.',
        'Los artistas cumplieron, pero la organización podría mejorar.',
        'Experiencia agradable, aunque el precio me pareció algo elevado para lo ofrecido.',
        'El contenido fue bueno, sin embargo la logística tuvo algunos problemas menores.',
        'Evento correcto, ni sobresaliente ni decepcionante.',
        'Había partes muy buenas y otras mejorables. En general, satisfecho.'
    ];
    
    -- Arrays de posibles comentarios negativos
    v_contenido_neg := ARRAY[
        'Decepcionante. No cumplió con las expectativas que generó la publicidad.',
        'Mala organización. Hubo retrasos y problemas técnicos constantes.',
        'No volvería a asistir. La relación calidad-precio fue muy mala.',
        'Esperaba mucho más. Los artistas no estuvieron a la altura del evento.',
        'Experiencia frustrante. Problemas de sonido y visuales durante toda la presentación.',
        'No lo recomendaría. Perdí tiempo y dinero en algo que no valió la pena.',
        'El peor evento cultural al que he asistido. Totalmente improvisado.',
        'Desorganización total y falta de profesionalismo en todos los aspectos.'
    ];
    
    -- Para cada entrada usada en eventos finalizados o en curso
    FOR v_evento_entrada IN 
        SELECT e.evento_id, en.usuario_id, en.entrada_id, en.fecha_check_in
        FROM entradas en
        JOIN eventos e ON en.evento_id = e.evento_id
        WHERE en.check_in = TRUE
          AND e.estado IN ('finalizado', 'en_curso')
    LOOP
        -- Determinar si el usuario deja comentario (60% de probabilidad)
        IF random() <= 0.6 THEN
            -- Determinar calificación (1-5)
            v_calificacion := 1 + floor(random() * 5)::INTEGER;
            
            -- Seleccionar contenido según calificación
            IF v_calificacion >= 4 THEN -- Positivo
                v_contenido := v_contenido_pos[1 + floor(random() * array_length(v_contenido_pos, 1))];
            ELSIF v_calificacion = 3 THEN -- Neutro
                v_contenido := v_contenido_neu[1 + floor(random() * array_length(v_contenido_neu, 1))];
            ELSE -- Negativo
                v_contenido := v_contenido_neg[1 + floor(random() * array_length(v_contenido_neg, 1))];
            END IF;
            
            -- Determinar si está aprobado (85% sí)
            v_aprobado := random() <= 0.85;
            
            -- Fecha de creación: entre la fecha de check-in y 5 días después
            v_fecha_creacion := v_evento_entrada.fecha_check_in + 
                              (random() * 5 * INTERVAL '1 day');
                              
            -- Si es una fecha futura, ajustar a fecha actual
            IF v_fecha_creacion > CURRENT_TIMESTAMP THEN
                v_fecha_creacion := CURRENT_TIMESTAMP - (random() * 2 * INTERVAL '1 hour');
            END IF;
            
            -- Insertar comentario
            INSERT INTO comentarios (evento_id, usuario_id, contenido, calificacion, 
                                  fecha_creacion, aprobado)
            VALUES (
                v_evento_entrada.evento_id,
                v_evento_entrada.usuario_id,
                v_contenido,
                v_calificacion,
                v_fecha_creacion,
                v_aprobado
            );
        END IF;
    END LOOP;
END $;

-- =============================================================================================
-- 17. INSERTANDO RECORDATORIOS
-- =============================================================================================

-- Para eventos futuros, crear recordatorios para algunos usuarios con entradas
DO $
DECLARE
    v_evento_entrada RECORD;
    v_tipo tipo_recordatorio;
    v_fecha_programada TIMESTAMP;
    v_enviado BOOLEAN;
BEGIN
    -- Para cada entrada de eventos futuros
    FOR v_evento_entrada IN 
        SELECT e.evento_id, en.usuario_id, e.fecha_inicio
        FROM entradas en
        JOIN eventos e ON en.evento_id = e.evento_id
        WHERE e.fecha_inicio > CURRENT_TIMESTAMP
          AND e.estado = 'programado'
          AND en.estado IN ('reservada', 'pagada')
    LOOP
        -- Determinar si crear recordatorio (70% de probabilidad)
        IF random() <= 0.7 THEN
            -- Determinar tipo de recordatorio
            v_tipo := CASE 
                WHEN random() <= 0.6 THEN 'email'
                WHEN random() <= 0.8 THEN 'sms'
                ELSE 'app'
            END;
            
            -- Fecha programada (entre 1 y 3 días antes del evento)
            v_fecha_programada := v_evento_entrada.fecha_inicio - 
                                ((1 + floor(random() * 2)) * INTERVAL '1 day');
            
            -- Determinar si ya fue enviado (depende de la fecha programada)
            v_enviado := v_fecha_programada <= CURRENT_TIMESTAMP;
            
            -- Insertar recordatorio
            INSERT INTO recordatorios (evento_id, usuario_id, tipo, fecha_envio, 
                                    enviado, fecha_programada)
            VALUES (
                v_evento_entrada.evento_id,
                v_evento_entrada.usuario_id,
                v_tipo,
                CASE WHEN v_enviado THEN v_fecha_programada ELSE NULL END,
                v_enviado,
                v_fecha_programada
            );
        END IF;
    END LOOP;
END $;

-- =============================================================================================
-- 18. INSERTANDO ARCHIVOS DE EVENTOS
-- =============================================================================================

-- Para cada evento, agregar archivos asociados
DO $
DECLARE
    v_evento_record RECORD;
    v_tipo_archivo tipo_archivo;
    v_url VARCHAR;
    v_nombre VARCHAR;
    v_formato VARCHAR;
    v_tamano INTEGER;
    v_fecha_subida TIMESTAMP;
    v_formatos_imagen VARCHAR[];
    v_formatos_video VARCHAR[];
    v_formatos_audio VARCHAR[];
    v_formatos_doc VARCHAR[];
    v_count INTEGER;
    i INTEGER;
BEGIN
    -- Arrays de posibles formatos
    v_formatos_imagen := ARRAY['jpg', 'png', 'jpeg', 'webp'];
    v_formatos_video := ARRAY['mp4', 'avi', 'mov', 'webm'];
    v_formatos_audio := ARRAY['mp3', 'wav', 'ogg', 'flac'];
    v_formatos_doc := ARRAY['pdf', 'docx', 'pptx', 'xlsx'];
    
    -- Para cada evento
    FOR v_evento_record IN 
        SELECT evento_id, titulo, fecha_creacion, estado
        FROM eventos
        WHERE publicado = TRUE
    LOOP
        -- Determinar cuántos archivos agregar (entre 2 y 8)
        v_count := 2 + floor(random() * 7);
        
        -- Agregar archivos
        FOR i IN 1..v_count LOOP
            -- Determinar tipo de archivo
            v_tipo_archivo := CASE 
                WHEN i <= 2 OR random() <= 0.5 THEN 'imagen' -- Mayoría imágenes
                WHEN random() <= 0.6 THEN 'documento'
                WHEN random() <= 0.7 THEN 'video'
                WHEN random() <= 0.8 THEN 'audio'
                ELSE 'otro'
            END;
            
            -- Determinar formato según tipo
            CASE v_tipo_archivo
                WHEN 'imagen' THEN
                    v_formato := v_formatos_imagen[1 + floor(random() * array_length(v_formatos_imagen, 1))];
                WHEN 'video' THEN
                    v_formato := v_formatos_video[1 + floor(random() * array_length(v_formatos_video, 1))];
                WHEN 'audio' THEN
                    v_formato := v_formatos_audio[1 + floor(random() * array_length(v_formatos_audio, 1))];
                WHEN 'documento' THEN
                    v_formato := v_formatos_doc[1 + floor(random() * array_length(v_formatos_doc, 1))];
                ELSE
                    v_formato := 'dat';
            END CASE;
            
            -- Generar nombre y URL
            v_nombre := CASE v_tipo_archivo
                WHEN 'imagen' THEN 
                    CASE 
                        WHEN i = 1 THEN 'Portada principal'
                        WHEN i = 2 THEN 'Banner promocional'
                        ELSE 'Imagen ' || i-2 || ' del evento'
                    END
                WHEN 'video' THEN 'Video promocional ' || i
                WHEN 'audio' THEN 'Audio promocional ' || i
                WHEN 'documento' THEN 
                    CASE random()
                        WHEN random() <= 0.3 THEN 'Programa del evento'
                        WHEN random() <= 0.6 THEN 'Información para asistentes'
                        ELSE 'Detalles adicionales'
                    END
                ELSE 'Archivo adicional ' || i
            END;
            
            v_url := 'https://storage.eventosculturales.com/' || 
                   v_evento_record.evento_id || '/' || 
                   lower(regexp_replace(v_nombre, '[^a-zA-Z0-9]', '_', 'g')) || 
                   '.' || v_formato;
            
            -- Generar tamaño según tipo (en KB)
            v_tamano := CASE v_tipo_archivo
                WHEN 'imagen' THEN 500 + floor(random() * 4500)::INTEGER
                WHEN 'video' THEN 10000 + floor(random() * 90000)::INTEGER
                WHEN 'audio' THEN 3000 + floor(random() * 17000)::INTEGER
                WHEN 'documento' THEN 100 + floor(random() * 2900)::INTEGER
                ELSE 50 + floor(random() * 950)::INTEGER
            END;
            
            -- Fecha de subida (entre la fecha de creación del evento y la fecha actual)
            v_fecha_subida := v_evento_record.fecha_creacion + 
                           (random() * EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - v_evento_record.fecha_creacion)) * 
                            INTERVAL '1 second');
            
            -- Insertar archivo
            INSERT INTO archivos_eventos (evento_id, tipo, url, nombre, fecha_subida, formato, tamano_kb)
            VALUES (
                v_evento_record.evento_id,
                v_tipo_archivo,
                v_url,
                v_nombre,
                v_fecha_subida,
                v_formato,
                v_tamano
            );
        END LOOP;
    END LOOP;
END $;

-- =============================================================================================
-- VERIFICACIÓN FINAL
-- =============================================================================================

-- Verificar número de registros en cada tabla
SELECT 'usuarios' AS tabla, COUNT(*) AS registros FROM usuarios UNION ALL
SELECT 'intereses_usuarios', COUNT(*) FROM intereses_usuarios UNION ALL
SELECT 'sedes', COUNT(*) FROM sedes UNION ALL
SELECT 'salas_sedes', COUNT(*) FROM salas_sedes UNION ALL
SELECT 'categorias', COUNT(*) FROM categorias UNION ALL
SELECT 'artistas', COUNT(*) FROM artistas UNION ALL
SELECT 'especialidades_artistas', COUNT(*) FROM especialidades_artistas UNION ALL
SELECT 'patrocinadores', COUNT(*) FROM patrocinadores UNION ALL
SELECT 'recursos', COUNT(*) FROM recursos UNION ALL
SELECT 'eventos', COUNT(*) FROM eventos UNION ALL
SELECT 'evento_categorias', COUNT(*) FROM evento_categorias UNION ALL
SELECT 'evento_artistas', COUNT(*) FROM evento_artistas UNION ALL
SELECT 'evento_patrocinadores', COUNT(*) FROM evento_patrocinadores UNION ALL
SELECT 'evento_recursos', COUNT(*) FROM evento_recursos UNION ALL
SELECT 'entradas', COUNT(*) FROM entradas UNION ALL
SELECT 'comentarios', COUNT(*) FROM comentarios UNION ALL
SELECT 'recordatorios', COUNT(*) FROM recordatorios UNION ALL
SELECT 'archivos_eventos', COUNT(*) FROM archivos_eventos
ORDER BY tabla;

-- Limpiar funciones auxiliares que solo se usaron para generar datos
DROP FUNCTION IF EXISTS fecha_aleatoria(DATE, DATE);
DROP FUNCTION IF EXISTS timestamp_evento_aleatorio(INTEGER, INTEGER, INTEGER, INTEGER, INTEGER, INTEGER);
 no existe ya la relación
            BEGIN
                INSERT INTO evento_categorias (evento_id, categoria_id)
                VALUES (v_evento_id, v_cat_id);
            EXCEPTION WHEN unique_violation THEN
                -- Ya existe, intentar con otro
                CONTINUE;
            END;
        END LOOP;
    END LOOP;
END $;

-- =============================================================================================
-- 12. INSERTANDO RELACIONES EVENTO-ARTISTAS (Asignar artistas a eventos)
-- =============================================================================================

-- Para cada evento, asignar entre 1 y 5 artistas con roles específicos
DO $
DECLARE
    v_evento_record RECORD;
    v_artista_ids INTEGER[];
    v_roles VARCHAR[];
    v_artista_id INTEGER;
    v_rol VARCHAR;
    v_hora_inicio TIMESTAMP;
    v_hora_fin TIMESTAMP;
    v_duracion_mins INTEGER;
    v_artistas_count INTEGER;
    i INTEGER;
BEGIN
    -- Obtener todos los IDs de artistas
    SELECT array_agg(artista_id) INTO v_artista_ids FROM artistas;
    
    -- Lista de posibles roles
    v_roles := ARRAY['Músico principal', 'Director', 'Solista', 'Expositor', 'Presentador', 
                    'Conferencista', 'Actor principal', 'Bailarín principal', 'Coreógrafo',
                    'Conductor', 'Invitado especial', 'Diseñador', 'Poeta', 'Narrador',
                    'Director artístico', 'Curador', 'Tallerista'];
    
    -- Para cada evento
    FOR v_evento_record IN SELECT evento_id, fecha_inicio, fecha_fin, titulo FROM eventos LOOP
        -- Determinar cuántos artistas asignar (entre 1 y 5, dependiendo del tipo de evento)
        IF v_evento_record.titulo LIKE '%Concierto%' OR v_evento_record.titulo LIKE '%Festival%' THEN
            v_artistas_count := 2 + floor(random() * 4); -- Entre 2 y 5 para conciertos/festivales
        ELSE
            v_artistas_count := 1 + floor(random() * 2); -- Entre 1 y 2 para otros eventos
        END IF;
        
        -- Asignar artistas aleatorios
        FOR i IN 1..v_artistas_count LOOP
            -- Seleccionar artista aleatorio
            v_artista_id := v_artista_ids[1 + floor(random() * array_length(v_artista_ids, 1))];
            
            -- Seleccionar rol aleatorio
            v_rol := v_roles[1 + floor(random() * array_length(v_roles, 1))];
            
            -- Calcular horas de participación (dentro del periodo del evento)
            v_duracion_mins := 30 + floor(random() * 120)::INTEGER; -- Entre 30 mins y 2.5 horas
            
            -- Para eventos de un solo día
            IF DATE_PART('day', v_evento_record.fecha_fin - v_evento_record.fecha_inicio) < 1 THEN
                -- Inicio entre 15 mins después del inicio del evento y 30 mins antes del final
                v_hora_inicio := v_evento_record.fecha_inicio + 
                              ((15 + floor(random() * 
                                (EXTRACT(EPOCH FROM (v_evento_record.fecha_fin - v_evento_record.fecha_inicio))/60 - 45)))
                              * INTERVAL '1 minute';
                              
                -- Duración no excede el final del evento
                v_duracion_mins := LEAST(v_duracion_mins, 
                                      EXTRACT(EPOCH FROM (v_evento_record.fecha_fin - v_hora_inicio))/60 - 15);
                                      
                v_hora_fin := v_hora_inicio + (v_duracion_mins * INTERVAL '1 minute');
            ELSE
                -- Para eventos de varios días, participación en un día aleatorio
                v_hora_inicio := v_evento_record.fecha_inicio + 
                              (floor(random() * EXTRACT(EPOCH FROM (v_evento_record.fecha_fin - v_evento_record.fecha_inicio))/
                                    (3600*24)) * INTERVAL '1 day') + 
                              ((10 + floor(random() * 8)) * INTERVAL '1 hour'); -- Entre 10am y 6pm
                              
                v_hora_fin := v_hora_inicio + (v_duracion_mins * INTERVAL '1 minute');
                
                -- Asegurar que no exceda el final del evento
                IF v_hora_fin > v_evento_record.fecha_fin THEN
                    v_hora_fin := v_evento_record.fecha_fin;
                END IF;
            END IF;
            
            -- Insertar si no existe ya la relación
            BEGIN
                INSERT INTO evento_artistas (evento_id, artista_id, rol, 
                                          hora_inicio_participacion, hora_fin_participacion)
                VALUES (v_evento_record.evento_id, v_artista_id, v_rol, v_hora_inicio, v_hora_fin);
            EXCEPTION WHEN unique_violation THEN
                -- Ya existe, intentar con otro
                CONTINUE;
            END;
        END LOOP;
    END LOOP;
END $;

-- =============================================================================================
-- 13. INSERTANDO RELACIONES EVENTO-PATROCINADORES
-- =============================================================================================

-- Para eventos seleccionados, asignar entre 1 y 3 patrocinadores
DO $
DECLARE
    v_evento_ids INTEGER[];
    v_patrocinador_ids INTEGER[];
    v_evento_id INTEGER;
    v_patrocinador_id INTEGER;
    v_monto DECIMAL(12,2);
    v_beneficios TEXT;
    v_acuerdos TEXT;
    v_pat_count INTEGER;
    i INTEGER;
BEGIN
    -- Obtener todos los IDs de eventos
    SELECT array_agg(evento_id) INTO v_evento_ids FROM eventos;
    
    -- Obtener todos los IDs de patrocinadores
    SELECT array_agg(patrocinador_id) INTO v_patrocinador_ids FROM patrocinadores;
    
    -- Lista de posibles beneficios
    v_beneficios := ARRAY[
        'Logo en materiales promocionales y página web',
        'Mención en redes sociales y comunicados de prensa',
        'Espacio para stand promocional en el evento',
        'Entradas VIP para invitados del patrocinador',
        'Presencia de marca en photocall y área de prensa'
    ];
    
    -- Lista de posibles acuerdos
    v_acuerdos := ARRAY[
        'Apoyo económico directo para la realización del evento',
        'Aportación en especie (materiales, servicios o productos)',
        'Difusión del evento en sus canales de comunicación',
        'Apoyo logístico para la realización del evento',
        'Intercambio de servicios y visibilidad de marca'
    ];
    
    -- Para aproximadamente 70% de los eventos, asignar patrocinadores
    FOREACH v_evento_id IN ARRAY v_evento_ids LOOP
        IF random() > 0.3 THEN -- 70% de probabilidad
            -- Determinar cuántos patrocinadores asignar (entre 1 y 3)
            v_pat_count := 1 + floor(random() * 3);
            
            -- Asignar patrocinadores aleatorios
            FOR i IN 1..v_pat_count LOOP
                -- Seleccionar patrocinador aleatorio
                v_patrocinador_id := v_patrocinador_ids[1 + floor(random() * array_length(v_patrocinador_ids, 1))];
                
                -- Generar monto de patrocinio (entre 1000 y 50000)
                v_monto := (1000 + floor(random() * 49) * 1000)::DECIMAL(12,2);
                
                -- Seleccionar beneficios y acuerdos aleatorios
                SELECT 
                    v_beneficios[1 + floor(random() * array_length(v_beneficios, 1))] || '. ' ||
                    v_beneficios[1 + floor(random() * array_length(v_beneficios, 1))]
                INTO v_beneficios;
                
                SELECT 
                    v_acuerdos[1 + floor(random() * array_length(v_acuerdos, 1))] || '. ' ||
                    v_acuerdos[1 + floor(random() * array_length(v_acuerdos, 1))]
                INTO v_acuerdos;
                
                -- Insertar si no existe ya la relación
                BEGIN
                    INSERT INTO evento_patrocinadores (evento_id, patrocinador_id, 
                                                  monto_patrocinio, beneficios, acuerdos)
                    VALUES (v_evento_id, v_patrocinador_id, v_monto, v_beneficios, v_acuerdos);
                EXCEPTION WHEN unique_violation THEN
                    -- Ya existe, intentar con otro
                    CONTINUE;
                END;
            END LOOP;
        END IF;
    END LOOP;
END $;

-- =============================================================================================
-- 14. INSERTANDO RELACIONES EVENTO-RECURSOS
-- =============================================================================================

-- Para cada evento, asignar entre 2 y 6 tipos de recursos necesarios
DO $
DECLARE
    v_evento_ids INTEGER[];
    v_recurso_ids INTEGER[];
    v_evento_id INTEGER;
    v_recurso_id INTEGER;
    v_cantidad INTEGER;
    v_rec_count INTEGER;
    i INTEGER;
BEGIN
    -- Obtener todos los IDs de eventos
    SELECT array_agg(evento_id) INTO v_evento_ids FROM eventos;
    
    -- Obtener todos los IDs de recursos
    SELECT array_agg(recurso_id) INTO v_recurso_ids FROM recursos;
    
    -- Para cada evento
    FOREACH v_evento_id IN ARRAY v_evento_ids LOOP
        -- Determinar cuántos recursos asignar (entre 2 y 6)
        v_rec_count := 2 + floor(random() * 5);
        
        -- Asignar recursos aleatorios
        FOR i IN 1..v_rec_count LOOP
            -- Seleccionar recurso aleatorio
            v_recurso_id := v_recurso_ids[1 + floor(random() * array_length(v_recurso_ids, 1))];
            
            -- Determinar cantidad asignada (entre 1 y 20, dependiendo del tipo)
            SELECT 
                CASE 
                    WHEN tipo IN ('equipo_sonido', 'equipo_iluminacion') THEN 1 + floor(random() * 3)
                    WHEN tipo IN ('seguridad', 'personal') THEN 2 + floor(random() * 10)
                    WHEN tipo = 'mobiliario' THEN 5 + floor(random() * 20)
                    ELSE 1 + floor(random() * 5)
                END INTO v_cantidad
            FROM recursos WHERE recurso_id = v_recurso_id;
            
            -- Insertar si