extends SceneTree

const CatalogScript = preload("res://scripts/anatomy_catalog.gd")

func _initialize() -> void:
	call_deferred("_run_validation")

func _run_validation() -> void:
	var catalog = CatalogScript.new()
	if not catalog.load_all():
		push_error("FALLO: el catálogo local no se pudo cargar.")
		quit(1)
		return

	var scenarios := [
		{
			"mode": "male",
			"path": "res://assets/anatomy/open_anatomy_3d/anatomy-male.glb",
			"required": ["heart", "brain", "femur_l", "kidney_l", "prostate", "reproductive"]
		},
		{
			"mode": "female",
			"path": "res://assets/anatomy/open_anatomy_3d/anatomy-female.glb",
			"required": ["heart", "brain", "femur_l", "kidney_l", "uterus", "ovary_l", "vagina"]
		}
	]

	for scenario in scenarios:
		var packed := ResourceLoader.load(str(scenario["path"])) as PackedScene
		if packed == null:
			push_error("FALLO: no se pudo cargar el GLB " + str(scenario["mode"]))
			quit(1)
			return
		var model := packed.instantiate()
		var node_by_name: Dictionary = {}
		var stack: Array[Node] = [model]
		while not stack.is_empty():
			var current: Node = stack.pop_back()
			node_by_name[str(current.name).to_lower()] = current
			for child in current.get_children():
				stack.append(child)

		var expected_keys: Array[String] = []
		for entry in catalog.entries:
			var mapping_status := str(entry.get("model_mapping_status", ""))
			if mapping_status == "info_only_no_mesh" or mapping_status == "anchor_only_no_independent_mesh":
				continue
			var sex_scope := str(entry.get("sex", "both"))
			if sex_scope != "both" and sex_scope != str(scenario["mode"]):
				continue
			var key := str(entry.get("key", ""))
			expected_keys.append(key)
			if not node_by_name.has(key):
				push_error("FALLO: no existe un nodo con clave anatómica " + key + " en el modelo " + str(scenario["mode"]))
				model.free()
				quit(1)
				return
			var structure_node := node_by_name[key] as Node
			var structure_meshes := structure_node.find_children("*", "MeshInstance3D", true, false)
			if structure_node is MeshInstance3D:
				structure_meshes.append(structure_node)
			if structure_meshes.is_empty():
				push_error("FALLO: el nodo " + key + " no contiene malla 3D en el modelo " + str(scenario["mode"]))
				model.free()
				quit(1)
				return

		var expected_count := 128 if str(scenario["mode"]) == "male" else 133
		if expected_keys.size() != expected_count:
			push_error("FALLO: catálogo espera " + str(expected_count) + " mallas en " + str(scenario["mode"]) + ", pero indexa " + str(expected_keys.size()))
			model.free()
			quit(1)
			return
		for required_key in scenario["required"]:
			if not node_by_name.has(str(required_key)):
				push_error("FALLO: falta " + str(required_key) + " en el modelo " + str(scenario["mode"]))
				model.free()
				quit(1)
				return
		print("OK modelo ", scenario["mode"], ": ", expected_keys.size(), " estructuras seleccionables con malla en jerarquía.")
		model.free()

	print("VALIDACIÓN DE MODELOS CORRECTA: masculino, femenino y catálogo local.")
	quit(0)
