class_name RouletteWheel
extends BoardObject
## A roulette wheel in raked perspective: alternating red and ink pockets, a steel rim, a dark hub
## and a gold cap, with the ivory ball on the track. All authored in the scene; this script only
## turns the pocket disc.

const SPIN_SPEED := 0.35

@onready var _spin: Node2D = $Disc/Spin


func on_tick() -> void:
	_spin.rotation += get_process_delta_time() * SPIN_SPEED
