extends ShakeUI

@export var world_radar: ShapeCast2D
@export var world_radar_size: float = 720
@export var ui_radar_size: float = 128
@export var point_scene: PackedScene
@export var point_lifetime: float = 6
@export var radar_sprites: Array[Texture2D]

var beep_types: Array[AudioStreamPlayer]
var radar_level_factor: float = 1
var audio: bool = true

func _ready():
	for child in get_children():
		if child is AudioStreamPlayer:
			beep_types.append(child)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if world_radar:
		%RadarCenter.global_rotation = world_radar.global_rotation
		for i in range(world_radar.get_collision_count()):
			var scannable := world_radar.get_collider(i)
			if scannable is Scannable and not (scannable is Scrap):
				var scan_result: Array = scannable.scan()
				if not scan_result.is_empty():
					scan_response(scannable.global_position, scan_result)
	var recall_vector: Vector2 = Vector2(3650, 2270) - PlayerCharacter.static_pos
	%RadarArrowCenter.rotation = recall_vector.angle()

func scan_response(global_pos: Vector2, scan_result: Array):
	var world_vector: Vector2 = global_pos - world_radar.global_position
	var ui_vector = (world_vector / (world_radar_size * radar_level_factor)) * ui_radar_size
	var new_point: Node2D = point_scene.instantiate()
	if scan_result.size() >= 3 and scan_result[2]:
		ui_vector += Vector2(randf_range(-10, 10), randf_range(-10, 10))
		ui_vector = ui_vector.normalized() * randf() * ui_radar_size
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
