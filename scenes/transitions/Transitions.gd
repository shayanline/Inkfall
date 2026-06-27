extends CanvasLayer
## Scene transitions: a shader-driven ink wipe, an act-name title card, and the THE END
## screen. The caller orchestrates a scene change as: await close(); swap panel;
## await show_card(title); await open().

var _ink: ColorRect
var _card: Label
var _end: Label


func _ready() -> void:
	layer = 100
	_ink = ColorRect.new()
	_ink.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ink.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/ink_wipe.gdshader")
	mat.set_shader_parameter("progress", 0.0)
	_ink.material = mat
	add_child(_ink)

	_card = _make_label(Palette.PAPER, 0.07, 0.32)
	add_child(_card)

	_end = _make_label(Color("ece6d6"), 0.085, 0.42)
	_end.text = "THE END"
	add_child(_end)


func _make_label(col: Color, size_ratio: float, spacing: float) -> Label:
	var l := Label.new()
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font", load("res://fonts/Oswald.ttf"))
	var vp := get_viewport().get_visible_rect().size if get_viewport() else Vector2(1280, 720)
	l.add_theme_font_size_override("font_size", int(min(vp.x, vp.y) * size_ratio))
	l.add_theme_color_override("font_color", col)
	l.add_theme_constant_override("line_spacing", 0)
	l.label_settings = null
	l.modulate.a = 0.0
	# letter spacing via tracking is not a Label theme const, so rely on the font; the look
	# stays close to Inkfall's spaced caps without per-glyph kerning.
	return l


func _set_progress(v: float) -> void:
	_ink.material.set_shader_parameter("progress", v)


func close(dur := -1.0) -> void:
	if dur < 0.0:
		dur = Palette.TRANS_IN
	var from: float = _ink.material.get_shader_parameter("progress")
	var tw := create_tween()
	tw.tween_method(_set_progress, from, 1.0, dur)
	await tw.finished


func open(dur := -1.0) -> void:
	if dur < 0.0:
		dur = Palette.TRANS_OUT
	var tw := create_tween()
	tw.tween_method(_set_progress, 1.0, 0.0, dur)
	await tw.finished


func show_card(title: String, hold := -1.0) -> void:
	if hold < 0.0:
		hold = Palette.CARD_HOLD
	_card.text = title
	var tw := create_tween()
	tw.tween_property(_card, "modulate:a", 1.0, 0.3)
	tw.tween_interval(hold)
	tw.tween_property(_card, "modulate:a", 0.0, 0.3)
	await tw.finished


func show_end() -> void:
	var tw := create_tween()
	tw.tween_property(_end, "modulate:a", 1.0, 1.6)
	await tw.finished


func hide_end() -> void:
	_end.modulate.a = 0.0
