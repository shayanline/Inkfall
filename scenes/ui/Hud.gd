class_name Hud
extends Control
## In-play overlay: the paper caption box, the typed scene tag, the input hint, a mute toggle,
## and the act picker shown at THE END. Crisp (drawn above the post FX), like Inkfall's DOM HUD.

signal mute_toggled(on: bool)
signal nav_selected(index: int)

const SPECIAL_ELITE := "res://fonts/SpecialElite.ttf"
const OSWALD := "res://fonts/Oswald.ttf"

var _caption: PanelContainer
var _caption_label: RichTextLabel
var _tag: Label
var _tap: Label
var _mute: Button
var _nav: HBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_scene_tag()
	_build_caption()
	_build_tap_note()
	_build_mute()
	_build_nav()


func _build_scene_tag() -> void:
	_tag = Label.new()
	_tag.position = Vector2(18, 16)
	_tag.add_theme_font_override("font", load(SPECIAL_ELITE))
	_tag.add_theme_font_size_override("font_size", 19)
	_tag.add_theme_color_override("font_color", Palette.BONE)
	_tag.add_theme_constant_override("shadow_offset_x", 2)
	_tag.add_theme_constant_override("shadow_offset_y", 2)
	_tag.add_theme_color_override("font_shadow_color", Color.BLACK)
	_tag.modulate.a = 0.0
	add_child(_tag)


func _build_caption() -> void:
	_caption = PanelContainer.new()
	_caption.anchor_left = 0.5
	_caption.anchor_right = 0.5
	_caption.anchor_top = 1.0
	_caption.anchor_bottom = 1.0
	_caption.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_caption.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_caption.custom_minimum_size = Vector2(760, 0)
	_caption.offset_left = -380
	_caption.offset_right = 380
	_caption.offset_bottom = -42
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.96, 0.949, 0.91, 0.95)
	sb.set_border_width_all(2)
	sb.border_color = Color.BLACK
	sb.set_content_margin_all(28)
	sb.shadow_color = Color(0, 0, 0, 0.6)
	sb.shadow_size = 0
	sb.shadow_offset = Vector2(7, 7)
	_caption.add_theme_stylebox_override("panel", sb)

	_caption_label = RichTextLabel.new()
	_caption_label.bbcode_enabled = true
	_caption_label.fit_content = true
	_caption_label.scroll_active = false
	_caption_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption_label.add_theme_font_override("normal_font", load(SPECIAL_ELITE))
	_caption_label.add_theme_font_override("bold_font", load(SPECIAL_ELITE))
	_caption_label.add_theme_font_size_override("normal_font_size", 28)
	_caption_label.add_theme_font_size_override("bold_font_size", 28)
	_caption_label.add_theme_color_override("default_color", Color("111111"))
	_caption.add_child(_caption_label)

	_caption.modulate.a = 0.0
	add_child(_caption)


func _build_tap_note() -> void:
	_tap = Label.new()
	_tap.text = "TAP  —  NEXT      ·      L  —  LIGHTNING"
	_tap.anchor_left = 0.5
	_tap.anchor_right = 0.5
	_tap.anchor_top = 1.0
	_tap.anchor_bottom = 1.0
	_tap.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_tap.offset_bottom = -8
	_tap.offset_top = -26
	_tap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tap.add_theme_font_override("font", load("res://fonts/Oswald.ttf"))
	_tap.add_theme_font_size_override("font_size", 12)
	_tap.add_theme_color_override("font_color", Color("7c7c7c"))
	_tap.modulate.a = 0.0
	add_child(_tap)


func _build_mute() -> void:
	_mute = Button.new()
	_mute.text = "\u266A"
	_mute.anchor_left = 1.0
	_mute.anchor_right = 1.0
	_mute.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_mute.offset_left = -68
	_mute.offset_top = 12
	_mute.offset_right = -12
	_mute.custom_minimum_size = Vector2(56, 56)
	_mute.add_theme_font_override("font", load(OSWALD))
	_mute.add_theme_font_size_override("font_size", 24)
	_mute.add_theme_color_override("font_color", Palette.BONE)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.55)
	sb.set_border_width_all(1)
	sb.border_color = Color(1, 1, 1, 0.28)
	_mute.add_theme_stylebox_override("normal", sb)
	_mute.add_theme_stylebox_override("hover", sb)
	_mute.add_theme_stylebox_override("pressed", sb)
	_mute.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_mute.visible = false
	_mute.pressed.connect(_on_mute)
	add_child(_mute)


func _on_mute() -> void:
	var on := AudioDirector.toggle_mute()
	_mute.text = "\u266A" if on else "\u2715"
	_mute.add_theme_color_override("font_color", Palette.BONE if on else Color("777777"))
	mute_toggled.emit(on)


func _build_nav() -> void:
	_nav = HBoxContainer.new()
	_nav.anchor_left = 0.5
	_nav.anchor_right = 0.5
	_nav.anchor_top = 1.0
	_nav.anchor_bottom = 1.0
	_nav.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_nav.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_nav.offset_bottom = -40
	_nav.add_theme_constant_override("separation", 10)
	_nav.visible = false
	add_child(_nav)


# --- API ----------------------------------------------------------------

func begin_play() -> void:
	_mute.visible = true
	var tw := create_tween()
	tw.tween_property(_tap, "modulate:a", 1.0, 0.6)


func set_scene_tag(title: String) -> void:
	_tag.text = title
	_tag.modulate.a = 0.85
	var tw := create_tween()
	tw.tween_interval(2.6)
	tw.tween_property(_tag, "modulate:a", 0.0, 0.5)


func show_caption(text: String) -> void:
	# convert Inkfall <b>..</b> to red bold bbcode
	var bb := text.replace("<b>", "[color=#c20012][b]").replace("</b>", "[/b][/color]")
	var tw := create_tween()
	tw.tween_property(_caption, "modulate:a", 0.0, 0.17)
	tw.tween_callback(func(): _caption_label.text = bb)
	tw.tween_property(_caption, "modulate:a", 1.0, 0.2)


func hide_caption() -> void:
	_caption.modulate.a = 0.0


func set_tap_visible(v: bool) -> void:
	create_tween().tween_property(_tap, "modulate:a", 1.0 if v else 0.0, 0.3)


func build_nav(titles: Array) -> void:
	for c in _nav.get_children():
		c.queue_free()
	for i in titles.size():
		var b := Button.new()
		b.text = String(titles[i]).strip_edges()
		b.add_theme_font_override("font", load(OSWALD))
		b.add_theme_font_size_override("font_size", 16)
		b.add_theme_color_override("font_color", Color("c9c4b6"))
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.03, 0.03, 0.04, 0.62)
		sb.set_border_width_all(1)
		sb.border_color = Color(0.85, 0.83, 0.78, 0.3)
		sb.set_content_margin_all(14)
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", sb)
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		var idx := i
		b.pressed.connect(func(): nav_selected.emit(idx))
		_nav.add_child(b)


func show_nav(v: bool) -> void:
	_nav.visible = v


func highlight_nav(index: int) -> void:
	for i in _nav.get_child_count():
		var b: Button = _nav.get_child(i)
		var sb: StyleBoxFlat = b.get_theme_stylebox("normal")
		sb.border_color = Palette.RED_HOT if i == index else Color(0.85, 0.83, 0.78, 0.3)
		b.add_theme_color_override("font_color", Color.WHITE if i == index else Color("c9c4b6"))
