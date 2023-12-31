# EXAMPLE OF USE
# This script will only find the mouse position in PaintSurface and call 'splash_at()'
# Refer to PaintSurface for shader logic
extends Node3D

@export var splash_color:Color ## Use alpha to blend with paint surface 
@onready var cam:Camera3D = $Camera3D
@onready var paint_surface:PaintSurface = $PaintSurface
@onready var space_state:PhysicsDirectSpaceState3D = get_world_3d().direct_space_state

const INTERACT_RADIUS:int = 15
var query := PhysicsRayQueryParameters3D.new()


func _ready():
	query.set_collide_with_areas(true)

func _input(event):
	if event is InputEventMouseButton and event.is_pressed():
		var result:Dictionary = _detect_from_cam_to_mouse()
		if result:
			var pos:Vector2 = Vector2(result.position.x, result.position.z) / paint_surface.mesh.size
			paint_surface.splash_at( pos, 0.3, splash_color )

func _detect_from_cam_to_mouse() -> Dictionary:
	query.from = cam.global_position
	query.to = query.from + _get_world_mouse_ray()
	return space_state.intersect_ray(query)

func _get_world_mouse_ray() -> Vector3:
	var mouse_pos:Vector2 = get_viewport().get_mouse_position()
	return cam.project_ray_normal(mouse_pos) * INTERACT_RADIUS
