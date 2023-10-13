shader_type spatial;

uniform float edge_width : hint_range(0.0, 1.0) = 0.1; // Adjust the edge width


float border(vec2 uv, float border_width)
{
	vec2 bottom_left = step(vec2(border_width), uv);
	vec2 top_right = step(vec2(border_width), 1.0 - uv);
	return bottom_left.x * bottom_left.y * top_right.x * top_right.y;
}

void fragment() {
    float asd = min(min(UV.x, 1.0-UV.x), min(UV.y, 1.0-UV.y));
	ALBEDO *= step(asd, edge_width);
}
