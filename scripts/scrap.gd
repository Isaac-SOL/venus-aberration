class_name Scrap extends Scannable

var value: int = 0
var speed: Vector2 = Vector2.ZERO
var angular_speed: float = 0

func _process(delta):
	super._process(delta)
	global_position += speed * delta
	global_rotation += angular_speed * delta

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func set_sprite(new_sprite: Texture2D):
	%Sprite.texture = new_sprite
