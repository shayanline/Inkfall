shader_type canvas_item;
// Combine the six pyramid levels into a single bloom texture, which post.gdshader then adds over the
// scene before the grade. The low-res levels are upsampled for free by bilinear sampling at full UV:
// the shallow (larger) levels carry the tight halo flush to the source, the deep (smaller) levels
// carry the wide far-reaching haze. Weighted so the spread reads as a smooth pool rather than a flat
// wash. Runs at half resolution, so post samples one cheap texture instead of six.

uniform sampler2D b0 : filter_linear;
uniform sampler2D b1 : filter_linear;
uniform sampler2D b2 : filter_linear;
uniform sampler2D b3 : filter_linear;
uniform sampler2D b4 : filter_linear;
uniform sampler2D b5 : filter_linear;

void fragment() {
	vec3 c = texture(b0, UV).rgb * 1.0
		+ texture(b1, UV).rgb * 1.0
		+ texture(b2, UV).rgb * 1.0
		+ texture(b3, UV).rgb * 1.1
		+ texture(b4, UV).rgb * 1.2
		+ texture(b5, UV).rgb * 1.3;
	COLOR = vec4(c / 6.6, 1.0);
}
