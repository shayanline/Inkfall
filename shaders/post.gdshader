shader_type canvas_item;
// Screen-space comic + noir finish: desaturate/grade, halftone (Ben-Day) dots,
// chromatic aberration, film grain, vignette. Reads the screen via the back buffer,
// so it must sit on a full-rect ColorRect under a BackBufferCopy(copy_mode = Viewport).

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;

uniform vec2 screen_size = vec2(1280.0, 720.0);
uniform float time = 0.0;

// grade
uniform float desaturate : hint_range(0.0, 1.0) = 0.82;   // 1 = full grayscale
uniform float contrast : hint_range(0.5, 2.0) = 1.12;
uniform vec3 cool_tint : source_color = vec3(0.86, 0.90, 1.0);
uniform float tint_amount : hint_range(0.0, 1.0) = 0.10;

// selective colour keep (lets a red coat survive the desaturation)
uniform float keep_red : hint_range(0.0, 1.0) = 0.7;

// halftone
uniform float halftone_amount : hint_range(0.0, 1.0) = 0.18;
uniform float halftone_scale : hint_range(1.0, 12.0) = 3.0;   // dot pitch in px

// chromatic aberration
uniform float aberration : hint_range(0.0, 6.0) = 1.1;

// grain
uniform float grain_amount : hint_range(0.0, 0.3) = 0.05;

// vignette
uniform float vignette : hint_range(0.0, 1.0) = 0.7;

float luma(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

float rand(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 px = 1.0 / screen_size;

	// --- chromatic aberration: offset R/B outward from centre ---
	vec2 dir = uv - vec2(0.5);
	vec2 off = dir * aberration * px;
	vec3 col;
	col.r = texture(screen_tex, uv + off).r;
	col.g = texture(screen_tex, uv).g;
	col.b = texture(screen_tex, uv - off).b;

	// --- grade: contrast, desaturate with a selective red keep, cool tint ---
	col = (col - 0.5) * contrast + 0.5;
	float l = luma(col);
	float redness = clamp(col.r - max(col.g, col.b), 0.0, 1.0);
	float desat = desaturate * (1.0 - keep_red * redness);
	col = mix(col, vec3(l), desat);
	col = mix(col, col * cool_tint, tint_amount);

	// --- halftone: dot pattern modulating the shadows, like comic print ---
	vec2 grid = SCREEN_UV * screen_size / halftone_scale;
	vec2 cell = fract(grid) - 0.5;
	float dot_d = length(cell);
	float tone = luma(col);
	float dot_r = (1.0 - tone) * 0.5;            // darker areas get bigger dots
	float dotmask = smoothstep(dot_r, dot_r - 0.15, dot_d);
	col = mix(col, col * (0.55 + 0.45 * dotmask), halftone_amount);

	// --- film grain ---
	float g = rand(SCREEN_UV * screen_size + vec2(time * 53.0, time * 11.0));
	col += (g - 0.5) * grain_amount;

	// --- vignette ---
	float d = distance(uv, vec2(0.5));
	float v = smoothstep(0.75, 0.35, d);
	col *= mix(1.0, v, vignette);

	COLOR = vec4(clamp(col, 0.0, 1.0), 1.0);
}
