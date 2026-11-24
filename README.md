# ATLAS DE ANATOMÍA

Aplicación Android-first de exploración anatómica 3D, desarrollada con Godot.

## Estado del repositorio

Esta rama contiene el README y el estado de desarrollo. El código fuente completo de la versión 0.5.0 está preparado en un paquete local de esta sesión; todavía no se ha publicado como archivos de código ni como release binaria en este repositorio.

## Base de desarrollo 0.5.0

- Visor 3D provisional con selector masculino/femenino, órbita, zoom, selección y aislamiento.
- Catálogo de 61 fichas iniciales en 13 sistemas anatómicos.
- Búsqueda, favoritos y navegación secuencial.
- Biblioteca bibliográfica con 16 fuentes y obras de consulta, lecturas para los 13 sistemas y referencias de histología, embriología y anatomía topográfica.
- Fuentes específicas registradas para húmero y escápula; ambas fichas continúan pendientes de revisión especializada.
- Estantería de obras comerciales actuales solo como referencia bibliográfica; no se copian capítulos ni ilustraciones.
- Backend del Tutor IA que separa fuentes específicas de lecturas generales y conserva la clave Gemini en el Worker.
- Validadores de catálogo, licencias, modelos y una prueba simulada de recuperación del Tutor.

## Límites conocidos

No se han incorporado todavía mallas anatómicas GLB reales. El maniquí visible es geométrico y provisional. El inventario no es exhaustivo, la mayoría de las fichas no tienen fuentes individuales, el contenido está pendiente de revisión especializada y no se ha generado una APK validada.

Las fuentes candidatas de modelos y sus condiciones se documentan en el paquete de desarrollo. No se distribuirá ningún activo 3D, texto o figura sin comprobar su licencia concreta, procedencia y atribución.

Consulta `docs/BIBLIOGRAFIA_Y_POLITICA_DE_FUENTES.md`, `data/reference_library.json` y `docs/REGISTRO_LICENCIAS.csv` en el paquete fuente 0.5.0 para conocer el alcance de las fuentes y sus límites de reutilización.
