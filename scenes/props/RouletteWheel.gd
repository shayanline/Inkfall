class_name RouletteWheel
extends BoardObject
## A roulette wheel in raked perspective: a squashed disc of alternating red and ink pockets around
## a steel rim, a dark hub and a gold centre cap, with the ivory ball on the track. The pockets are
## built into a spinning child so on_tick turns them slowly while the rim, hub and ball hold.

const R := 30.0
const SPIN_SPEED := 0.35

var _spin: Node2D


func _ready() -> void:
	_spin = $Disc/Spin
	_build_pockets()
	_build_rim()


func _build_pockets() -> void:
	for i in 18:
		var a0 := float(i) / 18.0 * TAU
		var a1 := float(i + 1) / 18.0 * TAU
		var pts := PackedVector2Array([Vector2.ZERO])
		for k in 4:
			var a := lerpf(a0, a1, float(k) / 3.0)
			pts.append(Vector2(cos(a), sin(a)) * R)
		var wedge := Polygon2D.new()
		wedge.polygon = pts
		wedge.color = Color("c8000f") if i % 2 else Color8(10, 10, 10)
		_spin.add_child(wedge)


func _build_rim() -> void:
	var pts := PackedVector2Array()
	for k in 37:
		var a := float(k) / 36.0 * TAU
		pts.append(Vector2(cos(a), sin(a)) * (R + 2.0))
	var rim := Line2D.new()
	rim.name = "Rim"
	rim.points = pts
	rim.width = 4.0
	rim.default_color = Color8(42, 46, 53)
	rim.joint_mode = Line2D.LINE_JOINT_ROUND
	$Disc.add_child(rim)


func on_tick() -> void:
	if _spin:
		_spin.rotation += get_process_delta_time() * SPIN_SPEED
