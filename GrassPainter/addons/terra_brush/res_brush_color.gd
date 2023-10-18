@tool
extends TBrush
class_name TBrushColor


## Modulates the brush texture. Use alpha to set the stroke strenght
## Modifying this will set it as the active brush
@export var color:Color:
	set(v):
		color = v
		on_active.emit()
		active = true

