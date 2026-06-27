class_name Act
extends Resource
## One act of a story: the staging (backdrop, lights, cast), the look and audio knobs, and the
## script of narration lines. The board reads this to build the scene tree for the act.

@export var title: String = ""
@export_range(0.0, 1.0) var ground: float = 0.8
@export var key_light := Vector2(0.3, 0.3)
@export var has_moon := false
@export var moon := Vector2(0.78, 0.18)
@export var indoor := false
@export var blood_rain := false

@export_group("Audio")
@export var ambience: String = ""
@export var ambience_vol: float = 0.4
@export var rain_vol: float = 0.16

@export_group("Staging")
@export var backdrop: Placement
@export var lights: Array[Placement] = []
@export var cast: Array[Placement] = []

@export_group("Script")
@export var lines: Array[Line] = []
