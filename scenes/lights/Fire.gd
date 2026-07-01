class_name Fire
extends BoardLight
## A realistic fire light fixture: a procedural noise flame (fire.gdshader) on a base Polygon2D
## plus GPU particle flame tips, a separate ember spark system, three phase-offset PointLight2Ds
## for dancing warm shadows, a wide ground heat pool, and a heat haze zone written to the post
## shader each frame.
##
## Params (from a story Placement):
##   size   float (0.5..4.0)  scale relative to the default barrel-fire size.  default 1.0
##   seed   float             per-instance noise and particle offset.           default 0.0
##   indoor bool              skip the wide heat pool and heat haze when true.  default false
##
## Use as a BoardLight in the Act "lights" array, just like Lamp or Neon.

const _FIRE_SHADER := preload("res://shaders/fire.gdshader")
## The photographed flame base texture (a warm flame on black), warped to life by fire.gdshader.
const _FLAME_TEX := preload("res://art/fire/flame_base.png")

## Design-unit dimensions of the base flame polygon at size == 1.0.
const _BASE_W := 26.0          ## flame polygon half-width in design units
const _BASE_H := 36.0          ## flame polygon height in design units

## Phase offsets for the three dancing-shadow casters, so each pulses at a different moment.
const _PHASE_A := 0.00
const _PHASE_B := 2.09   ## 2π/3
const _PHASE_C := 4.19   ## 4π/3

## Ember micro-light pool: 3 tiny transient PointLight2Ds that pop on briefly above the embers.
const _EMBER_POOL_SIZE := 3

var _fire_size := 1.0
var _seed := 0.0
var _indoor := false

## The primary warm shadow caster at the fire centre.
var _fire_light: PointLight2D
## Two offset shadow casters for the dancing warm shadows.
var _caster_b: PointLight2D
var _caster_c: PointLight2D
## Wide dim ambient heat pool below the fire (ground lighting, no shadows).
var _heat_pool: PointLight2D

## The base flame polygon (stable lower tongue, fire.gdshader).
var _flame_poly: Polygon2D
## Turbulent flame-tip particles that detach from the base and rise.
var _flames: GPUParticles2D
## Separate ember particle system.
var _embers: GPUParticles2D

## Per-instance flicker clocks.
var _t_a := 0.0
var _t_b := 0.0
var _t_c := 0.0

## Ember micro-light pool.
var _ember_lights: Array[PointLight2D] = []
var _ember_cooldown := 0.0

## The post shader material, resolved once in place() from the "post_material" group.
var _post_mat: ShaderMaterial


func on_object_params(p: Dictionary) -> void:
	super.on_object_params(p)
	if p.get("size") != null:
		_fire_size = float(p["size"])
	if p.get("seed") != null:
		_seed = float(p["seed"])
	if p.get("indoor") != null:
		_indoor = p["indoor"] == true


func place() -> void:
	super.place()
	_build_fire()


## Build the fire as an embedded sub-object inside another prop (e.g. BarrelFire). The host owns
## placement, so we keep the given local position rather than repositioning to a board coordinate.
## Call this instead of going through Board._spawn / place() when Fire is a scene child.
func build_embedded(host_board: Board, local_pos: Vector2, p: Dictionary) -> void:
	board = host_board
	on_object_params(p)
	position = local_pos
	_build_fire()


var _built_fire := false

func _build_fire() -> void:
	if _built_fire:
		return
	_built_fire = true
	_build_flame()
	# The photographed flame already carries its own curling tips, so the old additive soft-glow
	# tongue sprites are not built (they read as cheap glowing blobs over a photo flame).
	_build_lights()
	_build_embers()
	_build_ember_pool()
	_resolve_post_mat()
	# offset the phase clocks so multiple fires on the same act are never in lockstep.
	_t_a = _seed * 0.37
	_t_b = _PHASE_B + _seed * 0.53
	_t_c = _PHASE_C + _seed * 0.71


# --- build helpers -----------------------------------------------------------

func _build_flame() -> void:
	# A rectangular quad carrying the photographed flame texture, warped to life by fire.gdshader.
	# Design units: base at y = 0, tip at y = -h, x centred on 0. The flame silhouette comes from the
	# texture (warm flame on black, additive), not from the polygon outline. The quad is taller and a
	# touch narrower than the base box so the flame (and its bloom) reads as a tongue, not a sphere.
	var hw := _BASE_W * _fire_size * 0.42
	var h := _BASE_H * _fire_size * 1.35
	var quad := PackedVector2Array([
		Vector2(-hw, 0.0),
		Vector2(hw, 0.0),
		Vector2(hw, -h),
		Vector2(-hw, -h),
	])
	_flame_poly = Polygon2D.new()
	_flame_poly.name = "FlamePolygon"
	_flame_poly.polygon = quad
	# UV: the base (y = 0) maps to the bottom of the texture (v = 1), the tip (y = -h) to the top.
	_flame_poly.uv = PackedVector2Array([
		Vector2(0.0, 1.0),
		Vector2(1.0, 1.0),
		Vector2(1.0, 0.0),
		Vector2(0.0, 0.0),
	])
	_flame_poly.texture = _FLAME_TEX
	# White so BoardObject treats it as emissive (max channel > 0.6) and skips it as an occluder.
	_flame_poly.color = Color(1.0, 1.0, 1.0, 1.0)
	var mat := ShaderMaterial.new()
	mat.shader = _FIRE_SHADER
	mat.set_shader_parameter("flame_tex", _FLAME_TEX)
	mat.set_shader_parameter("seed_offset", _seed)
	mat.set_shader_parameter("brightness", 1.0)
	mat.set_shader_parameter("flame_speed", 1.15 + _seed * 0.07)
	mat.set_shader_parameter("turbulence", 0.28)
	mat.set_shader_parameter("sway", 0.045)
	_flame_poly.material = mat
	add_child(_flame_poly)


func _build_flame_tips() -> void:
	# Turbulent flame tongues rising off the base flame: additive warm blobs that read as the
	# detached, curling tips of the fire. Layered over the procedural base polygon.
	_flames = GPUParticles2D.new()
	_flames.name = "FlameParticles"
	_flames.amount = max(6, int(12 * _fire_size))
	_flames.lifetime = 0.9 + _fire_size * 0.2
	_flames.preprocess = 1.0 + _seed * 0.3
	_flames.randomness = 0.5
	# Local coords so the design-unit emission and velocities scale uniformly with the node's
	# board.unit scale, the same way the flame polygon does.
	_flames.local_coords = true
	_flames.position = Vector2(0.0, -_BASE_H * _fire_size * 0.25)
	var tex := load("res://src/util/soft_glow.tres") as Texture2D
	if tex:
		_flames.texture = tex
	var mat_path := "res://scenes/lights/fire_flame_material.tres"
	if ResourceLoader.exists(mat_path):
		_flames.process_material = load(mat_path)
	var draw_mat := CanvasItemMaterial.new()
	draw_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_flames.material = draw_mat
	# Warm modulate; kept light so the detached tongues read over the photographed flame, not on top.
	_flames.modulate = Color(1.0, 0.62, 0.22, 0.45)
	add_child(_flames)


func _build_lights() -> void:
	# All positions and texture scales are in design units: the node's board.unit scale converts
	# them to pixels, the same way the flame polygon and every other BoardObject child works.
	var s := _fire_size

	# Primary shadow caster: sits in the bright core of the photographed flame (a touch above the
	# base). Warm orange, casts proper PCF13 shadows (the main dancing shadow). Energised a little
	# higher than the old procedural flame to match the fuller, brighter photographic source.
	_fire_light = _make_caster(Vector2(0.0, -_BASE_H * s * 0.5), 1.3 * s)
	_light = _fire_light   # BoardLight reads _light for get_light_contributions()

	# Offset casters: positioned left and right of centre, lower energy, different phases.
	# Their spatial offset means a nearby figure gets two shadow edges, giving the dancing illusion.
	_caster_b = _make_caster(Vector2(-8.0 * s, -_BASE_H * s * 0.3), 0.55 * s)
	_caster_c = _make_caster(Vector2( 8.0 * s, -_BASE_H * s * 0.3), 0.55 * s)

	# Heat pool: a wide dim amber ambient below the fire that warms the wet floor and lower figures.
	# No shadows (soft fill) so it does not cut a dark wedge through nearby props.
	if not _indoor:
		_heat_pool = PointLight2D.new()
		_heat_pool.texture = LightTex.radial()
		_heat_pool.position = Vector2(0.0, -8.0 * s)   # just above ground
		# texture_scale in design terms (radius ~ 6.5 * 128 design units), node scale -> pixels.
		_heat_pool.texture_scale = 6.5 * s
		_heat_pool.energy = 0.38 * s
		_heat_pool.color = Color(1.0, 0.55, 0.12)
		_heat_pool.blend_mode = Light2D.BLEND_MODE_ADD
		LightKit.ambient(_heat_pool)
		add_child(_heat_pool)


func _make_caster(pos: Vector2, energy: float) -> PointLight2D:
	var lt := PointLight2D.new()
	lt.texture = LightTex.radial()
	lt.position = pos
	# Radius proportional to fire size (design units): a bigger fire throws light further.
	lt.texture_scale = 2.8 + _fire_size * 1.4
	lt.energy = energy
	lt.color = Color(1.0, 0.53, 0.14)   # warm amber-orange
	lt.blend_mode = Light2D.BLEND_MODE_ADD
	LightKit.caster(lt, LightKit.FIRE, 2.8)
	add_child(lt)
	return lt


func _build_embers() -> void:
	# The ember GPUParticles2D: fast-rising, widely spread orange sparks that arc above the flame.
	# Each ember is small, bright white-to-orange, additive, so it reads as a live spark.
	_embers = GPUParticles2D.new()
	_embers.name = "EmberParticles"
	# Particle count scales with fire size.
	_embers.amount = max(6, int(14 * _fire_size))
	_embers.lifetime = 1.4 + _fire_size * 0.3
	_embers.preprocess = 1.0 + _seed * 0.4
	_embers.randomness = 0.6
	_embers.local_coords = true
	_embers.position = Vector2(0.0, -_BASE_H * _fire_size * 0.5)
	# Particle texture: the shared soft glow (tiny white radial dot).
	var ember_tex := load("res://src/util/soft_glow.tres") as Texture2D
	if ember_tex:
		_embers.texture = ember_tex
	# Process material from the .tres file (authored separately so it is inspector-editable).
	var mat_path := "res://scenes/lights/fire_ember_material.tres"
	if ResourceLoader.exists(mat_path):
		_embers.process_material = load(mat_path)
	# Additive so embers look like hot particles against the dark scene.
	var draw_mat := CanvasItemMaterial.new()
	draw_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_embers.material = draw_mat
	_embers.modulate = Color(1.0, 0.7, 0.25, 1.0)
	add_child(_embers)


func _build_ember_pool() -> void:
	# Three pooled tiny PointLight2Ds that briefly pop on when an ember is rising.
	# Energy starts at 0; on_tick() tweens one on then off over 0.06 s for a micro-flash.
	for i in _EMBER_POOL_SIZE:
		var el := PointLight2D.new()
		el.texture = LightTex.radial()
		# Small radius in design units (a spark glow), node scale -> pixels.
		el.texture_scale = (0.35 + randf() * 0.25) * _fire_size
		el.energy = 0.0
		el.color = LightKit.SPARK
		el.blend_mode = Light2D.BLEND_MODE_ADD
		LightKit.ambient(el)   # ember flashes cast no shadows (they are too brief and small)
		add_child(el)
		_ember_lights.append(el)


func _resolve_post_mat() -> void:
	if _indoor:
		return
	# The post ColorRect is in the "post_material" group (added by Main.gd in _ready).
	var nodes := get_tree().get_nodes_in_group("post_material")
	for n in nodes:
		if n is ColorRect and (n as ColorRect).material is ShaderMaterial:
			_post_mat = (n as ColorRect).material
			# Write the heat haze radius for this fire. Scale the radius by fire size
			# in screen UV (0.5 board width at max, clamped to 0.25 for a barrel-scale fire).
			var base_radius := clampf(_fire_size * 0.055, 0.02, 0.25)
			_post_mat.set_shader_parameter("heat_radius", base_radius)
			_post_mat.set_shader_parameter("heat_amount", 0.55 * _fire_size)
			# Let the flame keep its photographic warmth: the grade is eased inside the keep zone.
			_post_mat.set_shader_parameter("fire_keep_amount", 0.8)
			return


# --- per-frame animation -----------------------------------------------------

func on_tick() -> void:
	if not _built_fire:
		return
	var dt := get_process_delta_time()

	# Phase-offset sine flicker for the three shadow casters.
	# The frequencies are slightly different so they never land on the same peak simultaneously.
	_t_a += dt * Palette.FLICKER_SPEED * 1.0
	_t_b += dt * Palette.FLICKER_SPEED * 0.73
	_t_c += dt * Palette.FLICKER_SPEED * 0.59

	if _fire_light:
		var base_e := _base_energy if _base_energy > 0.001 else 1.15
		var fa := _flicker_val(_t_a, 0.78, 0.22, 0.08)
		_fire_light.energy = base_e * fa

	if _caster_b:
		var fb := _flicker_val(_t_b, 0.78, 0.22, 0.06)
		_caster_b.energy = (_base_energy * 0.5 if _base_energy > 0.001 else 0.55) * fb

	if _caster_c:
		var fc := _flicker_val(_t_c, 0.78, 0.22, 0.06)
		_caster_c.energy = (_base_energy * 0.5 if _base_energy > 0.001 else 0.55) * fc

	# Heat pool does not flicker (it is the steady heat of the fire, not the dancing flame).

	# Heat haze: update the post shader with our screen-space position each frame.
	_update_heat_haze()

	# Ember micro-light pool: occasionally pop one on.
	_ember_cooldown -= dt
	if _ember_cooldown <= 0.0 and not _ember_lights.is_empty():
		_ember_cooldown = randf_range(0.06, 0.22)
		_pop_ember_light()


## A smooth flicker value built from a sum of two sines (different frequencies, one with noise).
static func _flicker_val(t: float, base: float, amp: float, noise: float) -> float:
	return base + amp * (sin(t) * 0.5 + 0.5) + randf() * noise


func _update_heat_haze() -> void:
	if _post_mat == null or _indoor:
		return
	# Convert the fire's global position to screen UV.
	var vp := get_viewport()
	if vp == null:
		return
	var vp_size := vp.get_visible_rect().size
	if vp_size.x < 1.0 or vp_size.y < 1.0:
		return
	# Local design units -> screen pixels, so the flame's real footprint (including the host barrel's
	# scale and the camera) drives the zone size, not just board.unit.
	var to_screen := vp.get_canvas_transform() * global_transform
	var uv := (to_screen * Vector2.ZERO) / vp_size
	var flame_h_uv := absf(to_screen.basis_xform(Vector2(0.0, -_BASE_H * _fire_size)).y) / vp_size.y
	var flame_hw_uv := absf(to_screen.basis_xform(Vector2(_BASE_W * _fire_size * 0.5, 0.0)).x) / vp_size.x
	# Place the haze zone above the fire centre (offset upward by half the flame height in screen uv).
	uv.y -= flame_h_uv * 0.5
	_post_mat.set_shader_parameter("heat_pos", uv)
	# The fire-keep mask tracks the same flame centre, sized to the flame's screen footprint.
	_post_mat.set_shader_parameter("fire_keep_pos", uv)
	_post_mat.set_shader_parameter("fire_keep_radius", clampf(flame_hw_uv * 1.6, 0.02, 0.3))
	_post_mat.set_shader_parameter("fire_keep_height", clampf(flame_h_uv * 0.65, 0.02, 0.5))


func _pop_ember_light() -> void:
	# Find a resting micro-light (energy ~= 0) and flare it briefly.
	for el in _ember_lights:
		if el.energy < 0.05:
			# Random position (design units) within the ember rise zone above the flame.
			var half_w := _BASE_W * _fire_size * 0.5
			var h_range := _BASE_H * _fire_size
			el.position = Vector2(
				randf_range(-half_w, half_w),
				-(_BASE_H * _fire_size * 0.5 + randf_range(0.0, h_range * 0.6))
			)
			var peak := randf_range(0.55, 1.1)
			var tw := el.create_tween()
			tw.tween_property(el, "energy", peak, 0.025)
			tw.tween_property(el, "energy", 0.0, 0.055)
			return


## Called by Board.gd at act end; clears the heat haze so it does not bleed into the next act.
func _exit_tree() -> void:
	if _post_mat:
		_post_mat.set_shader_parameter("heat_radius", 0.0)
		_post_mat.set_shader_parameter("fire_keep_radius", 0.0)
		_post_mat.set_shader_parameter("heat_amount", 0.0)
