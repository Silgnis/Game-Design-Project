shader_type canvas_item;

uniform vec3 tint : source_color = vec3(0.82, 0.88, 1.0);
uniform float brightness = 1.15;

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	float luminance = dot(color.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(vec3(luminance) * tint * brightness, color.a);
}
