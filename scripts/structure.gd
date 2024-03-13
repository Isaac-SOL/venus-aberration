class_name Structure extends Area2D

@export var sleeping: bool = false

var block_evolution: bool = false
var level: int = 0
var child_deposits: Array[Deposit] = []
var small_destruction: bool = true

static var global_level: int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	rotation = randf() * 2 * PI
	for child in get_children():
		if child is Deposit:
			child_deposits.append(child)
	if sleeping:
		visible = false
		set_deferred("process_mode", PROCESS_MODE_DISABLED)

func wake_up():
	if sleeping:
		sleeping = false
		visible = true
		set_deferred("process_mode", PROCESS_MODE_INHERIT)
		print(str(self), " woke up")

func increase_level_to(lv: int):
	if block_evolution:
		return
	if lv > level:
		level = lv
		global_level = lv
		
		match level:
			1:
				print(str(self), " starting blink mode")
				%AnimationPlayer.play("single_blink")
				for child in child_deposits:
					child.remove_all(["gold"])
			2:
				print(str(self), " starting SUPER blink mode")
				%AnimationPlayer.play("multi_blink", 1)
				for child in child_deposits:
					child.remove_all(["gold"])

func _on_deposit_warehouse_start_extracting():
	block_evolution = true
	get_tree().call_group("Structures", "increase_level_to", 1)

func causes_extinction() -> bool:
	return level == 1

func caused_extinction():
	get_tree().call_group("Structures", "increase_level_to", 2)
	get_tree().call_group("Mysteries", "increase_level_to", 0)

func causes_destruction() -> bool:
	return level == 2 and small_destruction

func caused_destruction():
	if not block_evolution:
		small_destruction = false
		print(str(self), " starting MEGA blink mode")
		%AnimationPlayer.play("mega_blink", 1)

func causes_big_destruction() -> bool:
	return level == 2 and not small_destruction
