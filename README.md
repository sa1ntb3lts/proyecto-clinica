# Clínica Vida Plena - Sistema de Gestión de Base de Datos

Sistema integral de base de datos relacional en PostgreSQL diseñado para centralizar la gestión de citas médicas, expedientes clínicos, inventario farmacéutico por lotes, facturación con aseguradoras y auditoría de seguridad multi-sede.

## Integrantes y Reparto de Trabajo

| Integrante                          | Rol / Enfoque | Entregables Asignados |
|:------------------------------------| :--- | :--- |
| **Maydeline Silva Buzani**          | Modelado Conceptual y Documentación | `docs/modelo_er.pdf`, `docs/esquema_relacional.pdf`, `README.md` |
| **Luis Ángel Lerma Coss**           | Normalización y Esquema Físico | `docs/normalizacion.md`, `sql/01_esquema.sql` |
| **Martín Valente Vindiola Morales** | Volumetría, Índices y Rendimiento | `sql/02_datos.sql`, `sql/03_vistas_indices.sql`, `docs/rendimiento.md` |
| **Uriel Nahum Santos Vazquez**      | Lógica de Negocio y Automatización | `sql/04_funciones_procedimientos.sql`, `sql/05_triggers.sql` |
| **Cesar Uriel Aguiar Altamirano**   | Seguridad, Concurrencia y Respaldos | `sql/06_seguridad.sql`, `sql/08_transacciones.sql`, `docs/permisos.md`, `respaldo/clinica.dump` |
| **Santiago Beltran Astorga**        | Consultas Analíticas e Integración | `sql/07_consultas.sql`, `ejecutar_todo.sql` |

---

## Supuestos de Negocio Documentados

Ante las ambigüedades detectadas en las reglas de negocio, el equipo estableció los siguientes supuestos de diseño:

1. **Duración fija de citas (RN-06 y RN-08):** Todas las citas tienen una duración estricta de 30 minutos y deben iniciar en bloques exactos (en punto `:00` o media hora `:30`) para evitar solapamientos parciales entre citas activas.
2. **Precios de consulta y medicamentos (RN-15):** El precio base de una consulta depende de la `ESPECIALIDAD` elegida al agendar, y el precio de venta de cada medicamento reside en el catálogo `MEDICAMENTO`. Al emitirse la factura, ambos valores se copian a la tabla de facturación para preservar el historial financiero ante futuros aumentos de precios.
3. **Cobertura de seguros (RN-16):** El porcentaje de cobertura de la aseguradora aplica sobre el total de la factura (consulta + medicamentos). Si un paciente no tiene aseguradora asociada (`NULL`), el porcentaje de cobertura es `0%` (paciente particular).
4. **Dispensación atómica de recetas (RN-14):** Si una receta contiene 3 medicamentos y al menos 1 no cuenta con stock suficiente entre los lotes vigentes de la sede donde se atiende, la transacción completa se rechaza (`ROLLBACK`) y no se descuenta ningún medicamento.
5. **Trazabilidad de auditoría (RN-18):** Se registra el usuario de base de datos (`current_user`) y la marca de tiempo (`now()`) mediante triggers automáticos cada vez que cambia el estado de una cita o el estado/total de una factura.
6. **Jerarquía de personas (RN-02 y RN-03):** Un empleado no puede tener dos roles operativos simultáneos (es médico, recepcionista o farmacéutico), pero cualquier empleado sí puede estar registrado simultáneamente como paciente.

---

## Estructura del Repositorio

```text
proyecto-clinica/
├── README.md
├── ejecutar_todo.sql
├── docs/
│   ├── modelo_er.pdf
│   ├── esquema_relacional.pdf
│   ├── normalizacion.md
│   ├── rendimiento.md
│   ├── permisos.md
│   └── evidencias/
├── sql/
│   ├── 01_esquema.sql
│   ├── 02_datos.sql
│   ├── 03_vistas_indices.sql
│   ├── 04_funciones_procedimientos.sql
│   ├── 05_triggers.sql
│   ├── 06_seguridad.sql
│   ├── 07_consultas.sql
│   └── 08_transacciones.sql
└── respaldo/
    └── clinica.dump
