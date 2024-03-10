extends RichTextLabel

@export var constant_name: StringName

# Called when the node enters the scene tree for the first time.
func _ready():
	if not constant_name.is_empty():
		text = $/root/Main.get(constant_name)
