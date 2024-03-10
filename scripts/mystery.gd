extends Node2D

var mysteries: Array[DroneKiller] = []
var level: int = -1
var block_evolution: bool = false

static var global_level: int = -1

# Called when the node enters the scene tree for the first time.
func _ready():
	for child in get_children():
		if child is DroneKiller:
			mysteries.append(child)

func increase_level_to(lv: int):
	if lv > level and not block_evolution:
		level = lv
		global_level = lv
		if level < mysteries.size():
			if level > 0:
				mysteries[level - 1].set_asleep()
			mysteries[level].wake_up()

func _on_mystery_found():
	block_evolution = true
	get_tree().call_group("Mysteries", "increase_level_to", level + 1)
