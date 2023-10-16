@tool
extends Node
class_name ManualGrassInstancer

@export var paint:bool: set=_paint

@export var grass_color:GrassBrush = GrassBrush.new()
@export var terrain_color:GrassBrush = GrassBrush.new()
@export var terrain_height:GrassBrush = GrassBrush.new()

@export_group("Setup")
@export var brush_mask:Image
@export var terrain:MeshInstance3D

const SIZE:Vector2i = Vector2(512, 512)
const HALF_SIZE:Vector2 = SIZE/2
const FULL_RECT:Rect2i = Rect2i(Vector2i.ZERO, SIZE)
var _mat_grass:ShaderMaterial = load("res://Materials/grass.tres")


func _paint(_value):
	var brushes:Array[GrassBrush] = [grass_color, terrain_color, terrain_height]
	for brush in brushes:
		if brush.active:
			_bake_brush_into_surface(brush, Vector2.ZERO)
			_mat_grass.set_shader_parameter("color_top_map", brush.surface_texture)


func _process(delta):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		print("Click")
		var cam = EditorPlugin.new().get_editor_interface().get_editor_main_screen().get_child(1).get_child(1).get_child(0).get_child(0).get_child(0).get_child(0).get_child(0).get_child(0).get_child(0)
		var space = get_tree().get_edited_scene_root().get_world_3d().direct_space_state
		var mouse = terrain.get_viewport().get_mouse_position()
		var origin = cam.project_ray_origin(mouse)
		var dir = cam.project_ray_normal(mouse)
		var ray = PhysicsRayQueryParameters3D.create(origin, origin + dir * cam.far)
		
		ray.collide_with_areas = true
		var result = space.intersect_ray(ray)
		print(result)


func _bake_brush_into_surface(brush:GrassBrush, pos:Vector2):
	var size:Vector2i = SIZE * brush.scale #resize splash
	pos *= Vector2(SIZE) #move relative to pixel size
	pos -= HALF_SIZE * brush.scale #move relative to top-left corner
	
	# Create splash. Duplicate so it doesn't loose resolution with every resize
	var splash_color_img:Image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	var splash_mask_img:Image = brush_mask.duplicate()
	splash_color_img.fill( brush.color )
	splash_mask_img.resize( size.x, size.y )
	
	# Draws the splash on top of 'surface_texture'
	var base_img:Image = brush.surface_texture.get_image()
	base_img.blend_rect_mask( splash_color_img, splash_mask_img, FULL_RECT, pos)
	brush.surface_texture.update(base_img)
	
