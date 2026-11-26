extends Control

const AnatomyCatalogScript = preload("res://scripts/anatomy_catalog.gd")
const AnatomyViewerScript = preload("res://scripts/anatomy_viewer.gd")
const SAVE_PATH := "user://atlas_progress.cfg"
const TUTOR_BACKEND_URL := ""

var catalog
var viewer
var mode := "male"
var active_system := "all"
var search_text := ""
var selected_key := ""
var visible_keys: Array[String] = []
var active_atlas_id := "base"
var external_entries: Array[Dictionary] = []
var external_catalog: Dictionary = {}

var item_list: ItemList
var details: RichTextLabel
var model_status: Label
var search_box: LineEdit
var system_dropdown: OptionButton
var atlas_dropdown: OptionButton
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
	catalog = AnatomyCatalogScript.new()
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
	# Mobile-first portrait interface: one vertical reading flow, large touch targets.
	var app_theme := Theme.new()
	app_theme.default_font_size = 16
	app_theme.set_color("font_color", "Label", Color("#183247"))
	theme = app_theme

	var background := ColorRect.new()
	background.color = Color("#eef3f7")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)

	var layout := VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 12)
	scroll.add_child(layout)

	# Brand row with the new launcher mark.
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	layout.add_child(header)
	var app_icon := TextureRect.new()
	if ResourceLoader.exists("res://assets/app_icon.svg"):
		app_icon.texture = load("res://assets/app_icon.svg") as Texture2D
	app_icon.custom_minimum_size = Vector2(48, 48)
	app_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	app_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header.add_child(app_icon)

	var brand := VBoxContainer.new()
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brand.add_theme_constant_override("separation", 1)
	header.add_child(brand)
	var title := Label.new()
	title.text = "ATLAS DE ANATOMÍA"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("#15364a"))
	brand.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Explora el cuerpo humano en 3D"
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", Color("#597285"))
	brand.add_child(subtitle)

	var tutor_button := Button.new()
	tutor_button.text = "Tutor"
	tutor_button.custom_minimum_size = Vector2(68, 44)
	_style_button(tutor_button, true)
	tutor_button.pressed.connect(_open_tutor)
	header.add_child(tutor_button)

	var about_button := Button.new()
	about_button.text = "⋯"
	about_button.tooltip_text = "Información"
	about_button.custom_minimum_size = Vector2(44, 44)
	_style_button(about_button, false)
	about_button.pressed.connect(_show_about)
	header.add_child(about_button)

	# Two clear, equally sized body-mode tabs.
	var mode_row := HBoxContainer.new()
	mode_row.add_theme_constant_override("separation", 8)
	layout.add_child(mode_row)
	male_button = Button.new()
	male_button.text = "Masculino"
	male_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	male_button.custom_minimum_size.y = 46
	_style_button(male_button, true)
	male_button.pressed.connect(func(): _set_mode("male", true))
	mode_row.add_child(male_button)
	female_button = Button.new()
	female_button.text = "Femenino"
	female_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	female_button.custom_minimum_size.y = 46
	_style_button(female_button, false)
	female_button.pressed.connect(func(): _set_mode("female", true))
	mode_row.add_child(female_button)

	atlas_dropdown = OptionButton.new()
	atlas_dropdown.custom_minimum_size = Vector2(0, 46)
	atlas_dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	atlas_dropdown.add_theme_color_override("font_color", Color("#183247"))
	atlas_dropdown.add_theme_stylebox_override("normal", _make_card_style(Color.WHITE, Color("#d7e1e8"), 12))
	atlas_dropdown.add_item("Modelo anatómico base")
	atlas_dropdown.set_item_metadata(0, "base")
	atlas_dropdown.add_item("Z-Anatomy · atlas masculino")
	atlas_dropdown.set_item_metadata(1, "z_anatomy_male")
	atlas_dropdown.add_item("HuBMAP · órganos femeninos")
	atlas_dropdown.set_item_metadata(2, "hubmap_hra_female")
	atlas_dropdown.item_selected.connect(_on_atlas_changed)
	layout.add_child(atlas_dropdown)

	search_box = LineEdit.new()
	search_box.placeholder_text = "Buscar órgano, hueso, músculo…"
	search_box.custom_minimum_size = Vector2(0, 48)
	search_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_box.add_theme_font_size_override("font_size", 15)
	search_box.add_theme_color_override("font_color", Color("#183247"))
	search_box.add_theme_color_override("font_placeholder_color", Color("#74899a"))
	search_box.add_theme_stylebox_override("normal", _make_card_style(Color.WHITE, Color("#d7e1e8"), 13))
	search_box.text_changed.connect(_on_search_changed)
	layout.add_child(search_box)

	var filter_row := HBoxContainer.new()
	filter_row.add_theme_constant_override("separation", 8)
	layout.add_child(filter_row)
	system_dropdown = OptionButton.new()
	system_dropdown.custom_minimum_size = Vector2(0, 44)
	system_dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	system_dropdown.add_theme_color_override("font_color", Color("#183247"))
	system_dropdown.add_theme_stylebox_override("normal", _make_card_style(Color.WHITE, Color("#d7e1e8"), 12))
	system_dropdown.item_selected.connect(_on_system_changed)
	filter_row.add_child(system_dropdown)

	var focus_button := Button.new()
	focus_button.text = "Centrar 3D"
	focus_button.custom_minimum_size = Vector2(112, 44)
	_style_button(focus_button, false)
	focus_button.pressed.connect(func():
		if viewer != null:
			viewer.focus_body()
	)
	filter_row.add_child(focus_button)

	# Large, dedicated anatomy viewport card.
	var viewer_card := PanelContainer.new()
	viewer_card.add_theme_stylebox_override("panel", _make_card_style(Color.WHITE, Color("#d9e4eb"), 18))
	layout.add_child(viewer_card)
	var viewer_box := VBoxContainer.new()
	viewer_box.add_theme_constant_override("separation", 5)
	viewer_card.add_child(viewer_box)

	var viewer_header := HBoxContainer.new()
	viewer_box.add_child(viewer_header)
	var viewer_title := Label.new()
	viewer_title.text = "MODELO ANATÓMICO 3D"
	viewer_title.add_theme_font_size_override("font_size", 13)
	viewer_title.add_theme_color_override("font_color", Color("#22465a"))
	viewer_header.add_child(viewer_title)
	var viewer_hint := Label.new()
	viewer_hint.text = "Arrastra para girar 360°"
	viewer_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	viewer_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	viewer_hint.add_theme_font_size_override("font_size", 11)
	viewer_hint.add_theme_color_override("font_color", Color("#6a8292"))
	viewer_header.add_child(viewer_hint)

	viewport = SubViewport.new()
	viewport.size = Vector2i(720, 640)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var viewport_container := SubViewportContainer.new()
	viewport_container.custom_minimum_size = Vector2(0, 340)
	viewport_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	viewport_container.stretch = true
	viewport_container.clip_contents = true
	viewport_container.add_child(viewport)
	viewer_box.add_child(viewport_container)

	# Tissue/system controls scroll horizontally, never squeeze into tiny labels.
	var layers_scroll := ScrollContainer.new()
	layers_scroll.custom_minimum_size = Vector2(0, 48)
	layers_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	layers_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(layers_scroll)
	var layers_bar := HBoxContainer.new()
	layers_bar.add_theme_constant_override("separation", 8)
	layers_scroll.add_child(layers_bar)
	var layer_specs := [
		["skin", "Piel", true],
		["skeleton", "Huesos", false],
		["muscles", "Músculos", false],
		["organs", "Órganos", false],
		["vessels", "Vasos", false],
		["nerves", "Nervios", false]
	]
	for spec in layer_specs:
		var toggle := CheckButton.new()
		toggle.text = spec[1]
		toggle.button_pressed = spec[2]
		toggle.custom_minimum_size = Vector2(96, 42)
		toggle.add_theme_color_override("font_color", Color("#24465a"))
		toggle.add_theme_color_override("font_pressed_color", Color("#0f766e"))
		var system_id: String = spec[0]
		toggle.toggled.connect(func(enabled: bool):
			if viewer != null:
				viewer.set_system_visibility(system_id, enabled)
		)
		layer_controls[system_id] = toggle
		layers_bar.add_child(toggle)

	viewer = AnatomyViewerScript.new()
	viewer.structure_selected.connect(_on_viewer_structure_selected)
	viewer.model_status_changed.connect(_on_model_status_changed)
	viewport.add_child(viewer)

	# Detail card appears before the catalogue: selection feedback stays visible.
	var detail_panel := PanelContainer.new()
	detail_panel.add_theme_stylebox_override("panel", _make_card_style(Color.WHITE, Color("#d9e4eb"), 16))
	layout.add_child(detail_panel)
	var detail_box := VBoxContainer.new()
	detail_box.add_theme_constant_override("separation", 6)
	detail_panel.add_child(detail_box)
	var detail_heading := Label.new()
	detail_heading.text = "FICHA ANATÓMICA"
	detail_heading.add_theme_font_size_override("font_size", 13)
	detail_heading.add_theme_color_override("font_color", Color("#22465a"))
	detail_box.add_child(detail_heading)
	details = RichTextLabel.new()
	details.bbcode_enabled = true
	details.fit_content = true
	details.scroll_active = false
	details.custom_minimum_size = Vector2(0, 120)
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_color_override("default_color", Color("#324e60"))
	details.meta_clicked.connect(_on_details_meta_clicked)
	detail_box.add_child(details)

	# Searchable catalogue list with a useful touch height.
	var list_panel := PanelContainer.new()
	list_panel.add_theme_stylebox_override("panel", _make_card_style(Color.WHITE, Color("#d9e4eb"), 16))
	layout.add_child(list_panel)
	var list_box := VBoxContainer.new()
	list_box.add_theme_constant_override("separation", 6)
	list_panel.add_child(list_box)
	var list_title := Label.new()
	list_title.text = "ESTRUCTURAS"
	list_title.add_theme_font_size_override("font_size", 13)
	list_title.add_theme_color_override("font_color", Color("#22465a"))
	list_box.add_child(list_title)
	item_list = ItemList.new()
	item_list.custom_minimum_size = Vector2(0, 230)
	item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_list.add_theme_constant_override("icon_margin", 8)
	item_list.add_theme_color_override("font_color", Color("#244256"))
	item_list.add_theme_color_override("font_selected_color", Color.WHITE)
	item_list.add_theme_stylebox_override("panel", _make_card_style(Color("#f7fafc"), Color("#e1e9ee"), 10))
	item_list.item_selected.connect(_on_item_selected)
	list_box.add_child(item_list)

	model_status = Label.new()
	model_status.text = "Preparando el atlas…"
	model_status.add_theme_font_size_override("font_size", 11)
	model_status.add_theme_color_override("font_color", Color("#527284"))
	layout.add_child(model_status)

func _make_card_style(fill: Color, outline: Color, corner: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = outline
	style.set_border_width_all(1)
	style.set_corner_radius_all(corner)
	style.content_margin_left = 12
	style.content_margin_top = 10
	style.content_margin_right = 12
	style.content_margin_bottom = 10
	return style

func _style_button(button: Button, primary: bool) -> void:
	var fill := Color("#0e7c78") if primary else Color("#e6eef3")
	var text_color := Color.WHITE if primary else Color("#24465a")
	var border := Color("#0e7c78") if primary else Color("#d2dfe7")
	var normal := _make_card_style(fill, border, 12)
	var hover := _make_card_style(fill.lightened(0.08), border, 12)
	var pressed := _make_card_style(fill.darkened(0.08), border, 12)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", normal)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_font_size_override("font_size", 14)
func _populate_system_filter() -> void:
	system_dropdown.clear()
	system_dropdown.add_item("Todos los sistemas")
	system_dropdown.set_item_metadata(0, "all")
	if active_atlas_id != "base":
		for system in external_catalog.get("systems", []):
			var system_id := str(system.get("system", ""))
			system_dropdown.add_item(_external_system_label(system_id))
			system_dropdown.set_item_metadata(system_dropdown.item_count - 1, system_id)
	else:
		for system in catalog.systems:
			var system_id := str(system.get("id", ""))
			system_dropdown.add_item(str(system.get("name_es", system_id)))
			system_dropdown.set_item_metadata(system_dropdown.item_count - 1, system_id)
	system_dropdown.select(0)
	active_system = "all"

func _external_system_label(system_id: String) -> String:
	var labels := {
		"articular": "Articulaciones",
		"cardiovascular": "Vasos y corazón",
		"digestive": "Sistema digestivo",
		"endocrine": "Sistema endocrino",
		"integumentary": "Piel",
		"lymphatic": "Sistema linfático",
		"muscular": "Músculos",
		"nervous": "Sistema nervioso",
		"renal": "Sistema urinario",
		"reproductive": "Sistema reproductor",
		"respiratory": "Sistema respiratorio",
		"skeletal": "Esqueleto",
		"visceral": "Órganos internos"
	}
	return str(labels.get(system_id, system_id.capitalize()))

func _on_atlas_changed(index: int) -> void:
	var atlas_id := str(atlas_dropdown.get_item_metadata(index))
	if atlas_id == active_atlas_id:
		return
	_load_selected_atlas(atlas_id)

func _load_selected_atlas(atlas_id: String) -> void:
	active_atlas_id = atlas_id
	selected_key = ""
	external_entries.clear()
	external_catalog.clear()
	if atlas_id == "base":
		_populate_system_filter()
		if viewer != null:
			viewer.load_body(mode)
		_refresh_list()
		return
	if (atlas_id == "z_anatomy_male" and mode != "male") or (atlas_id == "hubmap_hra_female" and mode != "female"):
		active_atlas_id = "base"
		atlas_dropdown.select(0)
		_populate_system_filter()
		if viewer != null:
			viewer.load_body(mode)
		_refresh_list()
		return
	var path := "res://data/external_atlas_catalog_male_zanatomy.json" if atlas_id == "z_anatomy_male" else "res://data/external_atlas_catalog_female_hra.json"
	if not FileAccess.file_exists(path):
		model_status.text = "El índice del atlas externo no está disponible."
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		model_status.text = "No se pudo leer el índice del atlas externo."
		return
	external_catalog = parsed
	for source_entry in parsed.get("structures", []):
		if not source_entry is Dictionary:
			continue
		var names: Dictionary = {
			"es": str(source_entry.get("names", {}).get("es", "")),
			"en": str(source_entry.get("names", {}).get("en", "")),
			"la": str(source_entry.get("names", {}).get("la", ""))
		}
		if names["es"].is_empty():
			names["es"] = names["en"]
		external_entries.append({
			"key": str(source_entry.get("key", "")),
			"names": names,
			"label": names["en"],
			"system": str(source_entry.get("system_id", "")),
			"atlas_system_id": str(source_entry.get("system_id", "")),
			"sex": mode,
			"external_mesh_file": str(source_entry.get("mesh_file", "")),
			"external_node_name": str(source_entry.get("node_name", "")),
			"external_atlas_id": atlas_id
		})
	_populate_system_filter()
	if viewer != null:
		viewer.load_external_atlas(atlas_id)
	_refresh_list()

func _find_external_entry(key: String) -> Dictionary:
	for entry in external_entries:
		if str(entry.get("key", "")) == key:
			return entry
	return {}

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
	if active_atlas_id == "z_anatomy_male" and mode != "male":
		active_atlas_id = "base"
		atlas_dropdown.select(0)
	if active_atlas_id == "hubmap_hra_female" and mode != "female":
		active_atlas_id = "base"
		atlas_dropdown.select(0)
	if viewer != null:
		if active_atlas_id == "base":
			viewer.load_body(mode)
		else:
			viewer.load_external_atlas(active_atlas_id)
		_apply_default_layers()
	_populate_system_filter()
	_refresh_list()
	if selected_key in visible_keys:
		if viewer != null:
			viewer.select_structure(selected_key)
		else:
			_update_detail(catalog.get_entry(selected_key))
	else:
		selected_key = ""
		_save_progress()
	if save:
		_save_progress()

func _apply_default_layers() -> void:
	var defaults := {
		"skin": true,
		"skeleton": false,
		"muscles": false,
		"organs": false,
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
	if item_list == null or catalog == null:
		return
	item_list.clear()
	visible_keys.clear()
	var matches: Array[Dictionary] = []
	if active_atlas_id == "base":
		if catalog.entries.is_empty():
			return
		matches = catalog.filter_entries(mode, active_system, search_text)
	else:
		var needle := search_text.strip_edges().to_lower()
		for entry in external_entries:
			if active_system != "all" and str(entry.get("system", "")) != active_system:
				continue
			var names: Dictionary = entry.get("names", {})
			var haystack := (str(entry.get("key", "")) + " " + str(names.get("es", "")) + " " + str(names.get("en", "")) + " " + str(names.get("la", ""))).to_lower()
			if not needle.is_empty() and not haystack.contains(needle):
				continue
			matches.append(entry)
	for entry in matches:
		var key := str(entry.get("key", ""))
		var display: String = catalog.get_name(entry)
		if str(entry.get("model_mapping_status", "")) == "info_only_no_mesh":
			display += "  ·  sin malla 3D"
		elif str(entry.get("system", "")) == "joints":
			display += "  ·  punto de referencia"
		item_list.add_item(display)
		item_list.set_item_metadata(item_list.item_count - 1, key)
		visible_keys.append(key)
	if selected_key in visible_keys:
		var index := visible_keys.find(selected_key)
		item_list.select(index)
		_update_detail(catalog.get_entry(selected_key) if active_atlas_id == "base" else _find_external_entry(selected_key))
	elif active_atlas_id != "base":
		var atlas_name := "Z-Anatomy" if active_atlas_id == "z_anatomy_male" else "HuBMAP / Human Reference Atlas"
		_set_detail_text("[b]" + atlas_name + "[/b]\n\n" + str(matches.size()) + " estructuras en el filtro actual. Selecciona una para ver su nombre, sistema, nodo 3D y atribución.")
	elif active_system == "all":
		_set_detail_text("Selecciona una estructura en la lista o tócala en el modelo 3D.\n\nEl índice local contiene " + str(catalog.entries.size()) + " entradas, entre estructuras de los modelos y entradas informativas sin malla 3D.")
	else:
		_show_system_overview(active_system)

func _show_system_overview(system_id: String) -> void:
	for system in catalog.systems:
		if str(system.get("id", "")) != system_id:
			continue
		var title := str(system.get("name_es", system_id))
		var description := str(system.get("description", ""))
		var count := int(system.get("catalog_entries", 0))
		var mesh_count := int(system.get("mesh_entries", 0))
		var info_count := int(system.get("info_only_entries", 0))
		var detail_count := int(system.get("detailed_entries", 0))
		var text_value := "[font_size=19][b]" + _escape_bbcode(title) + "[/b][/font_size]\n"
		text_value += _escape_bbcode(description) + "\n\n"
		text_value += "[b]Entradas indexadas:[/b] " + str(count) + "\n"
		text_value += "[b]Estructuras con malla de origen:[/b] " + str(mesh_count) + "\n"
		text_value += "[b]Entradas informativas sin malla:[/b] " + str(info_count) + "\n"
		text_value += "[b]Fichas profundas aprobadas:[/b] " + str(detail_count) + "\n\n"
		text_value += "[color=#e6bd76]La cobertura es parcial. Las entradas sin malla no se pueden seleccionar en 3D, y las fichas profundas deben completarse con fuentes y licencias verificadas.[/color]"
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
	var entry: Dictionary = catalog.get_entry(key) if active_atlas_id == "base" else _find_external_entry(key)
	if entry.is_empty():
		return
	selected_key = key
	if update_viewer and viewer != null:
		viewer.select_structure(key)
	_update_detail(entry)
	if key in visible_keys:
		item_list.select(visible_keys.find(key))
	_save_progress()

func _update_detail(entry: Dictionary) -> void:
	if active_atlas_id != "base":
		_update_external_detail(entry)
		return
	var key := str(entry.get("key", ""))
	var names: Dictionary = entry.get("names", {})
	var detail: Dictionary = catalog.get_detail(key)
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
		output += "\n[color=#91a7c3]Licencia: " + _escape_bbcode(str(detail.get("license", ""))) + "[/color]"
		var source_url := str(detail.get("source_url", ""))
		if source_url.begins_with("https://"):
			output += "\n[url=" + source_url + "]Abrir capítulo de referencia[/url]"
		output += "\n[color=#91a7c3]" + _escape_bbcode(str(detail.get("attribution", ""))) + "[/color]"
		var related_ids: Array = detail.get("related_structures", [])
		if not related_ids.is_empty():
			output += "\n\n[b]Estructuras relacionadas[/b]\n"
			for related_value in related_ids:
				var related_key := str(related_value)
				var related_entry: Dictionary = catalog.get_entry(related_key)
				if not related_entry.is_empty():
					output += "[url=atlas://structure/" + related_key + "]" + _escape_bbcode(catalog.get_name(related_entry)) + "[/url]  "
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

func _update_external_detail(entry: Dictionary) -> void:
	var names: Dictionary = entry.get("names", {})
	var title := str(names.get("es", names.get("en", entry.get("key", "Estructura"))))
	var output := "[font_size=19][b]" + _escape_bbcode(title) + "[/b][/font_size]\n"
	output += "[color=#91a7c3]" + _escape_bbcode(str(names.get("la", ""))) + " · " + _escape_bbcode(str(names.get("en", ""))) + "[/color]\n\n"
	output += "[b]Sistema:[/b] " + _escape_bbcode(_external_system_label(str(entry.get("system", "")))) + "\n"
	output += "[b]Atlas:[/b] " + ("Z-Anatomy / BodyParts3D" if active_atlas_id == "z_anatomy_male" else "HuBMAP / Human Reference Atlas") + "\n"
	output += "[b]Clave:[/b] " + _escape_bbcode(str(entry.get("key", ""))) + "\n"
	output += "[b]Nodo 3D:[/b] " + _escape_bbcode(str(entry.get("external_node_name", ""))) + "\n\n"
	output += "[color=#79d6ad]Estructura indexada en el atlas de origen. La geometría conserva los materiales originales de la fuente.[/color]\n\n"
	output += "[b]Licencia:[/b] " + _escape_bbcode(str(external_catalog.get("license", ""))) + "\n"
	output += "[b]Atribución:[/b] " + _escape_bbcode(str(external_catalog.get("attribution", "")))
	details.clear()
	details.append_text(output)

func _set_detail_text(text_value: String) -> void:
	if details == null:
		return
	details.clear()
	details.append_text(text_value)

func _escape_bbcode(value: String) -> String:
	return value.replace("[", "[lb]").replace("]", "[rb]")

func _on_details_meta_clicked(meta: Variant) -> void:
	var url := str(meta)
	if url.begins_with("https://"):
		OS.shell_open(url)
	elif url.begins_with("atlas://structure/"):
		var key := url.trim_prefix("atlas://structure/")
		_select_structure(key, true)

func _create_tutor_window() -> void:
	tutor_window = Window.new()
	tutor_window.title = "Tutor de anatomía"
	tutor_window.size = Vector2i(360, 620)
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
		tutor_window.popup_centered(Vector2i(360, 620))

func _ask_tutor() -> void:
	var question := tutor_input.text.strip_edges()
	if question.is_empty():
		return
	var selected: Dictionary = catalog.get_entry(selected_key)
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
	var matches: Array[Dictionary] = catalog.filter_entries(mode, "all", question)
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
