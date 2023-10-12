# SHADER LOGIC
# This script will call the shader to play the splash animation
# At the end of animation, it will bake the last frame into the base texture so the shader doesn't need to keep inifinite splashes drawn
# Then again, a shader might as well not even be needed since you can use an AnimatedSprite3D or something
extends MeshInstance3D
class_name PaintSurface

var _mat:ShaderMaterial = get_active_material(0)
var base_texture:ImageTexture
var splash_end_mask_image:Image = preload("res://Images/splash_end_mask.png").get_image()

const SIZE:Vector2 = Vector2(512, 512)
const HALF_SIZE:Vector2 = SIZE/2
const FULL_RECT:Rect2i = Rect2i(Vector2i.ZERO, SIZE)


func _ready():
	# 'CompressedTexture2D' is not versatile at all, recreate it as 'ImageTexture'
	var base_texture_compressed:CompressedTexture2D = preload("res://Images/base_texture.png")
	base_texture = ImageTexture.create_from_image( base_texture_compressed.get_image() )

func splash_at(splash_position:Vector2, slplash_scale:float, slplash_color:Color, splash_duration:float=2.0):
	_mat.set_shader_parameter("position", splash_position)
	_mat.set_shader_parameter("scale", slplash_scale)
	_mat.set_shader_parameter("color", slplash_color)
	
	# Start and wait for shader animation to finish
	var animation:MethodTweener = create_tween().tween_method(_set_reveal_factor, 0.0, 1.0, splash_duration).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	await animation.finished
	
	# Update baked texture and reset shader
	# If it lags baking the texture, consider pre-baking it inside a Thread
	_bake_splash_into_base_texture(splash_position, slplash_scale, slplash_color)
	_mat.set_shader_parameter("reveal_factor", 0)
	_mat.set_shader_parameter("base_texture", base_texture)
	_mat.set_shader_parameter("noise_map", base_texture)

func _set_reveal_factor(value:float):
	_mat.set_shader_parameter("reveal_factor", value)

func _bake_splash_into_base_texture(pos:Vector2, scal:float, color:Color):
	var size:Vector2i = SIZE * scal #resize splash
	pos *= SIZE #move relative to pixel size
	pos += HALF_SIZE * (1 - scal) #move relative to center
	
	# Create splash
	var splash_color_img:Image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	var splash_mask_img:Image = splash_end_mask_image.duplicate()
	splash_color_img.fill( color )
	splash_mask_img.resize( size.x, size.y )
	
	# Draws the last frame of the splash animation on top of 'base_texture'
	var base_img:Image = base_texture.get_image()
	base_img.blend_rect_mask( splash_color_img, splash_mask_img, FULL_RECT, pos)
	base_texture.update( base_img )
