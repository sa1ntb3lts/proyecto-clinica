CREATE OR REPLACE FUNCTION clinica.fn_auditar_cita()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF OLD.estado IS DISTINCT FROM NEW.estado THEN
        INSERT INTO clinica.auditoria_log (
            tabla_afectada,
            id_registro,
            campo_modificado,
            valor_anterior,
            valor_nuevo,
            usuario_bd,
            fecha_hora
        )
        VALUES (
            'cita',
            OLD.id_cita,
            'estado',
            OLD.estado::TEXT,
            NEW.estado::TEXT,
            CURRENT_USER,
            NOW()
        );
END IF;

RETURN NEW;
END;
$$;

CREATE TRIGGER trg_auditar_cita
    AFTER UPDATE ON clinica.cita
    FOR EACH ROW
    EXECUTE FUNCTION clinica.fn_auditar_cita();


CREATE OR REPLACE FUNCTION clinica.fn_auditar_factura()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF OLD.estado IS DISTINCT FROM NEW.estado THEN
        INSERT INTO clinica.auditoria_log (
            tabla_afectada,
            id_registro,
            campo_modificado,
            valor_anterior,
            valor_nuevo,
            usuario_bd,
            fecha_hora
        )
        VALUES (
            'factura',
            OLD.id_factura,
            'estado',
            OLD.estado::TEXT,
            NEW.estado::TEXT,
            CURRENT_USER,
            NOW()
        );
END IF;

    IF OLD.subtotal_consulta IS DISTINCT FROM NEW.subtotal_consulta THEN
        INSERT INTO clinica.auditoria_log (
            tabla_afectada, id_registro, campo_modificado,
            valor_anterior, valor_nuevo, usuario_bd, fecha_hora
        )
        VALUES (
            'factura', OLD.id_factura, 'subtotal_consulta',
            OLD.subtotal_consulta::TEXT, NEW.subtotal_consulta::TEXT,
            CURRENT_USER, NOW()
        );
END IF;

    IF OLD.subtotal_medicamentos IS DISTINCT FROM NEW.subtotal_medicamentos THEN
        INSERT INTO clinica.auditoria_log (
            tabla_afectada, id_registro, campo_modificado,
            valor_anterior, valor_nuevo, usuario_bd, fecha_hora
        )
        VALUES (
            'factura', OLD.id_factura, 'subtotal_medicamentos',
            OLD.subtotal_medicamentos::TEXT, NEW.subtotal_medicamentos::TEXT,
            CURRENT_USER, NOW()
        );
END IF;

    IF OLD.monto_seguro IS DISTINCT FROM NEW.monto_seguro THEN
        INSERT INTO clinica.auditoria_log (
            tabla_afectada, id_registro, campo_modificado,
            valor_anterior, valor_nuevo, usuario_bd, fecha_hora
        )
        VALUES (
            'factura', OLD.id_factura, 'monto_seguro',
            OLD.monto_seguro::TEXT, NEW.monto_seguro::TEXT,
            CURRENT_USER, NOW()
        );
END IF;

    IF OLD.monto_paciente IS DISTINCT FROM NEW.monto_paciente THEN
        INSERT INTO clinica.auditoria_log (
            tabla_afectada, id_registro, campo_modificado,
            valor_anterior, valor_nuevo, usuario_bd, fecha_hora
        )
        VALUES (
            'factura', OLD.id_factura, 'monto_paciente',
            OLD.monto_paciente::TEXT, NEW.monto_paciente::TEXT,
            CURRENT_USER, NOW()
        );
END IF;

    IF OLD.saldo_pendiente IS DISTINCT FROM NEW.saldo_pendiente THEN
        INSERT INTO clinica.auditoria_log (
            tabla_afectada, id_registro, campo_modificado,
            valor_anterior, valor_nuevo, usuario_bd, fecha_hora
        )
        VALUES (
            'factura', OLD.id_factura, 'saldo_pendiente',
            OLD.saldo_pendiente::TEXT, NEW.saldo_pendiente::TEXT,
            CURRENT_USER, NOW()
        );
END IF;

RETURN NEW;
END;
$$;

CREATE TRIGGER trg_auditar_factura
AFTER UPDATE ON clinica.factura
FOR EACH ROW
EXECUTE FUNCTION clinica.fn_auditar_factura();
