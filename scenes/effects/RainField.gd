class_name RainField
extends Node2D
## Native rain: a GPUParticles2D of falling streaks across the board, tinted grey for a normal
## night or red when the act calls for blood rain. Replaces the old hand stepped drop array.

@export var blood := false

var _p: GPUParticles2D


func _ready() -> void:
	var vp := get_viewport_rect().size
	_p = GPUParticles2D.new()
	_p.amount = int((vp.x * vp.y) / 2600.0)
	_p.lifetime = 1.1
	_p.preprocess = 1.1
	_p.position = Vector2(vp.x * 0.5, -30.0)
	_p.texture = _drop_texture()
	_p.modulate = Color(0.66, 0.03, 0.06, 0.7) if blood else Color(0.72, 0.76, 0.84, 0.5)

	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(vp.x * 0.75, 6.0, 1.0)
	mat.direction = Vector3(-0.22, 1.0, 0.0)
	mat.spread = 3.0
	mat.gravity = Vector3.ZERO
	mat.initial_velocity_min = 820.0
	mat.initial_velocity_max = 1080.0
	mat.scale_min = 0.8
	mat.scale_max = 1.5
	_p.process_material = mat
	add_child(_p)


func _drop_texture() -> ImageTexture:
	var img := Image.create(2, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 1))
	return ImageTexture.create_from_image(img)
