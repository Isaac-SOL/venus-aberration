class_name DroneKiller extends Area2D

signal mystery_found

@export var cause_extinction: bool = true
@export var cause_destruction: bool = false
@export var cause_big_destruction: bool = false
@export var sleeping: bool = false

func _ready():
	if sleeping:
		visible = false
		set_deferred("process_mode", PROCESS_MODE_DISABLED)

func set_asleep():
	if not sleeping:
		sleeping = true
		visible = false
		set_deferred("process_mode", PROCESS_MODE_DISABLED)
		print(str(self), " asleep")

func wake_up():
	if sleeping:
		sleeping = false
		visible = true
		set_deferred("process_mode", PROCESS_MODE_INHERIT)
		print(str(self), " woke up")

func causes_extinction() -> bool:
	return cause_extinction

func caused_extinction():
	pass

func causes_destruction() -> bool:
	return cause_destruction

func caused_destruction():
	pass

func causes_big_destruction() -> bool:
	return cause_big_destruction
