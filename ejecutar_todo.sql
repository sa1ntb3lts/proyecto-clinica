\echo '========================================================='
\echo 'Iniciando reconstrucción total de la BD: Clínica Vida Plena'
\echo '========================================================='

-- Configurar codificación y manejo de errores si se requiere
\set ON_ERROR_STOP on

-- 1. Estructura y Esquema Base (Tablas, Llaves, Restricciones, Índices parciales)
\echo '[1/7] Creando esquema, tablas, restricciones y llaves...'
\i sql/01_esquema.sql

-- 2. Datos Masivos y Poblado Inicial (Sedes, Médicos, Pacientes, 50k+ citas con generate_series)
\echo '[2/7] Insertando datos base y volumen masivo (50,000+ citas)...'
\i sql/02_datos.sql

-- 3. Vistas e Índices de Rendimiento Adicionales
\echo '[3/7] Creando vistas del sistema e índices de rendimiento...'
\i sql/03_vistas_indices.sql

-- 4. Funciones y Procedimientos Almacenados (Cálculo de seguros, dispensación por lotes)
\echo '[4/7] Compilando funciones y procedimientos almacenados (PL/pgSQL)...'
\i sql/04_funciones_procedimientos.sql

-- 5. Triggers y Auditoría Automática (Registro de cambios en citas y facturas)
\echo '[5/7] Configurando triggers y bitácora de auditoría...'
\i sql/05_triggers.sql

-- 6. Configuración de Roles, Privilegios y Seguridad (RN-19)
\echo '[6/7] Estableciendo roles, permisos y restricciones de privacidad...'
\i sql/06_seguridad.sql

-- 7. Pruebas de Consultas Analíticas (Validación del Módulo 6)
\echo '[7/7] Ejecutando consultas analíticas de verificación...'
\i sql/07_consultas.sql

\echo '========================================================='
\echo '¡PROYECTO COMPILADO Y EJECUTADO CON ÉXITO SIN ERRORES!'
\echo '=========================================================' 
