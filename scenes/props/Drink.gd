class_name Drink
extends BoardObject
## A bar drink in one of two glasses: a square tumbler of amber whiskey (the default) or a martini
## cone with an olive. Both glasses are authored in the scene, this script reveals the one named by
## the kind param and hides the other.

@export var kind := "whiskey"


func _ready() -> void:
	var martini := get_node_or_null("Martini")
	var whiskey := get_node_or_null("Whiskey")
	var is_martini := kind == "martini"
	if martini:
		martini.visible = is_martini
	if whiskey:
		whiskey.visible = not is_martini
