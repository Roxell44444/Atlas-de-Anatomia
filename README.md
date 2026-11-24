# ATLAS DE ANATOMÍA

Aplicación Android-first de exploración anatómica 3D, desarrollada con Godot 4.7.2.

## Estado de desarrollo — versión fuente 0.8.0

La versión 0.8.0 incorpora una base de aplicación más completa, catálogo anatómico y herramientas de adquisición de activos gratuitos. El paquete fuente de esta entrega se ha preparado y entregado por separado; **no se afirma que sus archivos completos estén todavía publicados en este repositorio**.

### Implementado en la base 0.8.0

- Interfaz adaptada a móvil con selector masculino/femenino.
- Visor 3D provisional con órbita, zoom táctil, selección de mallas aprobadas y encuadre.
- Catálogo de partida con 13 sistemas y 33 estructuras de ejemplo (no exhaustivo).
- Búsqueda, fichas extensibles, filtros por sistema y favoritos locales.
- Información de la aplicación con la dedicatoria exacta: **“para amorcito de parte de motito que te ama mucho”**.
- Cliente del Tutor IA por HTTPS; la clave del proveedor debe quedar en el backend, nunca dentro del APK.
- Registro de modelos con SHA-256, atribución, licencia, coste y revisión explícita.
- Herramientas para descargar candidatos BodyParts3D, inspeccionar/importar modelos y validar catálogo.
- Pruebas automáticas de datos y cuatro pruebas unitarias.

### Política de coste cero y licencias

No se comprarán modelos ni licencias. No se redistribuyen modelos o textos hasta comprobar la licencia del archivo concreto, el coste, la procedencia y la atribución.

- **BodyParts3D 4.0:** candidato masculino adulto, CC BY 4.0; se exige la atribución oficial y registrar modificaciones.
- **Human Reference Atlas / NIH 3D:** recursos HRA publicados bajo CC BY 4.0; cada objeto femenino candidato requiere inspección de sus metadatos y segmentación.
- **MakeHuman:** candidato para superficie corporal externa; no reemplaza órganos internos y cada archivo debe revisarse por separado.

Fuentes: [BodyParts3D](https://dbarchive.biosciencedbc.jp/en/bodyparts3d/download.html), [HRA 3D Reference Library](https://humanatlas.io/3d-reference-library), [NIH 3D](https://3d.nih.gov/entries/20992), [licencia CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).

### Límites que siguen abiertos

- Las mallas anatómicas reales no se incluyen en el paquete; los modelos candidatos se registran como `pending_review` hasta verificar la licencia, integridad y anatomía.
- El cuerpo geométrico provisional no es un modelo médico ni representa las diferencias anatómicas completas entre sexos.
- Las 33 fichas son una muestra inicial, no una cobertura anatómica exhaustiva ni contenido validado por especialistas.
- El Tutor requiere desplegar el Worker y configurar un secreto de API en el servidor. Sin esa configuración no responde.
- La ejecución real con Godot, la exportación Android y la prueba en dispositivo físico están pendientes. Las pruebas Python del catálogo no sustituyen esas validaciones.

La app es un recurso educativo; no diagnostica ni sustituye la evaluación de profesionales sanitarios.
