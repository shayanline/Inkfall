class_name RotationGate
extends Control
## On touch devices held in portrait, covers the screen and asks the player to rotate to
## landscape. Auto-hides in landscape. Harmless on desktop (it only shows when taller than wide
## on a touchscreen), so it never gets in the way of mouse play.

var _panel: Control
var _is_touch := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_is_touch = DisplayServer.is_touchscreen_available()

	var bg := ColorRect.new()
	bg.color = Palette.BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_panel = center

	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 24)
	center.add_child(vb)

	var icon := Label.new()
	icon.text = "\u27F3"  # rotate glyph
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_override("font", load("res://fonts/Oswald.ttf"))
	icon.add_theme_font_size_override("font_size", 96)
	icon.add_theme_color_override("font_color", Palette.RED_HOT)
	vb.add_child(icon)

	var msg := Label.new()
	msg.text = "ROTATE YOUR DEVICE"
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.add_theme_font_override("font", load("res://fonts/Oswald.ttf"))
	msg.add_theme_font_size_override("font_size", 30)
	msg.add_theme_color_override("font_color", Color("ece6d6"))
	vb.add_child(msg)

	var sub := Label.new()
	sub.text = "This city is best seen wide."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_override("font", load("res://fonts/Oswald.ttf"))
	sub.add_theme_font_size_override("font_size", 18)
	sub.add_theme_color_override("font_color", Color(0.92, 0.9, 0.84, 0.6))
	vb.add_child(sub)

	get_viewport().size_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	var s := get_viewport().get_visible_rect().size
	visible = _is_touch and s.y > s.x
