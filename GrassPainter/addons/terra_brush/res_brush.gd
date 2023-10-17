@tool
extends Resource
class_name TBrush

signal on_active()


## Check to draw with this brush. Note that this will unckeck every other brush so only one can be active at a time
@export var active:bool:
	set(v):
		if v:
			on_active.emit()
		active = v

## Modulates the brush texture. Use alpha to set the stroke strenght
## Modifying this will set it as the active brush
@export var color:Color:
	set(v):
		color = v
		on_active.emit()
		active = true

## A scale of 100% is a brush the size of the whole surface
@export_range(0, 100, 1, "suffix:%") var scale:float = 20.0

@export_group("Advanced")
@export var surface_texture:Texture2D ## The texture you'll be drawing with this brush. A new texture will be provided if you dont set this property
@export var custom_brush:Texture2D ## Override this property to use with this brush in specific. Like a grass texture for "grass_color" brush

