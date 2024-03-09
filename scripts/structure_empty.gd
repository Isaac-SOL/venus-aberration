extends Deposit

# Called when the node enters the scene tree for the first time.
func _ready():
	super._ready()
	rotation = randf() * 2 * PI


func _on_area_entered(area):
	if area is PlayerCharacter:
		get_tree().call_group("Structures", "wake_up")
