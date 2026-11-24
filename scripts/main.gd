extends Control

const AnatomyCatalog = preload("res://scripts/anatomy_catalog.gd")
const AnatomyViewer = preload("res://scripts/anatomy_viewer.gd")
const SAVE_PATH := "user://atlas_progress.cfg"
const TUTOR_BACKEND_URL := ""

var catalog: AnatomyCatalog
var viewer: AnatomyViewer
var mode := "male"
var active_system := "all"
var search_text := ""
var selected_key := ""
var visible_keys: Array[String] = []

var item_list: ItemList
var details: RichTextLabel
var model_status: Label
var search_box: LineEdit
var system_dropdown: OptionButton
var male_button: Button
var female_button: Button
var viewport: SubViewport
var tutor_window: Window
var tutor_input: LineEdit
var tutor_output: RichTextLabel
var tutor_http: HTTPRequest
var layer_controls: Dictionary = {}
var progress := ConfigFile.new()

func _ready() -> void:
	catalog = AnatomyCatalog.new()
	_build_interface()
	_load_progress()
	if not catalog.load_all():
		model_status.text = "Error al cargar el catálogo anatómico local."
		_set_detail_text("No se pudo abrir data/anatomy_catalog_es.json. Revisa los archivos locales del atlas.")
		return
	_populate_system_filter()
	_set_mode(mode, false)
	_refresh_list()
	_create_tutor_window()

func _build_interface() -> void:
	var background := ColorRect.new()
	background.color = Color("#0b1220")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	margin.add_child(layout)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	layout.add_child(header)

	var brand := VBoxContainer.new()
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(brand)
	var title := Label.new()
	title.text = "ATLAS DE ANATOMÍA"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("#f4f7fb"))
	brand.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Exploración anatómica interactiva · Versión de desarrollo"
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", Color("#9aabc1"))
	brand.add_child(subtitle)

	male_button = Button.new()
	male_button.text = "Masculino"
	male_button.pressed.connect(func(): _set_mode("male", true))
	header.add_child(male_button)
	female_button = Button.new()
	female_button.text = "Femenino"
	female_button.pressed.connect(func(): _set_mode("female", true))
	header.add_child(female_button)
	var tutor_button := Button.new()
	tutor_button.text = "Tutor"
	tutor_button.pressed.connect(_open_tutor)
	header.add_child(tutor_button)
	var about_button := Button.new()
	about_button.text = "Información"
	about_button.pressed.connect(_show_about)
	header.add_child(about_button)

	var toolbar := HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 8)
	layout.add_child(toolbar)

	search_box = LineEdit.new()
	search_box.placeholder_text = "Buscar órgano, hueso, músculo o estructura…"
	search_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_box.text_changed.connect(_on_search_changed)
	toolbar.add_child(search_box)

	system_dropdown = OptionButton.new()
	system_dropdown.custom_minimum_size.x = 190
	system_dropdown.item_selected.connect(_on_system_changed)
	toolbar.add_child(system_dropdown)

	var focus_button := Button.new()
	focus_button.text = "Centrar cuerpo"
	focus_button.pressed.connect(func():
		if viewer != null:
			viewer.focus_body()
	)
	toolbar.add_child(focus_button)

	viewport = SubViewport.new()
	viewport.size = Vector2i(1200, 690)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var viewport_container := SubViewportContainer.new()
	viewport_container.custom_minimum_size = Vector2(320, 280)
	viewport_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	viewport_container.stretch = true
	viewport_container.add_child(viewport)
	layout.add_child(viewport_container)

	var layers_bar := HFlowContainer.new()
	layers_bar.add_theme_constant_override("h_separation", 8)
	layers_bar.add_theme_constant_override("v_separation", 2)
	layout.add_child(layers_bar)
	var layer_specs := [
		["skin", "Piel", false],
		["skeleton", "Huesos", true],
		["muscles", "Músculos", true],
		["organs", "Órganos", true],
		["vessels", "Vasos", false],
		["nerves", "Nervios", false]
	]
	for spec in layer_specs:
		var toggle := CheckButton.new()
		toggle.text = spec[1]
		toggle.button_pressed = spec[2]
		var system_id: String = spec[0]
		toggle.toggled.connect(func(enabled: bool):
			if viewer != null:
				viewer.set_system_visibility(system_id, enabled)
		)
		layer_controls[system_id] = toggle
		layers_bar.add_child(toggle)

	viewer = AnatomyViewer.new()
	viewer.structure_selected.connect(_on_viewer_structure_selected)
	viewer.model_status_changed.connect(_on_model_status_changed)
	viewport.add_child(viewer)

	var lower := HBoxContainer.new()
	lower.custom_minimum_size = Vector2(0, 205)
	lower.add_theme_constant_override("separation", 10)
	layout.add_child(lower)

	var list_panel := PanelContainer.new()
	list_panel.custom_minimum_size.x = 235
	list_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lower.add_child(list_panel)
	var list_box := VBoxContainer.new()
	list_box.add_theme_constant_override("separation", 5)
	list_panel.add_child(list_box)
	var list_title := Label.new()
	list_title.text = "ESTRUCTURAS"
	list_title.add_theme_color_override("font_color", Color("#dce6f4"))
	list_box.add_child(list_title)
	item_list = ItemList.new()
	item_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_list.item_selected.connect(_on_item_selected)
	item_list.add_theme_color_override("font_color", Color("#e9eef6"))
	list_box.add_child(item_list)

	var detail_panel := PanelContainer.new()
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lower.add_child(detail_panel)
	var detail_box := VBoxContainer.new()
	detail_panel.add_child(detail_box)
	var detail_heading := Label.new()
	detail_heading.text = "FICHA ANATÓMICA"
	detail_heading.add_theme_color_override("font_color", Color("#dce6f4"))
	detail_box.add_child(detail_heading)
	details = RichTextLabel.new()
	details.bbcode_enabled = true
	details.fit_content = true
	details.scroll_active = true
	details.size_flags_vertical = Control.SIZE_EXPAND_FILL
	details.add_theme_color_override("default_color", Color("#d7e0ec"))
	detail_box.add_child(details)

	model_status = Label.new()
	model_status.text = "Preparando catálogo local…"
	model_status.add_theme_font_size_override("font_size", 12)
	model_status.add_theme_color_override("font_color", Color("#9aabc1"))
	layout.add_child(model_status)

func _populate_system_filter() -> void:
	system_dropdown.clear()
	system_dropdown.add_item("Todos los sistemas")
	system_dropdown.set_item_metadata(0, "all")
	for system in catalog.systems:
		var system_id := str(system.get("id", ""))
		system_dropdown.add_item(str(system.get("name_es", system_id)))
		system_dropdown.set_item_metadata(system_dropdown.item_count - 1, system_id)

func _load_progress() -> void:
	if progress.load(SAVE_PATH) == OK:
		mode = str(progress.get_value("atlas", "mode", "male"))
		selected_key = str(progress.get_value("atlas", "selected_key", ""))

func _save_progress() -> void:
	progress.set_value("atlas", "mode", mode)
	progress.set_value("atlas", "selected_key", selected_key)
	progress.save(SAVE_PATH)

func _set_mode(next_mode: String, save: bool) -> void:
	mode = next_mode
	male_button.text = "✓ Masculino" if mode == "male" else "Masculino"
	female_button.text = "✓ Femenino" if mode == "female" else "Femenino"
	if viewer != null:
		viewer.load_body(mode)
		_apply_default_layers()
	_refresh_list()
	if selected_key in catalog.by_key:
		_update_detail(catalog.get_entry(selected_key))
	if save:
		_save_progress()

func _apply_default_layers() -> void:
	var defaults := {
		"skin": false,
		"skeleton": true,
		"muscles": true,
		"organs": true,
		"vessels": false,
		"nerves": false
	}
	for system_id in defaults:
		var enabled: bool = defaults[system_id]
		if layer_controls.has(system_id):
			(layer_controls[system_id] as CheckButton).button_pressed = enabled
		if viewer != null:
			viewer.set_system_visibility(system_id, enabled)

func _on_model_status_changed(message: String, ready: bool) -> void:
	model_status.text = message
	model_status.add_theme_color_override(
		"font_color",
		Color("#79d6ad") if ready else Color("#f0bd72")
	)

func _on_search_changed(value: String) -> void:
	search_text = value
	_refresh_list()

func _on_system_changed(index: int) -> void:
	active_system = str(system_dropdown.get_item_metadata(index))
	_refresh_list()

func _refresh_list() -> void:
	if item_list == null or catalog == null or catalog.entries.is_empty():
		return
	item_list.clear()
	visible_keys.clear()
	var matches := catalog.filter_entries(mode, active_system, search_text)
	for entry in matches:
		var key := str(entry.get("key", ""))
		var display := catalog.get_name(entry)
		if str(entry.get("system", "")) == "joints":
			display += "  ·  referencia"
		item_list.add_item(display)
		item_list.set_item_metadata(item_list.item_count - 1, key)
		visible_keys.append(key)
	if selected_key in visible_keys:
		var index := visible_keys.find(selected_key)
		item_list.select(index)
	else:
		_set_detail_text("Selecciona una estructura en la lista o tócala en el modelo 3D.\n\nEl catálogo local contiene " + str(catalog.entries.size()) + " entradas de la fuente Open Anatomy 3D; algunas son puntos de referencia y no mallas independientes.")

func _show_system_overview(system_id: String) -> void:
	for system in catalog.systems:
		if str(system.get("id", "")) != system_id:
			continue
		var title := str(system.get("name_es", system_id))
		var description := str(system.get("description", ""))
		var count := int(system.get("catalog_entries", 0))
		var status := str(system.get("coverage_status", "not_yet_catalogued"))
		var text_value := "[font_size=19][b]" + _escape_bbcode(title) + "[/b][/font_size]\\n"
		text_value += _escape_bbcode(description) + "\\n\\n"
		text_value += "[b]Entradas indexadas:[/b] " + str(count) + "\\n"
		text_value += "[b]Estado:[/b] " + _escape_bbcode(status) + "\\n"
		text_value += "[color=#e6bd76]La cobertura de este sistema todavía es parcial. Las estructuras sin ficha ampliada se marcarán y completarán con fuentes verificadas.[/color]"
		_set_detail_text(text_value)
		return
	_set_detail_text("No se encontró información del sistema seleccionado.")

func _on_item_selected(index: int) -> void:
	var key := str(item_list.get_item_metadata(index))
	_select_structure(key, true)

func _on_viewer_structure_selected(key: String) -> void:
	if key.is_empty():
		return
	_select_structure(key, false)

func _select_structure(key: String, update_viewer: bool) -> void:
	if not catalog.has_key(key):
		return
	selected_key = key
	var entry := catalog.get_entry(key)
	if update_viewer and viewer != null:
		viewer.select_structure(key)
	_update_detail(entry)
	if key in visible_keys:
		item_list.select(visible_keys.find(key))
	_save_progress()

func _update_detail(entry: Dictionary) -> void:
	var key := str(entry.get("key", ""))
	var names: Dictionary = entry.get("names", {})
	var detail := catalog.get_detail(key)
	var output := "[font_size=19][b]" + _escape_bbcode(catalog.get_name(entry)) + "[/b][/font_size]\n"
	output += "[color=#91a7c3]" + _escape_bbcode(str(names.get("la", ""))) + " · " + _escape_bbcode(str(entry.get("label", ""))) + "[/color]\n\n"
	output += "[b]Sistema:[/b] " + _escape_bbcode(str(entry.get("system_label_es", catalog.get_system_label(str(entry.get("system", ""))))))
	output += "\n[b]Categoría:[/b] " + _escape_bbcode(str(entry.get("category", "Anatomía")))
	output += "\n[b]Clave:[/b] " + _escape_bbcode(key)
	if detail.is_empty():
		output += "\n\n[color=#e6bd76]Ficha ampliada pendiente de documentación anatómica y revisión de licencia.[/color]"
		output += "\nLa estructura está indexada en el catálogo local, pero todavía no se han incorporado aquí sus detalles anatómicos verificados."
	else:
		output += "\n\n[b]Descripción[/b]\n" + _escape_bbcode(str(detail.get("description", "")))
		for section in detail.get("sections", []):
			output += "\n\n[b]" + _escape_bbcode(str(section.get("title", ""))) + "[/b]\n"
			for line in section.get("items", []):
				output += "• " + _escape_bbcode(str(line)) + "\n"
		output += "\n[color=#91a7c3]Fuente: " + _escape_bbcode(str(detail.get("source_title", ""))) + "[/color]"
	if viewer != null:
		if viewer.has_mesh(key):
			output += "\n\n[color=#79d6ad]Malla 3D localizada en el modelo actual.[/color]"
		elif str(entry.get("model_mapping_status", "")) == "info_only_no_mesh":
			output += "\n\n[color=#91a7c3]Entrada informativa sin malla 3D en los modelos actuales. La ficha profunda está pendiente de documentación.[/color]"
		elif str(entry.get("system", "")) == "joints":
			output += "\n\n[color=#91a7c3]Punto de referencia: no es una malla independiente en esta fuente.[/color]"
		else:
			output += "\n\n[color=#e6bd76]La malla no se ha localizado en el modelo actual.[/color]"
	details.clear()
	details.append_text(output)

func _set_detail_text(text_value: String) -> void:
	if details == null:
		return
	details.clear()
	details.append_text(text_value)

func _escape_bbcode(value: String) -> String:
	return value.replace("[", "\\[").replace("]", "\\]")

func _create_tutor_window() -> void:
	tutor_window = Window.new()
	tutor_window.title = "Tutor de anatomía"
	tutor_window.size = Vector2i(560, 500)
	tutor_window.visible = false
	tutor_window.close_requested.connect(func(): tutor_window.hide())
	add_child(tutor_window)

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.add_theme_constant_override("separation", 10)
	var margins := MarginContainer.new()
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margins.add_theme_constant_override("margin_left", 16)
	margins.add_theme_constant_override("margin_top", 16)
	margins.add_theme_constant_override("margin_right", 16)
	margins.add_theme_constant_override("margin_bottom", 16)
	tutor_window.add_child(margins)
	margins.add_child(box)

	var explanation := Label.new()
	explanation.text = "Pregunta sobre anatomía. Sin conexión, el tutor consulta el catálogo local."
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(explanation)
	tutor_input = LineEdit.new()
	tutor_input.placeholder_text = "Ej.: ¿Qué partes tiene el corazón?"
	box.add_child(tutor_input)
	var ask := Button.new()
	ask.text = "Consultar"
	ask.pressed.connect(_ask_tutor)
	box.add_child(ask)
	tutor_output = RichTextLabel.new()
	tutor_output.bbcode_enabled = true
	tutor_output.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(tutor_output)
	tutor_http = HTTPRequest.new()
	tutor_http.timeout = 18.0
	tutor_http.request_completed.connect(_on_tutor_http_completed)
	box.add_child(tutor_http)

func _open_tutor() -> void:
	if tutor_window != null:
		tutor_window.popup_centered(Vector2i(560, 500))

func _ask_tutor() -> void:
	var question := tutor_input.text.strip_edges()
	if question.is_empty():
		return
	var selected := catalog.get_entry(selected_key)
	var payload := {
		"question": question,
		"selected_structure": selected,
		"local_detail": catalog.get_detail(selected_key),
		"language": "es"
	}
	if not TUTOR_BACKEND_URL.is_empty():
		var headers := PackedStringArray(["Content-Type: application/json"])
		var err := tutor_http.request(
			TUTOR_BACKEND_URL,
			headers,
			HTTPClient.METHOD_POST,
			JSON.stringify(payload)
		)
		if err == OK:
			tutor_output.text = "Consultando al tutor…"
			return
	_show_local_tutor_answer(question)

func _on_tutor_http_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		_show_local_tutor_answer(tutor_input.text)
		return
	var response: Variant = JSON.parse_string(body.get_string_from_utf8())
	if response is Dictionary and response.has("answer"):
		tutor_output.text = str(response["answer"])
	else:
		_show_local_tutor_answer(tutor_input.text)

func _show_local_tutor_answer(question: String) -> void:
	var matches := catalog.filter_entries(mode, "all", question)
	var lines := PackedStringArray()
	for entry in matches.slice(0, 8):
		lines.append("• " + catalog.get_name(entry) + " (" + str(entry.get("system_label_es", "")) + ")")
	var answer := "[b]Tutor local[/b]\n"
	if not selected_key.is_empty():
		answer += "Estructura seleccionada: " + catalog.get_name(catalog.get_entry(selected_key)) + ".\n"
	if not lines.is_empty():
		answer += "\nEncontré estas entradas relacionadas en el catálogo:\n" + "\n".join(lines)
	else:
		answer += "No encontré una coincidencia directa en el índice local. Prueba con el nombre de un órgano, hueso, músculo o sistema."
	answer += "\n\n[color=#dcb979]La explicación generativa de Gemini requiere configurar un servicio seguro en línea. Este modo local no inventa respuestas ni sustituye una ficha anatómica revisada.[/color]"
	tutor_output.text = answer

func _show_about() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "Información de la aplicación"
	dialog.dialog_text = "ATLAS DE ANATOMÍA\n\npara amorcito de parte de motito que te ama mucho\n\nAtlas educativo en desarrollo. No diagnostica ni sustituye una evaluación profesional.\n\nModelos Open Anatomy 3D: BodyParts3D © DBCLS (CC BY 4.0); órganos femeninos: Human Reference Atlas / HuBMAP (CC BY 4.0); superficie femenina: MakeHuman (CC0). Adaptación: Open Anatomy 3D (CC BY 4.0)."
	add_child(dialog)
	dialog.confirmed.connect(func(): dialog.queue_free())
	dialog.close_requested.connect(func(): dialog.queue_free())
	dialog.popup_centered()
