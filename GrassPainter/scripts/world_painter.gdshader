shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_toon,specular_toon,unshaded,shadows_disabled,ambient_light_disabled;

uniform sampler2D splash_texture:repeat_disable;
uniform sampler2D base_texture:source_color,filter_linear_mipmap,repeat_disable;
//uniform sampler2D grass_patches:hint_default_white;

uniform vec2 position;
uniform float scale:hint_range(0.0, 10.0);
uniform float reveal_factor:hint_range(0.0, 1.0);
uniform vec3 splash_color:source_color;


vec2 scale_from_center(vec2 uv, float s){
	s = 1.0 / s;
	return ((uv - 0.5) * s) + 0.5;
}

void fragment(){
	vec2 uv_transformed = scale_from_center( UV - position, scale );
	float splash_pixel = texture( splash_texture, uv_transformed ).r;
	
	bool splash = (splash_pixel > (1.0-reveal_factor));
	ALBEDO = splash ? splash_color : texture( base_texture, UV ).rgb;
}
