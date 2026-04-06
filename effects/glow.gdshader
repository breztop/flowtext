shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float glow_intensity : hint_range(0.0, 5.0) = 1.5;
uniform float glow_size : hint_range(0.001, 0.15) = 0.03;
uniform float glow_softness : hint_range(0.1, 2.0) = 0.8;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	vec4 glow = vec4(0.0);
	float total_weight = 0.0;

	// Multi-layer glow: 3 layers x 16 samples for rich, soft glow
	for (float layer = 1.0; layer <= 3.0; layer++) {
		float r = glow_size * layer / 3.0;
		float lw = 1.0 / layer;
		for (float i = 0.0; i < 16.0; i++) {
			float angle = (i / 16.0) * 6.28318530718;
			vec2 offset = vec2(cos(angle), sin(angle)) * r;
			float w = exp(-length(offset) / (glow_size * glow_softness)) * lw;
			glow += texture(TEXTURE, UV + offset) * w;
			total_weight += w;
		}
	}

	if (total_weight > 0.0) {
		glow /= total_weight;
	}

	vec4 g = glow * glow_color * glow_intensity;
	COLOR.rgb = tex_color.rgb + g.rgb * (1.0 - tex_color.a * 0.3);
	COLOR.a = max(tex_color.a, g.a * 0.6);
}
