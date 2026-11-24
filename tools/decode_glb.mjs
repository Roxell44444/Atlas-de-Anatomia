import { NodeIO } from '@gltf-transform/core';
import { EXTMeshoptCompression, KHRONOS_EXTENSIONS } from '@gltf-transform/extensions';
import { dequantize } from '@gltf-transform/functions';
import { MeshoptDecoder } from 'meshoptimizer';

const [inputPath, outputPath] = process.argv.slice(2);
if (!inputPath || !outputPath) {
  throw new Error('Uso: node tools/decode_glb.mjs entrada.glb salida.glb');
}

await MeshoptDecoder.ready;
const io = new NodeIO()
  .registerExtensions([...KHRONOS_EXTENSIONS, EXTMeshoptCompression])
  .registerDependencies({ 'meshopt.decoder': MeshoptDecoder });

const document = await io.read(inputPath);
for (const extension of document.getRoot().listExtensionsUsed()) {
  if (extension.extensionName === 'EXT_meshopt_compression') {
    extension.dispose();
  }
}
await document.transform(dequantize());

const remaining = document.getRoot().listExtensionsUsed()
  .map((extension) => extension.extensionName);
if (remaining.includes('EXT_meshopt_compression')) {
  throw new Error('El archivo de salida todavía declara EXT_meshopt_compression.');
}

await io.write(outputPath, document);
console.log(`GLB preparado para importación: ${outputPath}`);
