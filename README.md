# ATLAS DE ANATOMÍA

Aplicación educativa 3D de anatomía humana, prevista para Android y construida con Godot. La ficha de estado del proyecto indica la versión fuente preparada **0.9.0**; la integración de los modelos 3D continúa en fase de preparación.

## Características descritas para la versión 0.9.0

- Visor 3D previsto para selección, resaltado y centrado de estructuras.
- Capas de disección, transparencia y planos sagital, coronal y transversal.
- Comparador de anatomía masculina y femenina.
- Academia local, cursos y cuestionarios.
- Fichas en español, latín e inglés.
- Tutor HTTPS preparado para contexto anatómico y referencias.
- Dedicatoria en Información: “para amorcito de parte de motito que te ama mucho”.

## Política de coste cero y licencias

No se compran modelos ni licencias. La ruta de importación admite recursos CC0, CC BY 4.0, CC BY 3.0 y dominio público de EE. UU. con procedencia y atribución documentadas; se excluyen materiales NC, ND y ShareAlike de la ruta principal.

## Modelos anatómicos: modos masculino y femenino

Se ha identificado y revisado una fuente reutilizable que cubre los dos modos corporales:

- **Open Anatomy 3D 0.1.0:** modelos GLB masculino y femenino con piel, esqueleto, músculos, órganos, vasos y nervios, más hotspots articulares.
- **Catálogo:** 147 entradas; 12 son puntos de referencia articulares y no mallas. La fuente declara 140 estructuras en el cuerpo masculino y 145 en el femenino.
- **Licencia de modelos y catálogo:** CC BY 4.0, compatible con reutilización y adaptación comercial si se conserva la atribución, se enlaza la licencia y se declaran los cambios.
- **Atribución obligatoria y límites:** `docs/ATTRIBUTION_OPEN_ANATOMY_3D.md`.
- **Manifiesto de los modelos, URLs y hashes Git upstream:** `data/open_anatomy_3d_manifest.json`.
- **Catálogo original de estructuras:** `data/open_anatomy_3d_catalog.json`.

La anatomía masculina procede de estructuras BodyParts3D agrupadas; la superficie corporal femenina se basa en una malla media joven-adulta MakeHuman ajustada a la anatomía, y sus órganos reproductores femeninos específicos provienen del Human Reference Atlas. No se deben presentar estas mallas como escaneos clínicos completos ni usar las diferencias de una malla para generalizar a todas las personas.

**Estado real:** la licencia y la procedencia de esta fuente están revisadas y el catálogo se encuentra en el repositorio. Los dos archivos GLB todavía no están empaquetados localmente ni activados en una escena Godot. La compresión `EXT_meshopt_compression`, la escala, orientación, selección por estructura y funcionamiento offline deben validarse antes de declarar los modos operativos.

## Paquete piloto Visible Human

Se conservan 20 mallas STL de referencia, diez tipos de hueso por cada uno de dos especímenes cadavéricos:

- Índice: `data/visible_human_bone_pack.json`.
- Atribución y limitaciones: `docs/ATTRIBUTION_VISIBLE_HUMAN.md`.
- Mallas: `assets/skeleton/visible_human/`.

Este paquete es una muestra piloto, no un esqueleto completo ni una representación poblacional. Los dos sujetos son especímenes individuales; sus diferencias no representan diferencias universales entre sexos.

## Estado real del repositorio

- Hay 13 sistemas y 33 fichas iniciales; el catálogo pedagógico todavía no es exhaustivo y necesita revisión especializada.
- Los modelos Open Anatomy 3D están aprobados en cuanto a licencia, pero aún no están integrados en el visor.
- Las capas y los cortes dependen de metadatos y materiales compatibles; los cortes actuales no generan tapas geométricas.
- El Tutor necesita desplegar su servicio y configurar `GEMINI_API_KEY` como secreto del servidor.
- No se ha confirmado la importación/ejecución con Godot ni la exportación/prueba APK en Android.
- **Este repositorio contiene la ficha de estado, catálogos y algunos activos, pero todavía no incluye los archivos de código individuales del proyecto Godot.** No se debe afirmar que el proyecto completo está integrado o compilado hasta que se incorporen esos archivos y se ejecuten pruebas.

La aplicación es educativa; no diagnostica ni sustituye una evaluación profesional.
