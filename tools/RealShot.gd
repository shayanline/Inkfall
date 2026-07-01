extends Node2D
## Throwaway faithful capture (delete when done). Replicates Main's full render path: the scene
## renders into a SubViewport, a six-level bloom pyramid bright-passes and downsamples it, and
## post.gdshader adds that bloom over the scene before the grade. This is what the player sees, unlike
## LightShot/ObjectShot which skip the bloom pyramid. Hosts one real story act.
##   Godot --path . --rendering-driver opengl3 --resolution 1920x1080 tools/RealShot.tscn

const ENV := preload("res://scenes/core/Environment.tres")
const POST_MAT := preload("res://scenes/core/post_material.tres")
const _BLOOM_DOWN := preload("res://shaders/bloom_down.gdshader")
const _BLOOM_COMBINE := preload("res://shaders/bloom_combine.gdshader")
const _BLOOM_DIVS := [2, 4, 8, 16, 32, 64]

const STORY_INDEX := 1   ## danny_cole
const ACT_INDEX := 0     ## "THE ITCH", the first outdoor barrel-fire act
const LINE_INDEX := 1
const OUT_PATH := "/tmp/real_shot.png"

var _scene_vp: SubViewport
var _bloom_levels: Array[SubViewport] = []
var _bloom_combine: SubViewport


func _ready() -> void:
	var vp := get_viewport().get_visible_rect().size

	_scene_vp = SubViewport.new()
	_scene_vp.size = Vector2i(vp)
	_scene_vp.transparent_bg = false
	_scene_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_scene_vp)

	var cm := CanvasModulate.new()
	cm.color = Color(0.30, 0.32, 0.40)
	_scene_vp.add_child(cm)
	var we := WorldEnvironment.new()
	we.environment = ENV
	_scene_vp.add_child(we)
	var cam := Camera2D.new()
	cam.position = vp * 0.5
	cam.enabled = true
	_scene_vp.add_child(cam)
	var world := Node2D.new()
	_scene_vp.add_child(world)

	var lib: StoryLibrary = load("res://stories/library.tres")
	var story: Story = lib.stories[STORY_INDEX]
	GameState.load_story(story)
	var act: Act = story.acts[ACT_INDEX]
	var board: Board = load("res://scenes/board/Board.tscn").instantiate()
	board.setup(act)
	world.add_child(board)

	# bloom pyramid (mirrors Main._build_bloom)
	var src: Texture2D = _scene_vp.get_texture()
	for i in _BLOOM_DIVS.size():
		var sz := _level_size(vp, _BLOOM_DIVS[i])
		var sv := _make_bloom_vp(sz)
		var mat := ShaderMaterial.new()
		mat.shader = _BLOOM_DOWN
		mat.set_shader_parameter("tex", src)
		mat.set_shader_parameter("texel", Vector2(1.0 / float(sz.x), 1.0 / float(sz.y)))
		mat.set_shader_parameter("do_bright", i == 0)
		(sv.get_child(0) as ColorRect).material = mat
		add_child(sv)
		_bloom_levels.append(sv)
		src = sv.get_texture()
	var csz := _level_size(vp, 2)
	_bloom_combine = _make_bloom_vp(csz)
	var cmat := ShaderMaterial.new()
	cmat.shader = _BLOOM_COMBINE
	for i in _bloom_levels.size():
		cmat.set_shader_parameter("b%d" % i, _bloom_levels[i].get_texture())
	(_bloom_combine.get_child(0) as ColorRect).material = cmat
	add_child(_bloom_combine)

	var layer := CanvasLayer.new()
	layer.layer = 1
	add_child(layer)
	var post := ColorRect.new()
	post.material = POST_MAT
	post.anchor_right = 1.0
	post.anchor_bottom = 1.0
	post.mouse_filter = Control.MOUSE_FILTER_IGNORE
	post.add_to_group("post_material")
	layer.add_child(post)

	var pm: ShaderMaterial = POST_MAT
	pm.set_shader_parameter("screen_size", vp)
	pm.set_shader_parameter("scene_tex", _scene_vp.get_texture())
	pm.set_shader_parameter("bloom_tex", _bloom_combine.get_texture())
	pm.set_shader_parameter("reflect_horizon", clampf((board.position.y + board.ground_y) / vp.y, 0.0, 1.0))
	pm.set_shader_parameter("reflect_strength", 0.0 if act.indoor else 0.35)

	await get_tree().process_frame
	await get_tree().process_frame
	GameState.line_index = LINE_INDEX
	GameState.notify_line()

	var t := 0.0
	for i in 110:
		pm.set_shader_parameter("time", t)
		t += 1.0 / 60.0
		await get_tree().process_frame

	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT_PATH)
	print("SHOT SAVED ", OUT_PATH)
	get_tree().quit()


func _make_bloom_vp(sz: Vector2i) -> SubViewport:
	var sv := SubViewport.new()
	sv.size = sz
	sv.disable_3d = true
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var rect := ColorRect.new()
	rect.size = Vector2(sz)
	sv.add_child(rect)
	return sv


func _level_size(vp: Vector2, div: int) -> Vector2i:
	return Vector2i(maxi(1, ceili(vp.x / float(div))), maxi(1, ceili(vp.y / float(div))))
