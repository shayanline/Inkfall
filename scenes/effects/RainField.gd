class_name RainField
extends Node2D
## Native rain: two GPUParticles2D layers (near and far) of falling streaks. The far layer has
## fewer, slower, smaller, dimmer particles for depth. A slow wind sway modulates the direction
## over time. Particle lifetime is clamped so drops die at the ground line, not past it.
##
## Legacy reference: ~398 drops at 1080p (area / 5200), steel blue rgba(180,190,210,0.35),
## blood red rgba(168,8,16,0.57), line width 1.1 (1.6 blood), ~19 degree leftward tilt.

@export var blood := false

## The board sets these before the node enters the tree.
var area := Vector2(1920, 1080)
var ground_y := 576.0

const _WIND_PERIOD := 8.0          ## seconds per full wind sway cycle
const _WIND_AMOUNT := 0.08         ## max lateral drift added to direction.x

@onready var _near: GPUParticles2D = $Rain
var _far: GPUParticles2D
var _near_mat: ParticleProcessMaterial
var _far_mat: ParticleProcessMaterial
var _base_dir := Vector3(-0.22, 1.0, 0.0)
var _t := 0.0


func _ready() -> void:
	# near layer: the main rain
	var count := int((area.x * area.y) / 5200.0)
	_near.amount = count
	_near.position = Vector2(area.x * 0.5, -30.0)
	if blood:
		_near.modulate = Color(0.66, 0.03, 0.06, Palette.RAIN_ALPHA + 0.22)
	else:
		_near.modulate = Color(0.71, 0.75, 0.82, Palette.RAIN_ALPHA)
	_near_mat = _near.process_material.duplicate()
	_near_mat.emission_box_extents = Vector3(area.x * 0.75, 6.0, 1.0)
	_near.process_material = _near_mat
	# clamp lifetime so drops die around the ground line, not past it.
	# lifetime = distance / avg_velocity. The drop travels from -30 to ground_y.
	var fall_dist := ground_y + 30.0
	var avg_speed := (_near_mat.initial_velocity_min + _near_mat.initial_velocity_max) * 0.5
	if avg_speed > 0.0:
		_near.lifetime = maxf(fall_dist / avg_speed, 0.3)
		_near.preprocess = _near.lifetime

	# far layer: fewer, slower, smaller, dimmer particles behind the main rain
	_far = GPUParticles2D.new()
	_far.amount = maxi(count / 3, 20)
	_far.position = _near.position
	_far.texture = _near.texture
	_far.z_index = -1
	if blood:
		_far.modulate = Color(0.66, 0.03, 0.06, (Palette.RAIN_ALPHA + 0.22) * 0.5)
	else:
		_far.modulate = Color(0.71, 0.75, 0.82, Palette.RAIN_ALPHA * 0.5)
	_far_mat = _near_mat.duplicate()
	_far_mat.initial_velocity_min = _near_mat.initial_velocity_min * 0.6
	_far_mat.initial_velocity_max = _near_mat.initial_velocity_max * 0.6
	_far_mat.scale_min = 0.5
	_far_mat.scale_max = 0.8
	_far.process_material = _far_mat
	_far.lifetime = _near.lifetime * 1.4
	_far.preprocess = _far.lifetime
	add_child(_far)


func _process(delta: float) -> void:
	_t += delta
	var wind := sin(_t * TAU / _WIND_PERIOD) * _WIND_AMOUNT
	var dir := _base_dir
	dir.x = _base_dir.x + wind
	_near_mat.direction = dir
	_far_mat.direction = dir
