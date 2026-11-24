extends SceneTree

func _initialize() -> void:
	call_deferred("_prepare_icons")

func _prepare_icons() -> void:
	var icon_sources := {
		"res://assets/app_icon.svg": ["res://assets/app_icon.png", 512],
		"res://assets/app_icon_foreground.svg": ["res://assets/app_icon_foreground.png", 432],
		"res://assets/app_icon_background.svg": ["res://assets/app_icon_background.png", 432],
		"res://assets/app_icon_monochrome.svg": ["res://assets/app_icon_monochrome.png", 432]
	}
	for source_path in icon_sources:
		var texture := load(source_path) as Texture2D
		if texture == null:
			push_error("No se pudo importar el icono: " + source_path)
			quit(1)
			return
		var output_path: String = icon_sources[source_path][0]
		var target_size: int = icon_sources[source_path][1]
		var image := texture.get_image()
		image.resize(target_size, target_size, Image.INTERPOLATE_LANCZOS)
		var result := image.save_png(output_path)
		if result != OK:
			push_error("No se pudo guardar el PNG del icono: " + output_path)
			quit(1)
			return
		print("Icono preparado: ", output_path, " (", target_size, " px)")
	quit(0)
