SET search_path TO clinica;

-- -------------------------------------------------------------------------
-- 1. ¿Qué citas tiene una sede en un rango de fechas, de la más próxima a la más lejana?
-- Técnica: WHERE, BETWEEN, ORDER BY
-- -------------------------------------------------------------------------
SELECT 
    c.id_cita, 
    c.fecha_hora_inicio, 
    p.nombre AS paciente, 
    m.nombre AS medico, 
    e.nombre AS especialidad
FROM clinica.cita c
JOIN clinica.paciente pac ON c.id_paciente = pac.id_persona
JOIN clinica.persona p ON pac.id_persona = p.id_persona
JOIN clinica.medico med ON c.id_medico = med.id_persona
JOIN clinica.persona m ON med.id_persona = m.id_persona
JOIN clinica.especialidad e ON c.id_especialidad = e.id_especialidad
WHERE c.id_sede = 1 
  AND c.fecha_hora_inicio BETWEEN '2026-01-01 00:00:00' AND '2026-12-31 23:59:59'
ORDER BY c.fecha_hora_inicio ASC;


-- -------------------------------------------------------------------------
-- 2. ¿Qué pacientes no tienen aseguradora? Mostrar «Particular» en su lugar.
-- Técnica: LEFT JOIN, IS NULL, COALESCE
-- -------------------------------------------------------------------------
SELECT 
    p.id_persona AS id_paciente, 
    per.nombre, 
    COALESCE(a.nombre_aseguradora, 'Particular') AS aseguradora
FROM clinica.paciente p
JOIN clinica.persona per ON p.id_persona = per.id_persona
LEFT JOIN clinica.paciente_aseguradora pa ON p.id_persona = pa.id_paciente
LEFT JOIN clinica.aseguradora a ON pa.id_aseguradora = a.id_aseguradora;


-- -------------------------------------------------------------------------
-- 3. ¿Qué pacientes coinciden con un nombre parcial, por páginas de 20 y con el nombre formateado?
-- Técnica: ILIKE, funciones de texto, LIMIT, OFFSET
-- -------------------------------------------------------------------------
SELECT 
    INITCAP(per.nombre) AS nombre_formateado, 
    per.telefono
FROM clinica.paciente p
JOIN clinica.persona per ON p.id_persona = per.id_persona
WHERE per.nombre ILIKE '%carlos%'
ORDER BY per.nombre
LIMIT 20 OFFSET 0;


-- -------------------------------------------------------------------------
-- 4. ¿Qué especialidades superaron 20 citas por mes en el último año?
-- Técnica: Funciones de fecha, GROUP BY, HAVING
-- -------------------------------------------------------------------------
SELECT 
    e.nombre AS especialidad, 
    DATE_TRUNC('month', c.fecha_hora_inicio) AS mes, 
    COUNT(*) AS total_citas
FROM clinica.cita c
JOIN clinica.especialidad e ON c.id_especialidad = e.id_especialidad
WHERE c.fecha_hora_inicio >= NOW() - INTERVAL '1 year'
GROUP BY e.id_especialidad, e.nombre, DATE_TRUNC('month', c.fecha_hora_inicio)
HAVING COUNT(*) > 20
ORDER BY mes DESC, total_citas DESC;


-- -------------------------------------------------------------------------
-- 5. ¿Cuál es la agenda del día, con paciente, médico, especialidad y sede?
-- Técnica: JOIN múltiple
-- -------------------------------------------------------------------------
SELECT 
    c.fecha_hora_inicio, 
    per_pac.nombre AS paciente, 
    per_med.nombre AS medico, 
    esp.nombre AS especialidad, 
    s.nombre AS sede, 
    c.estado
FROM clinica.cita c
JOIN clinica.paciente pac ON c.id_paciente = pac.id_persona
JOIN clinica.persona per_pac ON pac.id_persona = per_pac.id_persona
JOIN clinica.medico med ON c.id_medico = med.id_persona
JOIN clinica.persona per_med ON med.id_persona = per_med.id_persona
JOIN clinica.especialidad esp ON c.id_especialidad = esp.id_especialidad
JOIN clinica.sede s ON c.id_sede = s.id_sede
WHERE DATE(c.fecha_hora_inicio) = CURRENT_DATE
ORDER BY c.fecha_hora_inicio ASC;


-- -------------------------------------------------------------------------
-- 6. ¿Cuántas citas tuvo cada médico este mes, incluidos los que no tuvieron ninguna?
-- Técnica: LEFT JOIN, COUNT
-- -------------------------------------------------------------------------
SELECT 
    per.nombre AS medico, 
    COUNT(c.id_cita) AS total_citas
FROM clinica.medico m
JOIN clinica.persona per ON m.id_persona = per.id_persona
LEFT JOIN clinica.cita c ON m.id_persona = c.id_medico 
     AND DATE_TRUNC('month', c.fecha_hora_inicio) = DATE_TRUNC('month', CURRENT_DATE)
GROUP BY m.id_persona, per.nombre
ORDER BY total_citas DESC;


-- -------------------------------------------------------------------------
-- 7. ¿Cuántas citas hubo por cada combinación de sede y especialidad, incluidas las que suman cero?
-- Técnica: CROSS JOIN, LEFT JOIN
-- -------------------------------------------------------------------------
SELECT 
    s.nombre AS sede, 
    e.nombre AS especialidad, 
    COUNT(c.id_cita) AS total_citas
FROM clinica.sede s
CROSS JOIN clinica.especialidad e
LEFT JOIN clinica.cita c ON s.id_sede = c.id_sede AND e.id_especialidad = c.id_especialidad
GROUP BY s.id_sede, s.nombre, e.id_especialidad, e.nombre
ORDER BY s.nombre, e.nombre;


-- -------------------------------------------------------------------------
-- 8. ¿Qué pacientes menores tienen responsable, y quién es?
-- Técnica: Self join
-- -------------------------------------------------------------------------
SELECT 
    p_menor.nombre AS menor, 
    p_resp.nombre AS responsable
FROM clinica.paciente pac
JOIN clinica.persona p_menor ON pac.id_persona = p_menor.id_persona
JOIN clinica.paciente resp ON pac.id_responsable = resp.id_persona
JOIN clinica.persona p_resp ON resp.id_persona = p_resp.id_persona;


-- -------------------------------------------------------------------------
-- 9. ¿Qué medicamentos del catálogo nunca se han recetado?
-- Técnica: NOT EXISTS
-- -------------------------------------------------------------------------
SELECT 
    m.id_medicamento, 
    m.nombre_comercial
FROM clinica.medicamento m
WHERE NOT EXISTS (
    SELECT 1 FROM clinica.receta_detalle rd WHERE rd.id_medicamento = m.id_medicamento
);


-- -------------------------------------------------------------------------
-- 10. ¿Qué médicos facturan más que el promedio de su especialidad?
-- Técnica: Subconsulta correlacionada / CTEs
-- -------------------------------------------------------------------------
WITH facturacion_medico AS (
    SELECT 
        m.id_persona AS id_medico, 
        me.id_especialidad, 
        SUM(f.total) AS total_facturado
    FROM clinica.factura f
    JOIN clinica.consulta co ON f.id_consulta = co.id_consulta
    JOIN clinica.cita ci ON co.id_cita = ci.id_cita
    JOIN clinica.medico m ON ci.id_medico = m.id_persona
    JOIN clinica.medico_especialidad me ON m.id_persona = me.id_medico AND ci.id_especialidad = me.id_especialidad
    GROUP BY m.id_persona, me.id_especialidad
),
promedio_especialidad AS (
    SELECT 
        id_especialidad, 
        AVG(total_facturado) AS promedio_esp
    FROM facturacion_medico
    GROUP BY id_especialidad
)
SELECT 
    p.nombre AS medico, 
    fm.total_facturado, 
    pe.promedio_esp
FROM facturacion_medico fm
JOIN promedio_especialidad pe ON fm.id_especialidad = pe.id_especialidad
JOIN clinica.persona p ON fm.id_medico = p.id_persona
WHERE fm.total_facturado > pe.promedio_esp;


-- -------------------------------------------------------------------------
-- 11. ¿Qué personas son empleados y pacientes a la vez?
-- Técnica: INTERSECT (o JOIN directo)
-- -------------------------------------------------------------------------
SELECT id_persona FROM clinica.empleado
INTERSECT
SELECT id_persona FROM clinica.paciente;


-- -------------------------------------------------------------------------
-- 12. ¿Qué lotes vencen en los próximos 90 días, por sede y con su stock?
-- Técnica: Funciones de fecha, JOIN, WHERE
-- -------------------------------------------------------------------------
SELECT 
    s.nombre AS sede, 
    l.numero_lote, 
    l.fecha_vencimiento, 
    l.stock_actual, 
    m.nombre_comercial AS medicamento
FROM clinica.lote l
JOIN clinica.sede s ON l.id_sede = s.id_sede
JOIN clinica.medicamento m ON l.id_medicamento = m.id_medicamento
WHERE l.fecha_vencimiento BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '90 days'
ORDER BY l.fecha_vencimiento ASC;


-- -------------------------------------------------------------------------
-- 13. ¿Cómo cambian las citas por especialidad entre este mes y el anterior, incluidas las que solo aparecen en uno?
-- Técnica: CTE, FULL OUTER JOIN
-- -------------------------------------------------------------------------
WITH citas_este_mes AS (
    SELECT id_especialidad, COUNT(*) AS total
    FROM clinica.cita
    WHERE DATE_TRUNC('month', fecha_hora_inicio) = DATE_TRUNC('month', CURRENT_DATE)
    GROUP BY id_especialidad
),
citas_mes_anterior AS (
    SELECT id_especialidad, COUNT(*) AS total
    FROM clinica.cita
    WHERE DATE_TRUNC('month', fecha_hora_inicio) = DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')
    GROUP BY id_especialidad
)
SELECT 
    COALESCE(e1.id_especialidad, e2.id_especialidad) AS id_especialidad,
    COALESCE(e1.total, 0) AS citas_este_mes,
    COALESCE(e2.total, 0) AS citas_mes_anterior,
    COALESCE(e1.total, 0) - COALESCE(e2.total, 0) AS diferencia
FROM citas_este_mes e1
FULL OUTER JOIN citas_mes_anterior e2 ON e1.id_especialidad = e2.id_especialidad;


-- -------------------------------------------------------------------------
-- 14. ¿Cuál es el ranking de médicos por citas atendidas dentro de cada especialidad?
-- Técnica: DENSE_RANK, PARTITION BY
-- -------------------------------------------------------------------------
SELECT 
    e.nombre AS especialidad, 
    p.nombre AS medico, 
    COUNT(c.id_cita) AS citas_atendidas,
    DENSE_RANK() OVER (PARTITION BY c.id_especialidad ORDER BY COUNT(c.id_cita) DESC) AS ranking
FROM clinica.cita c
JOIN clinica.medico m ON c.id_medico = m.id_persona
JOIN clinica.persona p ON m.id_persona = p.id_persona
JOIN clinica.especialidad e ON c.id_especialidad = e.id_especialidad
WHERE c.estado = 'atendida'
GROUP BY c.id_especialidad, e.nombre, m.id_persona, p.nombre;


-- -------------------------------------------------------------------------
-- 15. ¿Cuál fue la última consulta de cada paciente?
-- Técnica: ROW_NUMBER
-- -------------------------------------------------------------------------
WITH ultimas_consultas AS (
    SELECT 
        co.id_consulta, 
        c.id_paciente, 
        co.motivo, 
        co.fecha_creacion,
        ROW_NUMBER() OVER (PARTITION BY c.id_paciente ORDER BY c.fecha_hora_inicio DESC) AS rn
    FROM clinica.consulta co
    JOIN clinica.cita c ON co.id_cita = c.id_cita
)
SELECT 
    id_paciente, 
    id_consulta, 
    motivo, 
    fecha_creacion
FROM ultimas_consultas
WHERE rn = 1; 
