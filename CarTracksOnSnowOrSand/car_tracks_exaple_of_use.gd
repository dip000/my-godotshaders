# EXAMPLE SCRIPT
# The car will move where the mouse pointer goes
# Make sure the particles are following your car by either appending them as children or using a RemoteTransform3D
extends Node3D
class_name CarExampleOfUse

@onready var cam:Camera3D = $"../Camera3D"
@onready var wheels:Array[Node3D] = [$WheelFR, $WheelFL, $WheelBR, $WheelBL]
@onready var space_state:PhysicsDirectSpaceState3D = get_world_3d().direct_space_state

const INTERACT_RADIUS:int = 15
var query := PhysicsRayQueryParameters3D.new()
var mouse_position:Vector3


func _ready():
	query.set_collide_with_areas(true)

func _physics_process(delta:float):
	# Save the world position from where the mouse is pointing
	var result:Dictionary = _detect_from_cam_to_mouse()
	if result:
		mouse_position = result.position
	
	# Move and rotate car towards point continuously
	global_position = lerp(global_position, mouse_position, delta)
	var speed:float = (global_position - mouse_position).length()
	if speed > 0.01:
		look_at(mouse_position)
	
		# Animate wheels according to car's speed
		for wheel in wheels:
			wheel.rotate(Vector3.LEFT, delta*speed*5.0)


func _detect_from_cam_to_mouse() -> Dictionary:
	query.from = cam.global_position
	query.to = query.from + _get_world_mouse_ray()
	return space_state.intersect_ray(query)

func _get_world_mouse_ray() -> Vector3:
	var mouse_pos:Vector2 = get_viewport().get_mouse_position()
	return cam.project_ray_normal(mouse_pos) * INTERACT_RADIUS

