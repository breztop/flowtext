shader_type canvas_item;

uniform vec4 color_start : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform vec4 color_end : source_color = vec4(0.0, 0.0, 1.0, 1.0);
uniform float gradient_speed : hint_range(0.0, 5.0) = 1.0;
uniform bool animate = false;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	
	float t = UV.x;
	if (animate) {
		t = fract(UV.x + TIME * gradient_speed);
	}
	
	vec4 gradient_color = mix(color_start, color_end, t);
	COLOR = vec4(gradient_color.rgb, tex_color.a * gradient_color.a);
}