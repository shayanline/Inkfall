extends Node
## The flow/data model. Holds the loaded story (pure data), the current act and the current
## script line. It never touches the visual tree, Main reads it and drives the view. This keeps
## stories portable, the Inkfall idea: behaviour is data, not engine edits.

var story := {}
var scene_index := 0
var line_index := 0


func load_story(s: Dictionary) -> void:
	story = s
	scene_index = 0
	line_index = 0


func scenes() -> Array:
	return story.get("scenes", [])


func scene_count() -> int:
	return scenes().size()


func current_scene() -> Dictionary:
	var list := scenes()
	if scene_index < 0 or scene_index >= list.size():
		return {}
	return list[scene_index]


func script_lines() -> Array:
	return current_scene().get("script", [])


func current_line() -> Dictionary:
	var lines := script_lines()
	if line_index < 0 or line_index >= lines.size():
		return {}
	return lines[line_index]


func has_next_line() -> bool:
	return line_index < script_lines().size() - 1


func next_line() -> void:
	line_index += 1


func at_last_scene() -> bool:
	return scene_index >= scene_count() - 1


func go_to_scene(idx: int) -> void:
	scene_index = clamp(idx, 0, scene_count() - 1)
	line_index = 0


func scene_titles() -> Array[String]:
	var out: Array[String] = []
	for s in scenes():
		out.append(String(s.get("title", "SCENE")))
	return out
