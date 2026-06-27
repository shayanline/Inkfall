class_name Newspaper
extends BoardObject
## A blown in tabloid resting on the ground, ported from the old Newspaper. The sheet and its faint
## text rules are authored as child nodes in the scene. A gentle flutter rocks it in place so it
## never reads as fully frozen.

var _t := 0.0


func on_tick() -> void:
	_t += get_process_delta_time()
	$Art.rotation = 0.04 * sin(_t * 1.2)
