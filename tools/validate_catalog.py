#!/usr/bin/env python3
"""Valida integridad del catálogo offline y las fichas anatómicas versionadas."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read_json(relative: str):
    return json.loads((ROOT / relative).read_text(encoding="utf-8"))


def main() -> None:
    source = read_json("data/open_anatomy_3d_catalog.json")
    localized = read_json("data/anatomy_catalog_es.json")
    details = read_json("data/anatomy_entries.json")
    manifest = read_json("data/open_anatomy_3d_manifest.json")

    source_keys = [item["key"] for item in source]
    localized_keys = [item["key"] for item in localized]
    assert len(source) == 147, f"El catálogo de origen cambió: {len(source)} entradas"
    assert len(source_keys) == len(set(source_keys)), "Claves repetidas en catálogo fuente"
    assert len(localized_keys) == len(set(localized_keys)), "Claves repetidas en catálogo ES"
    assert set(source_keys) == set(localized_keys), "El catálogo español no corresponde al original"

    for item in localized:
        assert item.get("names", {}).get("es", "").strip(), f"Falta traducción: {item['key']}"
        assert item.get("names", {}).get("en", "").strip(), f"Falta nombre inglés: {item['key']}"
        assert item.get("system_label_es", "").strip(), f"Falta sistema traducido: {item['key']}"
        if item.get("system") == "joints":
            assert item["model_mapping_status"] == "anchor_only_no_independent_mesh"

    for key, detail in details.items():
        if key == "_metadata":
            continue
        assert key == detail.get("id"), f"ID interno incorrecto en {key}"
        assert detail.get("description", "").strip(), f"Falta descripción en {key}"
        assert detail.get("source_url", "").startswith("https://"), f"Falta fuente en {key}"
        assert detail.get("license") == "CC BY 4.0", f"Licencia inesperada en {key}"
        assert detail.get("sections"), f"Ficha sin apartados: {key}"

    assert len(manifest.get("models", [])) == 2, "Deben existir modelos masculino y femenino"
    for model in manifest["models"]:
        assert model["license"] == "CC BY 4.0"
        assert model["download_url"].startswith("https://")
        assert model["upstream_git_blob_sha1"]

    print(
        "VALIDACIÓN CORRECTA: "
        f"{len(source)} claves únicas, 147 nombres ES, "
        f"{len(details) - 1} fichas educativas con fuentes, 2 modelos declarados."
    )


if __name__ == "__main__":
    main()
