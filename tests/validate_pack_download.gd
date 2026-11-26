extends SceneTree

const PACKS := [
	{
		"id": "z_anatomy_male",
		"url": "https://raw.githubusercontent.com/Roxell44444/Atlas-de-Anatomia/atlas-model-assets/packs/z_anatomy_male.zip"
	},
	{
		"id": "hubmap_hra_female",
		"url": "https://raw.githubusercontent.com/Roxell44444/Atlas-de-Anatomia/atlas-model-assets/packs/hubmap_hra_female.zip"
	}
]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for pack in PACKS:
		var pack_id := str(pack["id"])
		var request := HTTPRequest.new()
		request.timeout = 600.0
		request.download_file = "user://atlas-pack-validation-" + pack_id + ".zip"
		root.add_child(request)
		var request_error := request.request(str(pack["url"]))
		if request_error != OK:
			push_error("FALLO: no se pudo iniciar la descarga de " + pack_id)
			quit(1)
			return
		var response: Array = await request.request_completed
		var result_code := int(response[0])
		var response_code := int(response[1])
		if result_code != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
			push_error("FALLO: descarga de " + pack_id + " devolvió HTTP " + str(response_code))
			quit(1)
			return

		var reader := ZIPReader.new()
		var zip_path := "user://atlas-pack-validation-" + pack_id + ".zip"
		if reader.open(zip_path) != OK:
			push_error("FALLO: el paquete " + pack_id + " no es un ZIP válido.")
			quit(1)
			return
		var selected_file := ""
		for filename in reader.get_files():
			if str(filename).ends_with(".godot.glb"):
				selected_file = str(filename)
				break
		if selected_file.is_empty():
			reader.close()
			push_error("FALLO: el paquete " + pack_id + " no contiene GLB preparados.")
			quit(1)
			return
		var model_bytes := reader.read_file(selected_file)
		reader.close()
		var output_path := "user://atlas-pack-validation-" + pack_id + ".glb"
		var output := FileAccess.open(output_path, FileAccess.WRITE)
		if output == null:
			push_error("FALLO: no se pudo extraer el modelo " + pack_id)
			quit(1)
			return
		output.store_buffer(model_bytes)
		output.close()

		var document := GLTFDocument.new()
		var state := GLTFState.new()
		var import_error := document.append_from_file(output_path, state)
		if import_error != OK:
			push_error("FALLO: GLTFDocument no pudo abrir el modelo " + pack_id)
			quit(1)
			return
		var scene: Node3D = document.generate_scene(state)
		if scene == null:
			push_error("FALLO: no se pudo reconstruir la escena " + pack_id)
			quit(1)
			return
		var mesh_count := scene.find_children("*", "MeshInstance3D", true, false).size()
		scene.free()
		if mesh_count < 1:
			push_error("FALLO: el modelo " + pack_id + " no contiene mallas renderizables.")
			quit(1)
			return
		print("OK descarga offline ", pack_id, ": ", selected_file, " — ", mesh_count, " mallas importadas.")

	print("VALIDACIÓN CORRECTA: ambos paquetes se descargan, extraen y reconstruyen sin conexión posterior.")
	quit(0)
