class_name PlayerCharacter extends Area2D

signal collected_scrap(value: int)

@export var acceleration: float = 10
@export var rot_acceleration: float = 10
@export var friction: float = 1
@export var rot_friction: float = 1

var speed := Vector2(0, 0)
var rot_speed: float = 0

static var static_pos: Vector2

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Input
	var input_force: float = 0
	if Input.is_action_pressed("forward"): input_force += acceleration
	%GPUParticles2D.emitting = input_force != 0
	speed += transform.basis_xform(Vector2.UP) * input_force * delta
	var input_torque: float = 0
	if Input.is_action_pressed("roll_right"): input_torque += rot_acceleration
	if Input.is_action_pressed("roll_left"): input_torque -= rot_acceleration
	rot_speed += input_torque * delta
	
	# Friction
	var eff_friction: float = speed.length() * friction * delta
	var eff_rot_friction: float = rot_speed * rot_friction * delta
	if speed.length() > 0.01: speed -= (speed * eff_friction) / speed.length()
	rot_speed -= eff_rot_friction
	
	# Apply speed
	position += speed * delta
	rotation += rot_speed * delta
	
	# Save publicly-accessible position
	static_pos = position
	
	# Audio
	%EngineAudio.pitch_scale = lerpf(0.01, 1, speed.length() / 100)

func _on_area_entered(area):
	if area is Scrap:
		collected_scrap.emit(area.value)
		area.queue_free()

func add_speed(velocity: Vector2):
	speed += velocity
