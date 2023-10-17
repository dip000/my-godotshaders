@tool
extends Node
class_name TerraBrush

@export_category("Color")
@export var grass_color := TBrush.new()
@export var terrain_color := TBrush.new()
@export_category("Terrain")
@export var terrain_height := TBrush.new()
@export var grass_spawn := TBrush.new()

@export_group("Setup")
@export var brush_texture:Texture2D = preload("res://addons/terra_brush/textures/default_brush.tres") ## The paint mask to draw with. Use white if you want a solid brush color
@export var grass_variants:Array[GrassVariant] ## The grass variant texture to render and how many of them
@export var terrain:MeshInstance3D ## Surface in scene tree to draw over

const SIZE:Vector2i = Vector2(512, 512)
const HALF_SIZE:Vector2i = SIZE/2
const FULL_RECT:Rect2i = Rect2i(Vector2i.ZERO, SIZE)
const GRASS:ShaderMaterial = preload("res://addons/terra_brush/materials/grass.tres")
const TERRAIN:ShaderMaterial = preload("res://addons/terra_brush/materials/terrain.tres")

var _active_brush:TBrush


func _ready():
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
	
	if terrain_color.active:
		# The grass roots need to be colored as well so it looks prrety
		GRASS.set_shader_parameter("terrain_color", terrain_color.surface_texture)
		TERRAIN.set_shader_parameter("terrain_color", terrain_color.surface_texture)
	
	if terrain_height.active:
		# Mountains with primary key, ridges with secondary
		# Alpha small for extra smoothness
		terrain_height.color = Color(1,1,1,0.03) if primary_action else Color(0,0,0,0.03)
		TERRAIN.set_shader_parameter("terrain_height", terrain_height.surface_texture)
	
	if grass_spawn.active:
		# Spawn with primary key, erase with secondary
		grass_spawn.color = Color.WHITE if primary_action else Color.BLACK
		GRASS.set_shader_parameter("grass_spawn", grass_spawn.surface_texture)
	
	if _active_brush and _active_brush.scale > 0:
		# Save persistent colors into textures
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
	
