class_name Skyline
extends BoardBackdrop
## A city skyline: seeded buildings with lit windows baked to a texture, over a wet floor. The
## story supplies the seed and the layer configs (depth, shade, sizes, window density).

var _seed := 0
var _layers: Array = []


func on_object_params(p: Dictionary) -> void:
	_seed = int(p.get("seed", 0))
	_layers = p.get("layers", [])


func build(board_size: Vector2, ground_y: float) -> void:
	_add_sky(board_size, ground_y)
	var cfgs := _resolved_layers()
	var sky := Sprite2D.new()
	sky.texture = BackdropBaker.bake_skyline(board_size, ground_y, _seed, cfgs)
	sky.centered = false
	add_child(sky)
	_add_wet_floor(board_size, ground_y)


## a faint night sky that lifts toward the horizon, so the dark building silhouettes read.
func _add_sky(vp: Vector2, g: float) -> void:
	var sky := Polygon2D.new()
	sky.polygon = PackedVector2Array([Vector2(0, 0), Vector2(vp.x, 0), Vector2(vp.x, g), Vector2(0, g)])
	var top := Color(0.03, 0.04, 0.07)
	var horizon := Color(0.16, 0.17, 0.22)
	sky.vertex_colors = PackedColorArray([top, top, horizon, horizon])
	add_child(sky)


func _resolved_layers() -> Array:
	var out := []
	for l in _layers:
		var c: Dictionary = (l as Dictionary).duplicate()
		c["shade"] = c["shade"] if c["shade"] is Color else Color(String(c["shade"]))
		out.append(c)
	return out


func _add_wet_floor(vp: Vector2, g: float) -> void:
	var wet := Polygon2D.new()
	wet.polygon = PackedVector2Array([Vector2(0, g), Vector2(vp.x, g), Vector2(vp.x, vp.y), Vector2(0, vp.y)])
	wet.vertex_colors = PackedColorArray([Color8(10, 11, 15), Color8(10, 11, 15), Palette.INK, Palette.INK])
	add_child(wet)
