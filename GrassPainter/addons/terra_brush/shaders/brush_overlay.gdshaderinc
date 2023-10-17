group_uniforms BrushOverlay;
uniform sampler2D brush_texture:repeat_disable;
uniform vec2 brush_position;
uniform float brush_scale:hint_range(0.0, 1.0);
uniform vec4 brush_color:source_color;
group_uniforms;


vec2 scale_from_center(vec2 uv, float s){
	return ((uv - 0.5)/s) + 0.5;
}

vec3 draw_brush(vec2 uv, vec3 surface){
	vec2 uv_transformed_outer_line = scale_from_center( uv - brush_position + 0.5, brush_scale+0.05 );
	float brush_pixel_outer_line = texture( brush_texture, uv_transformed_outer_line ).r;
	
	vec2 uv_transformed = scale_from_center( uv - brush_position + 0.5, brush_scale );
	float brush_pixel = texture( brush_texture, uv_transformed ).r;
	
	// ???
	vec3 brush = mix(vec3(brush_pixel_outer_line), brush_color.rgb*brush_pixel, 0.9 + 0.1*sin(TIME*3.0));
	
	// Alpha blend
	return mix(surface, brush, brush_pixel_outer_line);
}
