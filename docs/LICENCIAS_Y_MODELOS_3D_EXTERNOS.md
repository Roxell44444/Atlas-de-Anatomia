# Modelos anatómicos externos: integración y licencias

## Fuentes que se incorporan

### 1. Z-Anatomy / BodyParts3D — atlas masculino

- Cobertura declarada en el manifiesto de la distribución: 3.478 estructuras en 13 GLB por sistema.
- Licencia de los recursos masculinos adaptados: CC BY-SA 4.0. Las mallas y los datos derivados deben conservar atribución y la misma licencia.
- Cadena de atribución: BodyParts3D (DBCLS) → Z-Anatomy → mallas adaptadas distribuidas por Anatria3D.
- No se incorpora ni copia el código de Anatria3D. Solo se descarga el conjunto de modelos y su manifiesto de atribución.
- Los modelos se mantienen separados por sistema y por fuente.

### 2. HuBMAP / Human Reference Atlas — atlas femenino de órganos

- El manifiesto consultado enumera 264 estructuras en siete grupos GLB.
- Licencia: CC BY 4.0.
- Cobertura: columna, abdomen, pelvis, mama, órganos y vasos de referencia. **No es un cuerpo femenino completo**; el modelo corporal femenino que ya existe en el proyecto no debe sustituirse por este tronco.
- Los recursos se mantienen separados de los GLB masculinos CC BY-SA 4.0. No se mezclan ni se relicencian como una sola obra.
- Fuente: https://humanatlas.io/3d-reference-library

### 3. VOXEL-MAN / Visible Human Male — SIO

- 232 objetos anatómicos etiquetados, desde cuello hasta muslos superiores.
- Licencia confirmada: CC BY 4.0.
- Descarga original: volumen de cortes TIFF (fotografía criogénica, CT y etiquetas de 16 bits), no una malla GLB lista para Godot.
- Para mostrarlo como mallas hay que extraer superficies de las etiquetas, simplificarlas con cuidado y validar la geometría. No se debe anunciar como integrado visualmente hasta completar ese proceso.
- DOI: https://doi.org/10.5281/zenodo.15882019
- Referencia y descripción técnica: https://www.virtual-body.org/segmented-internal-organs/

## Regla de integración

Los tres atlas no comparten necesariamente origen, escala, orientación, anatomía de referencia ni cobertura. No se superponen en el mismo cuerpo hasta verificar:
1. ejes y unidades;
2. orientación anatómica y coordenadas;
3. escala y posición respecto al modelo base;
4. identidad y nombres de cada nodo;
5. correspondencia entre manifest y geometría;
6. selección táctil y colisiones;
7. rendimiento y memoria en Android.

Mientras no pasen esas comprobaciones, se conservan como recursos separados y se muestra claramente qué atlas/fuente está activo. Los modelos Z-Anatomy (CC BY-SA 4.0) y HRA/VOXEL-MAN (CC BY 4.0) nunca se fusionan en un único archivo derivado.

## Estado

El registro de fuentes y licencias está en `data/third_party_anatomy_sources.json`. El pipeline verifica descargas y hashes de los recursos Z-Anatomy/HRA antes de cualquier importación en Godot. La activación en el visor y la extracción de superficies VOXEL-MAN siguen siendo tareas pendientes y no se consideran completadas.
