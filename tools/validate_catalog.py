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
    assert set(source_keys).issubset(set(localized_keys)), "Faltan claves de la fuente en el catálogo español"
    extras = set(localized_keys) - set(source_keys)
    for item in localized:
        if item["key"] in extras:
            assert item.get("model_mapping_status") == "info_only_no_mesh", f"Extra debe declararse sin malla: {item['key']}"
            assert item.get("content_status") == "planned_needs_research", f"Extra debe declarar contenido pendiente: {item['key']}"
            assert item.get("review_status") == "nomenclature_seed_only", f"Extra debe indicar revisión de nomenclatura pendiente: {item['key']}"

    expected_systems = {
        "integumentary", "skeletal", "muscular", "nervous", "endocrine",
        "cardiovascular", "lymphatic_immune", "respiratory", "digestive",
        "urinary", "reproductive", "sensory", "hematologic"
    }
    for item in localized:
        assert item.get("names", {}).get("es", "").strip(), f"Falta traducción: {item['key']}"
        assert item.get("names", {}).get("en", "").strip(), f"Falta nombre inglés: {item['key']}"
        assert item.get("system_label_es", "").strip(), f"Falta sistema traducido: {item['key']}"
        assert item.get("atlas_system_id") in expected_systems, f"Sistema desconocido: {item['key']}"
        assert set(item.get("secondary_system_ids", [])).issubset(expected_systems), (
            f"Sistema secundario desconocido: {item['key']}"
        )
        if item.get("system") == "joints" and item["key"] in set(source_keys):
            assert item["model_mapping_status"] == "anchor_only_no_independent_mesh"
    assert expected_systems.issubset({item["atlas_system_id"] for item in localized}), "Falta un sistema en el índice"
    mesh_entries = [
        item for item in localized
        if item.get("model_mapping_status") not in {
            "info_only_no_mesh", "anchor_only_no_independent_mesh"
        } and item["key"] in set(source_keys)
    ]
    expected_by_sex = {
        sex: sum(1 for item in mesh_entries
                 if item.get("sex", "both") in {"both", sex})
        for sex in ("male", "female")
    }
    assert expected_by_sex == {"male": 128, "female": 133}, (
        f"Conteo inesperado de mallas seleccionables por modelo: {expected_by_sex}"
    )
    assert len(extras) == 116, f"Número inesperado de entradas informativas: {len(extras)}"

    metadata = details.get("_metadata", {})
    assert metadata.get("commercial_use_clearance_required") is True, (
        "El catálogo de fichas debe exigir revisión de licencia antes de distribución."
    )
    allowed_licenses = {"CC BY 4.0", "CC0 1.0", "Public Domain"}
    for key, detail in details.items():
        if key == "_metadata":
            continue
        assert key == detail.get("id"), f"ID interno incorrecto en {key}"
        assert detail.get("description", "").strip(), f"Falta descripción en {key}"
        assert detail.get("source_url", "").startswith("https://"), f"Falta fuente en {key}"
        assert detail.get("license") in allowed_licenses, f"Licencia no aprobada: {key}"
        assert detail.get("sections"), f"Ficha sin apartados: {key}"
        assert detail.get("review_status") == "approved_for_distribution", (
            f"Ficha pendiente de revisión: {key}"
        )
        assert detail.get("source_license") == "CC BY 4.0", (
            f"Fuente con licencia no aprobada: {key}"
        )
        assert "Douglas College Human Anatomy & Physiology" in detail.get("source_edition", ""), (
            f"Edición de la fuente no verificada: {key}"
        )
        assert "Download for free at https://pressbooks.bccampus.ca/dcbiol" in detail.get("attribution", ""), (
            f"Falta atribución digital obligatoria de la fuente: {key}"
        )
        assert detail.get("content_origin") == "original_spanish_paraphrase", (
            f"Origen del contenido no declarado: {key}"
        )

    assert len(manifest.get("models", [])) == 2, "Deben existir modelos masculino y femenino"
    for model in manifest["models"]:
        assert model["license"] == "CC BY 4.0"
        assert model["download_url"].startswith("https://")
        assert model["upstream_git_blob_sha1"]

    print(
        "VALIDACIÓN CORRECTA: "
        f"{len(source)} mallas/hotspots de origen, {len(localized)} entradas indexadas "
        f"({len(extras)} informativas sin malla), 13 sistemas, "
        f"{len(details) - 1} fichas educativas con fuentes, 2 modelos declarados."
    )


if __name__ == "__main__":
    main()
