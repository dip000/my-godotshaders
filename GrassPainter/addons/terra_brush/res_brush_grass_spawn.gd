@tool
extends TBrush
class_name TBrushGrassSpawn

const BATCH_PROCESS_FRAMES:int = 50 # Set higher if you have a better computer :D
const HEIGHT_STRENGTH:float = 0.95 # Grass in slopes might look like they're floating at full strenght

@export var variant:int:
	set(v):
		variant = v
		on_active.emit()
		active = true

@export_group("Shader Properties")
@export var variants:Array[Texture2D]
@export var instance_count:int = 128
@export var billboard_y:bool = true
@export var margin_enable:bool = true
@export var margin_color:Color = Color.BLACK

var _populating:bool
var _terrain_height:ImageTexture = preload("res://addons/terra_brush/textures/terrain_height.tres")


func paint(terrain:MeshInstance3D, scale:float, pos:Vector3, primary_action:bool):
	if active:
		if not surface_texture:
			surface_texture = load("res://addons/terra_brush/textures/grass_spawn.tres")
		
		# Spawn with primary key, erase with secondary
		t_color = Color.WHITE if primary_action else Color.BLACK
		TerraBrush.GRASS.set_shader_parameter("grass_spawn", surface_texture)
		_bake_brush_into_surface(terrain, scale, pos)
		_populate_grass(terrain)


func _populate_grass(terrain:MeshInstance3D):
	if _populating:
		return
	_populating = true
	
	# Save previous instances to free them at the end
	for child in terrain.get_children():
		if child is MultiMeshInstance3D:
			child.queue_free()
	
	# Setup shader
	TerraBrush.GRASS.set_shader_parameter("bilboard_y", billboard_y)
	TerraBrush.GRASS.set_shader_parameter("enable_margin", margin_enable)
	TerraBrush.GRASS.set_shader_parameter("color_margin", margin_color)
	TerraBrush.GRASS.set_shader_parameter("grass_variants", variants) #pulls textures from resource
	
	# Caches
	var terrain_image:Image = surface_texture.get_image()
	var height_image:Image = _terrain_height.get_image()
	var terrain_size_m:Vector2 = terrain.mesh.size
	var terrain_size_px:Vector2i = terrain_image.get_size()
	
	# Create mesh
	var grass_mesh := QuadMesh.new()
	grass_mesh.size = Vector2(0.3, 0.3)
	grass_mesh.subdivide_depth = 5
	grass_mesh.center_offset.y += 0.15
	grass_mesh.material = TerraBrush.GRASS
	
	TerraBrush._rng.set_state(TerraBrush._rng_state)
	
	for variant_index in variants.size():
#		var variant:Texture2D = variants[variant_index]
		
		# Create node
		var multimesh_inst = MultiMeshInstance3D.new()
		terrain.add_child( multimesh_inst )
		multimesh_inst.set_owner(terrain.owner)
		multimesh_inst.name = "Grass" + str(variant_index)
		
		# Align with terrain
		multimesh_inst.position.x -= terrain_size_m.x*0.5
		multimesh_inst.position.z -= terrain_size_m.y*0.5
		
		# We need to find all actual valid places first
		var transforms:Array[Transform3D] = []
		for current_instance in instance_count*0.5:
			var x:float = TerraBrush._rng.randf()
			var z:float = TerraBrush._rng.randf()
			var x_px:int = floori(x*terrain_size_px.x)
			var z_px:int = floori(z*terrain_size_px.y)
			var x_m:float = x*terrain_size_m.x
			var z_m:float = z*terrain_size_m.y
			
			# The grass will only spawn where the terrain's texture is WHITE
			if can_spawn_at(terrain_image, x_px, z_px):
				var y:float = height_image.get_pixel(x_px, z_px).r
				var pos := Vector3(x_m, y*HEIGHT_STRENGTH, z_m)
				var transf := Transform3D(Basis(), Vector3()).translated( pos )
				transforms.append( transf )
		
		# Setup multimesh
		multimesh_inst.multimesh =  MultiMesh.new()
		multimesh_inst.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh_inst.multimesh.instance_count = transforms.size()
		multimesh_inst.multimesh.mesh = grass_mesh
		multimesh_inst.set_instance_shader_parameter("variant_index", variant_index)
		
		# Create the actual grass
		var instances:int = transforms.size()
		for instance_index in range(instances):
			multimesh_inst.multimesh.set_instance_transform( instance_index, transforms[instance_index] )

	_populating = false


func can_spawn_at(terrain_image:Image, x:int, z:int) -> bool:
	var image_color:Color = terrain_image.get_pixel(x, z)
	return image_color.is_equal_approx( Color.WHITE )
