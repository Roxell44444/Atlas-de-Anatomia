# ATLAS DE ANATOMÍA

Aplicación Android-first de exploración anatómica 3D, desarrollada con Godot 4.7.2.

## Estado de desarrollo

La entrega fuente más reciente preparada es **0.7.0**. El paquete descargable se entregó en la conversación; todavía no se ha publicado como árbol de archivos ni como release ZIP en este repositorio. Esta README describe el contenido de esa entrega, no afirma que el código esté ya subido a esta rama.

## Cambios 0.7.0

- Dedicatoria en **Información de la aplicación**: “para amorcito de parte de motito que te ama mucho”.
- Icono propio de la aplicación.
- Visor provisional con selector masculino/femenino, órbita, zoom, búsqueda, favoritos, aislamiento y fichas.
- Propagación de `anatomy_id`, colisiones para selección por toque y centrado de cámara usando los límites reales de la malla.
- Política obligatoria de coste cero: adquisición y licencia deben costar 0 USD; el visor solo carga recursos `approved` con SHA-256 coincidente.
- Pipeline de descarga/importación BodyParts3D 4.0 y registro de GLB HRA en estado `pending_review`; ningún importador aprueba modelos automáticamente.
- Candidato femenino HRA/NIH 3D “Body, Female” (3DPX-020992) añadido para inspeccionar su segmentación.

## Fuentes 3D gratuitas candidatas

- **BodyParts3D 4.0:** referencia masculina adulta, 2.234 mallas OBJ según el proveedor, CC BY 4.0 con atribución obligatoria. [Ficha oficial](https://dbarchive.biosciencedbc.jp/data/bodyparts3d/LATEST/README_e.html).
- **Human Reference Atlas / NIH 3D:** conjunto femenino “Body, Female” 3DPX-020992, CC BY 4.0 según la biblioteca HRA. [Ficha NIH 3D](https://3d.nih.gov/entries/20992). La jerarquía debe inspeccionarse antes de prometer selección órgano por órgano.
- **MakeHuman:** recursos gráficos core CC0 para superficie externa solamente; no son anatomía interna.

No se comprarán modelos ni licencias. Los candidatos todavía están pendientes de descarga, revisión visual/anatómica y aprobación; el maniquí geométrico provisional continúa activo. No se ha generado una APK validada ni se ha probado la app en un dispositivo físico.

Consulta los documentos de bibliografía y licencias incluidos en el paquete fuente 0.7.0.
