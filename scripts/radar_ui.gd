extends ShakeUI

@export var world_radar: ShapeCast2D
@export var world_radar_size: float = 720
@export var ui_radar_size: float = 128
@export var point_scene: PackedScene
@export var noisy_point_scene: PackedScene
@export var point_lifetime: float = 6
@export var radar_sprites: Array[Texture2D]
@export var arrow_target: Vector2
@export var max_angle_diff_rad: float = 0.139

var beep_types: Array[AudioStreamPlayer]
var radar_level_factor: float = 1
var audio: bool = true
var tracked_drones: Array[Scannable] = []
@onready var radar: ShapeCast2D = get_tree().get_first_node_in_group("Radar")

func _ready():
	for child in get_children():
		if child is AudioStreamPlayer:
			beep_types.append(child)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if world_radar:
		%RadarCenter.global_rotation = world_radar.global_rotation
		# Scan in area
		for i in range(world_radar.get_collision_count()):
			var scannable := world_radar.get_collider(i)
			if scannable is Scannable and not (scannable is Scrap):
				var scan_result: Array = scannable.scan()
				if not scan_result.is_empty():
					scan_response(scannable.global_position, scan_result)
		# Scan drones out of range
		for drone in tracked_drones:
			var drone_vector: Vector2 = drone.global_position - PlayerCharacter.static_pos
			var angle_diff: float = angle_add(drone_vector.angle(), -(radar.global_rotation + (PI / 2)))
			if abs(angle_diff) <= max_angle_diff_rad:
				var scan_result: Array = drone.scan()
				if not scan_result.is_empty():
					scan_response(drone.global_position, scan_result, true)
	var recall_vector: Vector2 = arrow_target - PlayerCharacter.static_pos
	%RadarArrowCenter.rotation = recall_vector.angle()
	%DirectionArrow.rotation = PlayerCharacter.static_rot
	%DirectionArrowShadow.rotation = PlayerCharacter.static_rot

func angle_add(a: float, b: float):
	const dpi: float = 2 * PI
	var c: float = a + b
	while c > dpi:
		c -= dpi
	while c < -dpi:
		c += dpi
	return c

func scan_response(global_pos: Vector2, scan_result: Array, out_of_range: bool = false):
	var noisy: bool = scan_result.size() >= 3 and scan_result[2]
	var world_vector: Vector2 = global_pos - world_radar.global_position
	var ui_vector = (world_vector / (world_radar_size * radar_level_factor)) * ui_radar_size
	var new_point: Node2D = noisy_point_scene.instantiate() if noisy else point_scene.instantiate()
	if noisy:
		ui_vector += Vector2(randf_range(-10, 10), randf_range(-10, 10))
		ui_vector = ui_vector.normalized() * randf() * ui_radar_size
	if out_of_range:
		ui_vector = ui_vector.normalized() * ui_radar_size * 1.05
	new_point.position = %RadarCenter.position + ui_vector
	new_point.self_modulate = scan_result[0]
	new_point.lifetime = point_lifetime
	add_child(new_point)
	if visible:
		beep_types[scan_result[1]].play()

func force_response(global_pos: Vector2, scan_result: Array):
	var world_vector: Vector2 = global_pos - world_radar.global_position
	if world_vector.length() <= world_radar_size * radar_level_factor:
		scan_response(global_pos, scan_result)

func set_radar_level(level: int):
	%RadarLines.texture = radar_sprites[level]
	match level:
		0: radar_level_factor = 1
		1: radar_level_factor = 1.5
		2: radar_level_factor = 2

func is_active() -> bool:
	return visible

func is_lower() -> bool:
	return not audio

func toggle_audio():
	audio = not audio
	var change_db: float = 9 if audio else -9
	for beep in beep_types:
		beep.volume_db += change_db

func set_arrow_active(active: bool):
	%RadarArrowCenter.visible = active

func add_tracked_drone(drone: Scannable):
	if drone not in tracked_drones:
		tracked_drones.append(drone)

func remove_tracked_drone(drone: Scannable):
	if drone in tracked_drones:
		tracked_drones.remove_at(tracked_drones.find(drone))
