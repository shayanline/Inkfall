class_name Story
extends Resource
## A complete tale: the title card copy, the score, and the ordered acts. Telling a new tale is
## writing one of these resources, not editing the board.

@export var title: String = ""
@export var subtitle: String = ""
@export_multiline var blurb: String = ""
@export var music: String = ""
@export var music_vol: float = 0.5
@export var acts: Array[Act] = []
