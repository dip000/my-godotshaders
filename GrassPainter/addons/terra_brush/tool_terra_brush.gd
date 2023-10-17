## TERRA BRUSH: Tool for terraforming and coloring grass
# 1. Instantiate a TerraBrush node in scene tree and select it
# 2. Set up the terrain and grass shader properties from the inspector
# 3. Select a color if it is a color brush, ignore the color if is a terrain brush
# 4. Hover over your terrain and left-click-and-drag to draw a stroke

@tool
extends Node
class_name TerraBrush

@export_category("Color")
@export var grass_color := TBrush.new()
@export var terrain_color := TBrush.new()
@export_category("Terrain")
@export var terrain_height := TBrush.new()
@export var grass_spawn := TBrush.new()

@export var brush_texture:Texture2D = preload("res://addons/terra_brush/textures/default_brush.tres") ## The paint mask to draw with
@export var terrain:MeshInstance3D ## Surface in scene tree to draw over
@export_group("Grass Shader Properties", "grass_")
@export var grass_variant := GrassVariant.new()## The grass variant texture to render and how many of them
@export var grass_billboard_y:bool = true
@export var grass_margin_enable:bool = true
@export var grass_margin_color:Color = Color.BLACK


const SIZE:Vector2i = Vector2(512, 512)
const HALF_SIZE:Vector2i = SIZE/2
const FULL_RECT:Rect2i = Rect2i(Vector2i.ZERO, SIZE)
const GRASS:ShaderMaterial = preload("res://addons/terra_brush/materials/grass.tres")
const TERRAIN:ShaderMaterial = preload("res://addons/terra_brush/materials/terrain.tres")
const BATCH_PROCESS_FRAMES:int = 50 # Set higher if you have a better computer :D
const HEIGHT_STRENGTH:float = 0.95 # Grass in slopes might look like they're floating at full strenght

var _active_brush:TBrush
var _populating:bool
var _rng := RandomNumberGenerator.new()
var _rng_state:int


func _ready():
	_rng.set_seed( hash("Godot") )
	_rng_state = _rng.get_state()
	
	# Always keep only one brush active at a time
	for brush in [grass_color, terrain_color, terrain_height, grass_spawn]:
		brush.active = false
		brush.on_active.connect(_deactivate_brushes)

func _deactivate_brushes():
	for brush in [grass_color, terrain_color, terrain_height, grass_spawn]:
		brush.active = false


func paint(pos:Vector3, primary_action:bool):
	if grass_color.active:
		GRASS.set_shader_parameter("grass_color", grass_color.surface_texture)
	
	# The grass roots need to be colored as well so it looks prrety
	if terrain_color.active:
		GRASS.set_shader_parameter("terrain_color", terrain_color.surface_texture)
		TERRAIN.set_shader_parameter("terrain_color", terrain_color.surface_texture)
	
	# Mountains with primary key, ridges with secondary
	# Alpha small for extra smoothness
	if terrain_height.active:
		terrain_height.color = Color(1,1,1,0.03) if primary_action else Color(0,0,0,0.03)
		TERRAIN.set_shader_parameter("terrain_height", terrain_height.surface_texture)
		_populate_grass()
	
	# Spawn with primary key, erase with secondary
	if grass_spawn.active:
		grass_spawn.color = Color.WHITE if primary_action else Color.BLACK
		GRASS.set_shader_parameter("grass_spawn", grass_spawn.surface_texture)
		_populate_grass()
	
	# Save persistent data into textures
	if _active_brush and _active_brush.scale > 0:
		_bake_brush_into_surface(_active_brush, pos)


func brush_overlay(pos:Vector3):
	# The shader draws a circle over mouse pointer to show where and what size are you hovering
	_active_brush = null
	for brush in [grass_color, terrain_color, terrain_height, grass_spawn]:
		if brush.active:
			_active_brush = brush
			var brush_tex:Texture2D = brush.custom_brush if brush.custom_brush else brush_texture
			var scale:float = brush.scale/100.0
			var pos_rel:Vector2 = Vector2(pos.x, pos.z)/terrain.mesh.size
			
			TERRAIN.set_shader_parameter("brush_texture", brush_tex)
			TERRAIN.set_shader_parameter("brush_position", pos_rel)
			TERRAIN.set_shader_parameter("brush_scale", scale)
			TERRAIN.set_shader_parameter("brush_color", brush.color)
			return

func exit_overlay():
	TERRAIN.set_shader_parameter("brush_position", Vector2(2,2)) #move brush outside viewing scope

func scale(value:float):
	if _active_brush:
		var terrain_material:ShaderMaterial = terrain.mesh.surface_get_material(0)
		_active_brush.scale = clampf(_active_brush.scale+value, 0, 100)
		terrain_material.set_shader_parameter("brush_scale", _active_brush.scale/100.0)


func _bake_brush_into_surface(brush:TBrush, pos:Vector3):
	# Transforms
	var scale:float = brush.scale/100.0
	var size:Vector2i = SIZE * scale #size in pixels
	var pos_absolute:Vector2 = Vector2(pos.x, pos.z)/terrain.mesh.size #in [0,1] range
	pos_absolute *= Vector2(SIZE) #move in pixel size
	pos_absolute -= HALF_SIZE * scale #move to top-left corner
	
	# Create a black surface texture if it wasn't provided
	if not brush.surface_texture:
		var img := Image.create(SIZE.x, SIZE.y, false, Image.FORMAT_RGBA8)
		img.fill(Color.BLACK)
		brush.surface_texture = ImageTexture.create_from_image( img )
	
	# Create color
	var color_img:Image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	color_img.fill( brush.color )
	
	# Blend brush_texture with color
	var brush_tex:Texture2D = brush.custom_brush if brush.custom_brush else brush_texture
	var brush_img:Image = brush_tex.get_image().duplicate()
	brush_img.resize( size.x, size.y )
	brush_img.blend_rect_mask(color_img, brush_img, FULL_RECT, Vector2i.ZERO)
	
	# Blend brush_img over surface_texture
	var base_img:Image = brush.surface_texture.get_image()
	base_img.blend_rect( brush_img, FULL_RECT, pos_absolute)
	brush.surface_texture.update(base_img)
	

func _populate_grass():
	if _populating:
		return
	_populating = true
	
	# Save previous instance to free it at the end
	var prev_instance:MultiMeshInstance3D = terrain.find_child("Grass")
	
	# Setup shader
	GRASS.set_shader_parameter("bilboard_y", grass_billboard_y)
	GRASS.set_shader_parameter("enable_margin", grass_margin_enable)
	GRASS.set_shader_parameter("color_margin", grass_margin_color)
	GRASS.set_shader_parameter("grass_variant", grass_variant.texture)
	
	# Caches
	var terrain_image:Image = grass_spawn.surface_texture.get_image()
	var height_image:Image = terrain_height.surface_texture.get_image()
	var terrain_size_m:Vector2 = terrain.mesh.size
	var terrain_size_px:Vector2i = terrain_image.get_size()
	_rng.set_state( _rng_state )
	
	# Create mesh
	var grass_mesh := QuadMesh.new()
	grass_mesh.size = Vector2(0.3, 0.3)
	grass_mesh.subdivide_depth = 5
	grass_mesh.center_offset.y += 0.15
	grass_mesh.material = GRASS
	
	# Create node
	var multimesh_inst = MultiMeshInstance3D.new()
	terrain.add_child( multimesh_inst )
	multimesh_inst.set_owner(owner)
	multimesh_inst.name = "Grass"
	
	# Align with terrain
	multimesh_inst.position.x -= terrain_size_m.x*0.5
	multimesh_inst.position.z -= terrain_size_m.y*0.5
	
	# We need to find all actual valid places first
	var transforms:Array[Transform3D] = []
	for current_instance in grass_variant.instance_count:
		await process_batch_frame(current_instance, grass_variant.instance_count)
		var x:float = _rng.randf()
		var z:float = _rng.randf()
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
	
	# Create the actual grass
	var instances:int = transforms.size()
	for instance_index in range(instances):
		multimesh_inst.multimesh.set_instance_transform( instance_index, transforms[instance_index] )
		await process_batch_frame(instance_index, instances)
	
	if prev_instance:
		prev_instance.queue_free()
	
	_populating = false


func process_batch_frame(index:int, total:int):
	# So the program doesn't get blocked and crashes over long iterations
	if index%BATCH_PROCESS_FRAMES == BATCH_PROCESS_FRAMES-1:
		await get_tree().process_frame

func can_spawn_at(terrain_image:Image, x:int, z:int) -> bool:
	var image_color:Color = terrain_image.get_pixel(x, z)
	return image_color.is_equal_approx( Color.WHITE )
