#!/usr/bin/env python3
"""Descarga y verifica atlases externos sin mezclarlos ni importarlos aún en el visor."""

from __future__ import annotations
import hashlib
import json
import struct
import subprocess
import sys
import tempfile
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REGISTRY = ROOT / "data" / "third_party_anatomy_sources.json"
DEST = Path(tempfile.gettempdir()) / "atlas-third-party-atlases"
BASE = "https://raw.githubusercontent.com/Nurkan1/Anatria-3D/main/public/anatomy/"

def fetch(url: str) -> bytes:
    request = urllib.request.Request(url, headers={"User-Agent": "Atlas-de-Anatomia/1.0"})
    with urllib.request.urlopen(request, timeout=240) as response:
        return response.read()

def git_blob_sha1(data: bytes) -> str:
    return hashlib.sha1(f"blob {len(data)}\0".encode("ascii") + data).hexdigest()

def write_verified(url: str, path: Path, expected_sha: str | None = None) -> bytes:
    data = fetch(url)
    if expected_sha and git_blob_sha1(data).lower() != expected_sha.lower():
        raise RuntimeError(f"Hash Git blob incorrecto: {url}")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)
    return data

def validate_glb(data: bytes, name: str) -> None:
    if len(data) < 20:
        raise RuntimeError(f"GLB demasiado pequeño: {name}")
    magic, version, declared = struct.unpack_from("<4sII", data, 0)
    if magic != b"glTF" or version != 2 or declared != len(data):
        raise RuntimeError(f"Cabecera GLB no válida: {name}")
    offset, has_json = 12, False
    while offset + 8 <= len(data):
        length, kind = struct.unpack_from("<I4s", data, offset)
        offset += 8
        chunk = data[offset:offset + length]
        if len(chunk) != length:
            raise RuntimeError(f"Chunk truncado: {name}")
        if kind == b"JSON":
            doc = json.loads(chunk.decode("utf-8").rstrip("\x00 \t\r\n"))
            used = set(doc.get("extensionsUsed", []))
            if "KHR_draco_mesh_compression" in used:
                print(f"AVISO {name}: requiere descompresión Draco antes de importarse en Godot.")
            has_json = True
        offset += length
    if not has_json:
        raise RuntimeError(f"Falta el chunk JSON: {name}")

def main() -> None:
    registry = json.loads(REGISTRY.read_text(encoding="utf-8"))
    DEST.mkdir(parents=True, exist_ok=True)
    summary = []
    for source in registry["sources"]:
        if source["id"] == "voxel_man_sio":
            # La fuente es un volumen de 395 MB, no se descarga en cada build Android.
            summary.append({"id": source["id"], "status": source["status"], "downloaded": False})
            continue
        source_dir = DEST / source["id"]
        manifest_name = "manifest.json" if source["id"] == "z_anatomy_male" else "manifest_female.json"
        manifest_url = source["manifest_url"]
        expected_manifest_sha = (
            "cacf7394f5e33e8543b1c8509adad2840ec71e0e"
            if source["id"] == "z_anatomy_male"
            else source["manifest_git_blob_sha1"]
        )
        manifest_data = write_verified(manifest_url, source_dir / manifest_name, expected_manifest_sha)
        manifest = json.loads(manifest_data.decode("utf-8"))
        actual_count = len(manifest.get("organs", []))
        expected_count = int(source["structures"])
        if actual_count != expected_count:
            raise RuntimeError(f"{source['id']}: manifiesto declara {actual_count}, registro esperaba {expected_count}")
        for filename, expected_size, expected_sha in source["models"]:
            url = BASE + filename
            data = write_verified(url, source_dir / filename, expected_sha)
            if len(data) != int(expected_size):
                raise RuntimeError(f"Tamaño inesperado para {filename}: {len(data)}")
            validate_glb(data, filename)
            decoded_path = source_dir / (filename.replace(".glb", ".godot.glb"))
            subprocess.run(
                ["node", str(ROOT / "tools" / "decode_glb.mjs"), str(source_dir / filename), str(decoded_path)],
                cwd=ROOT,
                check=True,
            )
            validate_glb(decoded_path.read_bytes(), decoded_path.name)
            # Stage only the converted GLB in the Godot project; keep source and temp files outside.
            runtime_dir = ROOT / "assets" / "external_atlases" / source["id"]
            runtime_dir.mkdir(parents=True, exist_ok=True)
            (runtime_dir / decoded_path.name).write_bytes(decoded_path.read_bytes())
        # Keep the upstream license notices next to the staged runtime assets.
        for name, url in (("NOTICE", source["license_notice_url"]), ("LICENSE", source["license_file_url"])):
            notice_data = write_verified(url, source_dir / name)
            runtime_dir = ROOT / "assets" / "external_atlases" / source["id"]
            runtime_dir.mkdir(parents=True, exist_ok=True)
            (runtime_dir / name).write_bytes(notice_data)
        summary.append({
            "id": source["id"],
            "license": source["license"],
            "structures": actual_count,
            "models_verified": len(source["models"]),
            "bytes": sum(int(model[1]) for model in source["models"]),
            "status": "downloaded_and_hash_verified_but_not_yet_enabled_in_viewer"
        })
    (DEST / "verification-summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print(json.dumps(summary, indent=2))

if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"ERROR verificando atlas anatómicos externos: {exc}", file=sys.stderr)
        raise
