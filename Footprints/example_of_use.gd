@tool
extends Node3D

@onready var sub_viewport:SubViewport = $SubViewport
@onready var _mat:ShaderMaterial = $Floor.get_active_material(0)

@export var update:bool:
	set(v):
		print("asdasd")
		await RenderingServer.frame_post_draw
		var texture:ViewportTexture = $SubViewport.get_texture()
		$Floor.get_active_material(0).set_shader_parameter("viewport_texture", texture)
