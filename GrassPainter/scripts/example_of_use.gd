# EXAMPLE OF USE
# This script will only find the mouse position in PaintSurface and call 'splash_at()'
# Refer to PaintSurface for shader logic
extends Node3D

@export var splash_colors:Array[Color] ## Use alpha to blend with paint surface 
@export var brush:Texture2D
@export var terrain_mat:ShaderMaterial
@export var grass_mat:ShaderMaterial

@onready var space:PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
@onready var cam:Camera3D = get_viewport().get_camera_3d()
@onready var terrain:MeshInstance3D = $Terrain
@onready var base_texture:Texture2D = terrain_mat.get_shader_parameter("terrain_color")

const SIZE:Vector2 = Vector2(512, 512)
const HALF_SIZE:Vector2 = SIZE/2
const FULL_RECT:Rect2i = Rect2i(Vector2i.ZERO, SIZE)


func _input(event):
	if event is InputEventMouseButton and event.is_pressed():
		var origin := cam.project_ray_origin(event.position)
		var target := cam.project_ray_normal(event.position) * cam.far
		var ray := PhysicsRayQueryParameters3D.create(origin, target)
		
		ray.collide_with_areas = true
		var result := space.intersect_ray(ray)
		
		if result:
			var pos:Vector2 = Vector2(result.position.x, result.position.z) / terrain.mesh.size
			terrain.splash_at( pos, 0.3, splash_colors.pick_random() )


func splash_at(splash_position:Vector2, slplash_scale:float, slplash_color:Color, splash_duration:float=2.0):
	_set_all("splash_position", splash_position)
	_set_all("splash_scale", slplash_scale)
	_set_all("splash_color", slplash_color)
	
	# Start and wait for shader animation to finish
	var animation:MethodTweener = create_tween().tween_method(_set_reveal_factor, 0.0, 1.0, splash_duration).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	await animation.finished
	
	# Update baked texture and reset shader
	# If it lags baking the texture, consider pre-baking it inside a Thread
	_bake_splash_into_base_texture(splash_position, slplash_scale, slplash_color)
	_set_all("reveal_factor", 0)
	_set_all("terrain_color", terrain_mat.get_shader_parameter("terrain_color"))


func _set_reveal_factor(value:float):
	_set_all("reveal_factor", value)

func _set_all(param:String, value:Variant):
	terrain_mat.set_shader_parameter(param, value)
	grass_mat.set_shader_parameter(param, value)


func _bake_splash_into_base_texture(pos:Vector2, scal:float, color:Color):
	var size:Vector2i = SIZE * scal #resize splash
	pos *= SIZE #move relative to pixel size
	pos -= HALF_SIZE * scal #move relative to top-left corner
	
	# Create splash
	var splash_color_img:Image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	var splash_mask_img:Image = brush.duplicate()
	splash_color_img.fill( color )
	splash_mask_img.resize( size.x, size.y )
	
	# Draws the last frame of the splash animation on top of 'base_texture'
	var base_img:Image = base_texture.get_image()
	base_img.blend_rect_mask( splash_color_img, splash_mask_img, FULL_RECT, pos)
	base_texture.update( base_img )
	
