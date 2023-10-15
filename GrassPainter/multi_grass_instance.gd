@tool
extends Node3D
class_name MultyGrassInstancer

const GRASS_COLOR_EPSILON:float = 0.05
const MAX_RETRIES:int = 1

# Controls
@export var populate:bool = false : set=_populate ## Re-creates all grass instances given by "Variants" and places it inside "Terrain"
@export var reset:bool = false : set=_reset ## Deletes all grass instances from given "Terrain"

@export_group("Setup")
@export var terrain:MeshInstance3D ## Must have a PlaneMesh with 'paint_surface.gdshader' as ShaderMaterial
@export var variants:Array[GrassVariantInfo] ## Place all grass meshes you want to instance

var _terrain_image:Image = preload("res://Images/base_texture.png").get_image()


func _reset(value=true):
	if terrain:
		for child in terrain.get_children():
			if child is MultiMeshInstance3D:
				child.queue_free()


func _populate(_value=false):
	# Fail if already populating or errors found
	if populate or not _input_errors().is_empty():
		return
	populate = true
	
	# Clear previous instances and wait for them to be freed
	_reset(true)
	await get_tree().process_frame
	
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
		
		# MultiMesh requires to have the "instance_count" before setting it up
		var transforms:Array[Transform3D] = []
		var current_instances:int = 0
		var retries:int = 0
		
		while current_instances < variant.instance_count and retries < MAX_RETRIES*variant.instance_count:
			var x:float = randf()
			var z:float = randf()
			
			retries += 1
			await get_tree().process_frame
			
			if can_spawn_color_at(variant.spawn_color, x, z):
				current_instances += 1
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
		
		await get_tree().process_frame
	
	populate = false

func can_spawn_color_at(spawn_color:Color, x:float, z:float) -> bool:
	var image_color:Color = _terrain_image.get_pixel( x*_terrain_image.get_width(), z*_terrain_image.get_height() )
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
