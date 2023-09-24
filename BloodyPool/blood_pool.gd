# SHADER LOGIC
# This script animates the individual blood drops in the shader using uniforms 'positions' and 'scales'
# Make sure you don't call 'drop_at()' too often or it will flood the pool until 'drying_time' finishes

extends MeshInstance3D
class_name BloodPool

@export var pool_size:int = 64 ## This value MUST match the constant 'TOTAL_BLOOD_DROPS' in shader or it will throw index out-of-reach errors
@export var growing_time:float = 0.2 ## Time the blood drop will grow in size, usually fast
@export var drying_time:float = 4 ## Time the blod drop will start drying, usually slow
@export var delay_until_drying_starts:float = 0.2 ## Time the blod drop will remain idle when is fully grown

@onready var _mat:ShaderMaterial = get_active_material(0)
var _bloody_pool:Array[BloodDrop]


func _ready():
	# Fill up shader variables. They will not be immediately visible because all 'scales' are initialized as 0.0
	var positions:PackedVector2Array = []
	positions.resize(pool_size)
	_mat.set_shader_parameter("positions", positions)
	
	var scales:PackedFloat32Array = []
	scales.resize(pool_size)
	_mat.set_shader_parameter("scales", scales)
	
	# Setup '_bloody_pool' to manage and animate all active blood drops
	BloodDrop.mat = _mat
	for i in pool_size:
		_bloody_pool.append( BloodDrop.new(i) )


func drop_at(pos:Vector2):
	# Find any 'BloodDrop' inactive to use it
	# The tween will make it inactive again when animations finishes, so it can be reused
	for blod_drop in _bloody_pool:
		if not blod_drop.active:
			blod_drop.start(pos)
			var tween:Tween = get_tree().create_tween()
			tween.tween_method(blod_drop.animate, 0.0, growing_time, growing_time)
			tween.tween_method(blod_drop.animate, growing_time, 0.0, drying_time).set_delay(delay_until_drying_starts)
			tween.finished.connect(blod_drop.end)
			break


class BloodDrop:
	var active:bool
	var _index:int
	static var mat:ShaderMaterial
	
	func _init(index:int):
		_index = index
	
	func start(pos:Vector2):
		active = true
		mat["shader_parameter/positions"][_index] = pos
		
	func animate(value:float):
		mat["shader_parameter/scales"][_index] = value

	func end():
		active = false
