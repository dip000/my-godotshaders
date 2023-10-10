shader_type spatial;
render_mode cull_disabled, unshaded, shadows_disabled, depth_draw_always;

uniform float root_level:hint_range(0.0, 1.0) = 0.1;
uniform vec3 color_root:source_color;
uniform vec3 color_top:source_color;
uniform vec3 color_top_variant:source_color;
uniform vec3 color_margin:source_color;
uniform sampler2D noise_map;
uniform sampler2D grass_texture;

varying vec3 world_position;


void vertex(){
	VERTEX.x += sin(NODE_POSITION_WORLD.x + TIME * 1.25 + UV.y) * ( 1.0 - UV.y) * 0.2;
	VERTEX.z += cos(NODE_POSITION_WORLD.z + TIME * 0.45 + UV.y) * ( 1.0 - UV.y) * 0.15;

	// Vertex to world space
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Recolor noise map to grass variant colors
	vec3 map = texture(noise_map, world_position.xz).rgb;
	vec3 recolor_top = mix(color_top, color_top_variant, map.r);
	vec4 grass_figure = texture(grass_texture, UV);
	
	// Creates a gradient top=black, bottom=white
	float gradient_mask = smoothstep(0.0, 1.0-UV.y, root_level);
	
	// Look at it like masking the top with one color, then masking the bottom with another color. Finally adding both half masks in one
	vec3 bottom = color_root * grass_figure.rgb * gradient_mask;
	vec3 top = recolor_top * grass_figure.rgb * (1.0-gradient_mask);
	vec3 margin = color_margin * (1.0-grass_figure.rgb);
	
	ALBEDO = top + bottom + margin;
	ALPHA = grass_figure.a;
}
