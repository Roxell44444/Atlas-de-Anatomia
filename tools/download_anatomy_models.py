#!/usr/bin/env python3
"""Descarga, verifica y convierte los modelos licenciados para su empaquetado offline."""

from __future__ import annotations

import hashlib
import json
import struct
import subprocess
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "data" / "open_anatomy_3d_manifest.json"
DESTINATION = ROOT / "assets" / "anatomy" / "open_anatomy_3d"
WORK = ROOT / "build" / "model_sources"


def git_blob_sha1(data: bytes) -> str:
    header = f"blob {len(data)}\0".encode("ascii")
    return hashlib.sha1(header + data).hexdigest()


def validate_glb(path: Path) -> None:
    data = path.read_bytes()
    if len(data) < 20:
        raise RuntimeError(f"GLB demasiado pequeño: {path}")
    magic, version, declared_length = struct.unpack_from("<4sII", data, 0)
    if magic != b"glTF" or version != 2 or declared_length != len(data):
        raise RuntimeError(f"Cabecera GLB inválida: {path}")

    offset = 12
    json_chunk = None
    while offset + 8 <= len(data):
        chunk_length, chunk_type = struct.unpack_from("<I4s", data, offset)
        offset += 8
        chunk = data[offset : offset + chunk_length]
        if len(chunk) != chunk_length:
            raise RuntimeError(f"Chunk GLB truncado: {path}")
        if chunk_type == b"JSON":
            json_chunk = chunk
        offset += chunk_length

    if json_chunk is None:
        raise RuntimeError(f"El GLB no contiene chunk JSON: {path}")
    metadata = json.loads(json_chunk.decode("utf-8").rstrip("\x00 \t\r\n"))
    used = metadata.get("extensionsUsed", [])
    required = metadata.get("extensionsRequired", [])
    if "EXT_meshopt_compression" in used or "EXT_meshopt_compression" in required:
        raise RuntimeError(f"El GLB final todavía necesita meshopt: {path}")


def main() -> int:
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    WORK.mkdir(parents=True, exist_ok=True)
    DESTINATION.mkdir(parents=True, exist_ok=True)

    for model in manifest["models"]:
        mode = model["mode"]
        source = WORK / f"anatomy-{mode}-source.glb"
        target = ROOT / model["intended_local_path"]
        target.parent.mkdir(parents=True, exist_ok=True)

        request = urllib.request.Request(
            model["download_url"],
            headers={"User-Agent": "ATLAS-DE-ANATOMIA-model-fetch/1.0"},
        )
        print(f"Descargando modelo {mode}: {model['download_url']}")
        with urllib.request.urlopen(request, timeout=180) as response:
            data = response.read()

        if len(data) != int(model["size_bytes"]):
            raise RuntimeError(
                f"Tamaño inesperado para {mode}: {len(data)} bytes; "
                f"esperados {model['size_bytes']}"
            )

        actual_sha = git_blob_sha1(data)
        expected_sha = model["upstream_git_blob_sha1"]
        if actual_sha.lower() != expected_sha.lower():
            raise RuntimeError(
                f"Hash Git blob incorrecto para {mode}: {actual_sha}; "
                f"esperado {expected_sha}"
            )

        source.write_bytes(data)
        subprocess.run(
            ["node", str(ROOT / "tools" / "decode_glb.mjs"), str(source), str(target)],
            cwd=ROOT,
            check=True,
        )
        validate_glb(target)
        print(f"OK {mode}: fuente verificada; salida {target.stat().st_size:,} bytes")

    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:  # CI should report a concise actionable error.
        print(f"ERROR preparando modelos anatómicos: {exc}", file=sys.stderr)
        raise
