extends DroneKiller

@export var speed: float = 10

var started_walking: bool = false
var direction: Vector2

# Called when the node enters the scene tree for the first time.
func _ready():
	direction = (Vector2(6000, 4000) - global_position).normalized() * speed

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if started_walking:
		position += direction * delta

func _on_area_entered(area):
	if not started_walking and area is PlayerCharacter:
		await get_tree().create_timer(5).timeout
		%AnimationPlayer.play("stop_blinking")

func start_walking():
	%WalkTimer.start()

func _on_walk_timer_timeout():
	%StepAudioPlayer.play()


func _on_visible_on_screen_notifier_2d_screen_exited():
	if started_walking:
		queue_free()
