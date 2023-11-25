extends Sprite2D

var currentposition = 0
var maxposition = 0
var speed = 300

func _process(delta):
	currentposition = int(-global_position.y + 552)
	if currentposition > maxposition:
		maxposition = currentposition

	print(global_position.y)

	if Input.is_key_pressed(KEY_UP):
		position.y -= speed * delta
	if Input.is_key_pressed(KEY_DOWN):
		position.y += speed * delta
	if Input.is_key_pressed(KEY_LEFT):
		position.x -= speed * delta
	if Input.is_key_pressed(KEY_RIGHT):
		position.x += speed * delta
