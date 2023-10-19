@tool
extends TBrush
class_name TBrushTerrainHeight

const HEIGHT_STRENGTH:float = 0.95 # Grass in slopes might look like they're floating at full strenght


@export_range(8.0, 100.0, 1.0, "suffix:%") var strength:float = 20:
	set(v):
		strength = v
		on_active.emit()
		active = true


func paint(scale:float, pos:Vector3, primary_action:bool):
	if active:
		if not surface_texture:
			surface_texture = load("res://addons/terra_brush/textures/terrain_height.tres")
		
		# Mountains with primary key, ridges with secondary
		t_color = Color(1,1,1,strength*0.001) if primary_action else Color(0,0,0,strength*0.005)
		TerraBrush.TERRAIN.set_shader_parameter("terrain_height", surface_texture)
		_bake_brush_into_surface(scale, pos)
		_populate_grass()


func _populate_grass():
	# Caches
	var height_image:Image = surface_texture.get_image()
	var terrain_size_m:Vector2 = terrain.mesh.size
	var terrain_size_px:Vector2i = height_image.get_size()
	
	# 
	for child in terrain.get_children():
		if not child is MultiMeshInstance3D:
			continue
			
		var multimesh_instance:MultiMeshInstance3D = child
		for instance_index in multimesh_instance.multimesh.instance_count:
			var transform:Transform3D = multimesh_instance.multimesh.get_instance_transform(instance_index)
			var position:Vector3 = transform.origin
			
			# Convert to range [0,1] then to pixel size
			var x_px:int = (position.x / terrain_size_m.x) * terrain_size_px.x
			var z_px:int = (position.z / terrain_size_m.y) * terrain_size_px.y
			
			# Update the new height with that texture pixel
			var y_m:float = height_image.get_pixel(x_px, z_px).r * HEIGHT_STRENGTH
			transform.origin = Vector3(position.x, y_m, position.z)
			multimesh_instance.multimesh.set_instance_transform(instance_index , transform)

