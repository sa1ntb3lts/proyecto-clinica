CREATE OR REPLACE FUNCTION clinica.calcular_factura(
    p_id_consulta INT
)
RETURNS TABLE (
    subtotal_consulta NUMERIC(10,2),
    subtotal_medicamentos NUMERIC(10,2),
    monto_seguro NUMERIC(10,2),
    monto_paciente NUMERIC(10,2)
)
LANGUAGE plpgsql
AS $$
DECLARE
v_costo_consulta NUMERIC(10,2);
    v_subtotal_medicamentos NUMERIC(10,2);
    v_porcentaje_cobertura NUMERIC(5,2);
    v_total NUMERIC(10,2);
BEGIN
SELECT e.costo_consulta
INTO v_costo_consulta
FROM clinica.consulta co
         JOIN clinica.cita c ON co.id_cita = c.id_cita
         JOIN clinica.especialidad e
              ON c.id_especialidad = e.id_especialidad
WHERE co.id_consulta = p_id_consulta;

IF NOT FOUND THEN
        RAISE EXCEPTION 'no existe la consulta %', p_id_consulta;
END IF;

SELECT COALESCE(
               SUM(dr.cantidad * m.precio_unitario), 0
       )
INTO v_subtotal_medicamentos
FROM clinica.detalle_receta dr
         JOIN clinica.receta r ON dr.id_receta = r.id_receta
         JOIN clinica.medicamento m
              ON dr.id_medicamento = m.id_medicamento
WHERE r.id_consulta = p_id_consulta;

SELECT COALESCE(a.porcentaje_cobertura, 0)
INTO v_porcentaje_cobertura
FROM clinica.consulta co
         JOIN clinica.cita c ON co.id_cita = c.id_cita
         LEFT JOIN clinica.paciente p
                   ON c.id_paciente = p.id_persona
         LEFT JOIN clinica.aseguradora a
                   ON p.id_aseguradora = a.id_aseguradora
WHERE co.id_consulta = p_id_consulta;

v_total := v_costo_consulta + v_subtotal_medicamentos;

    subtotal_consulta := v_costo_consulta;
    subtotal_medicamentos := v_subtotal_medicamentos;

    monto_seguro := ROUND(
        v_total * v_porcentaje_cobertura / 100, 2
    );

    monto_paciente := v_total - monto_seguro;

RETURN NEXT;
END;
$$;

CREATE OR REPLACE FUNCTION clinica.dispensar_medicamento(
    p_id_medicamento INT,
    p_id_sede INT,
    p_cantidad INT
)
RETURNS TABLE (
    id_lote INT,
    cantidad_dispensada INT
)
LANGUAGE plpgsql
AS $$
DECLARE
v_disponible INT;
    v_restante INT;
    v_tomar INT;
    v_lote RECORD;
BEGIN
    IF p_cantidad IS NULL OR p_cantidad <= 0 THEN
        RAISE EXCEPTION 'la cantidad debe ser mayor que cero';
END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM clinica.medicamento m
        WHERE m.id_medicamento = p_id_medicamento
    ) THEN
        RAISE EXCEPTION 'el medicamento no existe';
END IF;

SELECT COALESCE(SUM(l.stock_actual), 0)
INTO v_disponible
FROM clinica.lote_inventario l
WHERE l.id_medicamento = p_id_medicamento
  AND l.id_sede = p_id_sede
  AND l.fecha_vencimiento >= CURRENT_DATE
  AND l.stock_actual > 0;

IF v_disponible < p_cantidad THEN
        RAISE EXCEPTION
            'stock insuficiente. disponible: %, solicitado: %',
            v_disponible, p_cantidad;
END IF;

    v_restante := p_cantidad;

FOR v_lote IN
SELECT l.id_lote, l.stock_actual
FROM clinica.lote_inventario l
WHERE l.id_medicamento = p_id_medicamento
  AND l.id_sede = p_id_sede
  AND l.fecha_vencimiento >= CURRENT_DATE
  AND l.stock_actual > 0
ORDER BY l.fecha_vencimiento ASC, l.id_lote ASC
    FOR UPDATE
    LOOP
        EXIT WHEN v_restante <= 0;

v_tomar := LEAST(v_lote.stock_actual, v_restante);

UPDATE clinica.lote_inventario
SET stock_actual = stock_actual - v_tomar
WHERE clinica.lote_inventario.id_lote = v_lote.id_lote;

id_lote := v_lote.id_lote;
        cantidad_dispensada := v_tomar;

RETURN NEXT;

v_restante := v_restante - v_tomar;
END LOOP;
END;
$$;
