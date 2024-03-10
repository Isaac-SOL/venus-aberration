extends DroneKiller

@export var interval_short: float = 0.2
@export var interval_long: float = 2
@export var dot_color: Color
@export var speed: float = 250

var noticed: bool = false
var blink_progress: float = 0
var direction: Vector2

# Called when the node enters the scene tree for the first time.
func _ready():
	super._ready()
	direction = (Vector2(8000, 6000) - global_position).normalized() * speed

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var distance = (PlayerCharacter.static_pos - global_position).length()
	var true_interval: float = interval_short if noticed else lerp(interval_short, interval_long, distance / 960)
	blink_progress += delta / true_interval
	if blink_progress > 1:
		blink_progress -= 1
		get_tree().get_first_node_in_group("RadarUI").force_response(global_position, [dot_color, 3, false])
	if noticed:
		position += direction * delta
		speed *= 1.02

func _on_visible_on_screen_notifier_2d_screen_exited():
	if noticed:
		await get_tree().create_timer(5).timeout
		queue_free()

func _on_area_entered(area):
	if not noticed and area is PlayerCharacter:
		await get_tree().create_timer(3).timeout
		noticed = true
		mystery_found.emit()
