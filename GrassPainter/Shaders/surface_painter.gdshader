shader_type spatial;
render_mode unshaded,shadows_disabled,ambient_light_disabled;
#include "res://Shaders/splash_grow.gdshaderinc"

uniform sampler2D terrain_color:source_color, repeat_disable;
uniform sampler2D terrain_height:source_color,repeat_disable,hint_default_black;


void fragment(){
	vec3 base = texture(terrain_color, UV).rgb;
	ALBEDO = grow_splash(UV, base);
}

void vertex(){
	VERTEX.y = texture(terrain_height, UV).r;
}