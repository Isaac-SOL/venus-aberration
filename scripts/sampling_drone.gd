class_name SamplingDrone extends Scannable

func find_deposit() -> Deposit:
	for area in get_overlapping_areas():
		if area is Deposit:
			return area
	return null

func is_on_structure_causing_extinction() -> bool:
	for area in get_overlapping_areas():
		if (area is Structure or area is DroneKiller) && area.causes_extinction():
			area.caused_extinction()
			return true
	return false

func is_on_structure_causing_destruction() -> bool:
	for area in get_overlapping_areas():
		if (area is Structure or area is DroneKiller) && area.causes_destruction():
			area.caused_extinction()
			return true
	return false

func disappear():
	%AnimationPlayer.play("disappear")

func destroy_slow():
	%AnimationPlayer.play("destroy_slow")

func destroy_immediate():
	queue_free()
