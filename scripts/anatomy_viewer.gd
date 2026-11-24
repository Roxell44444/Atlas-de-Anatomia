extends Node3D
class_name AnatomyViewer

signal structure_selected(key: String)
signal model_status_changed(message: String, ready: bool)

const MODEL_PATHS := {
	"male": "res://assets/anatomy/open_anatomy_3d/anatomy-male.glb",
	"female": "res://assets/anatomy/open_anatomy_3d/anatomy-female.glb"
}
const SYSTEM_IDS := ["skin", "skeleton", "muscles", "organs", "vessels", "nerves"]

var pivot: Node3D
var camera: Camera3D
var current_model: Node3D
var meshes_by_key: Dictionary = {} # clave anatómica -> Array[MeshInstance3D]
var system_nodes: Dictionary = {}
var mesh_systems: Dictionary = {}
var selected_key := ""
var selected_meshes: Array[MeshInstance3D] = []
var previous_overlays: Array[Material] = []
var highlight_material: StandardMaterial3D
var yaw := 0.0
var pitch := 0.0
var distance := 3.8
var right_dragging := false
var screen_dragging := false
var catalog_keys: Dictionary = {}
var source_system_by_key: Dictionary = {}

func _ready() -> void:
	_load_catalog_key_index()
	_build_world()
	highlight_material = StandardMaterial3D.new()
	highlight_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	highlight_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	highlight_material.albedo_color = Color(1.0, 0.34, 0.08, 0.42)
	highlight_material.emission_enabled = true
	highlight_material.emission = Color(0.8, 0.13, 0.02)

func _build_world() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#101a2a")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#aabbd0")
	environment.ambient_light_energy = 0.65
	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)

	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-32.0, -28.0, 0.0)
	key_light.light_energy = 1.8
	add_child(key_light)

	var fill_light := DirectionalLight3D.new()
	fill_light.rotation_degrees = Vector3(-18.0, 145.0, 0.0)
	fill_light.light_energy = 0.65
	add_child(fill_light)

	pivot = Node3D.new()
	pivot.position = Vector3(0.0, 0.9, 0.0)
	add_child(pivot)

	camera = Camera3D.new()
	camera.position = Vector3(0.0, 0.0, distance)
	camera.current = true
	camera.fov = 42.0
	pivot.add_child(camera)
	camera.look_at(Vector3.ZERO, Vector3.UP)

func load_body(mode: String) -> bool:
	_clear_model()
	var path: String = MODEL_PATHS.get(mode, MODEL_PATHS["male"])
	if not ResourceLoader.exists(path):
		model_status_changed.emit(
			"Modelo " + _mode_label(mode) + " aún no descargado. La vista 3D se activará al preparar los recursos licenciados.",
			false
		)
		return false

	var packed := load(path) as PackedScene
	if packed == null:
		model_status_changed.emit("No se pudo importar el modelo 3D: " + path, false)
		return false

	var instance := packed.instantiate()
	if instance is Node3D:
		current_model = instance as Node3D
	else:
		current_model = Node3D.new()
		current_model.add_child(instance)
	current_model.position = Vector3(0.0, -0.9, 0.0)
	pivot.add_child(current_model)

	_index_model()
	model_status_changed.emit(
		"Modelo " + _mode_label(mode) + " cargado. Estructuras con malla: " + str(meshes_by_key.size()),
		true
	)
	return true

func _mode_label(mode: String) -> String:
	return "femenino" if mode == "female" else "masculino"

func _clear_model() -> void:
	_clear_selection()
	if is_instance_valid(current_model):
		current_model.queue_free()
	current_model = null
	meshes_by_key.clear()
	system_nodes.clear()
	mesh_systems.clear()

func _index_model() -> void:
	if current_model == null:
		return
	for system_id in SYSTEM_IDS:
		var system_node := current_model.find_child(system_id, true, false)
		if system_node != null:
			system_nodes[system_id] = system_node

	var mesh_nodes := current_model.find_children("*", "MeshInstance3D", true, false)
	for node in mesh_nodes:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		# In GLTF a semantic anatomy name can belong to a Node3D parent,
		# while its renderable geometry is stored in one or more child meshes.
		var key := _find_catalog_key(mesh_instance)
		if key.is_empty():
			continue
		var related_meshes: Array = meshes_by_key.get(key, [])
		related_meshes.append(mesh_instance)
		meshes_by_key[key] = related_meshes

		var assigned_system := ""
		for system_id in SYSTEM_IDS:
			if system_nodes.has(system_id) and system_nodes[system_id].is_ancestor_of(mesh_instance):
				assigned_system = system_id
				break
		if assigned_system.is_empty():
			assigned_system = str(source_system_by_key.get(key, ""))
		if not assigned_system.is_empty():
			mesh_systems[key] = assigned_system

		mesh_instance.create_trimesh_collision()
		for child in mesh_instance.get_children():
			if child is StaticBody3D:
				child.set_meta("anatomy_key", key)
				child.collision_layer = 1
				child.collision_mask = 0

func _find_catalog_key(node: Node) -> String:
	var cursor: Node = node
	while cursor != null:
		var candidate := str(cursor.name).to_lower()
		if _is_catalog_structure(candidate):
			return candidate
		if cursor == current_model:
			break
		cursor = cursor.get_parent()
	return ""

func _load_catalog_key_index() -> void:
	var file := FileAccess.open("res://data/anatomy_catalog_es.json", FileAccess.READ)
	if file == null:
		push_error("No se pudo abrir el índice local de estructuras.")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Array:
		push_error("El índice local de estructuras no tiene formato de lista.")
		return
	for item in parsed:
		if item is Dictionary:
			var key := str(item.get("key", ""))
			catalog_keys[key] = true
			var model_mapping := str(item.get("model_mapping_status", ""))
			if model_mapping != "info_only_no_mesh" and model_mapping != "anchor_only_no_independent_mesh":
				source_system_by_key[key] = str(item.get("system", ""))

func _is_catalog_structure(key: String) -> bool:
	return catalog_keys.has(key)

func has_mesh(key: String) -> bool:
	return meshes_by_key.has(key) and not (meshes_by_key[key] as Array).is_empty()

func select_structure(key: String) -> void:
	_restore_selected_meshes()
	selected_key = key
	var related_meshes: Array = meshes_by_key.get(key, [])
	for value in related_meshes:
		var mesh_instance := value as MeshInstance3D
		if mesh_instance == null or not is_instance_valid(mesh_instance):
			continue
		selected_meshes.append(mesh_instance)
		previous_overlays.append(mesh_instance.material_overlay)
		mesh_instance.material_overlay = highlight_material
	structure_selected.emit(key)

func _restore_selected_meshes() -> void:
	for index in range(selected_meshes.size()):
		var mesh_instance := selected_meshes[index]
		if is_instance_valid(mesh_instance):
			mesh_instance.material_overlay = previous_overlays[index]
	selected_meshes.clear()
	previous_overlays.clear()

func _clear_selection() -> void:
	_restore_selected_meshes()
	selected_key = ""

func set_system_visibility(system_id: String, enabled: bool) -> void:
	# Toggle every renderable child belonging to an anatomical structure.
	for key in mesh_systems:
		if mesh_systems[key] != system_id or not meshes_by_key.has(key):
			continue
		for value in meshes_by_key[key]:
			var mesh_instance := value as MeshInstance3D
			if mesh_instance == null:
				continue
			mesh_instance.visible = enabled
			for child in mesh_instance.get_children():
				if child is StaticBody3D:
					(child as StaticBody3D).collision_layer = 1 if enabled else 0

func _unhandled_input(event: InputEvent) -> void:
	if camera == null or current_model == null:
		return

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			right_dragging = mouse_event.pressed
		elif mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_pick(mouse_event.position)
		elif mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom(-0.25)
		elif mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom(0.25)
	elif event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if right_dragging:
			_orbit(motion.relative)
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			screen_dragging = false
		elif not screen_dragging:
			_pick(touch.position)
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		screen_dragging = true
		_orbit(drag.relative)

func _orbit(delta: Vector2) -> void:
	yaw -= delta.x * 0.008
	pitch = clampf(pitch - delta.y * 0.006, -1.15, 1.15)
	pivot.rotation = Vector3(pitch, yaw, 0.0)

func _zoom(amount: float) -> void:
	distance = clampf(distance + amount, 2.0, 8.0)
	camera.position.z = distance

func _pick(screen_position: Vector2) -> void:
	var origin := camera.project_ray_origin(screen_position)
	var direction := camera.project_ray_normal(screen_position)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 20.0)
	query.collision_mask = 1
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var collider := hit.get("collider") as Node
	while collider != null:
		if collider.has_meta("anatomy_key"):
			select_structure(str(collider.get_meta("anatomy_key")))
			return
		collider = collider.get_parent()

func focus_body() -> void:
	yaw = 0.0
	pitch = 0.0
	distance = 3.8
	pivot.rotation = Vector3.ZERO
	camera.position.z = distance
