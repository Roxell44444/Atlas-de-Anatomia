# ATLAS DE ANATOMÍA

Aplicación educativa Android-first construida con Godot 4.7.2. Versión fuente preparada: **0.9.0**.

## Mejoras de la versión 0.9.0

- Visor 3D preparado para selección táctil, resaltado y centrado de estructuras aprobadas.
- Controles para capas de disección, transparencia y recortes sagital, coronal y transversal.
- Comparador masculino/femenino con dos vistas 3D y notas de diferencias generales.
- Academia local con seis cursos, cuestionarios y progreso guardado.
- Fichas con nombres en español, latín e inglés y enlaces a estructuras relacionadas.
- Tutor HTTPS con contexto de la ficha y referencias enlazadas explícitamente.
- Perfiles gráficos calidad/equilibrado/batería; catálogo, favoritos y cursos disponibles localmente.
- Dedicatoria en Información: “para amorcito de parte de motito que te ama mucho”.

## Política de coste cero

No se compran modelos ni licencias. El importador solo acepta CC0, CC BY 4.0, CC BY 3.0 y dominio público de EE. UU. con procedencia, atribución, hash y revisiones manuales. Se excluyen NC, ND y ShareAlike de esta ruta. BodyParts3D 4.0 y objetos HRA son candidatos gratuitos sujetos a revisión individual.

## Estado real y límites

- Hay 13 sistemas y 33 fichas iniciales; el catálogo no es exhaustivo y requiere revisión profesional.
- El selector busca modelos aprobados por sexo, pero todavía no hay mallas anatómicas reales aprobadas en la entrega. El modelo visible sigue siendo geométrico y provisional.
- Capas y cortes dependen de metadatos y materiales compatibles; los cortes actuales no generan tapas geométricas.
- El Tutor requiere desplegar el Worker y configurar GEMINI_API_KEY como secreto de servidor.
- No se ha confirmado aún ejecución con Godot ni exportación/prueba APK en Android.

## Validación local realizada

`python tools/validate_project.py`, 9 pruebas unitarias, `node --check workers/src/index.js` y comprobación de integridad del ZIP. Estas comprobaciones no sustituyen la importación/ejecución del proyecto en Godot ni las pruebas en teléfonos.

El paquete fuente 0.9.0 se adjunta en la conversación. **Este repositorio todavía no contiene los archivos de código individuales**, solo esta ficha de estado.

La aplicación es educativa; no diagnostica ni sustituye evaluación profesional.

## Primer paquete de geometría ósea real

Se han incorporado 20 mallas STL de referencia, diez tipos de hueso por cada uno de los dos especímenes Visible Human: mandíbula, C1, C2, clavícula izquierda, escápula izquierda, húmero izquierdo, radio izquierdo, ulna izquierda, fémur izquierdo y tibia izquierda.

- Índice y rutas: `data/visible_human_bone_pack.json`.
- Atribución y limitaciones: `docs/ATTRIBUTION_VISIBLE_HUMAN.md`.
- Mallas: `assets/skeleton/visible_human/`.

**Estado:** activos originales gratuitos CC BY 4.0 incorporados al repositorio, pendientes de comprobación de escala, orientación, alineación, mapeo anatómico y revisión independiente. Son vistas previas STL y una muestra piloto, no un esqueleto completo ni contenido anatómico validado por ATLAS. Los dos sujetos son especímenes individuales; no representan promedios poblacionales ni diferencias universales entre sexos.
