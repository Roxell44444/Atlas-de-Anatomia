extends SceneTree

const PACK_URL := "https://raw.githubusercontent.com/Roxell44444/Atlas-de-Anatomia/atlas-model-assets/packs/hubmap_hra_female.zip"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var request := HTTPRequest.new()
	request.timeout = 600.0
	request.download_file = "user://atlas-pack-validation.zip"
	root.add_child(request)
	var request_error := request.request(PACK_URL)
	if request_error != OK:
		push_error("FALLO: no se pudo iniciar la descarga de prueba del paquete.")
		quit(1)
		return
	var response: Array = await request.request_completed
	var result_code := int(response[0])
	var response_code := int(response[1])
	if result_code != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		push_error("FALLO: descarga del paquete devolvió HTTP " + str(response_code))
		quit(1)
		return

	var reader := ZIPReader.new()
	if reader.open("user://atlas-pack-validation.zip") != OK:
		push_error("FALLO: el paquete descargado no es un ZIP válido.")
		quit(1)
		return
	var selected_file := ""
	for filename in reader.get_files():
		if str(filename).ends_with(".godot.glb"):
			selected_file = str(filename)
			break
	if selected_file.is_empty():
		reader.close()
		push_error("FALLO: el paquete no contiene modelos GLB preparados.")
		quit(1)
		return
	var model_bytes := reader.read_file(selected_file)
	reader.close()
	var output := FileAccess.open("user://atlas-pack-validation.glb", FileAccess.WRITE)
	if output == null:
		push_error("FALLO: no se pudo guardar el modelo extraído.")
		quit(1)
		return
	output.store_buffer(model_bytes)
	output.close()

	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var import_error := document.append_from_file("user://atlas-pack-validation.glb", state)
	if import_error != OK:
		push_error("FALLO: GLTFDocument no pudo abrir el modelo extraído.")
		quit(1)
		return
	var scene: Node3D = document.generate_scene(state)
	if scene == null:
		push_error("FALLO: no se pudo generar la escena GLTF en tiempo de ejecución.")
		quit(1)
		return
	var mesh_count := scene.find_children("*", "MeshInstance3D", true, false).size()
	scene.free()
	if mesh_count < 1:
		push_error("FALLO: el modelo extraído no contiene mallas renderizables.")
		quit(1)
		return
	print("OK descarga offline: ", selected_file, " — ", mesh_count, " mallas importadas en tiempo de ejecución.")
	quit(0)
