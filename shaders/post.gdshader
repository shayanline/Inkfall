shader_type canvas_item;
// Screen-space comic + noir finish: bloom composite, wet-floor mirror, desaturate/grade, halftone
// (Ben-Day) dots, chromatic aberration, film grain, vignette. The lit scene is rendered into its own
// SubViewport and handed in as scene_tex (not the screen back buffer), so the bloom can sample a
// clean, feedback-free copy of the scene and post never reads its own output.
//
// Compatibility-safe: filter_linear, no mipmaps, no textureLod. The wide glow is built by the bloom
// pyramid (bloom_down + bloom_combine) and arrives here as one ready bloom_tex.
uniform sampler2D scene_tex : filter_linear;

uniform vec2 screen_size = vec2(1280.0, 720.0);
uniform float time = 0.0;

// bloom: the finished glow from the pyramid (bloom_down x6 + bloom_combine), added over the scene
// before the grade so it follows the noir desaturation and cool-tint rules. The pyramid spreads the
// glow far and smooth across the frame, the photographic light pool a bright neon throws into the
// night, which a single-pass gather cannot reach.
uniform sampler2D bloom_tex : filter_linear;
uniform float bloom_intensity : hint_range(0.0, 4.0) = 1.6;

// wet-floor mirror reflection: below the horizon, the scene above is mirrored down with a watery
// wobble and a depth fade. Set per act (strength 0 indoors). horizon is the ground line in screen uv.
uniform float reflect_strength : hint_range(0.0, 1.0) = 0.0;
uniform float reflect_horizon : hint_range(0.0, 1.0) = 0.8;
uniform float reflect_depth : hint_range(0.05, 1.0) = 0.42;

// grade
uniform float desaturate : hint_range(0.0, 1.0) = 0.82;   // 1 = full grayscale
uniform float contrast : hint_range(0.5, 2.0) = 1.12;
uniform vec3 cool_tint : source_color = vec3(0.86, 0.90, 1.0);
uniform float tint_amount : hint_range(0.0, 1.0) = 0.10;

// selective colour keep (lets neon reds and the red coat survive the desaturation)
uniform float keep_red : hint_range(0.0, 1.0) = 0.92;

// halftone
uniform float halftone_amount : hint_range(0.0, 1.0) = 0.18;
uniform float halftone_scale : hint_range(1.0, 12.0) = 3.0;   // dot pitch in px

// chromatic aberration
uniform float aberration : hint_range(0.0, 6.0) = 0.45;

// grain
uniform float grain_amount : hint_range(0.0, 0.3) = 0.05;

// vignette
uniform float vignette : hint_range(0.0, 1.0) = 0.7;

// heat haze: a zone of animated UV warp above a fire source, mimicking the shimmer of hot air.
// heat_pos is the screen UV of the fire centre. heat_radius is the zone radius in UV units (0 = off).
// heat_amount scales the distortion strength. Written each frame by the Fire BoardLight script.
uniform vec2  heat_pos    = vec2(0.5, 0.5);
uniform float heat_radius : hint_range(0.0, 0.5) = 0.0;
uniform float heat_amount : hint_range(0.0, 1.0) = 0.0;

// fire-keep mask: a soft, upward-biased ellipse over the flame where the noir grade is eased back, so
// the photographed fire keeps its warm colour and detail while the rest of the board stays graded.
// Written each frame by the Fire BoardLight script (single zone: with two fires the nearest wins).
uniform vec2  fire_keep_pos    = vec2(0.5, 0.5);
uniform float fire_keep_radius : hint_range(0.0, 0.5) = 0.0;   // horizontal half-extent in uv (0 = off)
uniform float fire_keep_height : hint_range(0.0, 1.0) = 0.0;   // vertical half-extent (the flame is tall)
uniform float fire_keep_amount : hint_range(0.0, 1.0) = 0.0;   // how strongly the flame bypasses the grade

float luma(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

float rand(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 px = 1.0 / screen_size;

	// --- heat haze: animated UV shimmer above a fire source. The warp is applied before everything
	// else so the aberration, bloom and grade all read through the distorted field. A radial Gaussian
	// falloff confines the shimmer to the zone directly above the flame; it fades to zero outside. ---
	if (heat_radius > 0.001 && heat_amount > 0.001) {
		vec2 d = uv - heat_pos;
		// Only apply above the fire (y < heat_pos.y in screen UV, because UV y=0 is the top).
		float vertical_mask = smoothstep(0.0, -heat_radius, uv.y - heat_pos.y);
		float falloff = exp(-dot(d, d) / (heat_radius * heat_radius)) * vertical_mask;
		uv.y += sin(uv.y * 28.0 + time * 9.1) * falloff * heat_amount * 0.004;
		uv.x += cos(uv.x * 22.0 + time * 7.4) * falloff * heat_amount * 0.0025;
	}

	// --- chromatic aberration: offset R/B outward from centre ---
	vec2 dir = uv - vec2(0.5);
	vec2 off = dir * aberration * px;
	vec3 col;
	col.r = texture(scene_tex, uv + off).r;
	col.g = texture(scene_tex, uv).g;
	col.b = texture(scene_tex, uv - off).b;

	// --- wet-floor mirror: below the horizon, blend in the scene above it, mirrored, with a watery
	// wobble that grows with depth and a fade into the dark floor. Reflects signs, cast, moon. ---
	if (reflect_strength > 0.001 && uv.y > reflect_horizon) {
		float depth = uv.y - reflect_horizon;
		float wob = sin(uv.x * 42.0 + time * 1.4) * 0.0016 + sin(uv.y * 90.0 - time * 2.1) * 0.0011;
		vec2 ruv = vec2(uv.x + wob * (0.4 + depth * 4.0), reflect_horizon - depth + wob * 0.6);
		if (ruv.y > 0.0) {
			vec3 refl = texture(scene_tex, ruv).rgb * 0.72;   // wet asphalt darkens the reflection
			float fade = clamp(1.0 - depth / reflect_depth, 0.0, 1.0);
			col = mix(col, refl, fade * fade * reflect_strength);
		}
	}

	// --- fire-keep mask: a soft elliptical zone over the flame, taller than wide and biased upward
	// (the flame rises above its base), where the grade is eased so the fire stays photographic. ---
	float fire_keep = 0.0;
	if (fire_keep_radius > 0.001 && fire_keep_amount > 0.001) {
		vec2 fd = SCREEN_UV - fire_keep_pos;
		float ry = max(fire_keep_height, 0.001);
		// above the centre the flame reaches full height; below it falls off fast (down into the base).
		float vy = (fd.y < 0.0) ? fd.y / ry : fd.y / (ry * 0.35);
		float vx = fd.x / max(fire_keep_radius, 0.001);
		fire_keep = exp(-(vx * vx + vy * vy) * 2.2) * fire_keep_amount;
	}

	// --- bloom: the finished pyramid glow, added before the grade so it follows the noir grade. The
	// glow is genuine (gathered from the lit scene through a downsample blur chain), wide and smooth,
	// not a ring clamped to the source. Sampled by the warped uv so the heat haze bends it too. The
	// bloom is damped inside the fire-keep zone so the flame reads as a shaped tongue, not a blown-out
	// glowing ball (lamps and neon outside the zone keep their full glow). ---
	col += texture(bloom_tex, uv).rgb * bloom_intensity * (1.0 - fire_keep * 0.7);

	// --- grade: contrast, desaturate with a selective colour keep, cool tint ---
	col = (col - 0.5) * contrast + 0.5;
	float l = luma(col);
	// protect saturated colours (neon reds, yellows, the red coat) from the desaturate: the more
	// saturated a pixel is, the less desaturation it receives. This lets the noir grade crush
	// neutrals to grey while neon colours bleed through vivid.
	float mx = max(max(col.r, col.g), col.b);
	float mn = min(min(col.r, col.g), col.b);
	float sat = (mx > 0.001) ? (mx - mn) / mx : 0.0;
	// only protect colours above a saturation floor (neon, the red coat), let low-sat tones
	// (city windows, sky) desaturate fully into noir grey
	float sat_keep = smoothstep(0.3, 0.7, sat);
	float desat = desaturate * (1.0 - keep_red * sat_keep);
	// the flame zone keeps its colour: ease the desaturation toward zero inside the mask.
	desat *= (1.0 - fire_keep);
	col = mix(col, vec3(l), desat);
	col = mix(col, col * cool_tint, tint_amount);

	// --- halftone: dot pattern modulating the shadows, like comic print ---
	vec2 grid = SCREEN_UV * screen_size / halftone_scale;
	vec2 cell = fract(grid) - 0.5;
	float dot_d = length(cell);
	float tone = luma(col);
	float dot_r = (1.0 - tone) * 0.5;            // darker areas get bigger dots
	float dotmask = smoothstep(dot_r, dot_r - 0.15, dot_d);
	// drop the Ben-Day dots over the flame so the fire reads as smooth, not printed.
	col = mix(col, col * (0.55 + 0.45 * dotmask), halftone_amount * (1.0 - fire_keep));

	// --- film grain ---
	float g = rand(SCREEN_UV * screen_size + vec2(time * 53.0, time * 11.0));
	col += (g - 0.5) * grain_amount;

	// --- vignette ---
	float d = distance(uv, vec2(0.5));
	float v = smoothstep(0.75, 0.35, d);
	col *= mix(1.0, v, vignette);

	COLOR = vec4(clamp(col, 0.0, 1.0), 1.0);
}
