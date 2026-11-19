-- 1. vistas

-- agenda de citas
CREATE OR REPLACE VIEW clinica.vista_agenda AS
SELECT c.id_cita, c.fecha_hora_inicio, c.estado,
       CONCAT(p.nombre, ' ', p.apellido) AS paciente,
       CONCAT(m.nombre, ' ', m.apellido) AS medico,
       e.nombre AS especialidad, s.nombre AS sede
FROM clinica.cita c
         JOIN clinica.persona p ON c.id_paciente = p.id_persona
         JOIN clinica.persona m ON c.id_medico = m.id_persona
         JOIN clinica.especialidad e ON c.id_especialidad = e.id_especialidad
         JOIN clinica.sede s ON c.id_sede = s.id_sede;

-- inventario por sede
CREATE OR REPLACE VIEW clinica.vista_inventario AS
SELECT l.id_lote, m.nombre_comercial, s.nombre AS sede,
       l.codigo_lote, l.fecha_vencimiento, l.stock_actual
FROM clinica.lote_inventario l
         JOIN clinica.medicamento m ON l.id_medicamento = m.id_medicamento
         JOIN clinica.sede s ON l.id_sede = s.id_sede;

-- resumen de facturas
CREATE OR REPLACE VIEW clinica.vista_facturas AS
SELECT id_factura, id_consulta,
       subtotal_consulta + subtotal_medicamentos AS total,
       monto_seguro, monto_paciente, saldo_pendiente, estado
FROM clinica.factura;


-- 2. indices

CREATE INDEX IF NOT EXISTS idx_cita_sede_fecha
    ON clinica.cita (id_sede, fecha_hora_inicio);

CREATE INDEX IF NOT EXISTS idx_cita_paciente_fecha
    ON clinica.cita (id_paciente, fecha_hora_inicio);

CREATE INDEX IF NOT EXISTS idx_cita_medico_fecha
    ON clinica.cita (id_medico, fecha_hora_inicio);

CREATE INDEX IF NOT EXISTS idx_cita_especialidad_fecha
    ON clinica.cita (id_especialidad, fecha_hora_inicio);

CREATE INDEX IF NOT EXISTS idx_lote_sede_vencimiento
    ON clinica.lote_inventario (id_sede, fecha_vencimiento);

CREATE INDEX IF NOT EXISTS idx_factura_consulta
    ON clinica.factura (id_consulta);

CREATE INDEX IF NOT EXISTS idx_detalle_medicamento
    ON clinica.detalle_receta (id_medicamento);
