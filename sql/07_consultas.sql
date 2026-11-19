-- =========================================================================
-- PROYECTO FINAL: CLINICA VIDA PLENA
-- Módulo: Consultas Analíticas (sql/07_consultas.sql)
-- Autor: Integrante 6
-- Nota: Alineado estrictamente con el esquema físico en sql/01_esquema.sql
-- =========================================================================

SET search_path TO clinica, public;

-- -------------------------------------------------------------------------
-- 1. ¿Qué citas tiene una sede en un rango de fechas, de la más próxima a la más lejana?
-- Técnica: WHERE, BETWEEN, ORDER BY
-- -------------------------------------------------------------------------
SELECT
    c.id_cita,
    c.fecha_hora_inicio,
    c.estado,
    per_pac.nombre || ' ' || per_pac.apellido AS paciente,
    per_med.nombre || ' ' || per_med.apellido AS medico,
    e.nombre AS especialidad
FROM clinica.cita c
JOIN clinica.paciente pac ON c.id_paciente = pac.id_persona
JOIN clinica.persona per_pac ON pac.id_persona = per_pac.id_persona
JOIN clinica.medico med ON c.id_medico = med.id_persona
JOIN clinica.persona per_med ON med.id_persona = per_med.id_persona
JOIN clinica.especialidad e ON c.id_especialidad = e.id_especialidad
WHERE c.id_sede = 1
  AND c.fecha_hora_inicio BETWEEN '2026-01-01 00:00:00' AND '2026-12-31 23:59:59'
ORDER BY c.fecha_hora_inicio ASC;


-- -------------------------------------------------------------------------
-- 2. ¿Qué pacientes no tienen aseguradora? Mostrar «Particular» en su lugar.
-- Técnica: LEFT JOIN, IS NULL, COALESCE
-- -------------------------------------------------------------------------
SELECT
    pac.id_persona AS id_paciente,
    per.nombre || ' ' || per.apellido AS paciente,
    COALESCE(a.nombre, 'Particular') AS aseguradora
FROM clinica.paciente pac
JOIN clinica.persona per ON pac.id_persona = per.id_persona
LEFT JOIN clinica.aseguradora a ON pac.id_aseguradora = a.id_aseguradora
ORDER BY pac.id_persona;

-- Variante si se desea filtrar únicamente los pacientes sin aseguradora (o mostrar todos con COALESCE):
-- WHERE pac.id_aseguradora IS NULL;


-- -------------------------------------------------------------------------
-- 3. ¿Qué pacientes coinciden con un nombre parcial, por páginas de 20 y con el nombre formateado?
-- Técnica: ILIKE, funciones de texto, LIMIT, OFFSET
-- -------------------------------------------------------------------------
SELECT
    pac.id_persona AS id_paciente,
    INITCAP(TRIM(per.nombre || ' ' || per.apellido)) AS nombre_formateado,
    per.telefono,
    per.email
FROM clinica.paciente pac
JOIN clinica.persona per ON pac.id_persona = per.id_persona
WHERE (per.nombre || ' ' || per.apellido) ILIKE '%carlos%'
ORDER BY nombre_formateado ASC, pac.id_persona ASC
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
    per_pac.nombre || ' ' || per_pac.apellido AS paciente,
    per_med.nombre || ' ' || per_med.apellido AS medico,
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
WHERE c.fecha_hora_inicio::date = CURRENT_DATE
ORDER BY c.fecha_hora_inicio ASC, s.nombre ASC;


-- -------------------------------------------------------------------------
-- 6. ¿Cuántas citas tuvo cada médico este mes, incluidos los que no tuvieron ninguna?
-- Técnica: LEFT JOIN, COUNT
-- -------------------------------------------------------------------------
SELECT
    med.id_persona AS id_medico,
    per.nombre || ' ' || per.apellido AS medico,
    COUNT(c.id_cita) AS total_citas
FROM clinica.medico med
JOIN clinica.persona per ON med.id_persona = per.id_persona
LEFT JOIN clinica.cita c
    ON med.id_persona = c.id_medico
   AND DATE_TRUNC('month', c.fecha_hora_inicio) = DATE_TRUNC('month', CURRENT_DATE)
GROUP BY med.id_persona, per.nombre, per.apellido
ORDER BY total_citas DESC, medico ASC;


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
LEFT JOIN clinica.cita c
    ON s.id_sede = c.id_sede
   AND e.id_especialidad = c.id_especialidad
GROUP BY s.id_sede, s.nombre, e.id_especialidad, e.nombre
ORDER BY s.nombre ASC, e.nombre ASC;


-- -------------------------------------------------------------------------
-- 8. ¿Qué pacientes menores tienen responsable, y quién es?
-- Técnica: Self join
-- -------------------------------------------------------------------------
SELECT
    pac_menor.id_persona AS id_paciente_menor,
    per_menor.nombre || ' ' || per_menor.apellido AS paciente_menor,
    pac_resp.id_persona AS id_responsable,
    per_resp.nombre || ' ' || per_resp.apellido AS responsable
FROM clinica.paciente pac_menor
JOIN clinica.persona per_menor ON pac_menor.id_persona = per_menor.id_persona
JOIN clinica.paciente pac_resp ON pac_menor.id_responsable = pac_resp.id_persona
JOIN clinica.persona per_resp ON pac_resp.id_persona = per_resp.id_persona
WHERE pac_menor.id_responsable IS NOT NULL
ORDER BY paciente_menor ASC;


-- -------------------------------------------------------------------------
-- 9. ¿Qué medicamentos del catálogo nunca se han recetado?
-- Técnica: NOT EXISTS
-- -------------------------------------------------------------------------
SELECT
    m.id_medicamento,
    m.nombre_comercial,
    m.principio_activo
FROM clinica.medicamento m
WHERE NOT EXISTS (
    SELECT 1
    FROM clinica.detalle_receta dr
    WHERE dr.id_medicamento = m.id_medicamento
)
ORDER BY m.nombre_comercial ASC;


-- -------------------------------------------------------------------------
-- 10. ¿Qué médicos facturan más que el promedio de su especialidad?
-- Técnica: Subconsulta correlacionada / CTEs
-- -------------------------------------------------------------------------
WITH facturacion_medico_esp AS (
    SELECT
        med.id_persona AS id_medico,
        me.id_especialidad,
        SUM(f.subtotal_consulta + f.subtotal_medicamentos) AS total_facturado
    FROM clinica.factura f
    JOIN clinica.consulta co ON f.id_consulta = co.id_consulta
    JOIN clinica.cita ci ON co.id_cita = ci.id_cita
    JOIN clinica.medico med ON ci.id_medico = med.id_persona
    JOIN clinica.medico_especialidad me
        ON med.id_persona = me.id_persona
       AND ci.id_especialidad = me.id_especialidad
    WHERE f.estado <> 'anulada'
    GROUP BY med.id_persona, me.id_especialidad
)
SELECT
    per.nombre || ' ' || per.apellido AS medico,
    esp.nombre AS especialidad,
    fme.total_facturado,
    (
        SELECT AVG(fme2.total_facturado)
        FROM facturacion_medico_esp fme2
        WHERE fme2.id_especialidad = fme.id_especialidad
    ) AS promedio_especialidad
FROM facturacion_medico_esp fme
JOIN clinica.persona per ON fme.id_medico = per.id_persona
JOIN clinica.especialidad esp ON fme.id_especialidad = esp.id_especialidad
WHERE fme.total_facturado > (
    SELECT AVG(fme2.total_facturado)
    FROM facturacion_medico_esp fme2
    WHERE fme2.id_especialidad = fme.id_especialidad
)
ORDER BY esp.nombre ASC, fme.total_facturado DESC;


-- -------------------------------------------------------------------------
-- 11. ¿Qué personas son empleados y pacientes a la vez?
-- Técnica: INTERSECT
-- -------------------------------------------------------------------------
SELECT emp.id_persona
FROM clinica.empleado emp
INTERSECT
SELECT pac.id_persona
FROM clinica.paciente pac
ORDER BY id_persona ASC;


-- -------------------------------------------------------------------------
-- 12. ¿Qué lotes vencen en los próximos 90 días, por sede y con su stock?
-- Técnica: Funciones de fecha, JOIN, WHERE
-- -------------------------------------------------------------------------
SELECT
    s.nombre AS sede,
    m.nombre_comercial AS medicamento,
    li.codigo_lote,
    li.fecha_vencimiento,
    li.stock_actual
FROM clinica.lote_inventario li
JOIN clinica.sede s ON li.id_sede = s.id_sede
JOIN clinica.medicamento m ON li.id_medicamento = m.id_medicamento
WHERE li.fecha_vencimiento BETWEEN CURRENT_DATE AND (CURRENT_DATE + INTERVAL '90 days')::date
ORDER BY li.fecha_vencimiento ASC, s.nombre ASC;


-- -------------------------------------------------------------------------
-- 13. ¿Cómo cambian las citas por especialidad entre este mes y el anterior, incluidas las que solo aparecen en uno?
-- Técnica: CTE, FULL OUTER JOIN
-- -------------------------------------------------------------------------
WITH citas_este_mes AS (
    SELECT
        id_especialidad,
        COUNT(*) AS total_actual
    FROM clinica.cita
    WHERE DATE_TRUNC('month', fecha_hora_inicio) = DATE_TRUNC('month', CURRENT_DATE)
    GROUP BY id_especialidad
),
citas_mes_anterior AS (
    SELECT
        id_especialidad,
        COUNT(*) AS total_anterior
    FROM clinica.cita
    WHERE DATE_TRUNC('month', fecha_hora_inicio) = DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')
    GROUP BY id_especialidad
)
SELECT
    COALESCE(e.nombre, 'Sin especialidad') AS especialidad,
    COALESCE(cm.total_actual, 0) AS citas_este_mes,
    COALESCE(ca.total_anterior, 0) AS citas_mes_anterior,
    COALESCE(cm.total_actual, 0) - COALESCE(ca.total_anterior, 0) AS variacion
FROM citas_este_mes cm
FULL OUTER JOIN citas_mes_anterior ca
    ON cm.id_especialidad = ca.id_especialidad
LEFT JOIN clinica.especialidad e
    ON COALESCE(cm.id_especialidad, ca.id_especialidad) = e.id_especialidad
ORDER BY especialidad ASC;


-- -------------------------------------------------------------------------
-- 14. ¿Cuál es el ranking de médicos por citas atendidas dentro de cada especialidad?
-- Técnica: DENSE_RANK, PARTITION BY
-- -------------------------------------------------------------------------
SELECT
    e.nombre AS especialidad,
    per.nombre || ' ' || per.apellido AS medico,
    COUNT(c.id_cita) AS citas_atendidas,
    DENSE_RANK() OVER (
        PARTITION BY c.id_especialidad
        ORDER BY COUNT(c.id_cita) DESC
    ) AS ranking
FROM clinica.cita c
JOIN clinica.medico med ON c.id_medico = med.id_persona
JOIN clinica.persona per ON med.id_persona = per.id_persona
JOIN clinica.especialidad e ON c.id_especialidad = e.id_especialidad
WHERE c.estado = 'atendida'
GROUP BY c.id_especialidad, e.nombre, med.id_persona, per.nombre, per.apellido
ORDER BY e.nombre ASC, ranking ASC, medico ASC;


-- -------------------------------------------------------------------------
-- 15. ¿Cuál fue la última consulta de cada paciente?
-- Técnica: ROW_NUMBER
-- -------------------------------------------------------------------------
WITH consultas_ordenadas AS (
    SELECT
        c.id_paciente,
        co.id_consulta,
        c.id_cita,
        c.fecha_hora_inicio,
        co.motivo,
        co.notas_clinicas,
        ROW_NUMBER() OVER (
            PARTITION BY c.id_paciente
            ORDER BY c.fecha_hora_inicio DESC, co.id_consulta DESC
        ) AS rn
    FROM clinica.consulta co
    JOIN clinica.cita c ON co.id_cita = c.id_cita
)
SELECT
    co.id_paciente,
    per.nombre || ' ' || per.apellido AS paciente,
    co.id_consulta,
    co.fecha_hora_inicio AS fecha_ultima_consulta,
    co.motivo
FROM consultas_ordenadas co
JOIN clinica.persona per ON co.id_paciente = per.id_persona
WHERE co.rn = 1
ORDER BY co.id_paciente ASC;