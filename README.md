# ATLAS DE ANATOMÍA

Atlas anatómico educativo e interactivo, Android primero, desarrollado con Godot 4.7.2. Versión de trabajo: **0.1.0-dev**.

## Base de aplicación incorporada

- Proyecto Godot real: `project.godot`, escena principal y scripts GDScript.
- Interfaz inicial en español y selector de cuerpo masculino/femenino.
- Visor 3D con cámara orbital, zoom, selección por rayo de colisión y resaltado de la malla seleccionada.
- Filtros por sistema y controles de visibilidad de piel, esqueleto, músculos, órganos, vasos y nervios.
- Índice local con 147 nombres anatómicos en español e inglés y claves originales estables.
- Panel de ficha y guardado local de modo/selección.
- Cinco fichas educativas iniciales con contenido y fuentes: corazón, ambos fémures y ambos riñones.
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

Las primeras fichas ampliadas son paráfrasis educativas de **Anatomy & Physiology 2e**, edición de Oregon State University Open Educational Resources bajo CC BY 4.0. Se incluyen referencias específicas por ficha y atribución en `docs/ATTRIBUTION_EDUCATIONAL_DATA.md`.

Los nombres y la indexación de las 147 entradas están disponibles sin conexión. La información profunda aún no está completada para todas las estructuras: las fichas sin contenido ampliado se identifican de forma explícita y no se rellenan con afirmaciones genéricas.

## Compilación Android

El flujo `.github/workflows/android-build.yml`:
1. Valida los catálogos y las fichas.
2. Descarga los dos GLB y comprueba sus hashes.
3. Decodifica los modelos para compatibilidad con el importador Godot.
4. Importa el proyecto con Godot 4.7.2.
5. Intenta exportar una APK Android de depuración y publica el archivo como artefacto de GitHub Actions.

El flujo ya está añadido al repositorio, pero su ejecución y la APK resultante todavía deben comprobarse en GitHub Actions.

## Estado y límites actuales

- El proyecto Godot y su interfaz inicial ya están en el repositorio.
- Los modelos binarios no se guardan en Git: se descargan y verifican durante la compilación y quedan empaquetados en la APK si el flujo finaliza correctamente.
- El visor crea colisiones para las mallas con clave coincidente en el catálogo; selección, orientación, capas y rendimiento necesitan validación real en Godot y Android.
- La ficha ampliada solo está disponible inicialmente para cinco estructuras; la ampliación por estructura necesita fuentes y revisión anatómica.
- El paquete Visible Human previo contiene 20 mallas óseas piloto, no un esqueleto completo.
- La aplicación principal está diseñada para funcionar offline cuando los recursos descargados estén empaquetados. Tutor Gemini requiere conexión y un backend seguro; el modo local solo busca en el catálogo.
- Todavía no se ha confirmado una APK funcional ni una prueba de modo avión en un teléfono Android.

## Regla de calidad

No se marca una función como completada hasta que exista código en el repositorio, importación o prueba reproducible y evidencia de ejecución. La aplicación es educativa: no diagnostica ni sustituye una evaluación profesional.
