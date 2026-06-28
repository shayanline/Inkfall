class_name RainRipples
extends Node2D
## Rain splash ripples on the floor. Spawns perspective squashed ellipses that expand and fade.
## Each ripple samples the nearest light and picks up its color when close enough, so splashes
## near a warm lamp glow amber and splashes in shadow stay cool grey.
##
## Legacy reference: ~51 ripples/sec (85% chance per frame at 60fps), radius 1 to 10-36px,
## expand rate 34px/s, lifetime ~0.91s, Y squash 0.4, additive blend,
## normal color (150,162,180) alpha 0.22, blood color (220,24,34) alpha 0.42, line width 1.2 (1.9).

@export var blood := false

## The board area and ground line. Set by Board before adding to the tree.
var area := Vector2(1920, 1080)
var ground_y := 576.0

## Scene lights for color sampling. Each entry: { pos: Vector2, col: Color, radius: float }
var lights: Array[Dictionary] = []

const _SPAWN_CHANCE := 0.85        ## per frame spawn probability (at 60fps = ~51/sec)
const _EXPAND_RATE := 34.0         ## radius growth in px/sec
const _DECAY_RATE := 1.1           ## life units lost per second (from 1.0, dies at 0)
const _Y_SQUASH := 0.4             ## perspective: ellipse Y radius = X radius * this
const _MAX_RIPPLES := 80           ## pool cap to keep draw calls bounded
const _LIGHT_THRESHOLD := 0.3      ## minimum light weight to tint a ripple

var _ripples: Array[Dictionary] = []
var _default_col := Color(0.59, 0.64, 0.71)
var _blood_col := Color(0.86, 0.09, 0.13)


func _process(delta: float) -> void:
	# spawn
	if _ripples.size() < _MAX_RIPPLES and randf() < _SPAWN_CHANCE:
		var floor_depth := area.y - ground_y
		var rx := randf() * area.x
		var ry := ground_y + randf() * floor_depth * 0.9
		var col := _blood_col if blood else _sample_light(rx, ry)
		_ripples.append({
			"x": rx, "y": ry,
			"r": 1.0,
			"max_r": 10.0 + randf() * 26.0,
			"life": 1.0,
			"col": col,
		})

	# update
	var i := _ripples.size() - 1
	while i >= 0:
		var rip: Dictionary = _ripples[i]
		rip["r"] += _EXPAND_RATE * delta
		rip["life"] -= _DECAY_RATE * delta
		if rip["life"] <= 0.0 or rip["r"] > rip["max_r"]:
			_ripples.remove_at(i)
		i -= 1

	queue_redraw()


## Find the dominant light at a position, matching the legacy elliptical influence with Y squash.
func _sample_light(x: float, y: float) -> Color:
	if lights.is_empty():
		return _default_col
	var best_w := _LIGHT_THRESHOLD
	var best_col := _default_col
	for li in lights:
		var pos: Vector2 = li["pos"]
		var dx := x - pos.x
		var dy := (y - pos.y) * 0.6   # Y compressed for elliptical influence
		var dist := sqrt(dx * dx + dy * dy)
		var energy: float = float(li.get("energy", 1.0))
		var radius: float = float(li["radius"])
		if radius < 1.0:
			continue
		var w := energy * (1.0 - dist / radius)
		if w > best_w:
			best_w = w
			best_col = li["col"]
	return best_col


func _draw() -> void:
	if _ripples.is_empty():
		return
	var base_alpha := 0.42 if blood else 0.22
	var lw := 1.9 if blood else 1.2

	for rip in _ripples:
		var a: float = base_alpha * rip["life"]
		if a < 0.005:
			continue
		var rx: float = rip["r"]
		var col: Color = rip["col"]
		col.a = a
		draw_set_transform(Vector2(rip["x"], rip["y"]), 0.0, Vector2(1.0, _Y_SQUASH))
		draw_arc(Vector2.ZERO, rx, 0.0, TAU, 32, col, lw, true)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
