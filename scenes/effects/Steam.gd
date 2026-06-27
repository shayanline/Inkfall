class_name Steam
extends BoardObject
## A slow column of steam rising from the ground. The GPUParticles2D and its process material are
## authored in the scene; this script only offsets the preprocess time by the seed param so two
## vents do not pulse in lockstep.

@onready var _ps: GPUParticles2D = $Particles

var _seed := 0.0


func on_object_params(p: Dictionary) -> void:
	super.on_object_params(p)
	_seed = float(p.get("seed", 0.0))


func _ready() -> void:
	_ps.preprocess = 4.0 + _seed
