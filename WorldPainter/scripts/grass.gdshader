shader_type spatial;
render_mode cull_disabled, unshaded, shadows_disabled;

uniform float root_level:hint_range(0, 20);
uniform vec3 color_root:source_color;
uniform vec3 color_top:source_color;
uniform vec3 color_top_variant:source_color;
uniform sampler2D noise_map;
uniform sampler2D splash_map;

varying vec3 world_pos;


void vertex(){
	VERTEX.x += sin(NODE_POSITION_WORLD.x + TIME * 1.25 + UV.y) * ( 1.0 - UV.y) * 0.2;
	VERTEX.z += cos(NODE_POSITION_WORLD.z + TIME * 0.45 + UV.y) * ( 1.0 - UV.y) * 0.15;

	// Vertex to world space
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Recolor noise map to grass variant colors
	vec3 map = texture(noise_map, world_pos.xz).rgb;
	vec3 top_variant = mix(color_top, color_top_variant, map.r);

	// Paints grass top and bottom sepparately
	float gradient = pow(UV.y, root_level);
	vec3 bottom = color_root * gradient;
	vec3 top = top_variant * (1.0-gradient);
	ALBEDO = top + bottom;
}
