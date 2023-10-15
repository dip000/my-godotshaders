@tool
extends Node
class_name ManualGrassInstancer

@export var paint:bool: set=_paint
@export var terrain:PaintSurface
@export var brush_top:GrassBrush
@export var brush_root:GrassBrush

const SIZE:Vector2 = Vector2(512, 512)
const HALF_SIZE:Vector2 = SIZE/2
const FULL_RECT:Rect2i = Rect2i(Vector2i.ZERO, SIZE)


func _paint(_value):
	var _mat_grass:ShaderMaterial = load("res://Materials/grass.tres")
	var top_texture:ImageTexture = _mat_grass.get_shader_parameter("color_top_map")
	
	if not top_texture:
		var img := Image.create(SIZE.x, SIZE.y, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		top_texture = ImageTexture.create_from_image( img )
	
	_bake_brush_into_texture(brush_top, top_texture, Vector2.ZERO)
	_mat_grass.set_shader_parameter("color_top_map", top_texture)
	
func _bake_brush_into_texture(brush:GrassBrush, texture:ImageTexture, pos:Vector2):
	var size:Vector2i = SIZE * brush.scale #resize splash
	pos *= SIZE #move relative to pixel size
	pos -= HALF_SIZE * brush.scale #move relative to top-left corner
	
	# Create splash
	var splash_color_img:Image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	var splash_mask_img:Image = brush.brush_mask.duplicate()
	splash_color_img.fill( brush.color )
	splash_mask_img.resize( size.x, size.y )
	
	# Draws the last frame of the splash animation on top of 'base_texture'
	var base_img:Image = texture.get_image()
	base_img.blend_rect_mask( splash_color_img, splash_mask_img, FULL_RECT, pos)
	texture.update(base_img)
	
