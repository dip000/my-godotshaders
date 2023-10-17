@tool
extends EditorPlugin

var instanced_tool:TerraBrush


func _enter_tree():
	add_custom_type("TerraBrush", "Node", preload("tool_terra_brush.gd"), preload("icon.svg"))

func _exit_tree():
	remove_custom_type("TerraBrush")


func _forward_3d_gui_input(cam:Camera3D, event:InputEvent):
	if instanced_tool:
		var root = get_tree().get_edited_scene_root()
		var space = root.get_world_3d().direct_space_state
		var mouse = root.get_viewport().get_mouse_position()
		var origin = cam.project_ray_origin(mouse)
		var dir = cam.project_ray_normal(mouse)
		var ray = PhysicsRayQueryParameters3D.create(origin, origin + dir * cam.far)
		
		ray.collide_with_areas = true
		var result = space.intersect_ray(ray)
		
		if not result:
			instanced_tool.exit_overlay()
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				return EditorPlugin.AFTER_GUI_INPUT_STOP
			return EditorPlugin.AFTER_GUI_INPUT_PASS
		
		instanced_tool.brush_overlay( result.position )
		
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			instanced_tool.paint(result.position, true)
		elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			instanced_tool.paint(result.position, false)
			
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_UP):
			instanced_tool.scale(-10)
			return EditorPlugin.AFTER_GUI_INPUT_STOP
		elif Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_DOWN):
			instanced_tool.scale(10)
			
		if event is InputEventMouseButton:
			return EditorPlugin.AFTER_GUI_INPUT_STOP
	
	return EditorPlugin.AFTER_GUI_INPUT_PASS

func _handles(object):
	if object is TerraBrush:
		instanced_tool = object
		return true
	else:
		instanced_tool = null
		return false
