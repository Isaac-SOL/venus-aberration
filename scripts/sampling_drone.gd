class_name SamplingDrone extends Scannable

func find_deposit() -> Deposit:
	for area in get_overlapping_areas():
		if area is Deposit:
			return area
	return null

func disappear():
	%AnimationPlayer.play("disappear")
