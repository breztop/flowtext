shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float glow_intensity : hint_range(0.0, 3.0) = 1.0;
uniform float glow_size : hint_range(0.0, 0.1) = 0.02;
uniform float glow_softness : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	vec4 glow = vec4(0.0);
	
	float samples = 8.0;
	float total_weight = 0.0;
	
	for (float i = 0.0; i < samples; i++) {
		float angle = (i / samples) * 6.28318530718;
		vec2 offset = vec2(cos(angle), sin(angle)) * glow_size;
		
		float dist = length(offset) / glow_size;
		float weight = exp(-dist * dist * 2.0 / glow_softness);
		
		vec4 sample_color = texture(TEXTURE, UV + offset);
		glow += sample_color * weight;
		total_weight += weight;
	}
	
	if (total_weight > 0.0) {
		glow /= total_weight;
	}
	
	vec4 final_glow = glow * glow_color * glow_intensity;
	COLOR = tex_color + final_glow * (1.0 - tex_color.a);
	COLOR.a = max(tex_color.a, final_glow.a);
}