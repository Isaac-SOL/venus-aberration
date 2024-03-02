extends Sprite2D

@export var lifetime: float = 5
@export var color_over_lifetime: Gradient

var current_lifetime = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	current_lifetime += delta
	modulate = color_over_lifetime.sample(current_lifetime / lifetime)
	if current_lifetime > lifetime:
		queue_free()
