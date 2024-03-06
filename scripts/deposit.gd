class_name Deposit extends Scannable

enum CompositionType {
	CUSTOM,
	NOTHING,
	BALANCED_LOW,
	BALANCED_HIGH,
	IRON_LOW,
	IRON_HIGH,
	BIS_LOW,
	BIS_HIGH
}

@export var composition_type: CompositionType = CompositionType.BALANCED_LOW
@export var composition: Dictionary = {}

func _ready():
	if composition_type != CompositionType.CUSTOM:
		composition_generator_table()
	print(CompositionType.find_key(composition_type) + "\t" + str(get_total_amount()))

func scan() -> Array:
	if time_since_last_scan > 2 && contains_useful_metal():
		time_since_last_scan = 0
		return base_array()
	return []

func get_composition_percentage() -> Dictionary:
	var total: int = get_total_amount()
	var res: Dictionary = {}
	for key in composition:
		res[key] = floori((composition[key] * 100.0) / total)
	return res

func get_total_amount() -> int:
	var total: int = 0
	for key in composition:
		total += composition[key]
	return total

func contains(metal: Array[String]) -> bool:
	for key in composition:
		if key in metal && composition[key] > 0:
			return true
	return false

func contains_useful_metal() -> bool:
	return contains(["iron", "bismuthine"])

func extract(metals: Array[String]) -> String:
	for key in composition:
		if key in metals:
			composition[key] -= 1
			if composition[key] == 0:
				composition.erase(key)
			return key
	return ""

func composition_generator_table():
	if composition_type == CompositionType.NOTHING:
		composition = {
			galena = randi_range(80, 250),
			bismuthine = randi_range(0, 50),
			other = randi_range(100, 200)
		}
	elif composition_type == CompositionType.BALANCED_LOW:
		composition = {
			galena = randi_range(80, 250),
			iron = randi_range(50, 120),
			bismuthine = randi_range(30, 150),
			other = randi_range(100, 200)
		}
	elif composition_type == CompositionType.BALANCED_HIGH:
		composition = {
			galena = randi_range(65, 210),
			iron = randi_range(90, 200),
			bismuthine = randi_range(90, 200),
			other = randi_range(70, 200)
		}
	elif composition_type == CompositionType.IRON_LOW:
		composition = {
			galena = randi_range(80, 250),
			iron = randi_range(90, 180),
			bismuthine = randi_range(20, 40),
			other = randi_range(100, 200)
		}
	elif composition_type == CompositionType.IRON_HIGH:
		composition = {
			galena = randi_range(80, 150),
			iron = randi_range(120, 250),
			bismuthine = randi_range(10, 50),
			other = randi_range(50, 120)
		}
	elif composition_type == CompositionType.BIS_LOW:
		composition = {
			galena = randi_range(80, 250),
			iron = randi_range(25, 90),
			bismuthine = randi_range(100, 150),
			other = randi_range(100, 200)
		}
	elif composition_type == CompositionType.BIS_HIGH:
		composition = {
			galena = randi_range(65, 170),
			iron = randi_range(25, 105),
			bismuthine = randi_range(100, 275),
			other = randi_range(70, 100)
		}
