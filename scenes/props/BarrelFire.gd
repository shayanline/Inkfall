class_name BarrelFire
extends BoardObject
## An oil drum fire on the noir street. The barrel (and its bands and rim) is drawn here in dark
## polygons so it casts a real shadow and occludes the flame. The fire itself is the shared Fire
## fixture (scenes/lights/Fire.tscn) embedded as a child at the barrel rim: a photographed flame
## texture warped to life by fire.gdshader, light particle tips, embers, three phase-offset warm
## shadow casters, a ground heat pool, a heat haze and the post fire-keep mask. The barrel sits in
## front of the lower flame, so light spills up and out, not down.

## Fire size relative to the default Fire: a barrel mouth is modest, so the flame is a touch smaller.
const _FIRE_SIZE := 0.75
## Local position of the flame base: the barrel rim sits around y = -44 in design units.
const _RIM_Y := -44.0


func place() -> void:
	super.place()
	var fire := get_node_or_null("FireInstance") as Fire
	if fire == null:
		return
	# The barrel owns placement, so build the fire as an embedded sub-object at the rim. A seed from
	# the barrel's x keeps two barrels on the same act out of lockstep.
	fire.build_embedded(board, Vector2(0.0, _RIM_Y), {
		"size": _FIRE_SIZE,
		"seed": nx * 7.3,
	})
