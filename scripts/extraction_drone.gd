class_name ExtractionDrone extends Scannable

signal finished_moving
signal finished_extracting
signal grabbed

@export var speed: float = 10

var target: Vector2
var moving: bool = false
var id: int
var contains: Dictionary = {}
var mined_metals: Array[String] = ["iron", "bismuthine", "gold"]
var ready_for_grab: bool = false
var extraction_factor: float = 1

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

func is_empty() -> bool:
	return contains.is_empty()

func set_extract_galena():
	mined_metals.append("galena")

func seconds(t: float, t2: float = -1):
	if t2 > 0:
		return get_tree().create_timer(randf_range(t, t2)).timeout
	return get_tree().create_timer(t).timeout

func find_deposit() -> Deposit:
	var distances: Dictionary = {}
	for area in %Scanner.get_overlapping_areas():
		if area is Deposit && area.contains(mined_metals):
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
	print("Starting extraction : ", str(deposit.get_composition()))
	while deposit.contains(mined_metals):
		await seconds(0.1, 0.4 * (1 / extraction_factor))
		var metal: String = deposit.extract(mined_metals)
		if metal == "galena":
			if randf() < 0.3:
				metal = "iron"
			else:
				continue
		if !metal.is_empty():
			add_metal(metal)
	await seconds(2)
	finished_extracting.emit()

func set_drilling_audio(do_set: bool):
	%DrillingAudio.volume_db = -60 if do_set else 6
	%DrillingAudio.play()
	var tween = get_tree().create_tween()
	tween.tween_property(%DrillingAudio, "volume_db", 6 if do_set else -60, 1)
	if not do_set:
		tween.tween_callback(%DrillingAudio.stop)

func grab():
	grabbed.emit()
	disappear()

func disappear():
	%AnimationPlayer.play("disappear")

func blink():
	%AnimationPlayer.play("blink")
