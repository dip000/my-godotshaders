extends Resource
class_name GrassVariantInfo

@export var mesh:Mesh ## The mesh with the "grass.gdshader" ShaderMaterial
@export var instance_count:int = 128 ## How many of these grasses will be spawned
@export var spawn_color:Color ## Grass will only spawn where the terrain's texture has this color
@export var any_but_color:bool ## Grass will only NOT spawn where the terrain's texture has this color
