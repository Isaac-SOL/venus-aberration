class_name Structure extends Area2D

@export var sleeping: bool = false

var block_evolution: bool = false
var level: int = 0
var child_deposits: Array[Deposit] = []

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
	if lv > level:
		level = lv
	
	if block_evolution:
		return
	
	match level:
		1:
			print(str(self), " starting blink mode")
			%AnimationPlayer.play("single_blink")
			for child in child_deposits:
				child.remove_all(["gold"])
			

func _on_deposit_warehouse_start_extracting():
	block_evolution = true
	get_tree().call_group("Structures", "increase_level_to", 1)
