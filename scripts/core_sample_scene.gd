extends Node3D

@export var unit_per_meter: float = 100
@export var cynlinders: Array[PackedScene]

var current_amount: int = 0

var mapping: Dictionary = {
	"other":      0,
	"galena":     1,
	"iron":       2,
	"bismuthine": 3,
	"gold":       4,
	"???":        5
}

func _process(delta):
	%Turntable.rotation.y -= delta

func get_height_meters() -> float:
	return -current_amount / unit_per_meter

func get_offset_meters() -> float:
	return get_height_meters() / 2

func clear():
	for child in %Turntable.get_children():
		child.queue_free()
	%Turntable.position.y = 0
	current_amount = 0

func spawn_cylinder(metal: String, amount: int):
	var add_height: float = -amount / unit_per_meter
	var scene: PackedScene = cynlinders[mapping[metal]]
	var new_cylinder: Node3D = scene.instantiate()
	new_cylinder.position.y = get_height_meters()
	new_cylinder.scale.y = add_height
	current_amount += amount
	%Turntable.add_child(new_cylinder)
	%Turntable.position.y = get_offset_meters()

func spawn_cylinders(composition: Dictionary):
	for metal in composition:
		spawn_cylinder(metal, composition[metal])
