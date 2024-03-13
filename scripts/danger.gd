extends DroneKiller

@export var killer: bool = false
@export var max_speed: float = 100
@export var min_speed: float = 20
@export var distance_max_speed: float = 50
@export var rad_per_sec: float = 0.2
@export var dist_per_sec: float = 15
@export var max_audio_pitch_scale: float = 1

var noticed: bool = false
var move_away: bool = false
var target_radial: float = 0
var target_distance: float = 300
var radial_dir: float
var light_time: float = 0.25

# Called when the node enters the scene tree for the first time.
func _ready():
	super._ready()
	radial_dir = -1 if randf() > 0.5 else 1
	if not killer:
		_on_visible_on_screen_notifier_2d_screen_entered()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if noticed:
		# Blinking light
		if killer:
			light_time -= delta
			if light_time <= 0:
				light_time += 0.25
				%Light.visible = not %Light.visible
		
		# Calculate target position in radial coordinates
		if not move_away:
			target_radial += rad_per_sec * delta * radial_dir
			var dist: float = global_position.distance_to(PlayerCharacter.static_pos)
			if dist < target_distance + 50:
				target_distance -= dist_per_sec * delta
			if killer and dist < target_distance:
				target_distance = dist
		else:
			dist_per_sec *= 1.05
			target_distance += 4 * dist_per_sec * delta
		
		# Transform to planar coordinates
		var target_vec := Vector2.from_angle(target_radial) * target_distance
		var target_pos: Vector2 = target_vec + PlayerCharacter.static_pos
		
		# Move to target position
		var move_vec: Vector2 = target_pos - global_position
		var dist_move: float = move_vec.length()
		var move_speed = clampf(lerp(min_speed, max_speed, dist_move / distance_max_speed), min_speed, max_speed)
		var eff_move_vec: Vector2 = move_vec.normalized() * move_speed * delta
		global_position += eff_move_vec
		rotation = (PlayerCharacter.static_pos - global_position).angle()
		
		# Audio
		%AudioStreamPlayer2D.pitch_scale = (((move_speed / max_speed) / 2) + 0.5) * max_audio_pitch_scale

func _on_visible_on_screen_notifier_2d_screen_entered():
	if not noticed:
		noticed = true
		mystery_found.emit()
		target_radial = (global_position - PlayerCharacter.static_pos).angle()
		%FlyTimer.start()


func _on_visible_on_screen_notifier_2d_screen_exited():
	if noticed:
		await get_tree().create_timer(5).timeout
		var alpha: float = 1
		while alpha > 0:
			modulate = Color(1, 1, 1, alpha)
			alpha -= 0.01
			await get_tree().process_frame
		queue_free()


func _on_fly_timer_timeout():
	move_away = true
	if not killer:
		target_radial = (Vector2(8000, 6000) - PlayerCharacter.static_pos).angle()


func _on_area_entered(area):
	if killer and area is PlayerCharacter:
		$/root/Main.damage_player_big(global_position, 2)
		queue_free()
