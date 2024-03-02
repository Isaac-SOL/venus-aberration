class_name ScreenShakeCamera extends Camera2D

@export var target_node: Node2D
@export var shake_interval: float = 0.035
@export var shake_factor: float = 10

var shake_tween: Tween
var current_radius: float

@onready var next_shake: float = shake_interval
@onready var base_pos: Vector2 = position

func _process(delta):
	if target_node: base_pos = target_node.position
	next_shake -= delta
	while next_shake < 0:
		position = base_pos + rand_on_circle(current_radius * shake_factor)
		next_shake += shake_interval

func rand_on_circle(radius: float) -> Vector2:
	var unit = Vector2.from_angle(randf() * PI * 2)
	return unit * radius

func screen_shake(amount: float, duration: float):
	current_radius = amount
	if shake_tween:
		shake_tween.kill()
	shake_tween = get_tree().create_tween().set_ease(Tween.EASE_OUT).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	shake_tween.tween_property(self, "current_radius", 0, duration).from_current()
