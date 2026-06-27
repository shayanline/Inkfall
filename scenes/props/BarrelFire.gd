class_name BarrelFire
extends BoardObject
## An oil drum fire on the noir street. The barrel, rim and bands are static in the scene. This
## script builds the flickering flame polygons plus a warm PointLight2D at the flames, then pulses
## the flame heights and the light energy every frame.

const FLAME_COUNT := 6
const BASE_Y := -44.0
const LIGHT_Y := -46.0
const WARM := Color(1.0, 0.549, 0.157, 1.0)

var _flames: Array[Polygon2D] = []
var _light: PointLight2D
var _light_base := 1.1


func _ready() -> void:
	_light = PointLight2D.new()
	_light.texture = LightTex.radial()
	_light.color = WARM
	_light.energy = _light_base
	_light.texture_scale = 1.6
	_light.position = Vector2(0, LIGHT_Y)
	add_child(_light)
	for i in FLAME_COUNT:
		var fl := Polygon2D.new()
		fl.color = _flame_color(i)
		add_child(fl)
		_flames.append(fl)


func _flame_color(i: int) -> Color:
	var c := Color(1.0, 0.478, 0.094) if i % 2 == 0 else Palette.AMBER
	c.a = 0.85
	return c


func on_tick() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for i in FLAME_COUNT:
		var fx := (i - 2.5) * 5.0
		var fh := 18.0 + sin(t * 8.0 + i) * 8.0
		_flames[i].polygon = PackedVector2Array([
			Vector2(fx - 4.0, BASE_Y),
			Vector2(fx, BASE_Y - fh),
			Vector2(fx + 4.0, BASE_Y),
		])
	var fl := 0.7 + 0.3 * sin(t * 7.0) + 0.1 * sin(t * 19.0)
	_light.energy = _light_base * fl
