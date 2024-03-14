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
@export var gold_deposit: PackedScene
@export var shade: PackedScene
@export var danger: PackedScene

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
var hint_queue: Array[Tween] = []
var hint_explore_extract_given: bool = false
var hint_sampling_given: bool = false
var hint_gold_given: bool = false
var player_hp: int = 10
var lost_hp: bool = false

const MENU_CLOSE :=           "[color=lightgreen][zero][color=green] - Close menu & upgrades"
const MENU_OPEN :=            "[color=lightgreen][zero][color=green] - Open menu & upgrades"
const MENU_OPEN_ATTENTION :=  "[color=lightgreen][zero][color=yellow] - Open menu & upgrades"
const MISSION_END_SUCCESS := "[center][color=lightgreen][font_size=72]end of mission\n[color=green][font_size=48]after running out of fuel, you left the planet\nand brought back home a total of\n[color=yellow][font_size=72] "
const MISSION_END_FAILURE := "[center][color=lightgreen][font_size=72]end of mission\n[color=green][font_size=48]after an encounter with several\nunknown entities, you lost your life as well as\n[color=red][font_size=72] "
const MENU_PAUSED := "[center][color=green][font_size=72]PAUSED"

const RADAR_AUDIO_INCREASE := "[center][color=lightgreen][9] [color=green]increase\nradar audio\nfeedback"
const RADAR_AUDIO_DECREASE := "[center][color=lightgreen][9] [color=green]decrease\nradar audio\nfeedback"
const HEAL_MENU := "[center][color=lightgreen][8] [color=yellow]heal one\nhull point\n[color=lightgreen]{200 Bi}"

const DRONE_SAMPLING_MENU :=      "[color=lightgreen]E[color=green] - Drop sampling drone [color=lightgreen]{20 Bi}"
const DRONE_SAMPLING_DROPPING :=  "Dropping sampling drone..."
const DRONE_SAMPLING_SEARCHING := "Sampling drone landed, detecting nearby deposits..."
const DRONE_SAMPLING_FOUND :=     "Deposit found, extracting sample..."
const DRONE_SAMPLING_NOT_FOUND := "No deposits found"
const DRONE_SAMPLING_SHOWING :=   "Now showing core sample data"
const DRONE_SAMPLING_DISMISS :=   "[color=lightgreen]E[color=green] - Dismiss core sample info"
const DRONE_SAMPLING_LOST :=      "Lost connection with drone"

const DRONE_EXTRACTION_MENU :=         "[color=lightgreen]R[color=green] - Drop/Collect extraction drone [color=lightgreen]{50 Fe}"
const DRONE_EXTRACTION_DROPPED :=      "Extraction drone dropped"
const DRONE_EXTRACTION_DROPPING :=     "Dropping extraction drone..."
const DRONE_EXTRACTION_LANDED :=       "Drone landed, detecting nearby suitable deposits..."
const DRONE_EXTRACTION_FOUND :=        "Found deposit, moving..."
const DRONE_EXTRACTION_NOT_FOUND :=    "No deposits found, self-destructing..."
const DRONE_EXTRACTION_NOT_FOUND_2 :=  "No more deposits found, awaiting aircraft"
const DRONE_EXTRACTION_EXTRACTING :=   "Deposit reached, extracting..."
const DRONE_EXTRACTION_SEARCHING :=    "Deposit extracted, looking for new deposits..."
const DRONE_EXTRACTION_CANT_DROP :=    "Cannot drop extraction drone: no room"
const DRONE_EXTRACTION_COLLECT :=      "Collected extraction drone"
const DRONE_EXTRACTION_CANT_COLLECT := "Collect failed: No awaiting extraction drone under aircraft"
const DRONE_EXTRACTION_LOST :=         "Lost connection with drone"

const HINT_FLOATING_SCRAP :=  "Grab the floating scrap\nto get iron (Fe)"
const HINT_RADAR_DRONES :=    "The radar detects ground deposits\nUse drones to analyze and extract"
const HINT_SAMPLING :=        "Use the sampling drone to check\nif a deposit is worth extracting"
const HINT_EXTRACT_EXPLORE := "You may explore while waiting\nfor the drone to finish extracting"
const HINT_USE_IRON :=        "Find iron (Fe) to upgrade\nand bismuthine (Bi) to refuel"
const HINT_FIND_GOLD :=       "Find as much gold (Au) as possible\nbefore running out of fuel (Bi)"

# Called when the node enters the scene tree for the first time.
func _ready():
	update_counts()
	await seconds(5)
	await seconds(20)
	queue_hint(HINT_FLOATING_SCRAP)
	spawn_leading_gold()
	spawn_leading_shade()

func spawn_leading_gold():
	await seconds(250)
	while true:
		await seconds(180)
		print("spawned gold")
		if Structure.global_level >= 1:
			break
		var new_deposit: Deposit = gold_deposit.instantiate()
		new_deposit.global_position = PlayerCharacter.static_pos + Vector2(600, 330)
		%Ground.add_child(new_deposit)

func spawn_leading_shade():
	await seconds(150)
	while true:
		await seconds(200)
		print("spawned shade")
		if Structure.global_level >= 2:
			break
		var new_shade: Node2D = shade.instantiate()
		new_shade.global_position = PlayerCharacter.static_pos + Vector2(680, 400)
		%Ground.add_child(new_shade)

func spawn_danger():
	var next_time: float = 250
	while true:
		await seconds(next_time)
		print("spawned danger")
		var new_danger: Node2D = danger.instantiate()
		var norm_pos := Vector2.from_angle(randf_range(0, 2 * PI)) * 700
		new_danger.global_position = PlayerCharacter.static_pos + norm_pos
		%Ground.add_child(new_danger)
		next_time *= 0.9

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	# Manage hints
	hint_player()
	
	if Input.is_action_just_pressed("send_drone") && can_send_or_stop_sample:
		spawn_sampling_drone()
	elif Input.is_action_just_pressed("send_extraction") && can_send_extraction:
		spawn_extraction_drone()
	elif Input.is_action_just_pressed("open_menu") && can_open_menu:
		open_upgrade_menu(not menu_open)
		%UIAudio.play()
	elif menu_open:
		for i in range(0, 9):
			if Input.is_action_just_pressed("menu_" + str(i + 1)) && can_open_menu:
				if %UpgradeSystem.is_upgrade_valid(i, iron):
					add_iron(-%UpgradeSystem.get_upgrade_price(i))
					%UpgradeSystem.perform_upgrade(i)
					if i == 0 and %UpgradeSystem.get_upgrade_level(0) == 1:
						queue_hint(HINT_RADAR_DRONES)
					open_upgrade_menu(false)
					%UpgradeAudio.play()
				elif i == 7 and player_hp < 10 and bismuthine >= 200:
					bismuthine -= 200
					update_counts()
					player_hp += 1
					%HPBoxContainer.set_hp(player_hp if player_hp > 0 else 0)
					screen_shake(1, 0.5)
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

func pause():
	get_tree().paused = not get_tree().paused
	if get_tree().paused:
		show_message_slow(%EndLabel, MENU_PAUSED, 0.01)
	else:
		await seconds(0.1)
		%EndLabel.text = ""
		

func hint_player():
	if hint_queue.size() > 0:
		if not hint_queue[0].is_valid() or hint_queue[0].get_loops_left() == 0:
			hint_queue.remove_at(0)
			if hint_queue.size() > 0:
				hint_queue[0].play()
		elif not hint_queue[0].is_running():
			hint_queue[0].play()

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
	var room := true
	# Attempt grabbing a drone
	for area in %MainCharacter.get_overlapping_areas():
		if area is ExtractionDrone:
			if area.ready_for_grab:
				extraction_grab_routine(area)
				return
			room = false
	# If there was no drone, drop one
	if iron >= extraction_drone_price:
		if not room:
			extraction_send_fail_routine()
			return
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
		%LabelMenu.text = MENU_CLOSE
		can_open_menu = false
		for i in range(%UpgradeFlowContainer.get_child_count()):
			%UpgradeFlowContainer.get_child(i).text = ""
			var message: String
			if i < 7: message = %UpgradeSystem.get_upgrade_text(i)
			elif i == 7 and player_hp < 10: message = HEAL_MENU
			elif i == 8 and %RadarUI.is_active(): message = RADAR_AUDIO_INCREASE if %RadarUI.is_lower() else RADAR_AUDIO_DECREASE
			else: message = ""
			show_message_slow_later(0.1, 0.5, %UpgradeFlowContainer.get_child(i), message, 0.02, "")
		await seconds(2.5)
		can_open_menu = true
	else:
		%LabelMenu.text = MENU_OPEN
		%UpgradeContainer.visible = false
		menu_open = false


func update_counts():
	%LabelIron.text = "[right][color=green]" + str(iron) + " [color=lightgreen]Fe"
	var bis_color: String
	if bismuthine > 500: bis_color = "[color=green]"
	elif bismuthine > 250: bis_color = "[color=yellow]"
	else: bis_color = "[color=red]"
	%LabelBismuthine.text = "[right]" + bis_color + str(bismuthine) + " [color=lightgreen]Bi"
	%LabelGold.text = "[color=green]" + str(gold) + " [color=lightgreen]Au"
	if not menu_open and %UpgradeSystem.get_upgrade_level(0) == 0 and iron >= %UpgradeSystem.get_upgrade_price(0):
		%LabelMenu.text = MENU_OPEN_ATTENTION

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

func show_hint(message: String):
	show_message_slow(%LabelHint, "[center][color=yellow]" + message, 0.05, "")

func queue_hint(message: String):
	var tween = create_tween()
	tween.tween_callback(func(): show_hint(message))
	tween.tween_interval(20)
	tween.tween_callback(func(): %LabelHint.text = "")
	tween.pause()
	hint_queue.append(tween)

func queue_hint_later(message: String, wait: float):
	await seconds(wait)
	queue_hint(message)

func show_message_slow_later(t1: float, t2: float, label: RichTextLabel, message: String, char_time: float, color: String = "green"):
	await seconds(t1, t2)
	show_message_slow(label, message, char_time, color)

func reset_sampling_message():
	show_message_slow(%LabelSampling, DRONE_SAMPLING_MENU, 0.01)
	%CoreSample.clear()

func damage_player_light(explosion_source: Vector2, max_distance: float = 300):
	var char_vector: Vector2 = %MainCharacter.global_position - explosion_source
	if char_vector.length() < max_distance:
		%MainCharacter.add_speed(char_vector.normalized() * 500)
	screen_shake(2, 1.5)
	%ExplosionAudio.play()

func damage_player_big(explosion_source: Vector2, damage_amount: int, max_distance: float = 500):
	var char_vector: Vector2 = %MainCharacter.global_position - explosion_source
	if char_vector.length() < max_distance:
		%MainCharacter.add_speed(char_vector.normalized() * 1000)
		player_hp -= damage_amount
		%HPBoxContainer.set_hp(player_hp if player_hp > 0 else 0)
		%HPBoxContainer.blink_danger(6)
		%MainCharacter.play_beeps(2)
	screen_shake(3, 2)
	%ExplosionAudioBig.play()
	if player_hp <= 0:
		end_mission(false)
	elif not lost_hp:
		lost_hp = true
		spawn_danger()

func end_mission(success: bool):
	if not success:
		%MainCharacter.visible = false
	var message: String = MISSION_END_SUCCESS if success else MISSION_END_FAILURE
	message += str(gold) + " Au"
	get_tree().paused = true
	show_message_slow(%EndLabel, message, 0.1, "")

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
	if amount < 400: text_base += "Low Amount"
	elif amount < 600: text_base += "Avg Amount"
	else: text_base += "High Amount"
	show_message_slow(%LabelSampleResults, text_base, 0.01)
	# Core sample visualization
	%CoreSample.spawn_cylinders(deposit.get_composition())

func sampling_routine(drone: SamplingDrone):
	drone_out = true
	show_message_slow(%LabelSampling, DRONE_SAMPLING_DROPPING, 0.05)
	await seconds(4)
	show_message_slow(%LabelSampling, DRONE_SAMPLING_SEARCHING, 0.01)
	
	if drone.is_on_structure_causing_extinction():
		await seconds(3)
		drone.destroy_slow()
		await seconds(7)
		drone_out = false
		show_message_slow(%LabelSampling, DRONE_SAMPLING_LOST, 0.03, "red")
		await seconds(7)
		show_message_slow(%LabelSampling, DRONE_SAMPLING_MENU, 0.01)
		can_send_or_stop_sample = true
		return
	
	if drone.is_on_structure_causing_destruction():
		await seconds(3)
		show_message_slow(%LabelSampling, DRONE_SAMPLING_FOUND, 0.05)
		await seconds(4)
		damage_player_light(drone.global_position)
		drone.destroy_immediate()
		drone_out = false
		show_message_slow(%LabelSampling, DRONE_SAMPLING_LOST, 0.03, "red")
		await seconds(7)
		show_message_slow(%LabelSampling, DRONE_SAMPLING_MENU, 0.01)
		can_send_or_stop_sample = true
		return
		
	if drone.is_on_structure_causing_big_destruction():
		await seconds(3)
		show_message_slow(%LabelSampling, DRONE_SAMPLING_FOUND, 0.05)
		await seconds(4)
		damage_player_big(drone.global_position, 2)
		drone.destroy_immediate()
		drone_out = false
		show_message_slow(%LabelSampling, DRONE_SAMPLING_LOST, 0.03, "red")
		await seconds(7)
		show_message_slow(%LabelSampling, DRONE_SAMPLING_MENU, 0.01)
		can_send_or_stop_sample = true
		return
	
	var deposit: Deposit = drone.find_deposit()
	if deposit:
		await seconds(3, 6)
		show_message_slow(%LabelSampling, DRONE_SAMPLING_FOUND, 0.05)
		await seconds(4)
		show_message_slow(%LabelSampling, DRONE_SAMPLING_SHOWING, 0.05)
		show_deposit_info(deposit)
		if not hint_sampling_given:
			hint_sampling_given = true
			queue_hint(HINT_SAMPLING)
		await seconds(5)
		%LabelSampling.text = DRONE_SAMPLING_DISMISS
		showing_deposit_info = true
	else:
		await seconds(5, 10)
		show_message_slow(%LabelSampling, DRONE_SAMPLING_NOT_FOUND, 0.1)
		await seconds(5)
		drone.disappear()
		drone_out = false
		reset_sampling_message()
	can_send_or_stop_sample = true

func extraction_sent_message():
	can_send_extraction = false
	show_message_slow(%LabelExtracting, DRONE_EXTRACTION_DROPPED, 0.1)
	await seconds(5)
	show_message_slow(%LabelExtracting, DRONE_EXTRACTION_MENU, 0.01)
	await seconds(1)
	can_send_extraction = true

func extraction_routine(drone: ExtractionDrone, label: RichTextLabel):
	var id_head: String = "[" + str(drone.id) + "] "
	show_message_slow(label, id_head + DRONE_EXTRACTION_DROPPING, 0.06)
	await seconds(4)
	show_message_slow(label, id_head + DRONE_EXTRACTION_LANDED, 0.05)
	
	if drone.is_on_structure_causing_extinction():
		await seconds(3)
		drone.destroy_slow()
		await seconds(7)
		show_message_slow(label, id_head + DRONE_EXTRACTION_LOST, 0.03, "red")
		await seconds(7)
		label.queue_free()
		return
	
	var deposit: Deposit = drone.find_deposit()
	while deposit:
		await seconds(3, 8)
		show_message_slow(label, id_head + DRONE_EXTRACTION_FOUND, 0.01)
		drone.move_toward_deposit(deposit)
		await drone.finished_moving
		var eta_secs: String = "\n(ETA " + drone.get_eta_string(deposit) + ")"
		show_message_slow(label, id_head + DRONE_EXTRACTION_EXTRACTING + eta_secs, 0.01)
		drone.set_drilling_audio(true)
		drone.extract_deposit(deposit)
		if not hint_explore_extract_given:
			queue_hint(HINT_EXTRACT_EXPLORE)
			hint_explore_extract_given = true
			%UpgradeSystem.allow_extraction_upgrades = true
		
		if drone.is_on_structure_causing_destruction():
			await seconds(3)
			damage_player_light(drone.global_position)
			drone.destroy_immediate()
			show_message_slow(label, id_head + DRONE_EXTRACTION_LOST, 0.03, "red")
			await seconds(7)
			label.queue_free()
			return
		
		if drone.is_on_structure_causing_big_destruction():
			await seconds(3)
			damage_player_big(drone.global_position, 2)
			drone.destroy_immediate()
			show_message_slow(label, id_head + DRONE_EXTRACTION_LOST, 0.03, "red")
			await seconds(7)
			label.queue_free()
			return
		
		await drone.finished_extracting
		show_message_slow(label, id_head + DRONE_EXTRACTION_SEARCHING, 0.04)
		drone.set_drilling_audio(false)
		deposit = drone.find_deposit()
	await seconds(6, 15)
	if drone.is_empty():
		show_message_slow(label, id_head + DRONE_EXTRACTION_NOT_FOUND, 0.04, "yellow")
		await seconds(5)
		drone.disappear()
	else:
		show_message_slow(label, id_head + DRONE_EXTRACTION_NOT_FOUND_2, 0.04, "yellow")
		drone.ready_for_grab = true
		drone.blink()
		await drone.grabbed
	label.queue_free()

func extraction_send_fail_routine():
	can_send_extraction = false
	show_message_slow(%LabelExtracting, DRONE_EXTRACTION_CANT_DROP, 0.03, "red")
	await seconds(5)
	show_message_slow(%LabelExtracting, DRONE_EXTRACTION_MENU, 0.01)
	await seconds(1)
	can_send_extraction = true

func extraction_fail_routine():
	can_send_extraction = false
	show_message_slow(%LabelExtracting, DRONE_EXTRACTION_CANT_COLLECT, 0.03, "red")
	await seconds(5)
	show_message_slow(%LabelExtracting, DRONE_EXTRACTION_MENU, 0.01)
	await seconds(1)
	can_send_extraction = true

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
	can_send_extraction = false
	show_message_slow(%LabelExtracting, DRONE_EXTRACTION_COLLECT + "\n" + grab_results, 0.04, "green")
	await seconds(8)
	show_message_slow(%LabelExtracting, DRONE_EXTRACTION_MENU, 0.01)
	await seconds(1)
	can_send_extraction = true
	if not hint_gold_given and "iron" in content:
		hint_gold_given = true
		await seconds(10)
		queue_hint(HINT_USE_IRON)
		queue_hint(HINT_FIND_GOLD)

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

func screen_shake(amount: float, time: float):
	%ScreenShakeCamera.screen_shake(amount, time)
	%RadarUI.screen_shake(amount, time)
	%MainUI.screen_shake(amount, time)
	%UIBorders.screen_shake(amount, time)

func _on_timer_bismuthine_timeout():
	bismuthine -= 1
	update_counts()
	if bismuthine <= 0:
		end_mission(true)


func _on_main_character_collected_scrap(value):
	iron += value
	update_counts()


func _on_ground_player_exited_area():
	%RadarUI.set_arrow_active(true)


func _on_ground_player_entered_area():
	%RadarUI.set_arrow_active(false)
