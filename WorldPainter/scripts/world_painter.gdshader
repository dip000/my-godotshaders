shader_type spatial;
render_mode unshaded;

uniform sampler2D splash_texture:repeat_disable;
uniform sampler2D base_texture:hint_default_black;
//uniform sampler2D grass_patches:hint_default_white;

uniform vec2 position;
uniform float rotation:hint_range(0.0, 6.283184);
uniform float scale:hint_range(0.0, 10.0);
uniform float reveal_factor:hint_range(0.0, 1.0);
uniform vec3 splash_color:source_color;

const float SPLASH_CUT = 0.1;
const float HALF_PI = PI/2.0;
const float HEIGHT = 0.05;


vec2 rotate_and_scale_from_center(vec2 uv, float s, float a){
	a = a + HALF_PI;
	s = 1.0 / s;
	mat2 rotation_matrix = mat2(vec2(sin(a), -cos(a)), vec2(cos(a), sin(a)));
	return ((uv - 0.5) * s*rotation_matrix) + 0.5;
}


void vertex(){
	vec2 uv_transformed = rotate_and_scale_from_center( UV - position, scale*0.3, rotation );
	float splash_pixel = texture( splash_texture, uv_transformed ).r;
	if(reveal_factor > 0.0)
		VERTEX.y = splash_pixel * HEIGHT * (1.0-reveal_factor);
}


void fragment(){
	vec3 base = texture( base_texture, UV ).rgb;
	vec2 uv_transformed = rotate_and_scale_from_center( UV - position, scale, rotation );
	float splash_pixel = texture( splash_texture, uv_transformed ).r;
	
	float splash_pixel_halved = smoothstep(splash_pixel, 0.0, SPLASH_CUT + 0.01*sin(TIME*5.0));
	float mixed = mix(splash_pixel, splash_pixel_halved, reveal_factor);
	
	if(splash_pixel > (1.0-reveal_factor)){
		ALBEDO = mix(base, splash_color, mixed);
	}
	else{
		ALBEDO = base;
	}
}
