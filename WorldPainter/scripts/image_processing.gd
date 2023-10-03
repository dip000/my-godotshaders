extends MeshInstance3D
class_name ShaderHelper

var material:ShaderMaterial = get_active_material(0)
var base_texture:ImageTexture
var base_image:Image = preload("res://Images/base_texture.png").get_image()
var splash_end_mask_image:Image = preload("res://Images/splash_end_mask.png").get_image()

const SIZE:Vector2 = Vector2(512, 512)
const HALF_SIZE:Vector2 = Vector2(256, 256)
const FULL_RECT:Rect2i = Rect2i(Vector2i.ZERO, SIZE)


func _ready():
	# 'CompressedTexture2D' is not versatile at all, recreate it as 'ImageTexture'
	var base_texture_compressed:CompressedTexture2D = preload("res://Images/base_texture.png")
	base_texture = ImageTexture.create_from_image( base_texture_compressed.get_image() )

func splash_at(splash_position:Vector2, slplash_scale:float, splash_color:Color):
	material.set_shader_parameter("position", splash_position)
	material.set_shader_parameter("rotation", randf_range(0.0, 2*PI))
	material.set_shader_parameter("scale", slplash_scale)
	material.set_shader_parameter("splash_color", splash_color)
	MultiMeshInstance3D
	# Start and wait for shader animation to finish
	var animation:MethodTweener = create_tween().tween_method(_set_reveal_factor, 0.0, 0.95, 2.0).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	await animation.finished
	
	# Update baked texture and reset shader
	# If it lags baking the texture, consider pre-baking it inside a Thread
	_bake_splash_into_base_texture(splash_position, slplash_scale, splash_color)
	material.set_shader_parameter("base_texture", base_texture)
	material.set_shader_parameter("reveal_factor", 0)

func _set_reveal_factor(value:float):
	material.set_shader_parameter("reveal_factor", value)

func _bake_splash_into_base_texture(p:Vector2, s:float, c:Color):
	var size:Vector2i = SIZE * s #resize splash
	p *= SIZE #move relative to pixel size
	p += HALF_SIZE * (1 - s) #move relative to center
	
	# Create splash
	var splash_color:Image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	var splash_mask:Image = splash_end_mask_image.duplicate()
	splash_color.fill(c)
	splash_mask.resize( size.x, size.y )
	
	# Draws the last frame of the splash animation on top of 'base_texture'
	base_image.blit_rect_mask( splash_color, splash_mask, FULL_RECT, p )
	base_texture.update( base_image )
	print("FINISHED!")
