extends Node2D
## A natively rendered noir act. Everything is real Godot 2D: CanvasModulate for the global
## wash, PointLight2D lights with LightOccluder2D cast shadows, GPUParticles2D rain and fog,
## an emissive neon that blooms via the WorldEnvironment glow. Driven by a config dict set by
## Main before it is added to the tree. fx events (lightning, muzzle, blood) are handled here.

signal shake_requested(amount: float)

var config := {}

var _size: Vector2
var _ground_y: float
var _rng := RandomNumberGenerator.new()

var _rain: GPUParticles2D
var _flash: Sprite2D
var _bolt: Line2D
var _lightning_light: PointLight2D
var _red_rain := false


func _ready() -> void:
	_size = get_viewport_rect().size
	if _size.x < 2.0:
		_size = Vector2(1280, 720)
	_ground_y = _size.y * float(config.get("ground", 0.8))
	_rng.seed = int(config.get("seed", 12345))
	_red_rain = bool(config.get("blood_rain", false))

	_build_wash()
	_build_sky()
	_build_skyline()
	_build_ground()
	_build_lights()
	_build_figure()
	if not bool(config.get("indoor", false)):
		_build_rain()
	_build_fog()
	_build_lightning_nodes()


# --- base look ----------------------------------------------------------

func _build_wash() -> void:
	var cm := CanvasModulate.new()
	cm.color = Color(0.40, 0.45, 0.58) if not bool(config.get("indoor", false)) else Color(0.5, 0.46, 0.42)
	add_child(cm)


func _build_sky() -> void:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	g.colors = PackedColorArray([Palette.SKY_TOP, Palette.SKY_MID, Palette.SKY_LOW])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = int(_size.x)
	t.height = int(_size.y)
	t.fill_from = Vector2(0, 0)
	t.fill_to = Vector2(0, 1)
	var sky := Sprite2D.new()
	sky.texture = t
	sky.centered = false
	sky.z_index = -100
	add_child(sky)

	if bool(config.get("moon", false)):
		var moon := Sprite2D.new()
		moon.texture = FXUtil.soft_dot_texture(192)
		moon.modulate = Palette.MOON
		moon.position = Vector2(_size.x * 0.78, _size.y * 0.2)
		moon.z_index = -90
		add_child(moon)


func _build_skyline() -> void:
	# two parallax-ready silhouette bands, far darker than near
	_skyline_band(_ground_y, _size.y * 0.28, _size.y * 0.50, Palette.FAR_INK, -80, 0.40)
	_skyline_band(_ground_y, _size.y * 0.18, _size.y * 0.34, Palette.MID_INK, -70, 0.0)


func _skyline_band(base_y: float, min_h: float, max_h: float, col: Color, z: int, lit_chance: float) -> void:
	var poly := PackedVector2Array()
	poly.append(Vector2(0, base_y))
	var x := 0.0
	var lit_windows := PackedVector2Array()
	while x < _size.x:
		var w := _rng.randf_range(_size.x * 0.05, _size.x * 0.11)
		var h := _rng.randf_range(min_h, max_h)
		var top := base_y - h
		poly.append(Vector2(x, top))
		poly.append(Vector2(x + w, top))
		# windows
		if lit_chance > 0.0:
			var wy := top + 14.0
			while wy < base_y - 16.0:
				var wx := x + 8.0
				while wx < x + w - 10.0:
					if _rng.randf() < lit_chance * 0.35:
						lit_windows.append(Vector2(wx, wy))
					wx += 14.0
				wy += 18.0
		x += w
	poly.append(Vector2(_size.x, base_y))
	var p := Polygon2D.new()
	p.polygon = poly
	p.color = col
	p.z_index = z
	add_child(p)

	for wpos in lit_windows:
		var win := Sprite2D.new()
		win.texture = FXUtil.soft_dot_texture(16)
		win.scale = Vector2(0.5, 0.7)
		win.position = wpos
		win.modulate = Palette.WARM_WIN if _rng.randf() < 0.6 else Palette.COOL_WIN
		win.z_index = z + 1
		add_child(win)


func _build_ground() -> void:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Palette.NEAR_INK, Palette.INK])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = int(_size.x)
	t.height = int(_size.y - _ground_y)
	t.fill_from = Vector2(0, 0)
	t.fill_to = Vector2(0, 1)
	var floor_spr := Sprite2D.new()
	floor_spr.texture = t
	floor_spr.centered = false
	floor_spr.position = Vector2(0, _ground_y)
	floor_spr.z_index = -50
	add_child(floor_spr)


# --- lighting -----------------------------------------------------------

func _make_light(pos: Vector2, col: Color, energy: float, scale: float, shadows := false) -> PointLight2D:
	var l := PointLight2D.new()
	l.texture = FXUtil.radial_light_texture(256)
	l.texture_scale = scale
	l.color = col
	l.energy = energy
	l.blend_mode = Light2D.BLEND_MODE_ADD
	l.position = pos
	l.shadow_enabled = shadows
	if shadows:
		l.shadow_filter = Light2D.SHADOW_FILTER_PCF5
		l.shadow_filter_smooth = 3.0
		l.shadow_color = Color(0, 0, 0, 0.7)
	add_child(l)
	return l


func _build_lights() -> void:
	# street lamp: warm key light that casts the figure's shadow
	if bool(config.get("lamp", true)):
		var lamp_x := _size.x * float(config.get("lamp_x", 0.3))
		var post := Polygon2D.new()
		post.polygon = PackedVector2Array([
			Vector2(lamp_x - 3, _ground_y),
			Vector2(lamp_x - 3, _ground_y - _size.y * 0.42),
			Vector2(lamp_x + 3, _ground_y - _size.y * 0.42),
			Vector2(lamp_x + 3, _ground_y),
		])
		post.color = Palette.INK
		post.z_index = -10
		add_child(post)
		var bulb_pos := Vector2(lamp_x, _ground_y - _size.y * 0.42)
		var bulb := Sprite2D.new()
		bulb.texture = FXUtil.soft_dot_texture(48)
		bulb.modulate = Color(1.6, 1.4, 1.0)  # > 1 so it blooms
		bulb.position = bulb_pos
		add_child(bulb)
		_make_light(bulb_pos, Color(1.0, 0.86, 0.6), 1.6, 4.0, true)

	# neon sign: emissive body + coloured light + wet-floor reflection
	if config.has("neon"):
		var n: Dictionary = config["neon"]
		var nx := _size.x * float(n.get("x", 0.66))
		var ny := _size.y * float(n.get("y", 0.42))
		var ncol: Color = n.get("color", Palette.RED_HOT)
		var body := Polygon2D.new()
		body.polygon = PackedVector2Array([
			Vector2(nx - 70, ny - 22), Vector2(nx + 70, ny - 22),
			Vector2(nx + 70, ny + 22), Vector2(nx - 70, ny + 22),
		])
		body.color = ncol * 1.8  # HDR for bloom
		add_child(body)
		_make_light(Vector2(nx, ny), ncol, 2.0, 3.2, false)
		# reflection streak on the wet floor
		var refl := Sprite2D.new()
		refl.texture = FXUtil.radial_light_texture(128)
		refl.modulate = Color(ncol.r, ncol.g, ncol.b, 0.5)
		refl.position = Vector2(nx, _ground_y + (_size.y - _ground_y) * 0.35)
		refl.scale = Vector2(1.2, (_size.y - _ground_y) / 64.0)
		refl.z_index = -40
		add_child(refl)

	# searchlight beam (rooftop scenes)
	if bool(config.get("searchlight", false)):
		var beam := Polygon2D.new()
		beam.polygon = PackedVector2Array([
			Vector2(_size.x * 0.5, _size.y),
			Vector2(_size.x * 0.5 - 70, 0),
			Vector2(_size.x * 0.5 + 70, 0),
		])
		beam.color = Color(0.75, 0.8, 0.86, 0.08)
		beam.z_index = -85
		add_child(beam)


# --- figure -------------------------------------------------------------

func _build_figure() -> void:
	var fx := _size.x * float(config.get("figure_x", 0.52))
	var poly := PackedVector2Array([
		Vector2(fx - 22, _ground_y),
		Vector2(fx - 18, _ground_y - 92),
		Vector2(fx - 26, _ground_y - 96),
		Vector2(fx - 13, _ground_y - 120),  # hat brim left
		Vector2(fx - 10, _ground_y - 132),
		Vector2(fx + 10, _ground_y - 132),
		Vector2(fx + 13, _ground_y - 120),  # hat brim right
		Vector2(fx + 26, _ground_y - 96),
		Vector2(fx + 18, _ground_y - 92),
		Vector2(fx + 22, _ground_y),
	])
	var fig := Polygon2D.new()
	fig.polygon = poly
	fig.color = Palette.INK
	fig.z_index = 5
	add_child(fig)

	# real cast shadow: an occluder matching the silhouette
	var occ := LightOccluder2D.new()
	var op := OccluderPolygon2D.new()
	op.polygon = poly
	op.closed = true
	occ.occluder = op
	add_child(occ)

	# selective-colour accent (a red scarf) that survives the desaturation
	if bool(config.get("red_accent", true)):
		var scarf := Polygon2D.new()
		scarf.polygon = PackedVector2Array([
			Vector2(fx - 12, _ground_y - 96),
			Vector2(fx + 12, _ground_y - 96),
			Vector2(fx + 8, _ground_y - 84),
			Vector2(fx - 8, _ground_y - 84),
		])
		scarf.color = Palette.RED_HOT
		scarf.z_index = 6
		add_child(scarf)


# --- weather ------------------------------------------------------------

func _build_rain() -> void:
	_rain = GPUParticles2D.new()
	_rain.texture = FXUtil.streak_texture()
	_rain.amount = 420
	_rain.lifetime = 1.1
	_rain.preprocess = 1.1
	_rain.position = Vector2(_size.x * 0.5, -20)
	_rain.z_index = 50
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(_size.x * 0.75, 4, 0)
	pm.direction = Vector3(-0.25, 1, 0)
	pm.spread = 2.0
	pm.initial_velocity_min = 900.0
	pm.initial_velocity_max = 1150.0
	pm.gravity = Vector3(0, 600, 0)
	pm.scale_min = 0.7
	pm.scale_max = 1.3
	var rc := Palette.RED if _red_rain else Color(0.78, 0.84, 0.95)
	pm.color = Color(rc.r, rc.g, rc.b, Palette.RAIN_ALPHA)
	_rain.process_material = pm
	add_child(_rain)


func _build_fog() -> void:
	var fog := GPUParticles2D.new()
	fog.texture = FXUtil.soft_dot_texture(128)
	fog.amount = 22
	fog.lifetime = 9.0
	fog.preprocess = 9.0
	fog.position = Vector2(_size.x * 0.5, _ground_y - 30)
	fog.z_index = 40
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(_size.x * 0.6, 30, 0)
	pm.direction = Vector3(1, 0, 0)
	pm.spread = 10.0
	pm.initial_velocity_min = 8.0
	pm.initial_velocity_max = 22.0
	pm.gravity = Vector3.ZERO
	pm.scale_min = 6.0
	pm.scale_max = 12.0
	pm.color = Color(0.7, 0.75, 0.85, 0.05)
	fog.process_material = pm
	fog.material = _additive_canvas_material()
	add_child(fog)


func _additive_canvas_material() -> CanvasItemMaterial:
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return m


# --- fx events ----------------------------------------------------------

func _build_lightning_nodes() -> void:
	_flash = Sprite2D.new()
	_flash.texture = _white_texture()
	_flash.centered = false
	_flash.scale = _size
	_flash.modulate = Color(1, 1, 1, 0)
	_flash.z_index = 60
	_flash.material = _additive_canvas_material()
	add_child(_flash)

	_bolt = Line2D.new()
	_bolt.width = 3.0
	_bolt.default_color = Color(0.85, 0.92, 1.0)
	_bolt.z_index = 61
	_bolt.visible = false
	add_child(_bolt)

	_lightning_light = _make_light(Vector2(_size.x * 0.5, _size.y * 0.1), Color(0.8, 0.88, 1.0), 0.0, 9.0, false)


func _white_texture() -> ImageTexture:
	var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	img.set_pixel(0, 0, Color.WHITE)
	return ImageTexture.create_from_image(img)


func on_fx(name: String) -> void:
	match name:
		"lightning":
			_strike_lightning()
		"muzzle":
			AudioDirector.gun()
			_flash.modulate.a = 0.5
			create_tween().tween_property(_flash, "modulate:a", 0.0, 0.4)
			shake_requested.emit(8.0)
		"blood":
			_red_rain = true
			if _rain:
				var pm: ParticleProcessMaterial = _rain.process_material
				pm.color = Color(Palette.RED.r, Palette.RED.g, Palette.RED.b, Palette.RAIN_ALPHA + 0.2)
		"lighter":
			AudioDirector.lid_open()
			get_tree().create_timer(0.65).timeout.connect(AudioDirector.flint)


func _strike_lightning() -> void:
	if bool(config.get("indoor", false)):
		return
	var x := _rng.randf_range(_size.x * 0.25, _size.x * 0.75)
	var pts := PackedVector2Array([Vector2(x, 0)])
	var y := 0.0
	while y < _size.y * 0.6:
		x += _rng.randf_range(-50, 50)
		y += _size.y * 0.6 / 9.0
		pts.append(Vector2(x, y))
	_bolt.points = pts
	_bolt.visible = true
	_flash.modulate.a = 0.55
	_lightning_light.position = Vector2(x, _size.y * 0.1)
	_lightning_light.energy = 2.2
	var tw := create_tween()
	tw.tween_property(_flash, "modulate:a", 0.0, 0.45)
	tw.parallel().tween_property(_lightning_light, "energy", 0.0, 0.45)
	tw.tween_callback(func(): _bolt.visible = false)
	get_tree().create_timer(0.2 + _rng.randf() * 0.3).timeout.connect(AudioDirector.thunder)
