
CREATE SCHEMA IF NOT EXISTS clinica;

-- 1. tablas independientes y catalogos (se crean primero)

CREATE TABLE clinica.persona
(
    id_persona       SERIAL PRIMARY KEY,
    nombre           VARCHAR(100) NOT NULL,
    apellido         VARCHAR(100) NOT NULL,
    fecha_nacimiento DATE         NOT NULL,
    telefono         VARCHAR(20),
    email            VARCHAR(100),
    direccion        TEXT
);

CREATE TABLE clinica.sede
(
    id_sede   SERIAL PRIMARY KEY,
    nombre    VARCHAR(100) NOT NULL,
    direccion TEXT         NOT NULL,
    telefono  VARCHAR(20)
);

CREATE TABLE clinica.especialidad
(
    id_especialidad SERIAL PRIMARY KEY,
    nombre          VARCHAR(100)   NOT NULL,
    costo_consulta  NUMERIC(10, 2) NOT NULL CHECK (costo_consulta >= 0)
);

CREATE TABLE clinica.medicamento
(
    id_medicamento   SERIAL PRIMARY KEY,
    nombre_comercial VARCHAR(150)   NOT NULL,
    principio_activo VARCHAR(150)   NOT NULL,
    presentacion     VARCHAR(100)   NOT NULL,
    precio_unitario  NUMERIC(10, 2) NOT NULL CHECK (precio_unitario >= 0)
);

CREATE TABLE clinica.aseguradora
(
    id_aseguradora       SERIAL PRIMARY KEY,
    nombre               VARCHAR(100)  NOT NULL,
    porcentaje_cobertura NUMERIC(5, 2) NOT NULL CHECK (porcentaje_cobertura >= 0 AND porcentaje_cobertura <= 100) -- restriccion CHECK
);

CREATE TABLE clinica.diagnostico
(
    id_diagnostico SERIAL PRIMARY KEY,
    codigo_cie10   VARCHAR(20) UNIQUE NOT NULL, -- Restricción UNIQUE
    descripcion    TEXT               NOT NULL
);


-- 2. jerarquia de personas (paciente y empleado)

CREATE TABLE clinica.paciente
(
    id_persona     INT PRIMARY KEY REFERENCES clinica.persona (id_persona) ON DELETE CASCADE,
    tipo_sangre    VARCHAR(10),
    alergias       TEXT,
    id_responsable INT REFERENCES clinica.paciente (id_persona), -- fk recursiva para menores de edad
    id_aseguradora INT REFERENCES clinica.aseguradora (id_aseguradora)
);

CREATE TABLE clinica.empleado
(
    id_persona         INT PRIMARY KEY REFERENCES clinica.persona (id_persona) ON DELETE CASCADE,
    fecha_contratacion DATE           NOT NULL,
    salario            NUMERIC(10, 2) NOT NULL CHECK (salario > 0), -- restriccion CHECK
    activo             BOOLEAN DEFAULT TRUE
);

-- subtipos de empleado (especializacion disjunta)
CREATE TABLE clinica.medico
(
    id_persona         INT PRIMARY KEY REFERENCES clinica.empleado (id_persona) ON DELETE CASCADE,
    cedula_profesional VARCHAR(50) UNIQUE NOT NULL -- restriccion UNIQUE
);

CREATE TABLE clinica.recepcionista
(
    id_persona           INT PRIMARY KEY REFERENCES clinica.empleado (id_persona) ON DELETE CASCADE,
    turno                VARCHAR(50) NOT NULL,
    extension_telefonica VARCHAR(10)
);

CREATE TABLE clinica.farmaceutico
(
    id_persona         INT PRIMARY KEY REFERENCES clinica.empleado (id_persona) ON DELETE CASCADE,
    licencia_sanitaria VARCHAR(50) NOT NULL
);


-- 3. tablas de operacion y horarios

CREATE TABLE clinica.horario_medico
(
    id_horario  SERIAL PRIMARY KEY,
    id_medico   INT REFERENCES clinica.medico (id_persona) ON DELETE CASCADE,
    id_sede     INT REFERENCES clinica.sede (id_sede) ON DELETE CASCADE,
    dia_semana  VARCHAR(20) NOT NULL,
    hora_inicio TIME        NOT NULL,
    hora_fin    TIME        NOT NULL,
    CHECK (hora_inicio < hora_fin) -- restriccion CHECK
);

CREATE TABLE clinica.cita
(
    id_cita           SERIAL PRIMARY KEY,
    id_paciente       INT REFERENCES clinica.paciente (id_persona) ON DELETE RESTRICT,
    id_medico         INT REFERENCES clinica.medico (id_persona) ON DELETE RESTRICT,
    id_especialidad   INT REFERENCES clinica.especialidad (id_especialidad) ON DELETE RESTRICT,
    id_sede           INT REFERENCES clinica.sede (id_sede) ON DELETE RESTRICT,
    fecha_hora_inicio TIMESTAMP   NOT NULL,
    estado            VARCHAR(30) NOT NULL CHECK (estado IN ('programada', 'confirmada', 'atendida', 'cancelada')) -- restriccion CHECK
);

-- indice unico parcial obligatorio (RN-08) evita citas duplicadas en el mismo horario para un médico (si no esta cancelada)
CREATE UNIQUE INDEX idx_cita_activa_medico
    ON clinica.cita (id_medico, fecha_hora_inicio) WHERE estado <> 'cancelada';


-- 4. consultas, recetas y detalles

CREATE TABLE clinica.consulta
(
    id_consulta      SERIAL PRIMARY KEY,
    id_cita          INT UNIQUE REFERENCES clinica.cita (id_cita) ON DELETE CASCADE,
    motivo           TEXT NOT NULL,
    presion_arterial VARCHAR(20),
    temperatura      NUMERIC(4, 2) CHECK (temperatura > 0), -- restriccion CHECK
    peso             NUMERIC(5, 2) CHECK (peso > 0),        -- restriccion CHECK
    notas_clinicas   TEXT
);

CREATE TABLE clinica.receta
(
    id_receta     SERIAL PRIMARY KEY,
    id_consulta   INT UNIQUE REFERENCES clinica.consulta (id_consulta) ON DELETE CASCADE,
    fecha_emision TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE clinica.lote_inventario
(
    id_lote           SERIAL PRIMARY KEY,
    id_medicamento    INT REFERENCES clinica.medicamento (id_medicamento) ON DELETE RESTRICT,
    id_sede           INT REFERENCES clinica.sede (id_sede) ON DELETE RESTRICT,
    codigo_lote       VARCHAR(50) NOT NULL,
    fecha_vencimiento DATE        NOT NULL,
    stock_actual      INT         NOT NULL CHECK (stock_actual >= 0) -- restriccion CHECK
);

-- Entidad Débil (Detalle de Receta)
CREATE TABLE clinica.detalle_receta
(
    id_receta      INT REFERENCES clinica.receta (id_receta) ON DELETE CASCADE,
    numero_linea   INT,
    id_medicamento INT REFERENCES clinica.medicamento (id_medicamento),
    dosis          VARCHAR(100) NOT NULL,
    frecuencia     VARCHAR(100) NOT NULL,
    cantidad       INT          NOT NULL CHECK (cantidad > 0), -- restriccion CHECK
    PRIMARY KEY (id_receta, numero_linea)
);


-- 5. facturacion, pagos y auditoria

CREATE TABLE clinica.factura
(
    id_factura            SERIAL PRIMARY KEY,
    id_consulta           INT REFERENCES clinica.consulta (id_consulta) ON DELETE CASCADE,
    subtotal_consulta     NUMERIC(10, 2) NOT NULL CHECK (subtotal_consulta >= 0),
    subtotal_medicamentos NUMERIC(10, 2) NOT NULL CHECK (subtotal_medicamentos >= 0),
    monto_seguro          NUMERIC(10, 2) NOT NULL CHECK (monto_seguro >= 0),
    monto_paciente        NUMERIC(10, 2) NOT NULL CHECK (monto_paciente >= 0),
    saldo_pendiente       NUMERIC(10, 2) NOT NULL CHECK (saldo_pendiente >= 0),
    estado                VARCHAR(30)    NOT NULL CHECK (estado IN ('pendiente', 'pagada', 'anulada'))
);

CREATE TABLE clinica.pago
(
    id_pago     SERIAL PRIMARY KEY,
    id_factura  INT REFERENCES clinica.factura (id_factura) ON DELETE CASCADE,
    monto       NUMERIC(10, 2) NOT NULL CHECK (monto > 0),
    metodo_pago VARCHAR(50)    NOT NULL,
    fecha_pago  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE clinica.auditoria_log
(
    id_auditoria     SERIAL PRIMARY KEY,
    tabla_afectada   VARCHAR(100) NOT NULL,
    id_registro      INT          NOT NULL,
    campo_modificado VARCHAR(100),
    valor_anterior   TEXT,
    valor_nuevo      TEXT,
    usuario_bd       VARCHAR(100) NOT NULL,
    fecha_hora       TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- 6. tablas intermediass (relaciones N:M)

CREATE TABLE clinica.medico_especialidad
(
    id_persona      INT REFERENCES clinica.medico (id_persona) ON DELETE CASCADE,
    id_especialidad INT REFERENCES clinica.especialidad (id_especialidad) ON DELETE CASCADE,
    PRIMARY KEY (id_persona, id_especialidad)
);

CREATE TABLE clinica.consulta_diagnostico
(
    id_consulta    INT REFERENCES clinica.consulta (id_consulta) ON DELETE CASCADE,
    id_diagnostico INT REFERENCES clinica.diagnostico (id_diagnostico) ON DELETE CASCADE,
    es_principal   BOOLEAN DEFAULT FALSE,
    PRIMARY KEY (id_consulta, id_diagnostico)
);