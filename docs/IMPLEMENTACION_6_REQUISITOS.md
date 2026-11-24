# Plan de implementación verificable — ATLAS DE ANATOMÍA

Este documento convierte los seis requisitos funcionales en criterios de aceptación. No declara funciones implementadas hasta que exista código ejecutable y pruebas.

## Principios

- Android primero; motor objetivo Godot 4.x (versión exacta fijada al crear el proyecto).
- Coste de licencia e infraestructura: 0 USD para la primera versión.
- Datos anatómicos, modelos, traducciones, fichas, índices y evaluaciones se empaquetan localmente.
- Ninguna pantalla principal debe depender de CDN, API o conexión.
- Gemini es una función opcional en línea; nunca bloquea la consulta local.
- No inventar detalles ni completar campos anatómicos con texto genérico. Cada dato tendrá fuente, licencia, idioma y estado de revisión.
- Uso educativo, no diagnóstico.

## Los seis requisitos y su aceptación

### 1. Modelos masculino y femenino

- Selector persistente y visible de modelo masculino/femenino.
- Cada modo carga su propio GLB local, nunca una URL en tiempo de ejecución.
- El manifiesto registra tamaño, SHA-256, procedencia, licencia, versión, escala, orientación y estado de validación.
- Validar importación, materiales, normales, escala, orientación, jerarquía y rendimiento en Android.
- Mostrar límites conocidos de cada modelo. No inferir diferencias universales a partir de una malla promedio o de un espécimen individual.

**Aceptación:** ambos modelos se abren en modo avión en un dispositivo Android y el selector cambia entre ellos sin pérdida de estado ni errores.

### 2. Cobertura anatómica

El catálogo se organiza por sistemas y regiones, incluyendo como mínimo:

- Tegumentario.
- Esquelético y articulaciones.
- Muscular y tendones.
- Nervioso central y periférico.
- Cardiovascular: corazón, arterias, venas y microcirculación cuando existan datos licenciados.
- Linfático e inmunitario.
- Respiratorio.
- Digestivo y órganos accesorios.
- Urinario.
- Reproductor masculino y femenino.
- Endocrino.
- Órganos de los sentidos.
- Sangre y tejidos; histología y microanatomía.
- Embriología y desarrollo, vinculados a etapas y estructuras.

No se presentará como cobertura completa un recurso parcial. El catálogo distingue: `available_3d`, `available_info_only`, `planned` y `not_in_source`.

### 3. Selección individual en 3D

Cada estructura tendrá un identificador estable independiente del nombre traducido. El índice local enlaza identificador con nodos/mallas reales por modelo y con sus estructuras relacionadas.

- Toque/clic selecciona la malla; resalta sin ocultar el contexto.
- Lista y búsqueda permiten seleccionar también estructuras que no estén segmentadas como malla independiente.
- Filtros por sistema, región, lado, profundidad y modelo.
- Las estructuras agrupadas se declaran como agrupadas; no se simula selección individual donde la malla no lo permite.
- Se admiten selección, aislamiento, ocultar/mostrar, transparencia y centrar cámara.

**Aceptación:** prueba automatizada que comprueba que cada ID seleccionable apunta a una malla existente o está marcado explícitamente como ficha sin malla.

### 4. Fichas anatómicas profundas

Esquema de ficha versionado, con campos opcionales y aplicables según el tipo:

- Nombre español, término latino, sinónimos y término inglés.
- Definición, ubicación, región, lateralidad, relaciones y límites.
- Partes, subdivisiones, caras/superficies, bordes, ángulos, apófisis, forámenes, conductos, surcos y accidentes óseos.
- Origen, inserción, acción, inervación e irrigación para músculos.
- Origen, trayecto, ramas, territorio y relaciones para nervios y vasos.
- Función, estructura, drenaje, irrigación, inervación y relaciones para órganos.
- Articulaciones: superficies, cápsula, ligamentos, movimientos y estabilizadores.
- Histología: tejido, células, organización y microfotografías licenciadas.
- Embriología: origen, semanas/etapas, derivados y correlaciones.
- Bibliografía, licencia, fecha de revisión, revisor/estado y nivel de confianza.

No se rellenan campos irrelevantes con “N/A” ni se inventan medidas. Las medidas deben incluir fuente y referencia anatómica.

**Aceptación:** validación de esquema, enlaces internos válidos, referencias por afirmación y fichas de ejemplo revisadas antes de ampliar masivamente.

### 5. Funcionamiento sin internet

Recursos locales obligatorios:
- Modelos 3D y texturas.
- Catálogo, traducciones y fichas.
- Índices de selección, sistemas y relaciones.
- Imágenes y microfotografías con licencia.
- Cursos, glosario, cuestionarios y progreso.
- Ayuda, créditos y avisos educativos.

Persistencia local con migraciones de esquema. Búsqueda e índice disponibles sin red. El modo avión debe permitir explorar, seleccionar, consultar, buscar y estudiar.

La app solo consulta red si el usuario abre voluntariamente funciones en línea. Si no hay conexión, el tutor informa que no está disponible y conserva el resto de la app.

**Aceptación:** pruebas de instrumentación en modo avión después de instalación limpia; bloquear red y verificar navegación, selección, búsqueda, fichas y progreso.

### 6. Tutor anatómico contextual

- En línea: enviar a Gemini solo la pregunta, el ID/nombre seleccionado y el extracto local relevante; nunca enviar fotos ni datos personales por defecto.
- Incluir fuentes de las fichas locales en la respuesta.
- Distinguir hechos del catálogo, inferencias y dudas.
- Si no hay internet/API, ofrecer búsqueda local y explicación basada en fichas descargadas.
- No diagnosticar ni sustituir profesionales.
- La clave Gemini se guarda en backend/secretos, nunca en APK ni repositorio.

**Aceptación:** pruebas con estructura seleccionada, contexto correcto, citas locales, ausencia de secreto en APK, timeout y fallback sin conexión.

## Arquitectura de datos local

Cada estructura usa un registro equivalente a:

```json
{
  "id": "bone.femur",
  "system_id": "skeletal",
  "region_ids": ["lower_limb", "thigh"],
  "names": {
    "es": "Fémur",
    "la": "Femur",
    "en": "Femur"
  },
  "models": {
    "male": {"mesh_ids": [], "availability": "info_only"},
    "female": {"mesh_ids": [], "availability": "info_only"}
  },
  "content_ref": "entries/bone.femur.json",
  "relations": [],
  "sources": [],
  "review_status": "needs_review"
}
```

Los IDs no cambian al traducir. Las mallas se enlazan mediante IDs verificados, nunca por coincidencia aproximada de nombres durante la ejecución.

## Plan de trabajo en orden

1. Crear proyecto Godot real y fijar versión, renderer, estructura de carpetas y exportación Android.
2. Descargar los dos GLB desde la fuente licenciada, verificar hashes/tamaño y probar conversión si meshopt no es compatible.
3. Importar ambos modelos y construir selector de modo, visor, selección y filtros por sistema.
4. Crear índice de mallas y catálogo local traducido; detectar cobertura real y huecos.
5. Implementar fichas versionadas y búsqueda sin conexión.
6. Ampliar modelos/datos por sistema con fuentes abiertas y licencias verificadas; priorizar esqueleto, músculos, órganos, nervios y vasos.
7. Añadir histología, embriología, cursos y tutor contextual con fallback local.
8. Automatizar validación de datos, licencias, enlaces, importación y pruebas Android.
9. Generar APK candidata, probar en Android físico en modo avión y conectado, corregir fallos y publicar créditos.

## Bloqueos y límites actuales confirmados

- El repositorio ya contiene un proyecto Godot inicial: `project.godot`, escena principal y scripts GDScript de catálogo, interfaz y visor. La importación y ejecución del proyecto todavía no se han validado con el motor.
- El catálogo de origen Open Anatomy 3D tiene 147 entradas: 12 son hotspots articulares y no mallas; declara 140 estructuras masculinas y 145 femeninas. Se amplió el índice de la aplicación a 263 entradas (147 de la fuente y 116 informativas sin malla 3D), distribuidas en 13 categorías de sistemas. Las entradas adicionales están marcadas con contenido pendiente; no se presentan como mallas.
- El flujo de CI descarga, comprueba y convierte los dos GLB para empaquetarlos con la exportación Android. La descarga y la importación aún necesitan un resultado de CI satisfactorio.
- El paquete Visible Human es un piloto de 20 mallas óseas y no un esqueleto completo.
- La cobertura exhaustiva de todo el cuerpo requiere incorporar más fuentes abiertas, revisar licencias y validar cada estructura; no puede declararse terminada por el mero hecho de listar sistemas.
- Hay un flujo GitHub Actions para validar catálogo, importar los modelos y exportar una APK de depuración; su ejecución y resultado no están confirmados. No hay todavía APK validada ni pruebas de modo avión.
- Hay veinticinco fichas profundas iniciales activas, basadas en capítulos específicos de las primeras ediciones de Douglas College I y II, que declaran CC BY 4.0. Cada ficha incluye la atribución digital exigida. Las demás entradas siguen pendientes de documentación. Histología y embriología completas todavía no están desarrolladas.
- La base del tutor ofrece búsqueda local; la conexión segura a Gemini y su servicio todavía no están configurados.


## Regla de finalización

Un requisito solo cambia a “completado” cuando existe implementación en el repositorio, prueba reproducible y evidencia de ejecución. La presencia de documentación, un catálogo o un modelo descargable por separado no basta.
