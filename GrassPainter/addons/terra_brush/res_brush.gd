@tool
extends Resource
class_name TBrush

signal on_active()


## Check to draw with this brush. Note that this will unckeck every other brush so only one can be active at a time
@export var active:bool=false:
	set(v):
		if v: on_active.emit()
		active = v

## A scale of 100% is a brush the size of the whole surface
@export_range(0, 100, 1, "suffix:%") var scale:float = 20.0

@export_group("Advanced")
@export var surface_texture:Texture2D ## The texture you'll be drawing with this brush. A new texture will be provided if you dont set this property
@export var brush_texture:Texture2D ## Leave empty to use a simple round texture. Or use a grass texture for "grass_color" brush for example

var t_color:Color
var texture_updated:bool
