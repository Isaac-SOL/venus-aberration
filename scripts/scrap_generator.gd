extends PathFollow2D

@export var scrap: PackedScene
@export var scrap_scan: PackedScene
@export var time: Vector2 = Vector2(10, 50)
@export var iron: Vector2i = Vector2i(5, 40)
@export var speed: Vector2 = Vector2(20, 60)
@export var angular_speed: Vector2 = Vector2(-90, 90)
@export var scrap_sprites: Array[Texture2D]

func _on_generator_timer_timeout():
	progress_ratio = randf()
	var vector: Vector2 = %MainCharacter.global_position - global_position
	vector += Vector2(randf_range(-200, 200), randf_range(-200, 200))
	var new_scrap: Scrap = scrap.instantiate()
	new_scrap.global_position = global_position
	new_scrap.value = randi_range(iron.x, iron.y)
	new_scrap.speed = vector.normalized() * randf_range(speed.x, speed.y)
	new_scrap.angular_speed = randf_range(angular_speed.x, angular_speed.y) * (PI / 180)
	pick_scrap_texture(new_scrap)
	%Above.add_child(new_scrap)
	var new_scan: Node2D = scrap_scan.instantiate()
	new_scan.global_position = global_position
	new_scan.set_value(new_scrap.value)
	new_scan.follow_node = new_scrap
	%WorldUI.add_child(new_scan)
	$GeneratorTimer.start(randf_range(time.x, time.y) * (1.0 if $/root/Main.iron >= 50 else 0.3))

func pick_scrap_texture(new_scrap: Scrap):
	if new_scrap.value < lerp(iron.x, iron.y, 0.33):
		new_scrap.set_sprite(scrap_sprites[0])
	elif new_scrap.value < lerp(iron.x, iron.y, 0.66):
		new_scrap.set_sprite(scrap_sprites[1])
	else:
		new_scrap.set_sprite(scrap_sprites[2])
