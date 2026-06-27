class_name Placement
extends Resource
## A scene placed in an act: a backdrop, a light, or a cast member. It points at the object scene
## and carries the authored params applied to that instance when the board builds the act.

@export var scene: PackedScene
@export var params: Dictionary = {}
