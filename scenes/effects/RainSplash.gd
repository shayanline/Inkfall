class_name RainSplash
extends GPUParticles2D
## Ground spray: tiny soft specks that burst upward where rain lands along the ground line, then
## arc back down under gravity. This is what reads as a heavy downpour, the drops shatter on the
## asphalt instead of just vanishing. Built entirely in code so the board can instance it with new().
##
## Pairs with RainField (the falling drops) and RainRipples (the expanding rings on the floor).

@export var blood := false

## The board sets these before the node enters the tree.
var area := Vector2(1920, 1080)
var ground_y := 576.0

## Kenney CC0 soft filled disc, scaled tiny so each speck is a small soft droplet.
const _SPECK_TEX := preload("res://scenes/effects/rain_speck.png")
const _SPECK_SCALE := 0.018         ## texture scale for one speck (512px sprite to a few px)


func _ready() -> void:
	texture = _SPECK_TEX
	# one speck per ~6500 px of board, enough to read as constant spray without flooding draw calls.
	amount = maxi(int((area.x * area.y) / 6500.0), 40)
	lifetime = 0.55
	preprocess = lifetime
	position = Vector2(area.x * 0.5, ground_y)
	if blood:
		modulate = Color(0.66, 0.03, 0.06, (Palette.RAIN_ALPHA + 0.22) * 0.7)
	else:
		modulate = Color(0.74, 0.78, 0.84, Palette.RAIN_ALPHA * 0.7)

	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(area.x * 0.5, 3.0, 1.0)
	# burst up and out, then gravity drags the spray back to the floor for a real bounce arc.
	mat.direction = Vector3(0.0, -1.0, 0.0)
	mat.spread = 38.0
	mat.gravity = Vector3(0.0, 900.0, 0.0)
	mat.initial_velocity_min = 90.0
	mat.initial_velocity_max = 220.0
	mat.scale_min = _SPECK_SCALE * 0.6
	mat.scale_max = _SPECK_SCALE * 1.4
	mat.scale_curve = _shrink_curve()
	mat.color_ramp = _fade_ramp()
	process_material = mat


## A scale curve that shrinks each speck to nothing over its life, so the spray dissolves.
func _shrink_curve() -> CurveTexture:
	var c := Curve.new()
	c.add_point(Vector2(0.0, 1.0))
	c.add_point(Vector2(1.0, 0.0))
	var tex := CurveTexture.new()
	tex.curve = c
	return tex


## A colour ramp that pops in then fades the alpha out, so specks do not blink off abruptly.
func _fade_ramp() -> GradientTexture1D:
	var g := Gradient.new()
	g.set_offset(0, 0.0)
	g.set_color(0, Color(1, 1, 1, 0.0))
	g.add_point(0.2, Color(1, 1, 1, 1.0))
	g.set_offset(g.get_point_count() - 1, 1.0)
	g.set_color(g.get_point_count() - 1, Color(1, 1, 1, 0.0))
	var tex := GradientTexture1D.new()
	tex.gradient = g
	return tex
