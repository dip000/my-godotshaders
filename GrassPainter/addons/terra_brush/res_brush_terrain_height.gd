@tool
extends TBrush
class_name TBrushTerrainHeight

@export_range(2.0, 100.0, 2.0, "suffix:%") var strength:float = 20:
	set(v):
		strength = v
		on_active.emit()
		active = true


func paint(terrain:MeshInstance3D, scale:float, pos:Vector3, primary_action:bool):
	if active:
		if not surface_texture:
			surface_texture = load("res://addons/terra_brush/textures/terrain_height.tres")
		
		# Mountains with primary key, ridges with secondary
		t_color = Color(1,1,1,strength*0.005) if primary_action else Color(0,0,0,strength*0.005)
		TerraBrush.TERRAIN.set_shader_parameter("terrain_height", surface_texture)
		_bake_brush_into_surface(terrain, scale, pos)
