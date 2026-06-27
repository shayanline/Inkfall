class_name Searchlight
extends BoardObject
## A rooftop searchlight that sweeps a pale cone of light back and forth, ported from the old
## Searchlight. The cone is an additive triangle that rotates about its apex, with a faint point
## light at the apex. Kept subtle so it reads as atmosphere, not a spotlight.

var _t := 0.0


func _ready() -> void:
	var pl := PointLight2D.new()
	pl.texture = LightTex.radial()
	pl.color = Color(0.745, 0.784, 0.863)
	pl.energy = 0.15
	pl.texture_scale = 1.5
	add_child(pl)


func on_tick() -> void:
	_t += get_process_delta_time()
	$Cone.rotation = sin(_t * 0.4) * 0.5
