shader_type spatial;
render_mode cull_disabled, unshaded, shadows_disabled;

uniform float root_level:hint_range(0.0, 1.0) = 0.1;
uniform vec3 color_root:source_color;
uniform vec3 color_top:source_color;
uniform vec3 color_top_variant:source_color;
uniform vec3 color_margin:source_color;
uniform bool enable_margin;
uniform bool bilboard_y;
uniform sampler2D noise_map:source_color,filter_linear_mipmap,repeat_disable;
uniform sampler2D grass_texture;


void vertex(){
	// I totally stole this part
	VERTEX.x += sin(NODE_POSITION_WORLD.x + TIME * 1.25 + UV.y) * ( 1.0 - UV.y) * 0.2;
	VERTEX.z += cos(NODE_POSITION_WORLD.z + TIME * 0.45 + UV.y) * ( 1.0 - UV.y) * 0.15;
	
	if(bilboard_y){
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)), 0.0), vec4(0.0, 1.0, 0.0, 0.0), vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0), MODEL_MATRIX[3]);
	}
	
	// Vertex to world space
	vec3 world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	// Coloring the mesh vertices will look exactly* the same as coloring the pixels but more performant
	// Recolor noise map to grass variant colors
	vec3 map = texture(noise_map, world_position.xz).rgb;
	vec3 recolor_top = mix(color_top, color_top_variant, map.r);
	
	// Creates a gradient top=black, bottom=white
	float gradient_mask = smoothstep(0.0, UV.y, root_level);
	
	// Look at it like masking the top with one color, then masking the bottom with another color. Finally adding both half masks in one
	COLOR.rgb = color_root * (1.0-gradient_mask);
	COLOR.rgb += recolor_top * gradient_mask;
}

void fragment() {
	// Apply vertex color to albedo
	ALBEDO = COLOR.rgb;
	
	// The margin will look awfull if you try to vertex-color it, so is better to process it here
	vec4 grass_mask = texture(grass_texture, UV);
	if(enable_margin){
		ALBEDO *= grass_mask.rgb;
		ALBEDO += color_margin * (1.0-grass_mask.rgb);
	}
	
	// TBH, i don't know why alpha must be multiplied or why it needs the threshold without glitching
	ALPHA *= grass_mask.a;
	ALPHA_SCISSOR_THRESHOLD = 0.8;
}
