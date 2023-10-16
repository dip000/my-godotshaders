@tool
extends EditorPlugin

var instancer:GrassInstancer


func _enter_tree():
	add_custom_type("GrassInstancer", "Node", preload("grass_instancer.gd"), preload("icon.png"))

func _exit_tree():
	remove_custom_type("GrassInstancer")


func _forward_3d_gui_input(cam:Camera3D, event:InputEvent):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var root = get_tree().get_edited_scene_root()
		var space = root.get_world_3d().direct_space_state
		var mouse = root.get_viewport().get_mouse_position()
		var origin = cam.project_ray_origin(mouse)
		var dir = cam.project_ray_normal(mouse)
		var ray = PhysicsRayQueryParameters3D.create(origin, origin + dir * cam.far)
		
		ray.collide_with_areas = true
		var result = space.intersect_ray(ray)
		if not result:
			return EditorPlugin.AFTER_GUI_INPUT_STOP
		
		instancer.paint(result.position)
		return EditorPlugin.AFTER_GUI_INPUT_STOP
	
	return EditorPlugin.AFTER_GUI_INPUT_PASS

func _handles(object):
	if object is GrassInstancer:
		instancer = object
		return true
	return false
