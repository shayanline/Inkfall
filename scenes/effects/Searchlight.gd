class_name Searchlight
extends BoardObject
## A rooftop searchlight that sweeps a pale additive cone back and forth, with a faint point light at
## the apex. The cone and apex light are authored in the scene; this script only sweeps the cone.

var _t := 0.0


func on_tick() -> void:
	_t += get_process_delta_time()
	$Cone.rotation = sin(_t * 0.4) * 0.5
