class_name CardTable
extends BoardObject
## A round felt card table: a dark skirt under a raked green top, a fan of dealt cards, loose chips
## and a tall stack topped with a hot red chip. When glow is true a soft green PointLight2D over the
## felt makes the table read as a lit gaming surface.

@export var glow := true


func _ready() -> void:
	var felt_glow := get_node_or_null("FeltGlow")
	if felt_glow == null:
		return
	felt_glow.visible = glow
	if felt_glow is PointLight2D and felt_glow.texture == null:
		felt_glow.texture = LightTex.radial()
