class_name Scannable extends Area2D

@export var scan_color: Color = Color.GREEN
@export var pitch_type: int = 0

var time_since_last_scan: float = INF

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time_since_last_scan += delta

func base_array() -> Array:
	return [scan_color, pitch_type]

func scan() -> Array:
	if time_since_last_scan > 2:
		time_since_last_scan = 0
		return base_array()
	return []
