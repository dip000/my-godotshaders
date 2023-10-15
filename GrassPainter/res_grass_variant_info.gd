extends Resource
class_name GrassVariantInfo

@export var mesh:Mesh ## The mesh with the "grass.gdshader" ShaderMaterial
@export var instance_count:int = 128 ## How many of these grasses will be spawned
@export var spawn_color:Color ## The grass will only spawn where the terrain's texture has this color

