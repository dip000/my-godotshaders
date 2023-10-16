@tool
extends Node
class_name GrassInstancer

@export var grass_color := GrassBrush.new()
@export var terrain_color := GrassBrush.new()
@export var terrain_height := GrassBrush.new()
@export var grass_spawn := GrassBrush.new()

@export_group("Setup")
@export var brush_mask:Image
@export var terrain:MeshInstance3D

const SIZE:Vector2i = Vector2(512, 512)
const HALF_SIZE:Vector2i = SIZE/2
const FULL_RECT:Rect2i = Rect2i(Vector2i.ZERO, SIZE)
const GRASS:Mesh = preload("res://Meshes/grass.tres")


func paint(pos:Vector3):
	var terrain_material:ShaderMaterial = terrain.mesh.surface_get_material(0)
	var grass_material:ShaderMaterial = GRASS.material
	
	if grass_color.active:
		_bake_brush_into_surface(grass_color, pos)
		grass_material.set_shader_parameter("grass_color", grass_color.surface_texture)
	
	if terrain_color.active:
		_bake_brush_into_surface(terrain_color, pos)
		grass_material.set_shader_parameter("terrain_color", terrain_color.surface_texture)
		terrain_material.set_shader_parameter("terrain_color", terrain_color.surface_texture)
	
	if terrain_height.active:
		# height and grass_spawn textures arent visible so just keep them in grayscale with black surfaces
		var gray:float = terrain_height.color.get_luminance()
		terrain_height.color = Color(gray, gray, gray, terrain_height.color.a)
		_bake_brush_into_surface(terrain_height, pos)
		terrain_material.set_shader_parameter("terrain_height", terrain_height.surface_texture)
	
	if grass_spawn.active:
		var gray:float = grass_spawn.color.get_luminance()
		grass_spawn.color = Color(gray, gray, gray, grass_spawn.color.a)
		_bake_brush_into_surface(grass_spawn, pos)
		grass_material.set_shader_parameter("grass_spawn", grass_spawn.surface_texture)


func _bake_brush_into_surface(brush:GrassBrush, pos:Vector3):
	var size:Vector2i = SIZE * brush.scale #size in pixels
	var rel_pos:Vector2 = Vector2(pos.x, pos.z)/terrain.mesh.size #in [0,1] range
	rel_pos *= Vector2(SIZE) #move relative to pixel size
	rel_pos -= HALF_SIZE * brush.scale #move relative to top-left corner
	
	# Create splash. Duplicate so it doesn't loose resolution with every resize
	var splash_color_img:Image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	var splash_mask_img:Image = brush_mask.duplicate()
	splash_color_img.fill( brush.color )
	splash_mask_img.resize( size.x, size.y )
	
	if not brush.surface_texture:
		var img := Image.create(SIZE.x, SIZE.y, false, Image.FORMAT_RGBA8)
		img.fill(Color.BLACK)
		brush.surface_texture = ImageTexture.create_from_image( img )
	
	# Draws the splash on top of 'surface_texture'
	var base_img:Image = brush.surface_texture.get_image()
	base_img.blend_rect_mask( splash_color_img, splash_mask_img, FULL_RECT, rel_pos)
	brush.surface_texture.update(base_img)
	
