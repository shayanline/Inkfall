class_name WetFloorShimmer
extends Node2D
## Animated highlights on the wet floor: 30 tiny steel colored flecks that drift slowly rightward,
## giving the dark ground a faint wet sheen. Matches the legacy's wet floor treatment.

var area := Vector2(1920, 1080)
var ground_y := 576.0

const _FLECK_COUNT := 30
const _DRIFT_SPEED := 6.0          ## px/sec rightward drift
const _ALPHA := 0.10
const _COL := Color(0.67, 0.71, 0.78)   ## steel grey, legacy #aab4c8


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var t := Time.get_ticks_msec() * 0.001
	var floor_h := area.y - ground_y
	if floor_h < 2.0:
		return
	var col := _COL
	col.a = _ALPHA
	for i in _FLECK_COUNT:
		# golden ratio spread with slow rightward drift, wrapping across the floor
		var x := fmod(i * 137.5 + t * _DRIFT_SPEED, area.x)
		var y := ground_y + fmod(i * 23.0, floor_h)
		var w := 2.0 + (i % 4)
		draw_rect(Rect2(x, y, w, 2.0), col)
