extends Node

@export var next_scene: PackedScene

func _ready():
	await seconds(3)
	show_message_1()

func seconds(t: float, t2: float = -1):
	if t2 > 0:
		return get_tree().create_timer(randf_range(t, t2)).timeout
	return get_tree().create_timer(t).timeout

func show_message_slow(message: String, char_time: float, color: String = "green"):
	var text_base: String = "[color=" + color + "]" if not color.is_empty() else ""
	var skipping_brackets: bool = false
	for i in message.length():
		if skipping_brackets && message[i] == ']':
			skipping_brackets = false
		if message[i] == '[':
			skipping_brackets = true
		if not skipping_brackets:
			var new_text: String = text_base + message.substr(0, i+1)
			%EndLabel.text = new_text
			await seconds(char_time)

func show_message_1():
	await show_message_slow("[center][font_size=48][color=lightgreen]DATE: [color=green]21XX-09-21\n[color=lightgreen]MISSION LOCATION: [color=green]VENUS, SOLAR SYSTEM 0001\n[color=lightgreen]UNIT NAME: [color=green]VENUS AIRCRAFT VA11037\n[color=lightgreen]OBJECTIVE: [color=green]GOLD MINING", 0.1, "")
	await seconds(5)
	await show_message_slow("[center][font_size=36][color=green]In order to minimize fuel usage,\nYour unit was only equipped with the bare minimum equipment.\nYou may use any encountered material to further\nthe mission's objective.", 0.05, "")
	await seconds(8)
	var fade_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	fade_tween.tween_property(%ColorRect, "modulate", Color.WHITE, 1)
	await fade_tween.finished
	get_tree().change_scene_to_packed(next_scene)
