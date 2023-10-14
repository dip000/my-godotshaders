
group_uniforms SplashGrow;
uniform sampler2D splash_texture:repeat_disable;
uniform vec2 splash_position;
uniform float splash_scale:hint_range(0.0, 1.0);
uniform vec4 splash_color:source_color;
uniform float reveal_factor:hint_range(0.0, 1.0);
group_uniforms;


vec2 scale_from_center(vec2 uv, float s){
	s = 1.0 / s;
	return ((uv - 0.5) * s) + 0.5;
}

vec3 grow_splash(vec2 uv, vec3 surface){
	vec2 uv_transformed = scale_from_center( uv - splash_position + 0.5, splash_scale );
	float splash_pixel = texture( splash_texture, uv_transformed ).r;
	
	bool splash = (splash_pixel > (1.0-reveal_factor));
	
	// Alpha blend
	return splash ? mix(splash_color.rgb, surface, 1.0-splash_color.a) : surface;
}

