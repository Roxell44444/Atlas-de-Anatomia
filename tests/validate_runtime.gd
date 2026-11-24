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
		var names: Dictionary = {}
		var mesh_nodes := model.find_children("*", "MeshInstance3D", true, false)
		var matched := 0
		for node in mesh_nodes:
			var key := str(node.name).to_lower()
			names[key] = true
			if catalog.has_key(key):
				matched += 1
		if matched < 100:
			push_error("FALLO: muy pocas estructuras catalogadas en " + str(scenario["mode"]) + ": " + str(matched))
			model.free()
			quit(1)
			return
		for required_key in scenario["required"]:
			if not names.has(required_key):
				push_error("FALLO: falta " + str(required_key) + " en el modelo " + str(scenario["mode"]))
				model.free()
				quit(1)
				return
		print("OK modelo ", scenario["mode"], ": ", matched, " mallas coinciden con el catálogo.")
		model.free()

	print("VALIDACIÓN DE MODELOS CORRECTA: masculino, femenino y catálogo local.")
	quit(0)
