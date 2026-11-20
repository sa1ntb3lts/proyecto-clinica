-- =====================================================================
-- 06_seguridad.sql: Roles, Privilegios Mínimos y Pruebas RN-19
-- Autor: Cesar Uriel Aguiar Altamirano (Integrante 5)
-- =====================================================================

-- 1. Creación segura de roles (NOLOGIN y sin contraseñas en repositorio)
DO $$
BEGIN
    CREATE ROLE rol_recepcion NOLOGIN;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    CREATE ROLE rol_medico NOLOGIN;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    CREATE ROLE rol_farmacia NOLOGIN;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    CREATE ROLE rol_auditor NOLOGIN;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- 2. Permiso de uso del esquema clinica
GRANT USAGE ON SCHEMA clinica TO rol_recepcion, rol_medico, rol_farmacia, rol_auditor;

-- 3. Permisos para ROL_RECEPCION
GRANT SELECT, INSERT, UPDATE ON clinica.persona, clinica.paciente, clinica.empleado, clinica.sede TO rol_recepcion;
GRANT SELECT, INSERT, UPDATE ON clinica.cita TO rol_recepcion;
GRANT SELECT ON clinica.horario_medico, clinica.especialidad, clinica.aseguradora, clinica.medico, clinica.medico_especialidad TO rol_recepcion;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA clinica TO rol_recepcion;
-- Privacidad RN-19: Recepción no puede leer notas clínicas ni diagnósticos
REVOKE ALL ON clinica.consulta, clinica.diagnostico, clinica.consulta_diagnostico FROM rol_recepcion;

-- 4. Permisos para ROL_MEDICO
GRANT SELECT ON ALL TABLES IN SCHEMA clinica TO rol_medico;
GRANT INSERT, UPDATE ON clinica.consulta, clinica.diagnostico, clinica.consulta_diagnostico, clinica.receta, clinica.detalle_receta TO rol_medico;
GRANT UPDATE (estado) ON clinica.cita TO rol_medico;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA clinica TO rol_medico;

-- 5. Permisos para ROL_FARMACIA
GRANT SELECT ON clinica.receta, clinica.detalle_receta, clinica.medicamento, clinica.lote_inventario, clinica.sede TO rol_farmacia;
GRANT UPDATE (stock_actual) ON clinica.lote_inventario TO rol_farmacia;

-- 6. Permisos para ROL_AUDITOR (Solo lectura general y auditoría)
GRANT SELECT ON ALL TABLES IN SCHEMA clinica TO rol_auditor;

-- 7. Pruebas de acceso permitido y denegado por rol (SET ROLE)
DO $$
BEGIN
    RAISE NOTICE '=== INICIANDO PRUEBAS DE ROLES (SET ROLE) ===';

    SET ROLE rol_recepcion;
    PERFORM count(*) FROM clinica.cita;
    RAISE NOTICE '[OK] rol_recepcion: acceso PERMITIDO a clinica.cita.';
    BEGIN
        PERFORM count(*) FROM clinica.consulta;
        RAISE EXCEPTION '[FALLO] rol_recepcion NO debería leer consulta (RN-19).';
    EXCEPTION WHEN insufficient_privilege THEN
        RAISE NOTICE '[OK] rol_recepcion: acceso DENEGADO a clinica.consulta (RN-19 cumplida).';
    END;
    RESET ROLE;

    SET ROLE rol_medico;
    PERFORM count(*) FROM clinica.consulta;
    RAISE NOTICE '[OK] rol_medico: acceso PERMITIDO a notas clínicas en clinica.consulta.';
    BEGIN
        DELETE FROM clinica.auditoria_log;
        RAISE EXCEPTION '[FALLO] rol_medico NO debería borrar auditoria_log.';
    EXCEPTION WHEN insufficient_privilege THEN
        RAISE NOTICE '[OK] rol_medico: acceso DENEGADO para eliminar en clinica.auditoria_log.';
    END;
    RESET ROLE;

    SET ROLE rol_farmacia;
    PERFORM count(*) FROM clinica.lote_inventario;
    RAISE NOTICE '[OK] rol_farmacia: acceso PERMITIDO a clinica.lote_inventario.';
    BEGIN
        PERFORM count(*) FROM clinica.factura;
        RAISE EXCEPTION '[FALLO] rol_farmacia NO debería leer factura.';
    EXCEPTION WHEN insufficient_privilege THEN
        RAISE NOTICE '[OK] rol_farmacia: acceso DENEGADO a clinica.factura.';
    END;
    RESET ROLE;

    SET ROLE rol_auditor;
    PERFORM count(*) FROM clinica.auditoria_log;
    RAISE NOTICE '[OK] rol_auditor: acceso PERMITIDO a clinica.auditoria_log.';
    BEGIN
        UPDATE clinica.factura SET estado = 'pagada';
        RAISE EXCEPTION '[FALLO] rol_auditor NO debería modificar factura.';
    EXCEPTION WHEN insufficient_privilege THEN
        RAISE NOTICE '[OK] rol_auditor: acceso DENEGADO para modificar clinica.factura (solo lectura).';
    END;
    RESET ROLE;

    RAISE NOTICE '=== TODAS LAS PRUEBAS DE SEGURIDAD PASARON CON ÉXITO ===';
END $$;
