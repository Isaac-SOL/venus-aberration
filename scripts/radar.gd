extends ShapeCast2D

@export var target: Node2D
@export var rot_speed: float = 1.257

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	rotation += rot_speed * delta
	if target: global_position = target.global_position
