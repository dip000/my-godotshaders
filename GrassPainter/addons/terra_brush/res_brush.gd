extends Resource
class_name TBrush

@export var active:bool ## Check to draw with this brush. Note that this will unckeck every other brush so only one can be active at a time
@export var color:Color ## Modulates the brush texture. Use alpha to set the stroke strenght
@export_range(0, 100, 1, "suffix:%") var scale:float = 20.0 ## A scale of 100% is a brush the size of the whole surface

@export_group("Advanced")
@export var surface_texture:Texture2D ## The texture you'll be drawing with this brush. A new texture will be provided if you dont set this property
@export var custom_brush:Texture2D ## Override this property to use with this brush in specific. Like a grass texture for "grass_color" brush
