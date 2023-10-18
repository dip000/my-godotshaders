extends Resource
class_name TGrassVariant

## The grass variant texture to render.
## This will be appended to the grass shader.
## Every MultyMeshInstance will have a different "instance_shader_parameters/variant_index"
@export var texture:Texture2D

## How many of these grass variants will be spawned
@export var instance_count:int = 128
