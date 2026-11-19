# Análisis de Normalización - Clínica Vida Plena

## 1. Dependencias Funcionales Principales
El diseño evita duplicidades asegurando que cada dato dependa de su llave correspondiente:
* `id_persona`: Datos generales (nombre, teléfono, correo, dirección).
* `id_persona`: (en paciente): Datos clínicos específicos (tipo de sangre, alergias, aseguradora).
* `id_cita`: Detalles de la consulta (fecha, hora, estado, médico y paciente asignados).
* `id_factura`: Montos, subtotales y estado del pago.

---

## 2. Niveles de Normalización (1FN, 2FN y 3FN)
* **1FN:** Se eliminaron listas o grupos repetitivos; todos los campos contienen un único valor atómico.
* **2FN:** En las tablas con llaves compuestas (como `detalle_receta` o las tablas intermedias N:M), los atributos no clave dependen por completo de toda la llave primaria, evitando dependencias parciales.
* **3FN:** Se validó que **no existan dependencias transitivas**. Ningún campo que no sea llave depende de otro atributo secundario; por ejemplo, en la tabla `persona`, la dirección o el teléfono dependen únicamente del identificador de la persona y no de otros datos de contacto.

---

## 3. Forma Normal de Boyce-Codd (FNBC)
Se analizó la tabla `medico` (cuya llave principal es `id_persona`), donde la **cédula profesional** actúa como un identificador único alternativo. Dado que la cédula determina de forma unívoca al médico y funciona como superclave, la tabla cumple con los requisitos de la FNBC.

---

## 4. Justificación de Desnormalización (RN-15)
Siguiendo la **Regla de Negocio 15**, aplicamos una **desnormalización controlada** en la tabla `factura`. Aunque lo ideal en teoría sería consultar siempre el precio actual del catálogo, por cuestiones contables e historiales **los precios de los medicamentos y consultas se guardan estáticos al momento de facturar**. Esto garantiza que si el costo de un servicio o medicina sube en el futuro, las facturas ya emitidas del pasado no sufran alteraciones en sus montos.