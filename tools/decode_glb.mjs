import { NodeIO } from '@gltf-transform/core';
import { EXTMeshoptCompression, KHRONOS_EXTENSIONS } from '@gltf-transform/extensions';
import { dequantize, dedup, prune, simplify, weld } from '@gltf-transform/functions';
import { MeshoptDecoder, MeshoptSimplifier } from 'meshoptimizer';
import draco3d from 'draco3dgltf';

const [inputPath, outputPath, simplifyRatioText] = process.argv.slice(2);
const simplifyRatio = Number(simplifyRatioText || 0);
if (!inputPath || !outputPath) {
  throw new Error('Uso: node tools/decode_glb.mjs entrada.glb salida.glb');
}

await MeshoptDecoder.ready;
await MeshoptSimplifier.ready;
const dracoDecoder = await draco3d.createDecoderModule();
const io = new NodeIO()
  .registerExtensions([...KHRONOS_EXTENSIONS, EXTMeshoptCompression])
  .registerDependencies({ 'meshopt.decoder': MeshoptDecoder, 'draco3d.decoder': dracoDecoder });

const document = await io.read(inputPath);
for (const extension of document.getRoot().listExtensionsUsed()) {
  if (extension.extensionName === 'EXT_meshopt_compression' || extension.extensionName === 'KHR_draco_mesh_compression') {
    extension.dispose();
  }
}
await document.transform(dequantize());
if (simplifyRatio > 0) {
  await document.transform(
    weld(),
    simplify({ simplifier: MeshoptSimplifier, ratio: simplifyRatio, error: 0.0001 }),
    prune(),
    dedup(),
  );
}

const remaining = document.getRoot().listExtensionsUsed()
  .map((extension) => extension.extensionName);
if (remaining.includes('EXT_meshopt_compression') || remaining.includes('KHR_draco_mesh_compression')) {
  throw new Error('El archivo de salida todavía declara una extensión de geometría comprimida.');
}

await io.write(outputPath, document);
console.log(`GLB preparado para importación: ${outputPath}`);
