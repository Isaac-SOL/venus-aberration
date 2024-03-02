class_name ExtractionDrone extends Scannable

signal finished_moving
signal finished_extracting
signal grabbed

@export var speed: float = 10
@export var max_space: int = 300

var target: Vector2
var moving: bool = false
var id: int
var contains: Dictionary = {}
const mined_metals: Array[String] = ["iron", "bismuthine"]
var ready_for_grab: bool = false

func _process(delta):
	super._process(delta)
	if moving:
		var vec := target - global_position
		global_position += vec.normalized() * delta * speed
		if (target - global_position).length() < 5:
			moving = false
			finished_moving.emit()

func get_contents() -> Dictionary:
	return contains

func seconds(t: float, t2: float = -1):
	if t2 > 0:
		return get_tree().create_timer(randf_range(t, t2)).timeout
	return get_tree().create_timer(t).timeout

func find_deposit() -> Deposit:
	var distances: Dictionary = {}
	for area in %Scanner.get_overlapping_areas():
		if area is Deposit && area.contains_useful_metal():
			distances[(area.global_position - global_position).length_squared()] = area
	if not distances.is_empty():
		return distances[distances.keys().min()]
	return null

func move_toward_deposit(deposit: Deposit):
	target = deposit.global_position
	moving = true

func total_amount() -> int:
	var total: int = 0
	for key in contains:
		total += contains[key]
	return total

func add_metal(metal: String):
	if metal in contains:
		contains[metal] += 1
	else:
		contains[metal] = 1

func extract_deposit(deposit: Deposit):
	while deposit.contains(mined_metals) && total_amount() < max_space:
		await seconds(0.2, 0.5)
		var metal: String = deposit.extract(mined_metals)
		if !metal.is_empty():
			add_metal(metal)
	finished_extracting.emit()

func grab():
	grabbed.emit()
	disappear()

func disappear():
	%AnimationPlayer.play("disappear")

func blink():
	%AnimationPlayer.play("blink")
