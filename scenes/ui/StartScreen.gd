class_name StartScreen
extends Control
## The opening screen: big title with the bleeding-red half, subtitle, blurb, a tale picker,
## and ENTER THE CITY. Built in code so it carries the Inkfall look with no scene wiring.

signal entered

const OSWALD := "res://fonts/Oswald.ttf"


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Palette.BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 18)
	center.add_child(vb)

	var story := SceneDirector.story
	if story.is_empty():
		story = DemoStory.get_story()

	vb.add_child(_title(String(story.get("title", "NOIR"))))
	vb.add_child(_text(String(story.get("subtitle", "")), 28, Color("ece6d6"), 0.28))
	vb.add_child(_text(String(story.get("blurb", "")), 22, Color(0.92, 0.9, 0.84, 0.72), 0.02, 640))
	vb.add_child(_spacer(28))
	vb.add_child(_text("CHOOSE YOUR TALE", 18, Color(0.92, 0.9, 0.84, 0.55), 0.38))

	var tale := _menu_button(String(story.get("title", "NOIR")))
	tale.disabled = true
	tale.add_theme_color_override("font_disabled_color", Color.WHITE)
	vb.add_child(tale)

	vb.add_child(_spacer(20))
	var enter := _menu_button("ENTER THE CITY")
	enter.pressed.connect(func():
		AudioDirector.whoosh()
		entered.emit())
	vb.add_child(enter)


func _title(t: String) -> Control:
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	var head := t.substr(0, max(1, int(t.length() / 2.0)))
	var tail := t.substr(head.length())
	hb.add_child(_title_part(head, Color.WHITE))
	hb.add_child(_title_part(tail, Palette.RED_HOT))
	return hb


func _title_part(t: String, col: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", load(OSWALD))
	l.add_theme_font_size_override("font_size", 150)
	l.add_theme_color_override("font_color", col)
	return l


func _text(t: String, size: int, col: Color, _spacing: float, max_w := 0) -> Label:
	var l := Label.new()
	l.text = t
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if max_w > 0 else TextServer.AUTOWRAP_OFF
	if max_w > 0:
		l.custom_minimum_size.x = max_w
	l.add_theme_font_override("font", load(OSWALD))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l


func _menu_button(t: String) -> Button:
	var b := Button.new()
	b.text = t
	b.add_theme_font_override("font", load(OSWALD))
	b.add_theme_font_size_override("font_size", 26)
	b.add_theme_color_override("font_color", Color("f2eee2"))
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0, 0, 0, 0)
	normal.set_border_width_all(1)
	normal.border_color = Color(0.92, 0.9, 0.84, 0.45)
	normal.set_content_margin_all(18)
	var hover := normal.duplicate()
	hover.border_color = Palette.RED_HOT
	hover.bg_color = Color(0.92, 0.9, 0.84, 0.06)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("disabled", hover)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return b


func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size.y = h
	return c
