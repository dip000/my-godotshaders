# EXAMPLE SCRIPT
# Refer to 'BloodPool' class which has all of the shader-related logic
# This class only moves the hearth where you point over the mouse cursor
# In a practical situation you'd just add 'bloody_pool_mesh.drop_at(global_position)' on your character

extends Node3D
class_name ExampleOfUse

@export var drip_time:float = 0.15 ## The time between each drop of blod. BloodPool will stop working momentarily if this value is too low (although it might look cooler)
@onready var bloody_pool_mesh:BloodPool = $BloodPool
@onready var bloody_cam:Camera3D = $Camera3D
@onready var bloody_hearth:Node3D = $hearth
@onready var bloody_space_state:PhysicsDirectSpaceState3D = get_world_3d().direct_space_state

const BLOODY_INTERACT_RADIUS:int = 3
var query := PhysicsRayQueryParameters3D.new()
var timer:SceneTreeTimer


func _ready():
	query.set_collide_with_areas(true)
	
	# Juice up the heart
	var bloody_dance:Tween = create_tween().set_loops()
	bloody_dance.tween_property(bloody_hearth, "rotation_degrees", Vector3.UP*45.0, 0.5)
	bloody_dance.tween_property(bloody_hearth, "rotation_degrees", Vector3.ZERO, 0.5)
	
	# Drip blood under heart position every 'drip_time' seconds
	while true:
		var pos:Vector2 = Vector2(bloody_hearth.global_position.x, bloody_hearth.global_position.z)
		bloody_pool_mesh.drop_at(pos*0.5)
		await get_tree().create_timer(drip_time).timeout


func _input(event):
	# Updates 'bloody_hearth' position on mouse pointer
	if event is InputEventMouseMotion:
		var result:Dictionary = _detect_from_cam_to_mouse()
		if result:
			bloody_hearth.global_position.x = result.position.x
			bloody_hearth.global_position.z = result.position.z

func _detect_from_cam_to_mouse() -> Dictionary:
	query.from = bloody_cam.global_position
	query.to = query.from + _get_world_mouse_position()
	return bloody_space_state.intersect_ray(query)

func _get_world_mouse_position() -> Vector3:
	var mouse_pos:Vector2 = get_viewport().get_mouse_position()
	return bloody_cam.project_ray_normal(mouse_pos) * BLOODY_INTERACT_RADIUS

