extends RefCounted
class_name AnatomyCatalog

const SOURCE_CATALOG := "res://data/open_anatomy_3d_catalog.json"
const LOCAL_CATALOG := "res://data/anatomy_catalog_es.json"
const DETAILS_FILE := "res://data/anatomy_entries.json"
const SYSTEMS_FILE := "res://data/anatomy_systems.json"

const SYSTEM_LABELS := {
	"all": "Todos los sistemas",
	"integumentary": "Sistema tegumentario",
	"skeletal": "Sistema esquelético",
	"muscular": "Sistema muscular",
	"nervous": "Sistema nervioso",
	"endocrine": "Sistema endocrino",
	"cardiovascular": "Sistema cardiovascular",
	"lymphatic_immune": "Sistema linfático e inmunitario",
	"respiratory": "Sistema respiratorio",
	"digestive": "Sistema digestivo",
	"urinary": "Sistema urinario",
	"reproductive": "Sistema reproductor",
	"sensory": "Órganos de los sentidos",
	"hematologic": "Sistema sanguíneo y hematopoyético"
}

var entries: Array[Dictionary] = []
var by_key: Dictionary = {}
var details: Dictionary = {}
var systems: Array[Dictionary] = []
var load_errors: Array[String] = []

func load_all() -> bool:
	entries.clear()
	by_key.clear()
	details.clear()
	systems.clear()
	load_errors.clear()

	var local_data: Variant = _read_json(LOCAL_CATALOG)
	if not local_data is Array:
		load_errors.append("No se pudo leer el catálogo anatómico local.")
		return false

	for value in local_data:
		if not value is Dictionary:
			continue
		var item: Dictionary = value
		var key := str(item.get("key", ""))
		if key.is_empty() or by_key.has(key):
			load_errors.append("Clave anatómica vacía o repetida: " + key)
			continue
		entries.append(item)
		by_key[key] = item

	var systems_data: Variant = _read_json(SYSTEMS_FILE)
	if systems_data is Array:
		for system_value in systems_data:
			if system_value is Dictionary:
				systems.append(system_value)
	else:
		load_errors.append("No se pudo leer el índice local de sistemas.")

	var detail_data: Variant = _read_json(DETAILS_FILE)
	if detail_data is Dictionary:
		details = detail_data
	else:
		load_errors.append("El archivo de fichas ampliadas no está disponible.")

	return not entries.is_empty()

func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		return null
	var parsed: Variant = JSON.parse_string(text)
	return parsed

func has_key(key: String) -> bool:
	return by_key.has(key)

func get_entry(key: String) -> Dictionary:
	return by_key.get(key, {})

func get_detail(key: String) -> Dictionary:
	return details.get(key, {})

func get_name(item: Dictionary) -> String:
	var names: Dictionary = item.get("names", {})
	return str(names.get("es", item.get("label", item.get("key", "Estructura"))))

func get_system_label(system_id: String) -> String:
	return SYSTEM_LABELS.get(system_id, system_id.capitalize())

func filter_entries(mode: String, system_id: String, query: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var needle := query.strip_edges().to_lower()
	for item in entries:
		var system := str(item.get("atlas_system_id", item.get("system", "")))
		var secondary_systems: Array = item.get("secondary_system_ids", [])
		if system_id != "all" and system != system_id and not secondary_systems.has(system_id):
			continue
		var sex_scope := str(item.get("sex", "both"))
		if sex_scope != "both" and sex_scope != mode:
			continue
		if not needle.is_empty():
			var names: Dictionary = item.get("names", {})
			var haystack := " ".join(PackedStringArray([
				str(item.get("key", "")),
				str(item.get("label", "")),
				str(names.get("es", "")),
				str(names.get("la", ""))
			])).to_lower()
			if not haystack.contains(needle):
				continue
		result.append(item)
	return result
