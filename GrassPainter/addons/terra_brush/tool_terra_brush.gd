@tool
extends Node
class_name TerraBrush

@export var grass_color := TBrush.new()
@export var terrain_color := TBrush.new()
@export var terrain_height := TBrush.new()
@export var grass_spawn := TBrush.new()

@export_group("Setup")
@export var brush_texture:Texture2D = preload("res://addons/terra_brush/textures/default_brush.tres") ## The paint mask to draw with. Use white if you want a solid brush color
@export var terrain:MeshInstance3D ## Surface in scene tree to draw over
@export var grass_variants:Array[GrassVariant] ## The grass variant texture to render and how many of them

const SIZE:Vector2i = Vector2(512, 512)
const HALF_SIZE:Vector2i = SIZE/2
const FULL_RECT:Rect2i = Rect2i(Vector2i.ZERO, SIZE)
const GRASS:ShaderMaterial = preload("res://addons/terra_brush/materials/grass.tres")


func paint(pos:Vector3):
	var terrain_material:ShaderMaterial = terrain.mesh.surface_get_material(0)
	
	if grass_color.active:
		_bake_brush_into_surface(grass_color, pos)
		GRASS.set_shader_parameter("grass_color", grass_color.surface_texture)
	
	if terrain_color.active:
		_bake_brush_into_surface(terrain_color, pos)
		GRASS.set_shader_parameter("terrain_color", terrain_color.surface_texture)
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
		GRASS.set_shader_parameter("grass_spawn", grass_spawn.surface_texture)


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
	
	# Blend brush_img over 'surface_texture'
	var base_img:Image = brush.surface_texture.get_image()
	base_img.blend_rect( brush_img, FULL_RECT, pos_absolute)
	brush.surface_texture.update(base_img)
	
