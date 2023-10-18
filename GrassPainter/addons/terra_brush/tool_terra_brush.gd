## TERRA BRUSH: Tool for terraforming and coloring grass
# 1. Instantiate a TerraBrush node in scene tree and select it
# 2. Set up the terrain and grass shader properties from the inspector
# 3. Select a color if it is a color brush, ignore the color if is a terrain brush
# 4. Hover over your terrain and left-click-and-drag to draw a stroke

@tool
extends Node
class_name TerraBrush

@export var terrain:MeshInstance3D ## Surface in scene tree to draw over

@export var terrain_color := TBrushColor.new()
@export var terrain_height := TBrush.new()
@export var grass_color := TBrushColor.new()
@export var grass_spawn := TBrush.new()

@export_group("Grass Shader Properties", "grass_")
@export var grass_variants:Array[TGrassVariant] ## The grass variant texture to render and how many of them
@export var grass_billboard_y:bool = true
@export var grass_margin_enable:bool = true
@export var grass_margin_color:Color = Color.BLACK

const BRUSH_SIZE:Vector2i = Vector2(512, 512)
const BRUSH_FULL_RECT:Rect2i = Rect2i(Vector2i.ZERO, BRUSH_SIZE)
const SURFACE_SIZE:Vector2i = Vector2(1024, 1024)
const SURFACE_HALF_SIZE:Vector2i = SURFACE_SIZE/2
const SURFACE_FULL_RECT:Rect2i = Rect2i(Vector2i.ZERO, SURFACE_SIZE)

const TEXTURES_FILE_PATH:String = "res://addons/terra_brush/textures"
const GRASS:ShaderMaterial = preload("res://addons/terra_brush/materials/grass.tres")
const TERRAIN:ShaderMaterial = preload("res://addons/terra_brush/materials/terrain.tres")
const BRUSH_MASK:Texture2D = preload("res://addons/terra_brush/textures/default_brush.tres")

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


func brush_overlay(pos:Vector3):
	# The shader draws a circle over mouse pointer to show where and what size are you hovering
	_active_brush = null
	for brush in [grass_color, terrain_color, terrain_height, grass_spawn]:
		if brush.active:
			_active_brush = brush
			var scale:float = brush.scale/100.0
			var pos_rel:Vector2 = Vector2(pos.x, pos.z)/terrain.mesh.size
			
			TERRAIN.set_shader_parameter("brush_position", pos_rel)
			TERRAIN.set_shader_parameter("brush_scale", scale)
			if brush == grass_color or brush == terrain_color:
				TERRAIN.set_shader_parameter("brush_color", brush.color)
			else:
				TERRAIN.set_shader_parameter("brush_color", brush.t_color)
			return

func exit_terrain():
	TERRAIN.set_shader_parameter("brush_position", Vector2(2,2)) #move brush outside viewing scope

func scale(value:float):
	if _active_brush:
		var terrain_material:ShaderMaterial = terrain.mesh.surface_get_material(0)
		_active_brush.scale = clampf(_active_brush.scale+value, 10, 100)
		terrain_material.set_shader_parameter("brush_scale", _active_brush.scale/100.0)

func save():
	print("Saving")
	var t := Thread.new()
	t.start(func():
		for brush in [grass_color, terrain_color, terrain_height, grass_spawn]:
			if brush.surface_texture and brush.texture_updated:
				ResourceSaver.save(brush.surface_texture)
	)
	while t.is_alive():
		await get_tree().create_timer(0.2).timeout
	t.wait_to_finish()
	print("Saved!")

func paint(pos:Vector3, primary_action:bool):
	# The grass roots need to be colored as well so it is also sent to grass shader
	if terrain_color.active:
		if not terrain_color.surface_texture:
			terrain_color.surface_texture = load("res://addons/terra_brush/textures/terrain_color.tres")
		terrain_color.t_color = terrain_color.color if primary_action else Color(terrain_color.color, 0.1)
		GRASS.set_shader_parameter("terrain_color", terrain_color.surface_texture)
		TERRAIN.set_shader_parameter("terrain_color", terrain_color.surface_texture)
		_bake_brush_into_surface(terrain_color, pos)
	
	# Mountains with primary key, ridges with secondary
	if terrain_height.active:
		if not terrain_height.surface_texture:
			terrain_height.surface_texture = load("res://addons/terra_brush/textures/terrain_height.tres")
		terrain_height.t_color = Color(1,1,1,0.02) if primary_action else Color(0,0,0,0.02)
		TERRAIN.set_shader_parameter("terrain_height", terrain_height.surface_texture)
		_bake_brush_into_surface(terrain_height, pos)
		_populate_grass()
	
	# Load surface texture if it was empty. This means that you can save and load the texture in your file system
	if grass_color.active:
		if not grass_color.surface_texture:
			grass_color.surface_texture = load("res://addons/terra_brush/textures/grass_color.tres")
		grass_color.t_color = grass_color.color if primary_action else Color(grass_color.color, 0.1)
		GRASS.set_shader_parameter("grass_color", grass_color.surface_texture)
		_bake_brush_into_surface(grass_color, pos)
	
	# Spawn with primary key, erase with secondary
	if grass_spawn.active:
		if not grass_spawn.surface_texture:
			grass_spawn.surface_texture = load("res://addons/terra_brush/textures/grass_spawn.tres")
		grass_spawn.t_color = Color.WHITE if primary_action else Color.BLACK
		GRASS.set_shader_parameter("grass_spawn", grass_spawn.surface_texture)
		_bake_brush_into_surface(grass_spawn, pos)
		_populate_grass()

func paint_end():
	pass

func _bake_brush_into_surface(brush:TBrush, pos:Vector3):
	# Transforms
	var scale:float = brush.scale/100.0
	var size:Vector2i = SURFACE_SIZE * scale #size in pixels
	var pos_absolute:Vector2 = Vector2(pos.x, pos.z)/terrain.mesh.size #in [0,1] range
	pos_absolute *= Vector2(SURFACE_SIZE) #move in pixel size
	pos_absolute -= SURFACE_HALF_SIZE * scale #move to top-left corner
	
	# Create color
	var brush_img:Image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	brush_img.fill( brush.t_color )
	
	# Recolor brush texture if it was provided
	if brush.brush_texture:
		brush_img.blend_rect(brush.brush_texture.get_image(), BRUSH_FULL_RECT, Vector2i.ZERO)
	
	# Blend brush over surface
	var surface:Image = brush.surface_texture.get_image()
	var brush_mask:Image = BRUSH_MASK.get_image()
	brush_mask.resize(size.x, size.y)
	surface.blend_rect_mask( brush_img, brush_mask, SURFACE_FULL_RECT, pos_absolute)
	brush.surface_texture.update(surface)
	brush.texture_updated = true
	

func _populate_grass():
	if _populating:
		return
	_populating = true
	
	# Save previous instances to free them at the end
	var prev_instances:Array[MultiMeshInstance3D]
	for child in terrain.get_children():
		if child is MultiMeshInstance3D:
			prev_instances.append(child)
	
	# Setup shader
	GRASS.set_shader_parameter("bilboard_y", grass_billboard_y)
	GRASS.set_shader_parameter("enable_margin", grass_margin_enable)
	GRASS.set_shader_parameter("color_margin", grass_margin_color)
	GRASS.set_shader_parameter("grass_variants", grass_variants.map(func(gv): return gv.texture)) #pulls textures from resource
	
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
	
	for variant_index in grass_variants.size():
		var variant:TGrassVariant = grass_variants[variant_index]
		
		# Create node
		var multimesh_inst = MultiMeshInstance3D.new()
		terrain.add_child( multimesh_inst )
		multimesh_inst.set_owner(owner)
		multimesh_inst.name = "Grass" + str(variant_index)
		
		# Align with terrain
		multimesh_inst.position.x -= terrain_size_m.x*0.5
		multimesh_inst.position.z -= terrain_size_m.y*0.5
		
		# We need to find all actual valid places first
		var transforms:Array[Transform3D] = []
		for current_instance in variant.instance_count:
			await process_batch_frame(current_instance, variant.instance_count)
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
		multimesh_inst.set_instance_shader_parameter("variant_index", variant_index)
		
		# Create the actual grass
		var instances:int = transforms.size()
		for instance_index in range(instances):
			multimesh_inst.multimesh.set_instance_transform( instance_index, transforms[instance_index] )
			await process_batch_frame(instance_index, instances)
		
		if variant_index < prev_instances.size():
			prev_instances[variant_index].queue_free()
	
	_populating = false


func process_batch_frame(index:int, total:int):
	# So the program doesn't get blocked and crashes over long iterations
	if index%BATCH_PROCESS_FRAMES == BATCH_PROCESS_FRAMES-1:
		await get_tree().process_frame

func can_spawn_at(terrain_image:Image, x:int, z:int) -> bool:
	var image_color:Color = terrain_image.get_pixel(x, z)
	return image_color.is_equal_approx( Color.WHITE )
