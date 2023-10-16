extends Resource
class_name GrassBrush

@export var active:bool
@export var color:Color
@export_range(0, 1, 0.05, "or_greater") var scale:float = 0.25

@export_group("Advanced")
@export var surface_texture:Texture2D ## The texture you'll be drawing using this brush
@export var grass_spawn_variants:Array[GrassVariantInfo] ## ONLY FOR GRASS SPAWNER BRUSH: The distribution of grass instances that this brush will spawn

