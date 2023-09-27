extends Node3D

@onready var material:ShaderMaterial = $MeshInstance3D.get_active_material(0)

var base_texture:ImageTexture
var splash_image:Image = preload("res://Images/splash_finish.png").get_image()


func _ready():
	# Change Texture type because 'CompressedTexture2D' cannot be processed with 'get_pixel()'
	var base_texture_compressed:CompressedTexture2D = preload("res://Images/base_texture.png")
	var image:Image = base_texture_compressed.get_image()
	base_texture = ImageTexture.create_from_image( image )
	
	# Merges 'base_texture' with the last frame of the splash animation
	# It must process in parallel or it will lag quite a bit (awaits don't work with image manipulation for some reason..)
	var splash_position:Vector2 = Vector2(0,0)
	var thread = Thread.new()
	thread.start( bake_splash_to_base_texture.bind(splash_position, 1) )
	
	# Start and wait for shader animation and thread to finish
	material.set_shader_parameter("position", splash_position)
	var animator:MethodTweener = create_tween().tween_method(func(v): material.set_shader_parameter("reveal_factor", v), 0.0, 0.99, 2.0)
	await animator.finished
	thread.wait_to_finish()
	
	# Update baked texture
	material.set_shader_parameter("base_texture", base_texture)
	material.set_shader_parameter("reveal_factor", 0)


func bake_splash_to_base_texture(translation:Vector2, scalation:float):
	var base_image:Image = base_texture.get_image()
	translation *= base_texture.get_size()
	
	for u in splash_image.get_width():
		for v in splash_image.get_height():
			var UV:Vector2i = Vector2i(u, v)
			var splash_pixel:Color = splash_image.get_pixelv(UV)
			base_image.set_pixelv( UV * scalation + translation, splash_pixel*base_image.get_pixelv(UV) )
		
	base_texture.update(base_image)

