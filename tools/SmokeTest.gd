extends Node
## Headless smoke test: builds every act of every story, sets every line and fires every fx, so all
## object scenes, lighting and weather are exercised at runtime. Run with:
##   Godot --path . --headless tools/SmokeTest.tscn


func _ready() -> void:
	var lib: StoryLibrary = load("res://stories/library.tres")
	for story in lib.stories:
		GameState.load_story(story)
		for i in story.acts.size():
			var act: Act = story.acts[i]
			var board: Board = load("res://scenes/board/Board.tscn").instantiate()
			board.setup(act)
			add_child(board)
			await get_tree().process_frame
			await get_tree().process_frame
			for li in act.lines.size():
				board.set_line(li)
				for fx in act.lines[li].fx:
					board.on_fx(fx)
				await get_tree().process_frame
			print("OK  ", story.subtitle, "  act ", i, " (", act.title, ")  nodes=", board.get_child_count())
			board.queue_free()
			await get_tree().process_frame
	print("SMOKE DONE")
	get_tree().quit()
