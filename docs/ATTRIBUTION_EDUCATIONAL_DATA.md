# Control de licencia de las fichas educativas

## Fuente excluida del paquete distribuible

En una revisión posterior se comprobó que la edición enlazada de **Anatomy & Physiology 2e** de Oregon State University declara licencia **Creative Commons Attribution-ShareAlike 4.0 (CC BY-SA 4.0)** en su información editorial. Esta licencia no coincide con la ruta principal prevista para el atlas, que busca distribuir contenido educativo propio bajo fuentes con permisos comerciales claros y sin obligación ShareAlike.

- Edición y ficha editorial: https://open.oregonstate.education/anatomy2e/
- Aviso de licencia de la edición: Creative Commons Attribution-ShareAlike 4.0 International.
- La licencia de cada obra se revisa por separado; no se debe inferir que todas las adaptaciones de una obra conservan la licencia de la fuente upstream.

## Medida correctiva

- Se retiraron del catálogo distribuible las cinco fichas borrador de corazón, fémur y riñón que se habían redactado usando esa edición.
- El archivo actual `data/anatomy_entries.json` no contiene esas fichas ni contenido derivado de esa edición.
- No se incorporan imágenes, figuras ni tablas de esa obra.
- Las futuras fichas solo se activarán después de identificar la edición exacta, confirmar licencia, autoría, permisos de imágenes por separado y guardar un localizador específico por ficha.

## Política para el nuevo contenido

Se priorizarán recursos CC0, CC BY 4.0 o dominio público con procedencia demostrable. Las fuentes CC BY-SA, CC BY-NC, CC BY-NC-SA, ND u otras licencias incompatibles con el plan de distribución no se incluirán en el paquete principal salvo revisión explícita de compatibilidad legal.

La aplicación no es un dispositivo médico; su contenido es educativo y no sustituye una evaluación profesional.
