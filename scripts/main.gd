class_name Main extends Node

@export var iron: int = 150
@export var bismuthine: int = 200
@export var gold: int = 0
@export var sampling_drone: PackedScene
@export var sampling_drone_price: int = 20
@export var extraction_drone: PackedScene
@export var extraction_drone_price: int = 100
@export var status_label: PackedScene
@export var scrap_scan: PackedScene

var drone_out: bool = false
var can_send_or_stop_sample: bool = true
var showing_deposit_info: bool = false
var out_drone: SamplingDrone
var out_extractions: Array[ExtractionDrone] = []
var extraction_ids: int = 1
var can_send_extraction: bool = true
var can_grab_extraction: bool = true
var can_open_menu: bool = true
var menu_open: bool = false
var extraction_factor: float = 1
var galena_extraction: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	update_counts()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed("send_drone") && can_send_or_stop_sample:
		spawn_sampling_drone()
	elif Input.is_action_just_pressed("send_extraction") && can_send_extraction:
		spawn_extraction_drone()
	elif Input.is_action_just_pressed("grab_extraction") && can_grab_extraction:
		grab_extraction_drone()
	elif Input.is_action_just_pressed("open_menu") && can_open_menu:
		open_upgrade_menu(not menu_open)
		%UIAudio.play()
	elif menu_open:
		for i in range(0, 9):
			if Input.is_action_just_pressed("menu_" + str(i + 1)) && can_open_menu:
				if %UpgradeSystem.is_upgrade_valid(i, iron):
					add_iron(-%UpgradeSystem.get_upgrade_price(i))
					%UpgradeSystem.perform_upgrade(i)
					open_upgrade_menu(false)
					%UpgradeAudio.play()
				elif i == 8 and %RadarUI.is_active():
					%RadarUI.toggle_audio()
					%UIAudio.play()
		if Input.is_action_just_pressed("debug_iron"):
			iron += 100
			update_counts()
		if Input.is_action_just_pressed("debug_bismuthine"):
			bismuthine += 100
			update_counts()

func spawn_sampling_drone():
	if not drone_out && bismuthine >= sampling_drone_price:
		can_send_or_stop_sample = false
		add_bismuthine(-sampling_drone_price)
		out_drone = sampling_drone.instantiate()
		out_drone.global_position = %MainCharacter.global_position
		%Ground.add_child(out_drone)
		make_scan(out_drone, "Sampler")
		%SpawnAudio.play()
		sampling_routine(out_drone)
	elif showing_deposit_info:
		reset_sampling_message()
		%LabelSampleResults.text = ""
		out_drone.disappear()
		drone_out = false
		reset_sampling_message()

func spawn_extraction_drone():
	if iron >= extraction_drone_price:
		add_iron(-extraction_drone_price)
		out_extractions.append(extraction_drone.instantiate())
		out_extractions[-1].global_position = %MainCharacter.global_position
		out_extractions[-1].id = extraction_ids
		out_extractions[-1].extraction_factor = extraction_factor
		if galena_extraction:
			out_extractions[-1].set_extract_galena()
		%Ground.add_child(out_extractions[-1])
		make_scan(out_extractions[-1], "[" + str(extraction_ids) + "]")
		extraction_ids += 1
		var new_label: RichTextLabel = status_label.instantiate()
		%StatusLabels.add_child(new_label)
		extraction_sent_message()
		%SpawnAudio.play()
		extraction_routine(out_extractions[-1], new_label)

func grab_extraction_drone():
	for area in %MainCharacter.get_overlapping_areas():
		if area is ExtractionDrone && area.ready_for_grab:
			%SpawnAudio.play()
			extraction_grab_routine(area)
			return
	extraction_fail_routine()

func open_upgrade_menu(open: bool):
	if open:
		menu_open = true
		%UpgradeContainer.visible = true
		%LabelMenu.text = "[color=lightgreen][0][color=green] - Close menu & upgrades"
		can_open_menu = false
		for i in range(%UpgradeFlowContainer.get_child_count()):
			%UpgradeFlowContainer.get_child(i).text = ""
			var inc_dec: String = "increase" if %RadarUI.is_lower() else "decrease"
			var message: String = %UpgradeSystem.get_upgrade_text(i) if i < 8 else "[center][color=lightgreen][9] [color=green]" + inc_dec +"\nradar audio\nfeedback" if %RadarUI.is_active() else ""
			show_message_slow_later(0.1, 0.5, %UpgradeFlowContainer.get_child(i), message, 0.02, "")
		await seconds(2.5)
		can_open_menu = true
	else:
		%LabelMenu.text = "[color=lightgreen][0][color=green] - Open menu & upgrades"
		%UpgradeContainer.visible = false
		menu_open = false


func update_counts():
	%LabelIron.text = "[right][color=green]" + str(iron) + " [color=lightgreen]Fe"
	var bis_color: String
	if bismuthine > 500: bis_color = "[color=green]"
	elif bismuthine > 250: bis_color = "[color=yellow]"
	else: bis_color = "[color=red]"
	%LabelBismuthine.text = "[right]" + bis_color + str(bismuthine) + " [color=lightgreen]Bi"
	%LabelGold.text = "[right][color=green]" + str(gold) + " [color=lightgreen]Au"

func seconds(t: float, t2: float = -1):
	if t2 > 0:
		return get_tree().create_timer(randf_range(t, t2)).timeout
	return get_tree().create_timer(t).timeout

func show_message_slow(label: RichTextLabel, message: String, char_time: float, color: String = "green"):
	var text_base: String = "[color=" + color + "]" if not color.is_empty() else ""
	var skipping_brackets: bool = false
	for i in message.length():
		if skipping_brackets && message[i] == ']':
			skipping_brackets = false
		if message[i] == '[':
			skipping_brackets = true
		if not skipping_brackets:
			var new_text: String = text_base + message.substr(0, i+1)
			if is_instance_valid(label):
				label.text = new_text
			await seconds(char_time)

func show_message_slow_later(t1: float, t2: float, label: RichTextLabel, message: String, char_time: float, color: String = "green"):
	await seconds(t1, t2)
	show_message_slow(label, message, char_time, color)

func reset_sampling_message():
	show_message_slow(%LabelSampling, "[color=lightgreen]E[color=green] - Send sampling drone [color=lightgreen]{20 Bi}", 0.01)

func show_deposit_info(deposit: Deposit):
	var text_base: String = "Sample Composition:\n"
	var comp = deposit.get_composition_percentage()
	for key in comp:
		var key_name: String = key
		if key_name == "iron": key_name = "iron (fe)"
		elif key_name == "bismuthine": key_name = "bismuthine (bi)"
		elif key_name == "gold": key_name = "gold (au)"
		text_base += "- " + str(comp[key]) + "%\t" + key_name + "\n"
	var amount: int = deposit.get_total_amount()
	if amount < 450: text_base += "Low Amount"
	elif amount < 700: text_base += "Avg Amount"
	else: text_base += "High Amount"
	show_message_slow(%LabelSampleResults, text_base, 0.01)

func sampling_routine(drone: SamplingDrone):
	drone_out = true
	show_message_slow(%LabelSampling, "Sending drone...", 0.1)
	await seconds(4)
	show_message_slow(%LabelSampling, "Drone landed, detecting nearby deposits...", 0.01)
	var deposit: Deposit = drone.find_deposit()
	if deposit:
		await seconds(3, 6)
		show_message_slow(%LabelSampling, "Deposit found, extracting sample...", 0.05)
		await seconds(4)
		show_message_slow(%LabelSampling, "Now showing core sample data", 0.05)
		show_deposit_info(deposit)
		await seconds(5)
		%LabelSampling.text = "[color=lightgreen]E[color=green] - Dismiss core sample info"
		showing_deposit_info = true
	else:
		await seconds(5, 10)
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
	show_message_slow(%LabelExtracting, "[color=lightgreen]R[color=green] - Send extraction drone [color=lightgreen]{50 Fe}", 0.01)
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
		show_message_slow(label, id_head + "Deposit reached, extracting...", 0.01)
		drone.set_drilling_audio(true)
		drone.extract_deposit(deposit)
		await drone.finished_extracting
		show_message_slow(label, id_head + "Deposit extracted, looking for new deposits...", 0.04)
		drone.set_drilling_audio(false)
		deposit = drone.find_deposit()
	await seconds(6, 15)
	if drone.is_empty():
		show_message_slow(label, id_head + "No deposits found, self-destroying...", 0.04, "yellow")
		await seconds(5)
		drone.disappear()
	else:
		show_message_slow(label, id_head + "No more deposits found, awaiting collection by aircraft", 0.04, "yellow")
		drone.ready_for_grab = true
		drone.blink()
		await drone.grabbed
	label.queue_free()

func extraction_fail_routine():
	can_grab_extraction = false
	show_message_slow(%LabelGrab, "Grab failed: No awaiting extraction drone under aircraft", 0.03, "red")
	await seconds(5)
	show_message_slow(%LabelGrab, "[color=lightgreen]F[color=green] - Collect extraction drone", 0.01)
	await seconds(1)
	can_grab_extraction = true

func extraction_grab_routine(drone: ExtractionDrone):
	var grab_results: String = "[color=yellow]"
	var content: Dictionary = drone.get_contents()
	if "iron" in content:
		iron += content["iron"]
		grab_results += "[" + str(content["iron"]) + " Fe] "
	if "bismuthine" in content:
		bismuthine += content["bismuthine"]
		grab_results += "[" + str(content["bismuthine"]) + " Bi] "
	if "gold" in content:
		gold += content["gold"]
		grab_results += "[" + str(content["gold"]) + " Au] "
	update_counts()
	drone.grab()
	can_grab_extraction = false
	show_message_slow(%LabelGrab, "Grabbed extraction drone\n" + grab_results, 0.04, "green")
	await seconds(8)
	show_message_slow(%LabelGrab, "[color=lightgreen]F[color=green] - Collect extraction drone", 0.01)
	await seconds(1)
	can_grab_extraction = true

func make_scan(follow_node: Node2D, text: String) -> Node2D:
	var new_scan: Node2D = scrap_scan.instantiate()
	new_scan.global_position = follow_node.global_position
	new_scan.set_text(text)
	new_scan.follow_node = follow_node
	%WorldUI.add_child(new_scan)
	return new_scan

func add_iron(value: int):
	iron += value
	update_counts()

func add_bismuthine(value: int):
	bismuthine += value
	update_counts()

func add_gold(value: int):
	gold += value
	update_counts()

func _on_timer_bismuthine_timeout():
	bismuthine -= 1
	update_counts()
	if bismuthine <= 0:
		# Game Over
		pass


func _on_main_character_collected_scrap(value):
	iron += value
	update_counts()
