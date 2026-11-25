import { NodeIO } from '@gltf-transform/core';
import { EXTMeshoptCompression, KHRONOS_EXTENSIONS } from '@gltf-transform/extensions';
import { dequantize } from '@gltf-transform/functions';
import { MeshoptDecoder } from 'meshoptimizer';
import draco3d from 'draco3dgltf';

const [inputPath, outputPath] = process.argv.slice(2);
if (!inputPath || !outputPath) {
  throw new Error('Uso: node tools/decode_glb.mjs entrada.glb salida.glb');
}

await MeshoptDecoder.ready;
const dracoDecoder = await draco3d.createDecoderModule();
const io = new NodeIO()
  .registerExtensions([...KHRONOS_EXTENSIONS, EXTMeshoptCompression])
  .registerDependencies({ 'meshopt.decoder': MeshoptDecoder, 'draco3d.decoder': dracoDecoder });

const document = await io.read(inputPath);
for (const extension of document.getRoot().listExtensionsUsed()) {
  if (extension.extensionName === 'EXT_meshopt_compression') {
    extension.dispose();
  }
}
await document.transform(dequantize());

const remaining = document.getRoot().listExtensionsUsed()
  .map((extension) => extension.extensionName);
if (remaining.includes('EXT_meshopt_compression') || remaining.includes('KHR_draco_mesh_compression')) {
  throw new Error('El archivo de salida todavía declara una extensión de geometría comprimida.');
}

await io.write(outputPath, document);
console.log(`GLB preparado para importación: ${outputPath}`);
