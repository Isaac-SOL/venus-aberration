extends CanvasLayer

@export var world_radar: ShapeCast2D
@export var world_radar_size: float = 720
@export var ui_radar_size: float = 128
@export var point_scene: PackedScene
@export var beep_types: Array[AudioStreamPlayer]
@export var point_lifetime: float = 6
@export var radar_sprites: Array[Texture2D]

var radar_level_factor: float = 1
var audio: bool = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if world_radar:
		%RadarCenter.global_rotation = world_radar.global_rotation
		for i in range(world_radar.get_collision_count()):
			var scannable := world_radar.get_collider(i)
			if scannable is Scannable:
				var scan_result: Array = scannable.scan()
				if not scan_result.is_empty():
					var world_vector: Vector2 = scannable.position - world_radar.position
					var ui_vector = (world_vector / (world_radar_size * radar_level_factor)) * ui_radar_size
					var new_point: Node2D = point_scene.instantiate()
					new_point.position = %RadarCenter.position + ui_vector
					new_point.self_modulate = scan_result[0]
					new_point.lifetime = point_lifetime
					add_child(new_point)
					if audio:
						beep_types[scan_result[1]].play()

func set_radar_level(level: int):
	%RadarLines.texture = radar_sprites[level]
	match level:
		0: radar_level_factor = 1
		1: radar_level_factor = 1.5
		2: radar_level_factor = 2

func toggle_audio():
	audio = not audio
