shader_type spatial;
render_mode vertex_lighting;

uniform float grow;


float border(vec2 uv, float border_width){
	vec2 bottom_left = step(vec2(border_width), uv);
	vec2 top_right = step(vec2(border_width), 1.0 - uv);
	return bottom_left.x * bottom_left.y * top_right.x * top_right.y;
}

void vertex() {
    COLOR.r = border(VERTEX.xy+0.5, grow);
	
}

void fragment(){
	ALBEDO = COLOR.rgb;
}
