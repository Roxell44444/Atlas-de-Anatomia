# ATLAS DE ANATOMÍA

Atlas anatómico educativo e interactivo, Android primero, desarrollado con Godot 4.7.2. Versión de trabajo: **0.1.0-dev**.

## Base de aplicación incorporada

- Proyecto Godot real: `project.godot`, escena principal y scripts GDScript.
- Interfaz inicial en español y selector de cuerpo masculino/femenino.
- Visor 3D con cámara orbital, zoom, selección por rayo de colisión y resaltado de la malla seleccionada.
- Filtros por sistema y controles de visibilidad de piel, esqueleto, músculos, órganos, vasos y nervios.
- Índice local con 263 entradas: 147 entradas originales de Open Anatomy 3D y 116 entradas informativas adicionales sin malla 3D, con nombres en español e inglés, claves estables y cobertura organizada en 13 categorías de sistemas.
- Panel de ficha y guardado local de modo/selección.
- Veinticinco fichas anatómicas profundas iniciales: corazón, ambos fémures, ambos riñones, piel, sangre, ganglios linfáticos, tiroides, hipófisis, suprarrenales, intestino delgado, hígado, páncreas, vesícula biliar, sistema reproductor, testículos, útero, ovarios, vagina, clítoris y articulación de la cadera. Están redactadas como paráfrasis en español, con fuente CC BY 4.0 y atribución específica en cada una.
- Panel tutor con búsqueda local. La integración generativa Gemini requiere un servicio seguro configurado; no se incluye ninguna clave en la aplicación.
- Dedicatoria en Información: “para amorcito de parte de motito que te ama mucho”.

## Modelos 3D y licencias

La fuente seleccionada es **Open Anatomy 3D 0.1.0**. Sus modelos GLB se descargan durante CI, se verifican mediante tamaño y Git blob SHA-1 upstream, se decodifican para eliminar dependencias de `EXT_meshopt_compression` y se incluyen en la exportación Android.

- Modelo masculino y femenino: CC BY 4.0.
- Código de la fuente: MIT.
- Fuentes de los modelos: BodyParts3D © DBCLS (CC BY 4.0); órganos femeninos del Human Reference Atlas / HuBMAP (CC BY 4.0); superficie corporal femenina MakeHuman (CC0).
- Atribución y limitaciones: `docs/ATTRIBUTION_OPEN_ANATOMY_3D.md`.
- Manifiesto y hashes: `data/open_anatomy_3d_manifest.json`.
- Catálogo original: `data/open_anatomy_3d_catalog.json`.
- Catálogo localizado: `data/anatomy_catalog_es.json`.

La fuente declara 147 entradas; 12 son puntos de referencia articulares y no mallas. Declara 140 estructuras en el modelo masculino y 145 en el femenino. No representa por sí sola todos los órganos ni todos los sistemas del cuerpo.

## Contenido anatómico educativo

Las veinticinco fichas iniciales usan capítulos específicos de *Douglas College Human Anatomy and Physiology I (1st ed.)* y *II (1st ed.)*, que declaran CC BY 4.0. Cada ficha conserva URL del capítulo y la atribución digital obligatoria “Download for free at…”. Se redactaron como paráfrasis originales en español, sin reutilizar figuras; `docs/ATTRIBUTION_EDUCATIONAL_DATA.md` explica las licencias y sus límites.

Los nombres y la indexación de las 263 entradas están disponibles sin conexión. Las 116 entradas añadidas son informativas, no aparecen como mallas del modelo y mantienen la ficha ampliada en estado pendiente. La información profunda aún no está completada para todas las estructuras: las fichas sin contenido ampliado se identifican de forma explícita y no se rellenan con afirmaciones genéricas.

## Compilación Android

El flujo `.github/workflows/android-build.yml` realiza estos pasos:

1. Valida el catálogo, los sistemas y las fichas con sus licencias.
2. Descarga los GLB masculino y femenino y comprueba su tamaño y hash.
3. Registra extensiones Khronos, descomprime meshopt y desquantiza la geometría para preparar el formato GLB.
4. Importa el proyecto con Godot 4.7.2.
5. Comprueba que las mallas esperadas se pueden localizar en ambos modelos.
6. Exporta una APK Android de depuración y la publica como artefacto.

Las pruebas de ejecución inspeccionan la jerarquía importada de cada GLB: una estructura se considera seleccionable cuando su clave anatómica identifica un nodo que contiene una o más mallas descendientes. La exportación de Android y la publicación del artefacto solo se ejecutan después de superar la importación, la comprobación de los dos modelos y el arranque del proyecto. Una ejecución fallida no produce una APK válida.

## Estado y límites actuales

- El proyecto Godot y su interfaz inicial ya están en el repositorio.
- Los modelos binarios no se guardan en Git: se descargan y verifican durante la compilación y quedan empaquetados en la APK si el flujo finaliza correctamente.
- El visor crea colisiones para las mallas con clave coincidente en el catálogo; selección, orientación, capas y rendimiento necesitan validación real en Godot y Android.
- Hay cinco fichas profundas iniciales aprobadas con fuentes CC BY 4.0; las otras 258 entradas siguen pendientes de documentación.
- El paquete Visible Human previo contiene 20 mallas óseas piloto, no un esqueleto completo.
- La aplicación principal está diseñada para funcionar offline cuando los recursos descargados estén empaquetados. Tutor Gemini requiere conexión y un backend seguro; el modo local solo busca en el catálogo.
- Todavía no se ha confirmado una APK funcional ni una prueba de modo avión en un teléfono Android.

## Regla de calidad

No se marca una función como completada hasta que exista código en el repositorio, importación o prueba reproducible y evidencia de ejecución. La aplicación es educativa: no diagnostica ni sustituye una evaluación profesional.
