-- =====================================================================
-- 08_transacciones.sql: Concurrencia, Bloqueos y Aislamiento
-- Autor: Cesar Uriel Aguiar Altamirano (Integrante 5)
-- =====================================================================

CREATE OR REPLACE PROCEDURE clinica.sp_reservar_cita_concurrente(
    p_id_paciente INT,
    p_id_medico INT,
    p_id_especialidad INT,
    p_id_sede INT,
    p_fecha_hora TIMESTAMP
)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO clinica.cita (id_paciente, id_medico, id_especialidad, id_sede, fecha_hora_inicio, estado)
    VALUES (p_id_paciente, p_id_medico, p_id_especialidad, p_id_sede, p_fecha_hora, 'programada');

    RAISE NOTICE 'Cita reservada con éxito para el paciente % en %', p_id_paciente, p_fecha_hora;
EXCEPTION WHEN unique_violation THEN
    RAISE EXCEPTION 'CONCURRENCIA (RN-08): El bloque horario % ya fue tomado por otra sesión.', p_fecha_hora;
END;
$$;

CREATE OR REPLACE PROCEDURE clinica.sp_dispensar_receta_atomica(
    p_id_receta INT,
    p_id_sede INT
)
LANGUAGE plpgsql AS $$
DECLARE
    r_linea RECORD;
    v_lote_id INT;
    v_stock INT;
BEGIN
    FOR r_linea IN
        SELECT id_medicamento, cantidad
        FROM clinica.detalle_receta
        WHERE id_receta = p_id_receta
    LOOP
        SELECT id_lote, stock_actual INTO v_lote_id, v_stock
        FROM clinica.lote_inventario
        WHERE id_sede = p_id_sede
          AND id_medicamento = r_linea.id_medicamento
          AND fecha_vencimiento >= CURRENT_DATE
          AND stock_actual > 0
        ORDER BY fecha_vencimiento ASC
        LIMIT 1
        FOR UPDATE;

        IF NOT FOUND OR v_stock < r_linea.cantidad THEN
            RAISE EXCEPTION 'RN-14: Stock insuficiente para medicamento ID %. Se revierte toda la transacción.', r_linea.id_medicamento;
        END IF;

        UPDATE clinica.lote_inventario
        SET stock_actual = stock_actual - r_linea.cantidad
        WHERE id_lote = v_lote_id;
    END LOOP;

    RAISE NOTICE 'Receta % dispensada completamente en sede %.', p_id_receta, p_id_sede;
END;
$$;

CREATE OR REPLACE PROCEDURE clinica.sp_registrar_pago_seguro(
    p_id_factura INT,
    p_monto NUMERIC,
    p_metodo_pago VARCHAR
)
LANGUAGE plpgsql AS $$
DECLARE
    v_saldo NUMERIC;
BEGIN
    SELECT saldo_pendiente INTO v_saldo
    FROM clinica.factura
    WHERE id_factura = p_id_factura
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Factura % no encontrada.', p_id_factura;
    END IF;

    IF p_monto > v_saldo THEN
        RAISE EXCEPTION 'RN-17: El pago (%) supera el saldo pendiente (%).', p_monto, v_saldo;
    END IF;

    INSERT INTO clinica.pago (id_factura, monto, metodo_pago)
    VALUES (p_id_factura, p_monto, p_metodo_pago);

    UPDATE clinica.factura
    SET saldo_pendiente = saldo_pendiente - p_monto,
        estado = CASE WHEN (saldo_pendiente - p_monto) = 0 THEN 'pagada' ELSE estado END
    WHERE id_factura = p_id_factura;

    RAISE NOTICE 'Pago de % registrado en factura %.', p_monto, p_id_factura;
END;
$$;
