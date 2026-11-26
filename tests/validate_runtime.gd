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

	# Validate all external atlas index entries against their imported source meshes.
	var external_scenarios := [
		{"id": "z_anatomy_male", "catalog_path": "res://data/external_atlas_catalog_male_zanatomy.json", "expected": 3478},
		{"id": "hubmap_hra_female", "catalog_path": "res://data/external_atlas_catalog_female_hra.json", "expected": 264}
	]
	for external_scenario in external_scenarios:
		var external_data: Variant = JSON.parse_string(FileAccess.get_file_as_string(str(external_scenario["catalog_path"])))
		if not external_data is Dictionary:
			push_error("FALLO: índice externo ilegible: " + str(external_scenario["id"]))
			quit(1)
			return
		var external_structures: Array = external_data.get("structures", [])
		if external_structures.size() != int(external_scenario["expected"]):
			push_error("FALLO: recuento de estructuras inesperado en " + str(external_scenario["id"]))
			quit(1)
			return
		var by_file: Dictionary = {}
		for external_entry in external_structures:
			var filename := str(external_entry.get("mesh_file", ""))
			if not by_file.has(filename):
				by_file[filename] = []
			by_file[filename].append(external_entry)
		var checked := 0
		for filename in by_file:
			var model_path := "res://assets/external_atlases/" + str(external_scenario["id"]) + "/" + str(filename).replace(".glb", ".godot.glb")
			var external_packed := ResourceLoader.load(model_path) as PackedScene
			if external_packed == null:
				push_error("FALLO: no se pudo cargar el GLB " + model_path)
				quit(1)
				return
			var external_model := external_packed.instantiate()
			var external_nodes: Dictionary = {}
			var external_stack: Array[Node] = [external_model]
			while not external_stack.is_empty():
				var external_node: Node = external_stack.pop_back()
				external_nodes[str(external_node.name).to_lower().replace(" ", "").replace(".", "").replace("_", "").replace("-", "")] = external_node
				for external_child in external_node.get_children():
					external_stack.append(external_child)
			for external_entry in by_file[filename]:
				var node_name := str(external_entry.get("node_name", "")).to_lower().replace(" ", "").replace(".", "").replace("_", "").replace("-", "")
				if not external_nodes.has(node_name):
					push_error("FALLO: nodo anatómico ausente: " + node_name + " en " + filename)
					external_model.free()
					quit(1)
					return
				var anatomy_node: Node = external_nodes[node_name]
				var render_meshes := anatomy_node.find_children("*", "MeshInstance3D", true, false)
				if anatomy_node is MeshInstance3D:
					render_meshes.append(anatomy_node)
				if render_meshes.is_empty():
					push_error("FALLO: nodo sin geometría: " + node_name)
					external_model.free()
					quit(1)
					return
				checked += 1
			external_model.free()
		print("OK atlas ", external_scenario["id"], ": ", checked, " nodos anatómicos con malla.")

	print("VALIDACIÓN DE MODELOS CORRECTA: modelos base, Z-Anatomy y HuBMAP.")
	quit(0)
