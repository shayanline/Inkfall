class_name Line
extends Resource
## One beat of narration: the caption shown and any fx events fired on this line.
## Text accepts simple emphasis, and <b>..</b> prints in blood red.

@export_multiline var text: String = ""
@export var fx: PackedStringArray = PackedStringArray()
