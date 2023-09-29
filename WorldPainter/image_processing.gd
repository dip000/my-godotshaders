extends Node3D

@onready var material:ShaderMaterial = $MeshInstance3D.get_active_material(0)

var base_texture:ImageTexture
var splash_image:Image = preload("res://Images/splash_finish.png").get_image()

const SIZE:Vector2i = Vector2(512, 512)
const HALF_SIZE:Vector2 = Vector2(256, 256)


func _ready():
	var base_texture_compressed:CompressedTexture2D = preload("res://Images/base_texture.png")
	base_texture = ImageTexture.create_from_image( base_texture_compressed.get_image() )
	
	animate(Vector2.ZERO, 1.0)
#	await get_tree().create_timer(2.1).timeout
#	animate(Vector2(0.5, 0.5), 0.25)

func animate(splash_position:Vector2, slplash_scale:float):
	material.set_shader_parameter("position", splash_position)
	material.set_shader_parameter("scale", slplash_scale)
	
	# Draws the last frame of the splash animation on top of 'base_texture' when the animation ends
	# It must process in parallel or it will lag quite a bit
	var thread = Thread.new()
	thread.start( _bake_splash_to_base_texture.bind(splash_position, slplash_scale) )
	
	# Start and wait for shader animation and thread to finish
	var animation:MethodTweener = create_tween().tween_method(_set_reveal_factor, 0.0, 0.99, 2.0)
	await animation.finished
	thread.wait_to_finish()
	
	# Update baked texture and reset shader
	material.set_shader_parameter("base_texture", base_texture)
	material.set_shader_parameter("reveal_factor", 0)


func _set_reveal_factor(value:float):
	material.set_shader_parameter("reveal_factor", value)

func _bake_splash_to_base_texture(t:Vector2i, s:float):
	var base_image:Image = base_texture.get_image()
	t *= SIZE
	
#	splash_image.resize( SIZE.x*s, SIZE.y*s )
#	base_image.blit_rect(splash_image, Rect2i(Vector2i(), SIZE), t)
	
	# Image processing in GDScript??!!
	for u in base_image.get_width():
		for v in base_image.get_height():
			var UV:Vector2i = Vector2i(u, v)
			var splash_pixel:Color = splash_image.get_pixelv(UV)
			var uv_scaled:Vector2i = scale_from_center(UV, s)
			var uv_translated:Vector2i = clamp_translate(uv_scaled, t)
			base_image.set_pixelv( uv_translated, splash_pixel )

	base_texture.update(base_image)
	print("FINISHED!")

func scale_from_center(uv:Vector2, s:float) -> Vector2i:
	return (uv - HALF_SIZE) * s + HALF_SIZE
func clamp_translate(uv:Vector2i, t:Vector2i) -> Vector2i:
	return clamp(uv + t, Vector2i.ZERO, SIZE)
