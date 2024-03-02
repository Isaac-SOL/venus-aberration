class_name Main extends Node

@export var iron: int = 200
@export var bismuthine: int = 200
@export var sampling_drone: PackedScene
@export var sampling_drone_price: int = 20
@export var extraction_drone: PackedScene
@export var extraction_drone_price: int = 100
@export var status_label: PackedScene

var drone_out: bool = false
var can_send_or_stop_sample: bool = true
var showing_deposit_info: bool = false
var out_drone: SamplingDrone
var out_extractions: Array[ExtractionDrone] = []
var extraction_ids: int = 1
var can_send_extraction: bool = true
var can_grab_extraction: bool = true

# Called when the node enters the scene tree for the first time.
func _ready():
	update_counts()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed("send_drone") && can_send_or_stop_sample:
		if not drone_out && bismuthine >= sampling_drone_price:
			can_send_or_stop_sample = false
			bismuthine -= sampling_drone_price
			out_drone = sampling_drone.instantiate()
			out_drone.global_position = %MainCharacter.global_position
			%Ground.add_child(out_drone)
			sampling_routine(out_drone)
			update_counts()
		elif showing_deposit_info:
			reset_sampling_message()
			%LabelSampleResults.text = ""
			out_drone.disappear()
			drone_out = false
			reset_sampling_message()
	elif Input.is_action_just_pressed("send_extraction") && can_send_extraction:
		if iron >= extraction_drone_price:
			iron -= extraction_drone_price
			out_extractions.append(extraction_drone.instantiate())
			out_extractions[-1].global_position = %MainCharacter.global_position
			out_extractions[-1].id = extraction_ids
			extraction_ids += 1
			%Ground.add_child(out_extractions[-1])
			var new_label: RichTextLabel = status_label.instantiate()
			%StatusLabels.add_child(new_label)
			extraction_sent_message()
			extraction_routine(out_extractions[-1], new_label)
			update_counts()
	elif Input.is_action_just_pressed("grab_extraction") && can_grab_extraction:
		for area in %MainCharacter.get_overlapping_areas():
			if area is ExtractionDrone && area.ready_for_grab:
				extraction_grab_routine(area)
				return
		extraction_fail_routine()

func update_counts():
	%LabelIron.text = str(iron) + " Fe"
	%LabelBismuthine.text = str(bismuthine) + " Bi"

func seconds(t: float, t2: float = -1):
	if t2 > 0:
		return get_tree().create_timer(randf_range(t, t2)).timeout
	return get_tree().create_timer(t).timeout

func show_message_slow(label: RichTextLabel, message: String, char_time: float, color: String = "green"):
	var text_base: String = "[color=" + color + "]"
	for i in message.length():
		var new_text: String = text_base + message.substr(0, i+1)
		label.text = new_text
		await seconds(char_time)

func reset_sampling_message():
	show_message_slow(%LabelSampling, "E - Send sampling drone {20 Bi}", 0.01)

func show_deposit_info(deposit: Deposit):
	var text_base: String = "Sample Composition:\n"
	var comp = deposit.get_composition_percentage()
	for key in comp:
		text_base += "- " + str(comp[key]) + "%\t" + key + "\n"
	var amount: int = deposit.get_total_amount()
	if amount < 400:
		text_base += "Low Amount"
	elif amount < 600:
		text_base += "Avg Amount"
	else:
		text_base += "High Amount"
	show_message_slow(%LabelSampleResults, text_base, 0.01)

func sampling_routine(drone: SamplingDrone):
	drone_out = true
	show_message_slow(%LabelSampling, "Sending drone...", 0.1)
	await seconds(4)
	show_message_slow(%LabelSampling, "Drone landed, detecting nearby deposits...", 0.05)
	var deposit: Deposit = drone.find_deposit()
	if deposit:
		await seconds(5, 20)
		show_message_slow(%LabelSampling, "Deposit found, extracting sample...", 0.05)
		await seconds(4, 8)
		show_message_slow(%LabelSampling, "Now showing core sample data", 0.05)
		show_deposit_info(deposit)
		await seconds(5)
		%LabelSampling.text = "[color=green]E - Dismiss core sample info"
		showing_deposit_info = true
	else:
		await seconds(15, 25)
		show_message_slow(%LabelSampling, "No deposits found", 0.1)
		await seconds(5)
		drone.disappear()
		drone_out = false
		reset_sampling_message()
	can_send_or_stop_sample = true

func extraction_sent_message():
	can_send_extraction = false
	show_message_slow(%LabelExtracting, "Extraction drone sent", 0.1)
	await seconds(5)
	show_message_slow(%LabelExtracting, "R - Send extraction drone {100 Fe}", 0.01)
	await seconds(1)
	can_send_extraction = true

func extraction_routine(drone: ExtractionDrone, label: RichTextLabel):
	var id_head: String = "[" + str(drone.id) + "] "
	show_message_slow(label, id_head + "Sending drone...", 0.1)
	await seconds(4)
	show_message_slow(label, id_head + "Drone landed, detecting nearby suitable deposits...", 0.05)
	var deposit: Deposit = drone.find_deposit()
	while deposit:
		await seconds(3, 8)
		show_message_slow(label, id_head + "Found deposit, moving...", 0.01)
		drone.move_toward_deposit(deposit)
		await drone.finished_moving
		show_message_slow(label, id_head + "Deposit reached, extracting...", 0.1)
		drone.extract_deposit(deposit)
		await drone.finished_extracting
		show_message_slow(label, id_head + "Deposit extracted, looking for new deposits...", 0.04)
		deposit = drone.find_deposit()
	await seconds(6, 15)
	show_message_slow(label, id_head + "No more deposits found, awaiting grab", 0.04, "yellow")
	drone.ready_for_grab = true
	drone.blink()
	await drone.grabbed
	label.queue_free()

func extraction_fail_routine():
	can_grab_extraction = false
	print("fail")
	show_message_slow(%LabelGrab, "Grab failed: No awaiting extraction drone under aircraft", 0.03, "red")
	await seconds(5)
	show_message_slow(%LabelGrab, "T - Grab extraction drone", 0.01)
	await seconds(1)
	can_grab_extraction = true

func extraction_grab_routine(drone: ExtractionDrone):
	var grab_results: String = "[color=yellow]"
	var content: Dictionary = drone.get_contents()
	if "iron" in content:
		iron += content["iron"]
		grab_results += "[" + str(iron) + " Fe] "
	if "bismuthine" in content:
		bismuthine += content["bismuthine"]
		grab_results += "[" + str(bismuthine) + " Bi] "
	update_counts()
	drone.grab()
	can_grab_extraction = false
	show_message_slow(%LabelGrab, "Grabbed extraction drone\n" + grab_results, 0.04)
	await seconds(8)
	show_message_slow(%LabelGrab, "T - Grab extraction drone", 0.01)
	await seconds(1)
	can_grab_extraction = true
