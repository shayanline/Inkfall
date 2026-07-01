extends Node2D
## THROWAWAY (light audit, delete when done). Hosts the Room backdrop with optionally the FORTUNE
## neon or the casino bulb, so each fixture's light footprint can be isolated by diffing against the
## room-only baseline. FIXTURE env = none|neon|bulb. OUT env = png path.
##   FIXTURE=neon OUT=/tmp/audit_neon.png Godot --path . --rendering-driver opengl3 --resolution 1920x1080 tools/_LightAudit.tscn

const ENV := preload("res://scenes/core/Environment.tres")
const POST_MAT := preload("res://scenes/core/post_material.tres")


func _ready() -> void:
	var vp := get_viewport().get_visible_rect().size
	var cm := CanvasModulate.new()
	cm.color = Color(0.30, 0.32, 0.40)
	add_child(cm)
	var we := WorldEnvironment.new()
	we.environment = ENV
	add_child(we)
	var cam := Camera2D.new()
	cam.position = vp * 0.5
	add_child(cam)
	var world := Node2D.new()
	add_child(world)

	var board: Board = load("res://scenes/board/Board.tscn").instantiate()
	board.setup(_act(OS.get_environment("FIXTURE")))
	world.add_child(board)

	# No post here on purpose: post.gdshader now reads the scene SubViewport set up by Main, which a
	# manual harness does not provide. Auditing the raw lit scene (CanvasModulate + lights, no grade or
	# bloom) is exactly what we want to measure each fixture's true light footprint.

	await get_tree().process_frame
	await get_tree().process_frame
	GameState.line_index = 0
	GameState.notify_line()
	for i in 90:
		await get_tree().process_frame

	await RenderingServer.frame_post_draw
	var out := OS.get_environment("OUT")
	if out == "":
		out = "/tmp/audit.png"
	get_viewport().get_texture().get_image().save_png(out)
	print("SHOT SAVED ", out)
	get_tree().quit()


func _act(fixture: String) -> Act:
	var act := Act.new()
	act.indoor = true
	act.ground = 0.82
	act.key_light = Vector2(0.5, 0.3)
	act.has_moon = false
	var bd := Placement.new()
	bd.scene = load("res://scenes/backdrops/Room.tscn")
	bd.params = {"wall": "#191c26", "wall_top": "#262a37", "door": 0.64}
	act.backdrop = bd
	var lights: Array[Placement] = []
	if fixture == "neon":
		var n := Placement.new()
		n.scene = load("res://scenes/lights/Neon.tscn")
		n.params = {"x": 0.10, "y": 0.245, "w": 240, "h": 60, "color": Color(1.0, 0.0, 0.094), "label": "FORTUNE", "shape": "arrow", "seed": 2.2, "par": 0.2, "intensity": 1.0}
		lights.append(n)
	elif fixture == "bulb":
		var b := Placement.new()
		b.scene = load("res://scenes/lights/Bulb.tscn")
		b.params = {"x": 0.45, "y": 0.30, "intensity": 1.0, "flicker": true, "par": 0.2}
		lights.append(b)
	act.lights = lights
	return act
