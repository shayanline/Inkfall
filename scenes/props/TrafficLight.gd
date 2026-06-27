class_name TrafficLight
extends BoardObject
## A street traffic light. The pole, housing and lamp octagons are static in the scene. It shows red
## until the line given by green_at, then switches to green by swapping which lamp is bright.

const GREEN_ON := Color(0.212, 0.827, 0.431, 1.0)
const LAMP_DIM := Color(0.275, 0.275, 0.29, 0.5)

@onready var _red_lamp: Polygon2D = $RedLamp
@onready var _red_halo: Polygon2D = $RedHalo
@onready var _green_lamp: Polygon2D = $GreenLamp
@onready var _green_halo: Polygon2D = $GreenHalo

var _green_at := -1
var _is_green := false


func on_object_params(p: Dictionary) -> void:
	super(p)
	if p.has("green_at"):
		_green_at = int(p["green_at"])


func on_line(idx: int) -> void:
	super(idx)
	if not _is_green and _green_at >= 0 and idx >= _green_at:
		_set_green()


func _set_green() -> void:
	_is_green = true
	_red_lamp.color = LAMP_DIM
	_red_halo.visible = false
	_green_lamp.color = GREEN_ON
	_green_halo.visible = true
