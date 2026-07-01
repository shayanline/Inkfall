shader_type canvas_item;
render_mode blend_add;
// Hybrid fire shader. A real photographed flame texture (a warm flame on black) is sampled through
// an animated domain warp: two-octave FBM noise, scrolling upward over time, displaces the sample
// UV so the still photo writhes and licks like a live flame. The warp is gentle at the base (the
// fire is anchored to the barrel) and strongest at the tip (where flames curl and detach). The
// black background contributes nothing under additive blend, and the flame luminance drives the
// additive coverage, so it reads as emitted light and is caught by the post bloom pass.
//
// gl_compatibility safe: plain texture sampling plus procedural value noise, no mipmap tricks.

// The photographed flame: warm flame on black, tip at the top (v=0), base at the bottom (v=1).
uniform sampler2D flame_tex : source_color, filter_linear, repeat_disable;

// Animation
uniform float flame_speed : hint_range(0.2, 4.0) = 1.25;  // upward scroll speed of the warp field
uniform float turbulence  : hint_range(0.0, 1.0) = 0.28;  // domain-warp amplitude (in UV)
uniform float sway        : hint_range(0.0, 0.2) = 0.045;  // slow whole-flame horizontal sway
uniform float brightness  : hint_range(1.0, 6.0) = 2.6;    // overdrive into the bloom
uniform float seed_offset : hint_range(0.0, 100.0) = 0.0;  // per-instance variation
uniform vec4  tint        : source_color = vec4(1.0, 1.0, 1.0, 1.0); // per-instance warmth nudge


// --- noise helpers (value noise + two-octave FBM) ----------------------------

float hash(vec2 p) {
	p = fract(p * vec2(127.1, 311.7));
	p += dot(p, p + 19.19);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(i),                  hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
		u.y);
}

float fbm(vec2 p) {
	return vnoise(p) * 0.65 + vnoise(p * 2.1 + vec2(3.7, 2.1)) * 0.35;
}


// --- fragment ----------------------------------------------------------------

void fragment() {
	// UV: v = 0 at the tip (top), v = 1 at the base (bottom). hb rises 0 (base) -> 1 (tip).
	float hb = 1.0 - UV.y;

	// A column of noise that scrolls upward over time, so detail rises like real flame.
	float t = TIME * flame_speed + seed_offset;
	vec2 nuv = vec2(UV.x * 2.5 + seed_offset, UV.y * 3.0 - t);
	float nx = fbm(nuv) - 0.5;
	float ny = fbm(nuv * 1.7 + vec2(2.3, 7.1)) - 0.5;

	// Warp grows toward the tip (the base stays planted on the barrel). Add a slow whole-flame sway.
	float amp = turbulence * (0.2 + hb);
	vec2 warp = vec2(
		nx * amp + sin(t * 1.3 + seed_offset) * sway * hb,
		ny * amp * 1.3 - hb * 0.04);
	vec2 suv = UV + warp;

	vec4 src = texture(flame_tex, suv) * tint;

	// A subtle global breathe from the noise field.
	float breathe = 0.85 + 0.15 * fbm(vec2(seed_offset * 1.7, t * 0.7));

	// The photograph drives the SHAPE and DETAIL; intensity i is read from it. But the strong bloom
	// pass clips any near-white core into a flat glowing disc, so the colour is remapped through a
	// controlled fire ramp that tops out at warm yellow, never pure white. The hottest the flame ever
	// gets is amber-yellow, so bloom spreads an amber glow rather than a white ball.
	float i = max(src.r, max(src.g, src.b)) * brightness * breathe;
	// Saturated fire ramp: deep red -> orange -> bright orange. Blue is kept low on purpose so the
	// strong bloom pass spreads an AMBER glow, not a white ball (high green+blue would clip to white).
	vec3 fire = mix(vec3(0.80, 0.10, 0.01), vec3(1.0, 0.42, 0.06), smoothstep(0.12, 0.55, i));
	fire = mix(fire, vec3(1.0, 0.60, 0.14), smoothstep(0.55, 1.0, i));   // hottest = bright orange
	// keep just a trace of the photographic colour for texture, but drive the hue from the fire ramp.
	vec3 col = mix(src.rgb * brightness, fire * i * 1.2, 0.85);

	// Additive coverage from the flame's own intensity: black background adds nothing.
	float alpha = clamp(i, 0.0, 1.0) * 0.8;
	// Dissolve the very tip so it never reads as a hard cropped edge.
	alpha *= smoothstep(1.0, 0.82, hb);

	// vertex COLOR carries the polygon colour; node modulate (the script flicker) is applied by the
	// engine after the shader.
	COLOR = vec4(col, alpha) * COLOR;
}
