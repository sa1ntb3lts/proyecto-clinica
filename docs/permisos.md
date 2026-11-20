cat << 'EOF' > docs/permisos.md
# Matriz de Permisos y Seguridad - Clínica Vida Plena

**Responsable:** Cesar Uriel Aguiar Altamirano (Integrante 5)

Este documento define el modelo de control de acceso basado en roles (RBAC) implementado en PostgreSQL sobre el esquema `clinica`, aplicando el principio de privilegios mínimos y garantizando la privacidad médica exigida por la regla de negocio **RN-19**.

## 1. Definición de Roles

| Rol | Descripción Operativa | Autenticación |
| :--- | :--- | :--- |
| **`rol_recepcion`** | Gestión de pacientes, consulta de médicos/horarios y agendamiento de citas. Tiene estrictamente bloqueado el acceso a consultas y diagnósticos (**RN-19**). | `NOLOGIN` (Sin contraseñas en repositorio) |
| **`rol_medico`** | Lectura general del catálogo y expedientes; creación y actualización de consultas, diagnósticos y recetas. | `NOLOGIN` (Sin contraseñas en repositorio) |
| **`rol_farmacia`** | Consulta de recetas médicas y gestión de stock en inventario por lotes (`lote_inventario`). | `NOLOGIN` (Sin contraseñas en repositorio) |
| **`rol_auditor`** | Supervisión y control interno. Privilegios de solo lectura (`SELECT`) sobre todas las tablas y bitácora (`auditoria_log`). | `NOLOGIN` (Sin contraseñas en repositorio) |

## 2. Matriz de Privilegios (`GRANT` / `REVOKE`)

| Tabla (`clinica.*`) | `rol_recepcion` | `rol_medico` | `rol_farmacia` | `rol_auditor` |
| :--- | :---: | :---: | :---: | :---: |
| `persona` / `paciente` / `empleado` | `SELECT, INSERT, UPDATE` | `SELECT` | `DENEGADO` | `SELECT` |
| `sede` / `especialidad` / `aseguradora` | `SELECT` | `SELECT` | `SELECT` (`sede`) | `SELECT` |
| `medico` / `horario_medico` / `medico_especialidad` | `SELECT` | `SELECT` | `DENEGADO` | `SELECT` |
| `cita` | `SELECT, INSERT, UPDATE` | `SELECT, UPDATE (estado)` | `DENEGADO` | `SELECT` |
| `consulta` / `diagnostico` / `consulta_diagnostico` | **`DENEGADO (RN-19)`** | `SELECT, INSERT, UPDATE` | `DENEGADO` | `SELECT` |
| `receta` / `detalle_receta` | `DENEGADO` | `SELECT, INSERT, UPDATE` | `SELECT` | `SELECT` |
| `medicamento` | `DENEGADO` | `SELECT` | `SELECT` | `SELECT` |
| `lote_inventario` | `DENEGADO` | `SELECT` | `SELECT, UPDATE (stock_actual)` | `SELECT` |
| `factura` / `pago` | `DENEGADO` | `SELECT` | `DENEGADO` | `SELECT` |
| `auditoria_log` | `DENEGADO` | `SELECT` | `DENEGADO` | `SELECT` |

## 3. Pruebas de Validación (`SET ROLE`)

En el script `sql/06_seguridad.sql` se incluyen bloques automatizados de prueba con `SET ROLE`:

1. **Prueba de Privacidad (RN-19):** Al activar `SET ROLE rol_recepcion;`, el motor permite consultar `clinica.cita`, pero lanza `ERROR: permission denied for table consulta` al intentar leer notas clínicas.
2. **Prueba de Escritura Clínica:** Al activar `SET ROLE rol_medico;`, se permite leer y registrar información en `clinica.consulta`, mientras que cualquier intento de eliminar registros en `clinica.auditoria_log` es denegado.
3. **Prueba de Farmacia:** Al activar `SET ROLE rol_farmacia;`, permite actualizar `stock_actual` en `clinica.lote_inventario`, pero bloquea la lectura de información financiera en `clinica.factura`.
4. **Prueba de Auditoría:** Al activar `SET ROLE rol_auditor;`, permite auditar `clinica.auditoria_log`, pero bloquea cualquier `UPDATE` o `DELETE` sobre las tablas operativas.
EOF 
