class_name UpgradeSystem extends Node

var labels: Array[RichTextLabel]
var allow_extraction_upgrades: bool = false

const upgrades: Array[Array] = [
	[
		{
			title = "create the\nground radar",
			message = "[color=yellow]detects deposits",
			price = 60
		},
		{
			title = "upgrade\nradar speed",
			message = "+ 33% speed",
			price = 200
		},
		{
			title = "upgrade\nradar speed",
			message = "+ 25% speed",
			price = 300
		},
	],
	[
		{
			title = "upgrade\nradar range",
			message = "+ 50% range",
			price = 300
		},
		{
			title = "upgrade\nradar range",
			message = "+ 33% range",
			price = 500
		},
	],
	[
		{
			title = "upgrade\nspeed",
			message = "+ 50% speed",
			price = 100
		},
		{
			title = "upgrade\nspeed",
			message = "+ 50% speed",
			price = 200
		},
		{
			title = "upgrade\nspeed",
			message = "+ 50% speed",
			price = 300
		},
		{
			title = "upgrade\nspeed",
			message = "+ 20% speed",
			price = 500
		}
	],
	[
		{
			title = "upgrade\nengine eff.",
			message = "- 50% Bi/sec",
			price = 250
		},
	],
	[
		{
			title = "upgrade\nextract. speed",
			message = "+ 100% speed",
			price = 250
		},
		{
			title = "upgrade\nextract. speed",
			message = "+ 50% speed",
			price = 350
		},
	],
	[
		{
			title = "extract iron\nfrom galena",
			message = "30% gal -> fe",
			price = 500
		}
	],
]

var levels: Array[int] = [0, 0, 0, 0, 0, 0]

func get_upgrade_level(pos: int) -> int:
	if pos >= levels.size():
		return 0
	return levels[pos]

func get_upgrade_info(pos: int) -> Dictionary:
	if pos >= levels.size():
		return {}
	if pos == 1 and levels[0] == 0:
		return {}
	if not allow_extraction_upgrades and pos in [4, 5]:
		return {}
	if levels[pos] >= upgrades[pos].size():
		return {}
	
	var info : Dictionary = upgrades[pos][levels[pos]]
	
	# Emphasize engine efficiency if bismuthine is low
	if not info.is_empty() and pos == 3:
		if (levels[3] == 0 and $/root/Main.bismuthine <= 1000) or (levels[3] == 1 and $/root/Main.bismuthine <= 400):
			info = {
				title = info["title"],
				message = "[color=yellow]" + info["message"],
				price = info["price"]
			}
	
	return info

func get_upgrade_text(pos: int) -> String:
	var info: Dictionary = get_upgrade_info(pos)
	if info == {}:
		return ""
	var text: String = "[center][color=lightgreen][" + str(pos + 1) + "][color=green] "
	text += info["title"] + "\n" + info["message"] + "\n"
	text += "[color=lightgreen]{" + str(info["price"]) + " Fe}"
	return text

func get_upgrade_price(pos: int) -> int:
	var info: Dictionary = get_upgrade_info(pos)
	if info == {}:
		return 0
	return info["price"]

func is_upgrade_valid(pos: int, available_iron: int) -> bool:
	if pos >= upgrades.size():
		return false
	if pos == 1 and levels[0] == 0:
		return false
	var info: Dictionary = get_upgrade_info(pos)
	if info == {}:
		return false
	if info["price"] > available_iron:
		return false
	return true

func perform_upgrade(pos: int):
	var price: int = get_upgrade_price(pos)
	if price == 0:
		return
	match [pos, levels[pos]]:
		[0, 0]:
			%RadarUI.visible = true
		[0, 1]:
			%Radar.rot_speed = (PI * 2.0) / 4
			%RadarUI.point_lifetime = 4
		[0, 2]:
			%Radar.rot_speed = (PI * 2.0) / 3
			%RadarUI.point_lifetime = 3
		[1, _]:
			%Radar.set_shape_level(levels[pos] + 1)
			%RadarUI.set_radar_level(levels[pos] + 1)
		[2, 3]:
			%MainCharacter.acceleration *= 1.2
		[2, _]:
			%MainCharacter.acceleration *= 1.5
		[3, _]:
			%TimerBismuthine.wait_time *= 2
			%BatterySprite.set_frame_and_progress(0, 0)
			%BatterySprite.pause()
		[4, _]:
			$"..".extraction_factor = levels[pos] + 2
		[5, _]:
			$"..".galena_extraction = true
	levels[pos] += 1
