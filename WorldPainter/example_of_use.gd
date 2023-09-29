extends Node3D

@onready var cam:Camera3D = $Camera3D
@onready var shader_helper:ShaderHelper = $Ground
@onready var space_state:PhysicsDirectSpaceState3D = get_world_3d().direct_space_state

const INTERACT_RADIUS:int = 15
var query := PhysicsRayQueryParameters3D.new()


func _ready():
	query.set_collide_with_areas(true)
	
func _input(event):
	if event is InputEventMouseButton and event.is_pressed():
		var result:Dictionary = _detect_from_cam_to_mouse()
		if result:
			var pos:Vector2 = Vector2(result.position.x, result.position.z) / shader_helper.mesh.size
			shader_helper.splash_at(pos, randf_range(0.1, 0.3))

func _detect_from_cam_to_mouse() -> Dictionary:
	query.from = cam.global_position
	query.to = query.from + _get_world_mouse_ray()
	return space_state.intersect_ray(query)

func _get_world_mouse_ray() -> Vector3:
	var mouse_pos:Vector2 = get_viewport().get_mouse_position()
	return cam.project_ray_normal(mouse_pos) * INTERACT_RADIUS
