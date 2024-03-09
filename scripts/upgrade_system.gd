class_name UpgradeSystem extends Node

var labels: Array[RichTextLabel]

const upgrades: Array[Array] = [
	[
		{
			title = "upgrade speed",
			message = "+ 50% speed",
			price = 100
		},
		{
			title = "upgrade speed",
			message = "+ 50% speed",
			price = 150
		},
		{
			title = "upgrade speed",
			message = "+ 50% speed",
			price = 250
		},
		{
			title = "upgrade speed",
			message = "+ 50% speed",
			price = 500
		}
	],
	[
		{
			title = "create the\nground radar",
			message = "[color=yellow]detects metals",
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
			price = 200
		},
		{
			title = "upgrade\nradar speed",
			message = "+ 33% speed",
			price = 350
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
			title = "upgrade\nengine eff.",
			message = "- 50% Bi/sec",
			price = 200
		},
		{
			title = "upgrade\nengine eff.",
			message = "- 50% Bi/sec",
			price = 500
		},
	],
	[
		{
			title = "upgrade\nextract. speed",
			message = "+ 100% speed",
			price = 150
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

func get_upgrade_info(pos: int) -> Dictionary:
	if pos >= levels.size():
		return {}
	if pos == 2 and levels[1] == 0:
		return {}
	if levels[pos] >= upgrades[pos].size():
		return {}
	return upgrades[pos][levels[pos]]

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
	if pos == 2 and levels[1] == 0:
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
		[0, _]:
			%MainCharacter.acceleration *= 1.5
		[1, 0]:
			%RadarUI.visible = true
		[1, 1]:
			%Radar.rot_speed = (PI * 2.0) / 4
			%RadarUI.point_lifetime = 4
		[1, 2]:
			%Radar.rot_speed = (PI * 2.0) / 3
			%RadarUI.point_lifetime = 3
		[1, 3]:
			%Radar.rot_speed = (PI * 2.0) / 2
			%RadarUI.point_lifetime = 2
		[2, _]:
			%Radar.set_shape_level(levels[pos] + 1)
			%RadarUI.set_radar_level(levels[pos] + 1)
		[3, _]:
			%TimerBismuthine.wait_time *= 2
		[4, _]:
			$"..".extraction_factor = levels[pos] + 2
		[5, _]:
			$"..".galena_extraction = true
	levels[pos] += 1
