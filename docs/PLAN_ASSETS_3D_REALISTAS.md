# Siguiente fase: anatomía 3D con aspecto de referencia médica

## Objetivo visual

El visor debe acercarse a un atlas anatómico de estudio: cuerpo completo en posición anatómica, anatomía diferenciada por tejidos, órganos con forma y apariencia propias, vasos y nervios reconocibles, control de capas, selección individual, giro horizontal de 360°, inclinación vertical, zoom y enfoque de una estructura.

La paleta de materiales incorporada en la fase móvil es solo una primera mejora de lectura. No convierte una malla simplificada en un modelo fotográfico ni sustituye una textura anatómica de alta calidad. La siguiente fase debe incorporar geometrías y materiales de fuentes abiertas que puedan redistribuirse legalmente.

## Fuentes gratuitas seleccionadas para evaluar e integrar

| Fuente | Material aprovechable | Licencia indicada por la fuente | Uso previsto |
|---|---|---|---|
| BodyParts3D 4.0 | Anatomía corporal masculina y piezas anatómicas | CC BY 4.0 | Referencia de geometría y terminología; ya forma parte de la base actual |
| HuBMAP / Human Reference Atlas CCF 3D Reference Object Library (release 2.5; versiones individuales por órgano) | Órganos de referencia masculinos y femeninos, con jerarquía semántica | CC BY 4.0 | Primera opción para reemplazar o complementar los órganos genéricos |
| Voxel-Man Segmented Inner Organs (Visible Human Male) | Torso y órganos internos segmentados | CC BY 4.0 | Complemento del torso masculino, sujeto a validación de escala y atribución |
| Z-Anatomy | Modelo masculino detallado, capas y estructuras anatómicas | CC BY-SA 4.0 | Candidato para aumentar el detalle musculoesquelético y de tejidos; su adaptación debe conservar CC BY-SA 4.0 |
| Allen Human Reference Atlas 3D | Modelo cerebral de referencia | CC BY 4.0 | Fuente especializada para mejorar el encéfalo |

## Cobertura comprobada en las fuentes de referencia

- La página del HRA CCF muestra modelos GLB individuales de corazón, hígado, pulmones, riñones, páncreas, intestinos, piel, vasos, bazo, timo y estructuras reproductoras, con variantes masculinas y femeninas cuando están disponibles. Los modelos los desarrolla un especialista en ilustración médica 3D y los aprueban expertos de cada órgano.
- El portal HRA v2.5 informa de 71 objetos de referencia y 1.295 estructuras 3D vinculadas a identificadores de ontología. Esto aporta una base mucho más profunda que el catálogo actual de 147 elementos de Open Anatomy 3D.
- El catálogo de Ana3D publica referencias de BodyParts3D masculino (3.432 estructuras), HRA femenino (1.166) y masculino (1.132), y Z-Anatomy masculino detallado (5.461). Los conteos pertenecen a esos atlas y no deben sumarse como si fueran una sola cobertura.
- El modelo Voxel-Man/SIO contiene 232 estructuras en el torso masculino, de cuello a muslos superiores, segmentadas a partir de cortes del Visible Human. El propio proveedor advierte que las superficies de objetos pequeños pueden verse escalonadas.

Fuentes y licencias revisadas:
- Ana3D, *Data sources and licences* (actualizada 9 de octubre de 2026): https://ana3d.app/en/sources-and-licences/
- Ana3D, catálogo de atlas y conteos por modelo: https://ana3d.app/en/atlas/
- Human Reference Atlas / CCF 3D Reference Object Library: https://hubmapconsortium.github.io/ccf/pages/ccf-3d-reference-library.html
- Voxel-Man, órganos internos segmentados del Visible Human masculino: https://www.virtual-body.org/segmented-internal-organs/
- Z-Anatomy, repositorio de aplicación y modelos: https://github.com/Z-Anatomy/Unity-app_Z-Anatomy
- Z-Anatomy, repositorio de aplicación y modelos: https://github.com/Z-Anatomy/Unity-app_Z-Anatomy

## Restricciones de licencia

- Cada objeto integrado debe conservar la atribución de su atlas de origen, la URL de la licencia y la indicación de las modificaciones.
- Los objetos de Z-Anatomy derivados bajo CC BY-SA 4.0 deben mantenerse bajo esa licencia cuando se redistribuyan adaptaciones.
- No se integrarán componentes de Z-Anatomy con restricciones no comerciales ni piezas cuya licencia no pueda comprobarse.
- Los modelos de Surgical Planning Laboratory / Open Anatomy indicados con 3D Slicer License, parte B, quedan excluidos de la distribución de la aplicación hasta una revisión específica de sus condiciones.
- No se utilizarán modelos de pago, recursos pirateados ni texturas copiadas de aplicaciones comerciales.

## Plan de implementación

1. Importar primero los órganos de HRA con licencia CC BY 4.0 y enlazar sus identificadores ontológicos con las fichas en español, latín e inglés.
2. Comprobar escala, orientación, ejes, posición anatómica y compatibilidad de cada órgano con los dos cuerpos base.
3. Separar por lo menos corazón, pulmones, cerebro, hígado, riñones, estómago, intestinos, páncreas, bazo y órganos reproductores cuando la fuente ofrezca malla independiente.
4. Mantener las variantes masculina y femenina con sus órganos específicos; no completar una variante con geometría de la otra sin declararlo.
5. Aplicar materiales PBR/texturas únicamente cuando estén incluidos en el recurso o se creen desde cero y se documenten; no usar un simple color plano como afirmación de realismo.
6. Crear pruebas de selección, aislamiento, transparencia, visibilidad por sistema, giro 360°, zoom y rendimiento en Android.
7. Empaquetar todos los modelos y texturas dentro de la APK para que el atlas básico funcione sin conexión.

## Estado

- **Hecho en la fase móvil:** paleta de materiales diferenciada por piel, huesos, músculos, órganos, vasos y nervios; cámara más cercana; rotación horizontal continua; gestos táctiles de giro y zoom; bloqueo vertical; nuevo icono y diseño de interfaz.
- **Pendiente:** importar y validar los recursos de órganos de HRA/Voxel-Man y el modelo detallado Z-Anatomy; añadir texturas realistas y validar cada integración en dispositivo Android.
- **No se afirma cobertura anatómica completa:** cada nueva malla debe tener fuente, licencia, atribución, escala y prueba de selección antes de marcarse como disponible.
