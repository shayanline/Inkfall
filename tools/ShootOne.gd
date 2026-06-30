extends Node
## Fast single-act capture. Loads the real Main, jumps straight to one act and line WITHOUT the
## transition flow (which stalls when the window is backgrounded), waits for the look to settle, then
## saves one PNG. Drive it with env vars so a shell can sweep acts:
##   STORY=0 ACT=1 LINE=3 OUT=/tmp/x.png Godot --path . tools/ShootOne.tscn
## Not part of the game. Safe to delete.

var _main: Node


func _ready() -> void:
	var story_idx := int(OS.get_environment("STORY")) if OS.get_environment("STORY") != "" else 0
	var act_idx := int(OS.get_environment("ACT")) if OS.get_environment("ACT") != "" else 0
	var line_idx := int(OS.get_environment("LINE")) if OS.get_environment("LINE") != "" else 0
	var out := OS.get_environment("OUT") if OS.get_environment("OUT") != "" else "/tmp/shootone.png"

	_main = load("res://scenes/core/Main.tscn").instantiate()
	add_child(_main)
	await get_tree().process_frame
	await get_tree().process_frame

	var lib: StoryLibrary = load("res://stories/library.tres")
	var story: Story = lib.stories[story_idx]
	GameState.load_story(story)
	_main._start.visible = false
	_main._hud.visible = false

	GameState.go_to_act(act_idx)
	var act: Act = GameState.current_act()
	_main._swap_board(act)
	_main._playing = true
	for i in line_idx:
		if GameState.has_next_line():
			GameState.next_line()
	GameState.notify_line()
	_main._fire_line_fx()

	# let the lights, ripples and the cold-start neon ignite settle
	await get_tree().create_timer(1.6).timeout
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(out)
	print("SHOTONE ", out)
	get_tree().quit()
