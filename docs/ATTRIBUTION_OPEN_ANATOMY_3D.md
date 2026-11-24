# Atribución y revisión de licencia — Open Anatomy 3D

## Resultado de la revisión

**Fuente aceptada para su uso en ATLAS DE ANATOMÍA:** los dos modelos GLB y el catálogo de estructuras del paquete `open-anatomy-3d@0.1.0` declaran licencia **Creative Commons Attribution 4.0 International (CC BY 4.0)**. Esta licencia permite compartir y adaptar los modelos, incluso con fines comerciales, siempre que se conserve la atribución, se incluya el enlace a la licencia y se indiquen las modificaciones realizadas.

- Repositorio: https://github.com/MervinR07/open-anatomy-3d
- Paquete: https://www.npmjs.com/package/open-anatomy-3d
- Licencia de los modelos y del catálogo: https://creativecommons.org/licenses/by/4.0/
- Licencia del código upstream: MIT (no confundir con la licencia de los modelos).

La licencia se revisó para el paquete citado y su documentación pública. Antes de distribuir una compilación, se conservará esta atribución en la pantalla Información/Créditos y en la documentación de licencias.

## Texto de crédito que debe mantenerse

> Anatomy: BodyParts3D © The Database Center for Life Science (CC BY 4.0); female organs: Human Reference Atlas 3D Reference Organs, HuBMAP (CC BY 4.0); female body: MakeHuman (CC0). Modified by open-anatomy-3d (https://github.com/MervinR07/open-anatomy-3d), CC BY 4.0.

Se debe enlazar también a la licencia CC BY 4.0 y declarar que ATLAS DE ANATOMÍA reutiliza/adapta estos modelos. No se debe quitar el crédito de las fuentes originales.

## Procedencia de las partes

- **BodyParts3D 4.0 — ambos modelos:** Database Center for Life Science (DBCLS), CC BY 4.0.
  https://dbarchive.biosciencedbc.jp/data/bodyparts3d/LATEST/
- **Human Reference Atlas 3D Reference Organs, conjunto female v1.10 — órganos reproductores femeninos:** HuBMAP / Cyberinfrastructure for Network Science Center, Indiana University, CC BY 4.0.
  https://cdn.humanatlas.io/digital-objects/ref-organ/united-female/v1.10/
- **MakeHuman — superficie corporal femenina:** malla base hm08, objetivos femeninos y rig/pesos por defecto, CC0 1.0.
  https://github.com/makehumancommunity/makehuman

El proyecto upstream describe el modelo masculino como una agrupación de unas 2.200 mallas BodyParts3D en estructuras identificadas. El cuerpo femenino utiliza una malla media joven-adulta de MakeHuman, ajustada a la anatomía mediante landmarks; los órganos femeninos específicos citados proceden del Human Reference Atlas. Esto debe explicarse correctamente: el cuerpo femenino no es un escaneo cadavérico individual ni un promedio clínico validado.

## Contenido declarado por la fuente

- Dos modelos GLB: masculino (7.614.076 bytes) y femenino (8.134.732 bytes).
- Siete grupos de visualización: piel, esqueleto, músculos, órganos, vasos, nervios y articulaciones.
- Catálogo upstream: 147 entradas; incluye 12 puntos de referencia articulares, que son hotspots y no mallas independientes.
- La documentación upstream indica 140 estructuras para el cuerpo masculino y 145 para el femenino.
- Los modelos usan metros, eje Y hacia arriba y pies en y=0.
- Los GLB están comprimidos con `EXT_meshopt_compression`; la importación debe probarse con la versión de Godot prevista. Si no es compatible, debe generarse una copia local descomprimida/decuantizada y comprobarse visualmente.

## Límites y control de calidad

La aprobación de licencia **no equivale a validación anatómica clínica**. Antes de activar el modelo en el atlas se debe comprobar en el motor:

1. Importación sin errores y sin extensiones GLTF sin resolver.
2. Orientación, escala y centrado de ambos cuerpos.
3. Correspondencia de las mallas con las 147 claves del catálogo.
4. Visibilidad independiente por sistema y selección de cada estructura disponible.
5. Diferencias masculino/femenino reales dentro del alcance del conjunto, sin generalizar características de una malla individual o promedio a todas las personas.
6. Presentación correcta de estructuras reproductoras disponibles y ausencia explícita de estructuras que el modelo no incluya.
7. Funcionamiento offline una vez empaquetados los archivos localmente.

Los modelos son para educación y visualización; no deben usarse para diagnóstico ni decisiones clínicas.

## Estado de integración en ATLAS DE ANATOMÍA

La fuente y su licencia CC BY 4.0 están revisadas y registradas, y el catálogo se ha copiado con sus claves originales. Los dos binarios GLB todavía no están incluidos en este repositorio ni activados en una escena. El repositorio actual tampoco contiene todavía los archivos individuales del proyecto Godot; por ello no sería correcto afirmar que los modos ya funcionan dentro de la aplicación.
