@tool
extends Node
class_name MultyGrassInstancer

# Controls
@export var populate:bool = false : set=_populate ## Re-creates all grass instances given by "Variants" and places it inside "Terrain"
@export var reset:bool = false : set=_reset ## Deletes all grass instances from given "Terrain"
@export var progress:String = "0%"  ## Outputs the populating progress, inputs will be ignored

@export_group("Setup")
@export var terrain:MeshInstance3D ## Must have a PlaneMesh with 'paint_surface.gdshader' as ShaderMaterial
@export var variants:Array[GrassVariantInfo] ## Place all grass meshes you want to instance

var _terrain_image:Image = preload("res://Images/base_texture.png").get_image()
const BATCH_PROCESS_FRAMES:int = 100 # Set higher if you have a better computer :D


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
	var terrain_size:Vector2 = terrain.mesh.size
	
	for variant in variants:
		# Create node
		var multimesh_inst = MultiMeshInstance3D.new()
		terrain.add_child( multimesh_inst )
		multimesh_inst.set_owner(owner)
		multimesh_inst.name = variant.mesh.resource_name
		
		# Align with terrain
		multimesh_inst.position.x -= terrain_size.x*0.5
		multimesh_inst.position.z -= terrain_size.y*0.5
		
		# We need to find all actual valid places first
		var transforms:Array[Transform3D] = []
		for current_instance in variant.instance_count:
			
			await process_batch_frame(current_instance, variant.instance_count)
			var x:float = randf()
			var z:float = randf()
			
			# The grass will only spawn where the terrain's texture has "spawn_color"
			if int(can_spawn_color_at(variant.spawn_color, x, z)) ^ int(variant.any_but_color): # xor keyword doesn't exist :P
				var pos := Vector3(x*terrain_size.x, 0, z*terrain_size.y)
				var transf := Transform3D(Basis(), Vector3()).translated( pos )
				transforms.append( transf )
		
		# Setup multimesh
		multimesh_inst.multimesh =  MultiMesh.new()
		multimesh_inst.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh_inst.multimesh.instance_count = transforms.size()
		multimesh_inst.multimesh.mesh = variant.mesh
		
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

func can_spawn_color_at(spawn_color:Color, x:float, z:float) -> bool:
	x = floori(x*_terrain_image.get_width())
	z = floori(z*_terrain_image.get_height())
	var image_color:Color = _terrain_image.get_pixel( int(x), int(z) )
	return image_color.is_equal_approx( spawn_color )


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
