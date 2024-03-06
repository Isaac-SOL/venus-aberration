extends ShapeCast2D

@export var target: Node2D
@export var rot_speed: float = 1.257
@export var shapes: Array[Shape2D]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	rotation += rot_speed * delta
	if target: global_position = target.global_position

func set_shape_level(level: int):
	set_deferred("shape", shapes[level])
