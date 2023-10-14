shader_type spatial;
render_mode unshaded,shadows_disabled,ambient_light_disabled;
#include "res://Scripts/splash_grow.gdshaderinc"

uniform sampler2D color_root_map:source_color, repeat_disable;


void fragment(){
	vec3 base = texture(color_root_map, UV).rgb;
	ALBEDO = grow_splash(UV, base);
}

