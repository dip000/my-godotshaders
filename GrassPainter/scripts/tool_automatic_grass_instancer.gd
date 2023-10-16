@tool
extends Node
class_name AutomaticGrassInstancer

# Controls
@export var populate:bool = false : set=_populate ## Re-creates all grass instances given by "Variants" and places it inside "Terrain"
@export var reset:bool = false : set=_reset ## Deletes all grass instances from given "Terrain"
@export var progress:String = "0%"  ## Outputs the populating progress, inputs will be ignored

@export_group("Setup")
@export var terrain:MeshInstance3D ## Must have a PlaneMesh with 'paint_surface.gdshader' as ShaderMaterial
@export var variants:Array[GrassVariantInfo] ## Place all grass meshes you want to instance
@export var height:Texture2D
@export var grass_spawn:Texture2D

const BATCH_PROCESS_FRAMES:int = 1000000 # Set higher if you have a better computer :D
const _GRASS_MESH:Mesh = preload("res://Meshes/grass.tres")


func _reset(_value):
	# Dont reset if you're populating
	if terrain and not populate:
		for child in terrain.get_children():
			if child is MultiMeshInstance3D:
				child.queue_free()

func _populate(_value):
	# Fail if already populating or errors found
	if populate or not _input_errors().is_empty():
		return
	
	# Clear previous instances and wait for them to be freed
	_reset(true)
	await get_tree().process_frame
	
	# Track visual progress
	populate = true
	progress = "0%"
	var terrain_image:Image = grass_spawn.get_image()
	var terrain_size_m:Vector2 = terrain.mesh.size
	var terrain_size_px:Vector2i = terrain_image.get_size()
	var height_image:Image = height.get_image()
	
	for variant_index in variants.size():
		var variant:GrassVariantInfo = variants[variant_index]
		
		# Create node
		var multimesh_inst = MultiMeshInstance3D.new()
		terrain.add_child( multimesh_inst )
		multimesh_inst.set_owner(owner)
		multimesh_inst.name = _GRASS_MESH.resource_name
		
		# Align with terrain
		multimesh_inst.position.x -= terrain_size_m.x*0.5
		multimesh_inst.position.z -= terrain_size_m.y*0.5
		
		# We need to find all actual valid places first
		var transforms:Array[Transform3D] = []
		for current_instance in variant.instance_count:
			await process_batch_frame(current_instance, variant.instance_count)
			var x:float = randf()
			var z:float = randf()
			var x_px:int = floori(x*terrain_size_px.x)
			var z_px:int = floori(z*terrain_size_px.y)
			var x_m:float = x*terrain_size_m.x
			var z_m:float = z*terrain_size_m.y
			
			# The grass will only spawn where the terrain's texture is WHITE
			if can_spawn_at(terrain_image, x_px, z_px):
				var y:float = height_image.get_pixel(x_px, z_px).r
				var pos := Vector3(x_m, y*0.3, z_m)
				var transf := Transform3D(Basis(), Vector3()).translated( pos )
				transforms.append( transf )
		
		# Setup multimesh
		multimesh_inst.multimesh =  MultiMesh.new()
		multimesh_inst.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh_inst.multimesh.instance_count = transforms.size()
		multimesh_inst.multimesh.mesh = _GRASS_MESH
		multimesh_inst.set_instance_shader_parameter("variant_index", variant_index)
		
		# Create the actual grass
		for instance_index in transforms.size():
			multimesh_inst.multimesh.set_instance_transform( instance_index, transforms[instance_index] )
			await process_batch_frame(instance_index, transforms.size())
			
	populate = false
	progress = "FINISHED!"

func process_batch_frame(index:int, total:int):
	# So the program doesn't get blocked and crashes over long iterations
	if index%BATCH_PROCESS_FRAMES == BATCH_PROCESS_FRAMES-1:
		progress = str(int(100.0*index/total)) + "%"
		await get_tree().process_frame

func can_spawn_at(terrain_image:Image, x:int, z:int) -> bool:
#	_terrain_image.fill(Color.WHITE)
	var image_color:Color = terrain_image.get_pixel(x, z)
	return image_color.is_equal_approx( Color.WHITE )


func _input_errors() -> Array[String]:
	var errors:Array[String] = []
	if not terrain:
		errors.append("No terrain selected. Must be a MeshInstance3D")
	elif not terrain.mesh is PlaneMesh:
		errors.append("Terrain mesh must be a PlaneMesh")
	if variants.size() <= 0:
		errors.append("Please add at least one mesh variant for your grass")
	return errors

func _get_configuration_warnings():
	return _input_errors()
