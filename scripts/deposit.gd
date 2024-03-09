class_name Deposit extends Scannable

enum CompositionType {
	CUSTOM,
	NOTHING,
	BALANCED_LOW,
	BALANCED_HIGH,
	IRON_LOW,
	IRON_HIGH,
	BIS_LOW,
	BIS_HIGH,
	GOLD_LOW,
	GOLD_HIGH,
	WAREHOUSE_GOLD
}

signal start_extracting

@export var composition_type: CompositionType = CompositionType.BALANCED_LOW
@export var composition: Dictionary = {}
@export var scan_time_interval: float = 2

const reflective_metals: Array[String] = ["iron", "bismuthine"]
const snowy_metals: Array[String] = ["gold"]

var extracted: bool = false

func _ready():
	if composition_type != CompositionType.CUSTOM:
		composition_generator_table()
	print(CompositionType.find_key(composition_type) + "\t" + str(composition))

func base_array() -> Array:
	return [scan_color, 2 if contains(snowy_metals) else pitch_type]

func scan() -> Array:
	var true_interval: float = 0.03 if contains(snowy_metals) else scan_time_interval
	if time_since_last_scan > true_interval && contains(reflective_metals):
		time_since_last_scan = 0
		return base_array() + [contains(snowy_metals)]
	return []

func get_composition_percentage() -> Dictionary:
	var total: int = get_total_amount()
	var res: Dictionary = {}
	for key in composition:
		res[key] = floori((composition[key] * 100.0) / total)
	return res

func get_composition() -> Dictionary:
	return composition

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

func extract(metals: Array[String]) -> String:
	if not extracted:
		start_extracting.emit()
		extracted = true
	for key in composition:
		if key in metals:
			composition[key] -= 1
			if composition[key] == 0:
				composition.erase(key)
			return key
	return ""

func remove_all(metals: Array[String]):
	for metal in metals:
		composition.erase(metal)

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
	elif composition_type == CompositionType.GOLD_LOW:
		composition = {
			galena = randi_range(65, 170),
			iron = randi_range(0, 50),
			bismuthine = randi_range(30, 50),
			gold = randi_range(10, 30),
			other = randi_range(70, 100)
		}
	elif composition_type == CompositionType.GOLD_HIGH:
		composition = {
			galena = randi_range(65, 100),
			iron = randi_range(0, 50),
			bismuthine = randi_range(30, 50),
			gold = randi_range(20, 60),
			other = randi_range(70, 100)
		}
	elif composition_type == CompositionType.WAREHOUSE_GOLD:
		composition = {
			"galena": randi_range(20, 65),
			"iron": randi_range(0, 50),
			"bismuthine": randi_range(30, 50),
			"gold": randi_range(20, 60),
			"???": randi_range(200, 300)
		}
