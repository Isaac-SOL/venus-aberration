extends HBoxContainer

@export var hp_scene: PackedScene
@export var base_modulate: Color
@export var damaged_modulate: Color
@export var damaged_modulate_2: Color

func add_hp(amount: int):
	for i in range(amount):
		add_child(hp_scene.instantiate())

func remove_hp(amount: int):
	for i in range(amount):
		remove_child(get_child(0))

func set_hp(amount: int):
	var curr_hp: int = get_child_count()
	var diff: int = amount - curr_hp
	if diff > 0:
		add_hp(diff)
	elif diff < 0:
		remove_hp(-diff)

func blink_danger(duration: float):
	modulate = damaged_modulate
	var tween := create_tween().set_loops(-1)
	tween.tween_property(self, "modulate", damaged_modulate_2, 0.25).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "modulate", damaged_modulate, 0.25).set_ease(Tween.EASE_IN_OUT)
	await get_tree().create_timer(duration).timeout
	tween.kill()
	modulate = base_modulate
