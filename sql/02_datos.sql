-- clinica vida plena: datos de prueba
BEGIN;

-- 1. personas y catálogos
INSERT INTO clinica.persona (id_persona, nombre, apellido, fecha_nacimiento, telefono, email, direccion)
SELECT i,
       (ARRAY['Ana','Luis','Maria','Carlos','Sofia','Jose','Valeria','Diego','Elena','Miguel',
        'Camila','Jorge','Daniela','Emilio','Lucia','Andres','Isabel','Rafael','Paula','David'])[(i-1)%20+1],
       (ARRAY['Garcia','Lopez','Martinez','Hernandez','Rodriguez','Perez','Gonzalez','Sanchez','Ramirez','Torres',
              'Flores','Rivera','Morales','Castro','Ortiz','Vargas','Reyes','Mendoza','Romero','Cruz'])[((i-1)/20)%20+1]
           || ' ' || (ARRAY['Ruiz','Silva','Vega','Rojas','Molina','Nava','Soto'])[(i*3)%7+1],
       (CURRENT_DATE - make_interval(years => CASE WHEN i BETWEEN 471 AND 490 THEN 7+i%6 ELSE 20+i%55 END)
                     - (i%365)*INTERVAL '1 day')::date,
       '000' || lpad(i::text, 7,'0'),
       'persona' || i || '@example.com',
       'Calle de prueba ' || i
FROM generate_series(1, 520) AS g(i);

INSERT INTO clinica.sede (id_sede, nombre, direccion, telefono) VALUES
                                                                    (1,'Sede Centro','Av. Central 100','0000000001'),
                                                                    (2,'Sede Norte','Calle Norte 200','0000000002'),
                                                                    (3,'Sede Sur','Av. Sur 300','0000000003');

INSERT INTO clinica.especialidad (id_especialidad, nombre, costo_consulta) VALUES
                                                                               (1,'Medicina general', 450), (2,'Pediatria', 550), (3,'Cardiologia', 900),
                                                                               (4,'Dermatologia', 700), (5,'Traumatologia', 850), (6,'Medicina interna', 750);

INSERT INTO clinica.medicamento (id_medicamento, nombre_comercial, principio_activo, presentacion, precio_unitario) VALUES
                                                                                                                        (1,'Paracetamol generico','Paracetamol','Tabletas', 45),
                                                                                                                        (2,'Ibuprofeno generico','Ibuprofeno','Tabletas', 65),
                                                                                                                        (3,'Loratadina generica','Loratadina','Tabletas', 55),
                                                                                                                        (4,'Omeprazol generico','Omeprazol','Capsulas', 80),
                                                                                                                        (5,'Solucion salina','Cloruro de sodio','Solucion', 35),
                                                                                                                        (6,'Vitamina C generica','Acido ascorbico','Tabletas', 70),
                                                                                                                        (7,'Crema humectante','Glicerina','Crema', 95),
                                                                                                                        (8,'Sales de rehidratacion','Sales minerales','Sobres', 30),
                                                                                                                        (9,'Calamina generica','Calamina','Locion', 60),
                                                                                                                        (10,'Suplemento de calcio','Carbonato de calcio','Tabletas', 110);

INSERT INTO clinica.aseguradora (id_aseguradora, nombre, porcentaje_cobertura) VALUES
                                                                                   (1,'Seguro Vida', 50), (2,'Seguro Bienestar', 70), (3,'Seguro Familiar', 80), (4,'Seguro Integral', 100);

INSERT INTO clinica.diagnostico (id_diagnostico, codigo_cie10, descripcion) VALUES
                                                                                (1,'J06.9','Infeccion respiratoria superior no especificada'),
                                                                                (2,'R51','Cefalea'), (3,'K29.7','Gastritis no especificada'),
                                                                                (4,'M54.9','Dorsalgia no especificada'), (5,'L30.9','Dermatitis no especificada'),
                                                                                (6,'J30.4','Rinitis alergica no especificada'), (7,'R53','Malestar y fatiga'),
                                                                                (8,'Z00.0','Examen medico general');

-- 2. pacientes y empleados

INSERT INTO clinica.paciente (id_persona, tipo_sangre, alergias, id_responsable, id_aseguradora)
SELECT id_persona,
       (ARRAY['O+','A+','B+','AB+','O-','A-','B-','AB-'])[(id_persona-1)%8+1],
       CASE WHEN id_persona%11 = 0 THEN 'Alergia registrada en expediente'
            WHEN id_persona%7 = 0 THEN 'Alergia al polen' ELSE 'Sin alergias conocidas' END,
       NULL,
       CASE WHEN id_persona%5 = 0 THEN NULL ELSE (id_persona-1)%4+1 END
FROM clinica.persona WHERE id_persona BETWEEN 1 AND 500 AND id_persona NOT BETWEEN 471 AND 490;

INSERT INTO clinica.paciente (id_persona, tipo_sangre, alergias, id_responsable, id_aseguradora)
SELECT id_persona, (ARRAY['O+','A+','B+','AB+'])[(id_persona-471)%4+1],
       CASE WHEN id_persona%3 = 0 THEN 'Alergia registrada en expediente' ELSE 'Sin alergias conocidas' END,
       id_persona-470,
       CASE WHEN id_persona%5 = 0 THEN NULL ELSE (id_persona-1)%4+1 END
FROM clinica.persona WHERE id_persona BETWEEN 471 AND 490;

-- personas 491 a 500: pacientes y empleados
INSERT INTO clinica.empleado (id_persona, fecha_contratacion, salario, activo)
SELECT i, CURRENT_DATE - (400+i%600),
       CASE WHEN i<=510 THEN 22000+(i%10)*1000
            WHEN i<=515 THEN 11000+(i%5)*500 ELSE 15000+(i%5)*700 END,
       TRUE
FROM generate_series(491, 520) AS g(i);

INSERT INTO clinica.medico (id_persona, cedula_profesional)
SELECT i, 'MED-PRUEBA-' || i FROM generate_series(491, 510) AS g(i);

INSERT INTO clinica.recepcionista (id_persona, turno, extension_telefonica)
SELECT i, CASE WHEN i%2 = 0 THEN 'Matutino' ELSE 'Vespertino' END, (100+i-510)::text
FROM generate_series(511, 515) AS g(i);

INSERT INTO clinica.farmaceutico (id_persona, licencia_sanitaria)
SELECT i, 'FAR-PRUEBA-' || i FROM generate_series(516, 520) AS g(i);

-- 3. horarios médicos

INSERT INTO clinica.horario_medico (id_medico, id_sede, dia_semana, hora_inicio, hora_fin)
SELECT m.id_persona,
       CASE WHEN d<=5 THEN (m.id_persona-491)%3+1 ELSE (m.id_persona-490)%3+1 END,
       (ARRAY['lunes','martes','miercoles','jueves','viernes','sabado','domingo'])[d],
       TIME '08:00', TIME '12:00'
FROM clinica.medico m CROSS JOIN generate_series(1, 7) AS dias(d);

-- 4. citas: 50000 registros en 365 dias
-- medico 510 sin citas para probar LEFT JOIN
WITH bloques AS (
    SELECT n, n%365 AS dia, (n/365)%19 AS medico, n/(365*19) AS bloque
FROM generate_series(0, 49999) AS g(n)
    ), agenda AS (
SELECT n, dia, medico, bloque, CURRENT_DATE-dia AS fecha
FROM bloques
    )
INSERT INTO clinica.cita (id_paciente, id_medico, id_especialidad, id_sede, fecha_hora_inicio, estado)
SELECT (dia*17+bloque*19+medico)%500+1,
       491+medico,
       CASE WHEN medico%4 = 0 AND bloque%3 = 0 THEN (medico+1)%6+1 ELSE medico%6+1 END,
       CASE WHEN EXTRACT(ISODOW FROM fecha)<=5 THEN medico%3+1 ELSE (medico+1)%3+1 END,
       fecha + TIME '08:00' + bloque*INTERVAL '30 minutes',
       CASE WHEN n%11 = 0 THEN 'cancelada'
            WHEN dia = 0 AND (medico+bloque)%2 = 0 THEN 'programada'
            WHEN dia = 0 THEN 'confirmada'
            ELSE 'atendida' END
FROM agenda ORDER BY n;


-- 5. consultas y recetas de las citas atendidas.

INSERT INTO clinica.consulta (id_cita, motivo, presion_arterial, temperatura, peso, notas_clinicas)
SELECT id_cita,
       (ARRAY['Revision general','Molestia respiratoria','Dolor de cabeza','Control de seguimiento',
        'Molestia digestiva','Revision de piel','Dolor muscular','Malestar general'])[(id_cita-1)%8+1],
       (ARRAY['110/70','120/80','115/75','125/85','105/70'])[(id_cita-1)%5+1],
       36.20+(id_cita%18)*0.10,
       CASE WHEN id_paciente BETWEEN 471 AND 490 THEN 25+(id_cita%15)*0.75 ELSE 50+(id_cita%55)*0.80 END,
       (ARRAY['Registro ficticio de revision','Seguimiento registrado','Evaluacion clinica simulada','Control de rutina'])[(id_cita-1)%4+1]
FROM clinica.cita WHERE estado='atendida' ORDER BY id_cita;

INSERT INTO clinica.receta (id_consulta, fecha_emision)
SELECT co.id_consulta, ci.fecha_hora_inicio+INTERVAL '25 minutes'
FROM clinica.consulta co JOIN clinica.cita ci ON ci.id_cita = co.id_cita
WHERE co.id_consulta%3<>0 ORDER BY co.id_consulta;


-- 6. lotes de inventario y detalles de recetas

INSERT INTO clinica.lote_inventario (id_medicamento, id_sede, codigo_lote, fecha_vencimiento, stock_actual)
SELECT m.id_medicamento, s.id_sede,
       'L-'||s.id_sede||'-'||m.id_medicamento||'-'||l,
       CURRENT_DATE + CASE l WHEN 1 THEN -30 WHEN 2 THEN 15+m.id_medicamento*3 ELSE 240+m.id_medicamento END,
       CASE l WHEN 1 THEN 5+m.id_medicamento WHEN 2 THEN 80+m.id_medicamento*5 ELSE 200+m.id_medicamento*10 END
FROM clinica.medicamento m CROSS JOIN clinica.sede s CROSS JOIN generate_series(1, 3) AS lotes(l);

-- dosis y frecuencias ficticias
INSERT INTO clinica.detalle_receta (id_receta, numero_linea, id_medicamento, dosis, frecuencia, cantidad)
SELECT r.id_receta, l, (r.id_receta+l-2)%9+1,
       CASE l WHEN 1 THEN 'Dosis de prueba A' ELSE 'Dosis de prueba B' END,
       CASE l WHEN 1 THEN 'Frecuencia simulada A' ELSE 'Frecuencia simulada B' END,
       1+(r.id_receta+l)%3
FROM clinica.receta r CROSS JOIN generate_series(1, 2) AS lineas(l)
WHERE l = 1 OR r.id_receta%2 = 0;

-- 7. facturas (medicamentos historicos considerados entregados)
WITH importes_receta AS (
    SELECT r.id_consulta, SUM(d.cantidad*m.precio_unitario) AS subtotal
    FROM clinica.receta r JOIN clinica.detalle_receta d ON d.id_receta = r.id_receta
                          JOIN clinica.medicamento m ON m.id_medicamento = d.id_medicamento
    GROUP BY r.id_consulta
), importes AS (
    SELECT co.id_consulta, e.costo_consulta AS base,
           COALESCE(ir.subtotal, 0) AS medicamentos,
           COALESCE(a.porcentaje_cobertura, 0) AS cobertura
    FROM clinica.consulta co JOIN clinica.cita ci ON ci.id_cita = co.id_cita
                             JOIN clinica.especialidad e ON e.id_especialidad = ci.id_especialidad
                             JOIN clinica.paciente p ON p.id_persona = ci.id_paciente
                             LEFT JOIN clinica.aseguradora a ON a.id_aseguradora = p.id_aseguradora
                             LEFT JOIN importes_receta ir ON ir.id_consulta = co.id_consulta
), seguro AS (
    SELECT *, ROUND((base+medicamentos)*cobertura/100, 2) AS monto_seguro FROM importes
), paciente AS (
    SELECT *, base+medicamentos-monto_seguro AS monto_paciente FROM seguro
), saldos AS (
    SELECT *, CASE WHEN id_consulta%5 IN (0, 2) THEN 0
    WHEN id_consulta%5 = 1 THEN monto_paciente-ROUND(monto_paciente*0.40, 2)
    ELSE monto_paciente END AS saldo
    FROM paciente
)
INSERT INTO clinica.factura (id_consulta, subtotal_consulta, subtotal_medicamentos, monto_seguro, monto_paciente, saldo_pendiente, estado)
SELECT id_consulta, base, medicamentos, monto_seguro, monto_paciente, saldo,
       CASE WHEN saldo = 0 THEN 'pagada' ELSE 'pendiente' END
FROM saldos ORDER BY id_consulta;



-- 8. pagos: facturas sin pagos, pagos parciales y facturas liquidadas.

WITH importes AS (
    SELECT f.id_factura, f.id_consulta, f.monto_paciente-f.saldo_pendiente AS pagado,
           ci.fecha_hora_inicio AS fecha
    FROM clinica.factura f JOIN clinica.consulta co ON co.id_consulta = f.id_consulta
                           JOIN clinica.cita ci ON ci.id_cita = co.id_cita
    WHERE f.monto_paciente>f.saldo_pendiente
), partes AS (
    SELECT *, CASE WHEN id_consulta%5 = 2 THEN ROUND(pagado/2, 2) ELSE pagado END AS primer_pago
    FROM importes
)
INSERT INTO clinica.pago (id_factura, monto, metodo_pago, fecha_pago)
SELECT id_factura, primer_pago, (ARRAY['Efectivo','Tarjeta','Transferencia'])[(id_factura-1)%3+1], fecha+INTERVAL '1 hour'
FROM partes WHERE primer_pago>0
UNION ALL
SELECT id_factura, pagado-primer_pago,'Tarjeta', fecha+INTERVAL '2 hours'
FROM partes WHERE pagado-primer_pago>0;



-- 9. auditoria historica simulada

INSERT INTO clinica.auditoria_log (tabla_afectada, id_registro, campo_modificado, valor_anterior, valor_nuevo, usuario_bd, fecha_hora)
SELECT 'cita', id_cita,'estado','programada','confirmada', current_user, fecha_hora_inicio-INTERVAL '1 day'
FROM clinica.cita WHERE estado IN ('confirmada','atendida')
UNION ALL
SELECT 'cita', id_cita,'estado','confirmada','atendida', current_user, fecha_hora_inicio+INTERVAL '30 minutes'
FROM clinica.cita WHERE estado='atendida'
UNION ALL
SELECT 'cita', id_cita,'estado','programada','cancelada', current_user, fecha_hora_inicio-INTERVAL '2 hours'
FROM clinica.cita WHERE estado='cancelada';

INSERT INTO clinica.auditoria_log (tabla_afectada, id_registro, campo_modificado, valor_anterior, valor_nuevo, usuario_bd, fecha_hora)
SELECT 'factura', f.id_factura,'estado','pendiente','pagada', current_user,
       COALESCE(p.ultimo_pago, ci.fecha_hora_inicio+INTERVAL '30 minutes')
FROM clinica.factura f JOIN clinica.consulta co ON co.id_consulta = f.id_consulta
                       JOIN clinica.cita ci ON ci.id_cita = co.id_cita
                       LEFT JOIN (SELECT id_factura, MAX(fecha_pago) AS ultimo_pago FROM clinica.pago GROUP BY id_factura) p
                                 ON p.id_factura = f.id_factura
WHERE f.estado='pagada';



-- 10. relaciones N:M

INSERT INTO clinica.medico_especialidad (id_persona, id_especialidad)
SELECT id_persona, (id_persona-491)%6+1
FROM clinica.medico
UNION ALL
SELECT id_persona, (id_persona-490)%6+1
FROM clinica.medico
WHERE (id_persona-491)%4 = 0;

INSERT INTO clinica.consulta_diagnostico (id_consulta, id_diagnostico, es_principal)
SELECT id_consulta, (id_consulta-1)%8+1, TRUE
FROM clinica.consulta
UNION ALL
SELECT id_consulta, id_consulta%8+1, FALSE
FROM clinica.consulta
WHERE id_consulta%4 = 0;

-- ajustar secuencias
SELECT setval(pg_get_serial_sequence('clinica.persona','id_persona'), MAX(id_persona)) FROM clinica.persona;
SELECT setval(pg_get_serial_sequence('clinica.sede','id_sede'), MAX(id_sede)) FROM clinica.sede;
SELECT setval(pg_get_serial_sequence('clinica.especialidad','id_especialidad'), MAX(id_especialidad)) FROM clinica.especialidad;
SELECT setval(pg_get_serial_sequence('clinica.medicamento','id_medicamento'), MAX(id_medicamento)) FROM clinica.medicamento;
SELECT setval(pg_get_serial_sequence('clinica.aseguradora','id_aseguradora'), MAX(id_aseguradora)) FROM clinica.aseguradora;
SELECT setval(pg_get_serial_sequence('clinica.diagnostico','id_diagnostico'), MAX(id_diagnostico)) FROM clinica.diagnostico;

-- validar datos antes de confirmar la carga
DO $$
BEGIN
    IF (SELECT COUNT(*) FROM clinica.sede)<>3 OR
       (SELECT COUNT(*) FROM clinica.medico)<>20 OR
       (SELECT COUNT(*) FROM clinica.paciente)<>500 OR
       (SELECT COUNT(*) FROM clinica.cita)<>50000 THEN
        RAISE EXCEPTION 'Las cantidades de datos no coinciden con las esperadas';
END IF;
    IF EXISTS (SELECT 1 FROM clinica.cita WHERE estado<>'cancelada'
               GROUP BY id_paciente, fecha_hora_inicio HAVING COUNT(*)>1) THEN
        RAISE EXCEPTION 'Hay citas activas duplicadas para un paciente';
END IF;
    IF EXISTS (SELECT 1 FROM clinica.cita c
        WHERE c.estado <> 'cancelada' AND NOT EXISTS (
            SELECT 1 FROM clinica.medico_especialidad me
            WHERE me.id_persona = c.id_medico AND me.id_especialidad = c.id_especialidad)) THEN
        RAISE EXCEPTION 'Hay citas con especialidades no asignadas al médico';
END IF;
    IF EXISTS (SELECT 1 FROM clinica.medico m WHERE NOT EXISTS (
        SELECT 1 FROM clinica.medico_especialidad me WHERE me.id_persona = m.id_persona)) THEN
        RAISE EXCEPTION 'Hay médicos sin especialidad asignada';
END IF;
    IF EXISTS (SELECT 1 FROM clinica.detalle_receta WHERE id_medicamento = 10) THEN
        RAISE EXCEPTION 'El medicamento 10 debía permanecer sin recetar';
END IF;
    IF NOT EXISTS (SELECT 1 FROM clinica.lote_inventario
        WHERE fecha_vencimiento BETWEEN CURRENT_DATE AND CURRENT_DATE + 90) THEN
        RAISE EXCEPTION 'No hay lotes con vencimiento en los próximos 90 días';
END IF;
    IF EXISTS (SELECT 1 FROM clinica.paciente p
        JOIN clinica.persona per ON per.id_persona = p.id_persona
        WHERE per.fecha_nacimiento > CURRENT_DATE - INTERVAL '18 years'
          AND (p.id_responsable IS NULL OR NOT EXISTS (
              SELECT 1 FROM clinica.paciente responsable
              WHERE responsable.id_persona = p.id_responsable))) THEN
        RAISE EXCEPTION 'Hay pacientes menores sin responsable válido';
END IF;
END $$;

COMMIT;
