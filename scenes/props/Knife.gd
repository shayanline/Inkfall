class_name Knife
extends BoardObject
## A switchblade lying near the ground at a given angle: a graded steel blade with a lit edge, a dark
## guard and an ink handle. When bloody is true a red drip and smear are revealed on the blade. Place
## it with on_flag "blood" so it appears once a body hits the floor.

@export var angle := 0.0
@export var bloody := false


func _ready() -> void:
	rotation = angle
	var blood := get_node_or_null("Bloody")
	if blood:
		blood.visible = bloody
